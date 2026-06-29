---
name: diagram
description: Draw polished diagrams, schemas, architecture maps, data-flow / lifecycle diagrams, workflows, and infographics by rendering them from code (HTML/CSS + SVG → headless Chrome → PNG) — not by AI image generation. Use when the user wants a clear, editable visual of how a system, process, or set of relationships works, or likes an example diagram and wants something in that style. Produces accurate text, exact colors, and a versionable source you can re-edit. Russian triggers — "нарисуй схему", "сделай диаграмму", "визуализируй архитектуру", "схема воркфлоу", "инфографика", "нарисуй как это работает". Distilled from a real diagramming session, 2026-06-15.
---

# /diagram — render diagrams from code, not from a paint model

For anything with **labels, structure, or precise relationships** — architecture, data
flow, lifecycle, workflow, org/topology — render it from **HTML/CSS (+ SVG for connectors)
screenshotted by headless Chrome**. You get correct text, exact colors, and a source you
can re-edit and recolor in seconds. This stays the right call whenever you need exact
design tokens, fully custom composition, or pixel control with no external dependency.

Raster image-gen used to be disqualified by garbled text; that changed in 2025-26 (Nano
Banana Pro / Gemini 3 Pro Image now renders legible in-image text and is marketed for
infographics; GPT-image is strong too — Flux is still unreliable for fine text). Use it
**only for soft *illustrative* infographics**, not structured technical diagrams (still no
element-level editing, no exact palette). And in THIS environment raster is **UI-only, not
agent-drivable**: Nano Banana Pro is available via the work Gemini subscription UI, GPT-image
via the ChatGPT/Codex ($20) UI — no API key here. So for raster you produce a **prompt and
hand it off** to the user to run in the UI — that path is `/illustration-prompt`. See
"Reach past this skill when" below.

The whole advantage is a **tight visual loop**: write generator → render → **Read the PNG
(you can see it)** → fix → re-render. Lean on it.

---

## The pipeline

1. **Write a Node generator** (`.mjs`) that inlines icons + emits self-contained HTML.
   Copy `template.mjs` from this skill as the skeleton.
2. **Render** with `render.sh out.html out.png <W> <H> <bgHex>`.
3. **Read the PNG**, adjust, re-render. Crop by tuning window height (see Gotchas).
4. Work in a **`scratch/`** dir (gitignored). Keep only the final `.png` + its `.mjs`;
   `node_modules` (lucide-static ≈ 59 MB) is build-only junk — don't leave it lying around.

```
cd scratch && npm init -y && npm i lucide-static
node build.mjs                                   # -> build.html (icons inlined)
.claude/skills/diagram/render.sh build.html build.png 1220 900 f1f3efff
```

---

## Get these right BEFORE styling — they're what makes a diagram good or useless

**1. Pick the topology from the SUBJECT, not from a reference image.**
The single biggest failure mode (learned the hard way this session): the user shows an
example they *like the look of*, and you clone its **composition**. But composition
encodes a *specific* system shape. Reproduce the example's **aesthetic** (cards, icons,
palette) and choose the **structure** from what you're actually drawing:

| Subject shape | Right composition |
|---|---|
| One controller managing N identical units (e.g. an orchestrator → many deployments) | A control-plane header → grid of repeated unit cards → shared foundation bar |
| A layered system / service | Stacked tiers + a cross-cutting concerns rail down the side |
| **Data / product lifecycle** | Horizontal **sources → ingest → store → aggregate → channels**, with fast-paths and feedback edges drawn explicitly |
| A process / workflow | Stages left→right with branch and decision edges |

If you catch yourself reusing the example's layout for a different kind of system, stop —
that's the mistake.

**2. Ground every component in reality (the Bennu evidence rule).**
Don't draw a system from imagination. Read the real source first; tag each claim
`[Observed: path:lines]` or `[ASSUMPTION]`. Delegate a fresh **Explore** agent to map a
codebase if the surface is large. Mark status honestly on nodes — `implemented` /
`planned` / `external` / `stub` — instead of presenting aspiration as fact. This session's
first early draft invented a component that did not exist; reading the repo
replaced it with the real path.

**3. Steal the palette from the subject's own design system.**
If the thing you're drawing has a UI, grep its CSS for color tokens and use them verbatim
(`grep -nE '\-\-color|#[0-9a-f]{6}' <stylesheet>`). Pull the palette straight from
the app's own global stylesheet — far better than a guessed palette, and instantly
on-brand.

---

## Layout: three modes

- **Simple (flex).** Linear or tiered flows: cards in flex rows/columns, an arrow between
  them. Fast. For the connector use a **Lucide arrow icon in a small circle** — never a
  hand-rolled CSS triangle (it renders as an ugly grey nub against rounded card corners).
- **Coordinate-driven (SVG edges).** Define every node once as `{x,y,w,h}`, place the HTML
  divs absolutely, and draw an SVG `.edges` layer of bezier `<path>`s with `<marker>`
  arrowheads — all computed from the *same* coordinates. `template.mjs` is exactly this.
  A back-edge (e.g. "a settings screen writes a value back to the store") or a stage-skipping
  fast-path (e.g. "a live event bypasses the batch pipeline") can ONLY be shown
  honestly with real arrows — flex can't draw them. Use this when you want **total control
  of the composition** (a lifecycle diagram was hand-placed for exactly that reason).
- **Auto-layout (ELK).** The fix for hand-placing coordinates. Describe the graph
  declaratively (nodes with box sizes, edges with source/target); **elkjs** computes
  positions AND routes the edges — its `layered` algorithm is built for directed node-link
  graphs and, unlike Dagre, auto-routes edges (incl. back-edges). You still render with
  *your own* HTML/CSS/SVG reading ELK's output, so design tokens and editability are kept —
  only the x/y math is delegated. `elk-template.mjs` is a working example (`npm i elkjs`).
  Reach for this for **larger or evolving graphs** where manual placement doesn't scale;
  reach for coordinate-driven when the composition itself is the message.

---

## Icons: inline Lucide, don't reach for emoji

- `npm i lucide-static` → 1964 monochrome SVGs in `node_modules/lucide-static/icons/`.
  **Verify a name exists before using it:** `ls node_modules/lucide-static/icons | grep -i key`.
- **Inline the SVG** and tint via the parent's `color` (lucide uses `stroke="currentColor"`).
  An `<img src=icon.svg>` will **not** take your color — it renders default black.
- Strip the license comment and the fixed `width="24"/height="24"` so CSS controls size
  (`template.mjs`'s `ico()` does this).
- Emoji are quick and colorful but read childish and render inconsistently. **Default to
  Lucide** for anything technical; offer emoji only if the user wants a playful look.

---

## Gotchas (each one cost an iteration this session)

- **Scope SVG CSS selectors.** A rule like `.canvas svg { position:absolute; inset:0;
  width:100% }` also matches every **inline icon SVG** (they're descendants of `.canvas`),
  flinging icons into the top-left corner and leaving the tiles empty. Give the edge layer
  a class and target `.canvas > svg.edges` — never a bare `svg` selector inside a container
  that also holds inline icons.
- **No hand-rolled CSS-triangle arrows.** Use a Lucide arrow in a circle (flex mode) or
  SVG `<marker>` arrowheads (coordinate mode).
- **Cropping.** `--screenshot` captures the `--window-size` viewport; there is no full-page
  CLI flag. Window too short cuts the footer; too tall leaves dead space. Iterate the
  height, and set `--default-background-color` to the page bg so any excess is seamless.
- **Retina.** `--force-device-scale-factor=2` — without it text looks soft.
- **Read the PNG every iteration.** The Read tool shows you the image; that visual check
  is the point. Don't ship a diagram you haven't looked at.

---

## Aesthetic defaults that read "polished"

Rounded cards (radius 13–18) · soft layered shadow (`0 1px 2px …, 0 4px 14px …`) · hairline
borders · icons in tinted rounded tiles · a faint dotted background · **restrained palette:
one accent + at most one secondary** (resist the rainbow) · status badges · a small legend
when there's more than one kind of edge/node · optional serif headings for an "institutional"
feel. Less candy, more structure.

---

## Reach past this skill when

This skill owns **bespoke, brand-exact** diagrams. For two other jobs, hand off:

- **Fast / throwaway / generic structural diagram** (you don't need custom styling): drive
  **Mermaid via an MCP server** instead of writing a generator. `mcp-mermaid` (open-source,
  hustcc) generates Mermaid and returns svg/png/base64 with **syntax validation for
  multi-round correction**; the official **Mermaid Chart MCP** has a `validate_and_render`
  tool returning PNG/SVG — a built-in verify loop. Lower visual ceiling, but one call and
  the text is always correct. `UML-MCP` covers 30+ types (Mermaid, D2, Graphviz, C4, …) if
  you need a multi-engine gateway. (Eraser.io has the cleanest agent integration — MCP +
  Agent Skill — but non-watermarked output is pay-gated.)
- **Soft illustrative infographic** (the "designed poster" look, text accuracy now OK):
  hand off a **raster prompt** via `/illustration-prompt`. Best text rendering in 2025-26 is
  **Nano Banana Pro (Gemini 3 Pro Image)**; GPT-image is also strong. **In this environment
  both are UI-only** (Nano Banana = work Gemini sub; GPT-image = ChatGPT/Codex $20) — no API
  key — so you write the prompt and the user runs it in the UI. Not for structured technical
  diagrams (no element editing, no exact palette).

Rule of thumb: **structure + brand → this skill; structure + speed → Mermaid-MCP;
illustration → raster hand-off.**

## Files in this skill

| File | What it is |
|---|---|
| `render.sh` | headless-Chrome screenshot wrapper — `render.sh in.html out.png [W] [H] [bg]` |
| `template.mjs` | coordinate-driven generator — you place `{x,y,w,h}` (Lucide inline + SVG `.edges`) |
| `elk-template.mjs` | auto-layout variant — ELK places nodes & routes edges, you keep the styling (`npm i elkjs`) |

When a new diagramming surprise appears, fold the fix back into the templates / this file —
don't let the skill calcify. (Research provenance: deep-research run 2026-06-15 — ELK+SVG
pairing, Mermaid/UML MCP servers, Nano Banana Pro text rendering, all from primary sources.)
