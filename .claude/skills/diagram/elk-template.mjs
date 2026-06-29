// elk-template.mjs — AUTO-LAYOUT variant. Fixes the hand-placed-coordinate weakness of
// template.mjs while keeping the same custom HTML/CSS/SVG rendering (your design tokens,
// editable source). ELK computes node positions AND routes edges; you render the result.
//
//   cd <scratch>; npm init -y; npm i elkjs lucide-static
//   node elk-template.mjs        # -> out.html
//   <skill>/render.sh out.html out.png <W> <H> <bg>   # W/H are printed by this script
//
// Why ELK: the layered algorithm is built for directed node-link diagrams with ports and
// it AUTO-ROUTES edges (Dagre does not). You describe the graph declaratively; no x/y by hand.
//
// PARTITIONING (the stage-band pattern): set `elk.partitioning.activate` and give each node
// an `elk.partitioning.partition` index → ELK pins nodes into ordered layers (= stages).
// After layout, derive each partition's x-extent from its placed nodes and draw a stage
// header centered over the column. This recovers SOURCES…CHANNELS-style swimlane labels
// with ZERO hand-placed coordinates — headers move automatically when the graph changes.
// Docs: github.com/kieler/elkjs

import { readFileSync, writeFileSync } from "node:fs";
import ELK from "elkjs/lib/elk.bundled.js";

function ico(name) {
  try {
    return readFileSync(`node_modules/lucide-static/icons/${name}.svg`, "utf8")
      .replace(/<!--[\s\S]*?-->/g, "").trim()
      .replace(/\swidth="24"/, "").replace(/\sheight="24"/, "")
      .replace(/class="[^"]*"/, `class="ico"`);
  } catch { return `<svg class="ico" viewBox="0 0 24 24"><circle cx="12" cy="12" r="9" fill="none" stroke="currentColor" stroke-width="2"/></svg>`; }
}

// ── 1. Describe the graph. `part` = stage index; ELK places, you just declare membership.
const META = {
  src:  { part: 0, icon: "database", title: "Source",   sub: "data enters" },
  proc: { part: 1, icon: "cpu",      title: "Process",  sub: "transform" },
  store:{ part: 2, icon: "box",      title: "Store",    sub: "persist" },
  outA: { part: 3, icon: "send",     title: "Output A", sub: "primary" },
  outB: { part: 3, icon: "monitor",  title: "Output B", sub: "surface" },
};
const STAGES = [[0, "Sources"], [1, "Process"], [2, "Store"], [3, "Output"]];
const NW = 196, NH = 64;

const graph = {
  id: "root",
  layoutOptions: {
    "elk.algorithm": "layered",
    "elk.direction": "RIGHT",
    "elk.partitioning.activate": "true",                       // <-- enable stage bands
    "elk.layered.spacing.nodeNodeBetweenLayers": "100",
    "elk.spacing.nodeNode": "40",
    "elk.edgeRouting": "SPLINES",
  },
  children: Object.keys(META).map(id => ({
    id, width: NW, height: NH,
    layoutOptions: { "elk.partitioning.partition": String(META[id].part) }, // <-- pin to stage
  })),
  edges: [
    { id: "e1", sources: ["src"],  targets: ["proc"] },
    { id: "e2", sources: ["proc"], targets: ["store"] },
    { id: "e3", sources: ["store"], targets: ["outA"] },
    { id: "e4", sources: ["store"], targets: ["outB"] },
    { id: "e5", sources: ["outB"], targets: ["store"] }, // back-edge — ELK routes it across partitions
  ],
};

// ── 2. Lay out: ELK fills x/y on nodes (respecting partitions) and routes the edges.
const laid = await new ELK().layout(graph);

// derive each partition's x-extent from its placed nodes -> stage-header center
const ext = {};
for (const n of laid.children) {
  const p = META[n.id].part;
  ext[p] ??= { min: Infinity, max: -Infinity };
  ext[p].min = Math.min(ext[p].min, n.x);
  ext[p].max = Math.max(ext[p].max, n.x + n.width);
}
const stageHead = ([p, label]) =>
  `<div class="sh" style="left:${(ext[p].min + ext[p].max) / 2}px"><span class="sh-n">${p + 1}</span>${label}</div>`;

// ── 3. Render with YOUR styling. Edges from ELK's routed sections (start/bend/end).
const edgePath = (e) => e.sections.map(s =>
  "M " + [s.startPoint, ...(s.bendPoints || []), s.endPoint].map(p => `${p.x} ${p.y}`).join(" L ")).join(" ");
const nodeDiv = (n) => {
  const m = META[n.id];
  return `<div class="node" style="left:${n.x}px;top:${n.y}px;width:${n.width}px;height:${n.height}px">
    <span class="n-ic">${ico(m.icon)}</span><div class="n-tx"><b>${m.title}</b><small>${m.sub}</small></div></div>`;
};

const PAD = 30, STAGE = 30;
const W = Math.ceil(laid.width) + PAD * 2, H = Math.ceil(laid.height) + STAGE + PAD * 2;

const html = `<!DOCTYPE html><html><head><meta charset="utf-8"><style>
*{margin:0;box-sizing:border-box}
:root{ --paper:#f7f8f6; --card:#fff; --line:#e2e6e0; --ink:#1a1f1a; --faint:#6b736a; --accent:#1f5a3f; }
body{font-family:-apple-system,system-ui,"Segoe UI",sans-serif;color:var(--ink)}
.poster{padding:${PAD}px;background:var(--paper);width:${W}px}
.stages{position:relative;width:${laid.width}px;height:${STAGE}px}
.sh{position:absolute;top:3px;transform:translateX(-50%);display:flex;align-items:center;gap:7px;
  font-size:11.5px;font-weight:800;letter-spacing:.6px;text-transform:uppercase;color:var(--faint)}
.sh-n{width:19px;height:19px;border-radius:50%;background:var(--accent);color:#fff;font-size:10.5px;
  font-weight:800;display:flex;align-items:center;justify-content:center}
.canvas{position:relative;width:${laid.width}px;height:${laid.height}px}
.canvas > svg.edges{position:absolute;inset:0;width:100%;height:100%;z-index:0;overflow:visible}
.node{position:absolute;z-index:1;display:flex;align-items:center;gap:10px;background:var(--card);
  border:1px solid var(--line);border-radius:13px;padding:10px 12px;
  box-shadow:0 1px 2px rgba(0,0,0,.04),0 4px 14px rgba(0,0,0,.05)}
.n-ic{width:32px;height:32px;border-radius:9px;flex-shrink:0;display:flex;align-items:center;
  justify-content:center;background:#e7ede9;color:var(--accent)}
.n-ic .ico{width:18px;height:18px}.ico{display:block}
.n-tx b{font-size:13.5px;display:block} .n-tx small{font-size:11px;color:var(--faint)}
</style></head><body><div class="poster">
  <div class="stages">${STAGES.map(stageHead).join("")}</div>
  <div class="canvas">
    <svg class="edges" viewBox="0 0 ${laid.width} ${laid.height}">
      <defs><marker id="ah" markerWidth="9" markerHeight="9" refX="7" refY="4.5" orient="auto">
        <path d="M0,0 L8,4.5 L0,9 Z" fill="#1f5a3f"/></marker></defs>
      ${laid.edges.map(e => `<path d="${edgePath(e)}" fill="none" stroke="#1f5a3f" stroke-width="2" marker-end="url(#ah)"/>`).join("\n      ")}
    </svg>
    ${laid.children.map(nodeDiv).join("\n    ")}
  </div>
</div></body></html>`;

writeFileSync("out.html", html);
console.log(`written out.html — now: render.sh out.html out.png ${W} ${H} f7f8f6ff`);
