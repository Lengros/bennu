# cyberpunk — high-tech control room

**Mood:** dark operational UI, neon signal colors, sharp panel geometry, dense-but-readable
content. "Mission systems online," not a marketing landing. Technical, tactical, premium;
energetic but not chaotic; luminous and interface-like; product-serious, not gamer-novelty.

**Proven on:** a product one-pager (cyberpunk + Counter-Strike variants), 2026-06-18.

## Bans (what this direction refuses)

- generic purple/blue gradient SaaS hero
- soft glassmorphism cards, rounded bubbly components
- decorative orbs / bokeh, stock cyberpunk-city photos
- animation that competes with reading

## Palette (tokens with roles)

```css
--bg:#07090d; --panel:#0d1118; --panel-2:#111722;
--ink:#eef7ff; --muted:#93a4b8; --faint:#526174;
--cyan:#2ef7ff; --magenta:#ff3df2; --lime:#a7ff4a; --amber:#ffd166; --red:#ff5b6e;
--line:rgba(46,247,255,.28); --line-soft:rgba(238,247,255,.12);
--shadow:0 0 0 1px rgba(46,247,255,.16), 0 18px 70px rgba(0,0,0,.45);
```

- **cyan** — primary system signal, borders, technical labels, step 01
- **magenta** — counter-signal, AI panels, glitch offset
- **lime** — validation / success / decisive action
- **amber** — warnings, human judgment, mission status
- **red** — alert, failure mode
- **ink** — main text; never pure white except tiny highlights

## Background (layered CSS, no images)

```css
background:
  linear-gradient(90deg,rgba(46,247,255,.05) 1px,transparent 1px),
  linear-gradient(0deg,rgba(46,247,255,.04) 1px,transparent 1px),
  repeating-linear-gradient(180deg,rgba(255,255,255,.025) 0 1px,transparent 1px 6px),
  linear-gradient(135deg,#05070b 0%,#09101a 48%,#140b18 100%);
background-size:48px 48px,48px 48px,100% 6px,100% 100%;
```
Plus a fixed low-opacity overlay with angled cyan/magenta beams (`mix-blend-mode:screen`).

## Type & signature mechanic

- System fonts only: `Inter, ui-sans-serif, system-ui, …` body; `ui-monospace, SFMono-Regular,
  Menlo, Consolas, monospace` for technical labels.
- H1 uppercase, huge, tight; labels small uppercase mono with wide letter-spacing (+, never −).
- **Signature: `border-radius:0` + `clip-path` corner notches** on cards, neon 1px borders,
  one-word **glitch** via text-shadow:
  ```css
  .glitch{text-shadow:3px 0 0 rgba(255,61,242,.72),-3px 0 0 rgba(46,247,255,.62),0 0 34px rgba(46,247,255,.26)}
  ```
  Status card notch: `clip-path:polygon(0 0,calc(100% - 18px) 0,100% 18px,100% 100%,18px 100%,0 calc(100% - 18px))`.

## Component patterns

- **Status / signal card** — angular, 1px neon border, the clip-path notch, soft inner glow.
- **Directive panels** — cyan top-border = "system/truth", magenta top-border = "AI/skeptic".
  Short principle, not a paragraph dump.
- **Pipeline cards** — number + phase label, short title, one-sentence tagline, 2 compact
  micro-blocks, an AI strip. Stable `min-height` on desktop; never resize on hover.
- **AI strip** — magenta accent; phrase AI as operational support ("AI: draft…, expose…,
  check…"), never "AI decides / replaces / guarantees".
- **Chips** — small uppercase mono for sources/tools/statuses (code · DB · logs · users · policy).

## Voice (if writing labels, not body copy)

Direct, sharp, mission-like, no SaaS fluff. Good: "Do not clone the legacy." "The prototype
shows shape, not truth." Avoid: "seamless transformation", "leverage AI to optimize",
"next-generation platform".

## Responsive & print

- Desktop: pipeline cards in one row, control panels in 3 columns.
- Mobile (`@media max-width:1120px` → 1fr; `640px` tighten): stack everything, H1 ≈38–42px,
  no horizontal scroll.
- PDF: `@media print{ @page{size:landscape;margin:10mm} body{-webkit-print-color-adjust:exact} }`.

## Reuse checklist

- One cyberpunk hero, not a marketing hero.
- Palette = black/cyan/magenta/lime/amber; no dominant purple gradient.
- Content decision-oriented and scannable; cards don't resize on hover.
- Mobile: no horizontal overflow. AI framed as support/skeptic, not authority.
- One strong bottom-line warning or win condition.
- Opens locally with no external font/image dependency.

## Variant: Counter-Strike / tactical

Same skeleton, swapped skin — proven sibling. Shift accents to tactical
amber/orange + concrete grey, squared HUD framing, stencil/condensed display, "operator
briefing" voice. The structure (status card → directives → pipeline → control panels →
bottom line) carries over unchanged; only the token set + label voice change. This is the
template lesson: **structure is reusable, the skin is the variable.**
