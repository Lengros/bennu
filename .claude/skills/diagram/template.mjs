// template.mjs — copyable skeleton for a code-rendered diagram.
// Pattern: a Node generator inlines Lucide icons + lays out nodes by coordinates,
// then emits a self-contained HTML. Render it with ./render.sh.
//
//   cd <scratch>; npm init -y; npm i lucide-static
//   node template.mjs           # writes out.html (icons inlined -> no node_modules needed to render)
//   <skill>/render.sh out.html out.png 760 420 ffffffff
//
// Two layout modes exist (see SKILL.md):
//   • simple      — flex rows/columns + an arrow glyph between cards (linear / tiered flows)
//   • coordinate  — nodes at {x,y,w,h}, an SVG `.edges` layer of bezier paths with arrowheads.
//                   REQUIRED whenever you have branches, fast-paths, or back-edges.
// This skeleton shows the coordinate mode (the general one). Delete what you don't need.

import { readFileSync, writeFileSync } from "node:fs";

// ── icon helper: inline Lucide SVG, color via parent `currentColor` ───────────
// lucide-static uses stroke="currentColor", so set `color` on the wrapper to tint.
// `<img src=icon.svg>` will NOT take your color — you must inline.
function ico(name) {
  try {
    let s = readFileSync(`node_modules/lucide-static/icons/${name}.svg`, "utf8");
    return s.replace(/<!--[\s\S]*?-->/g, "").trim()
            .replace(/\swidth="24"/, "").replace(/\sheight="24"/, "")  // let CSS size it
            .replace(/class="[^"]*"/, `class="ico"`);
  } catch {
    console.warn(`! icon "${name}" not found — run: npm i lucide-static`);
    return `<svg class="ico" viewBox="0 0 24 24"><circle cx="12" cy="12" r="9" fill="none" stroke="currentColor" stroke-width="2"/></svg>`;
  }
}

// ── geometry: define every node once; derive edges from the same coords ───────
const CW = 760, CH = 360;
const N = {
  src:   { x: 30,  y: 140, w: 200, h: 80, icon: "database",   title: "Source",    sub: "where data enters" },
  proc:  { x: 280, y: 140, w: 200, h: 80, icon: "cpu",        title: "Process",   sub: "transform / decide" },
  out:   { x: 530, y: 60,  w: 200, h: 80, icon: "send",       title: "Output A",  sub: "primary result" },
  alt:   { x: 530, y: 220, w: 200, h: 80, icon: "monitor",    title: "Output B",  sub: "secondary surface" },
};
const R = n => N[n].x + N[n].w, L = n => N[n].x, MY = n => N[n].y + N[n].h / 2;

// smooth horizontal bezier edge with arrowhead
const edge = (x1, y1, x2, y2, { color = "#1f5a3f", dash = false } = {}) => {
  const dx = Math.max(34, (x2 - x1) / 2);
  return `<path d="M ${x1} ${y1} C ${x1 + dx} ${y1}, ${x2 - dx} ${y2}, ${x2} ${y2}"
    fill="none" stroke="${color}" stroke-width="2" ${dash ? 'stroke-dasharray="6 5"' : ""} marker-end="url(#ah)"/>`;
};

const node = k => {
  const n = N[k];
  return `<div class="node" style="left:${n.x}px;top:${n.y}px;width:${n.w}px;height:${n.h}px">
    <span class="n-ic">${ico(n.icon)}</span>
    <div class="n-tx"><b>${n.title}</b><small>${n.sub}</small></div></div>`;
};

const html = `<!DOCTYPE html><html><head><meta charset="utf-8"><style>
*{margin:0;box-sizing:border-box}
:root{ --paper:#f7f8f6; --card:#fff; --line:#e2e6e0; --ink:#1a1f1a; --faint:#6b736a; --accent:#1f5a3f; }
body{font-family:-apple-system,system-ui,"Segoe UI",sans-serif;color:var(--ink)}
.poster{width:${CW + 60}px;padding:30px;background:var(--paper)}
.canvas{position:relative;width:${CW}px;height:${CH}px}
/* GOTCHA: scope the edge layer with a class. A bare ".canvas svg" rule also hits every
   inline icon SVG (they're descendants too) and flings the icons to the corners. */
.canvas > svg.edges{position:absolute;inset:0;width:100%;height:100%;z-index:0;overflow:visible}
.node{position:absolute;z-index:1;display:flex;align-items:center;gap:11px;background:var(--card);
  border:1px solid var(--line);border-radius:13px;padding:12px 14px;
  box-shadow:0 1px 2px rgba(0,0,0,.04),0 4px 14px rgba(0,0,0,.05)}
.n-ic{width:34px;height:34px;border-radius:9px;flex-shrink:0;display:flex;align-items:center;
  justify-content:center;background:#e7ede9;color:var(--accent)}
.n-ic .ico{width:19px;height:19px}            /* icons stay in flow, sized here */
.ico{display:block}
.n-tx b{font-size:14px;display:block} .n-tx small{font-size:11.5px;color:var(--faint)}
</style></head><body><div class="poster"><div class="canvas">
  <svg class="edges" viewBox="0 0 ${CW} ${CH}">
    <defs><marker id="ah" markerWidth="9" markerHeight="9" refX="7" refY="4.5" orient="auto">
      <path d="M0,0 L8,4.5 L0,9 Z" fill="#1f5a3f"/></marker></defs>
    ${edge(R("src"), MY("src"), L("proc"), MY("proc"))}
    ${edge(R("proc"), MY("proc"), L("out"), MY("out"))}
    ${edge(R("proc"), MY("proc"), L("alt"), MY("alt"))}
  </svg>
  ${Object.keys(N).map(node).join("\n  ")}
</div></div></body></html>`;

writeFileSync("out.html", html);
console.log("written out.html — now: render.sh out.html out.png 820 420 f7f8f6ff");
