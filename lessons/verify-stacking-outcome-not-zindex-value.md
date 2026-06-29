# A High z-index Is Not a Stacking Guarantee — Verify the Paint Outcome, Not the Computed Value

date: 2026-06-24
scope: frontend / css / verification
rule: z-index only orders within its stacking context; verify overlay layering by paint outcome (elementFromPoint), not the computed value.

## Why
A dropdown menu was being covered by a decorative fixed overlay (`fixed; z-index:60`). I "fixed" it by bumping the menu to `z-[70]` and "verified" by injecting an element with that class and reading `getComputedStyle().zIndex === 70`. The check passed; the bug remained. The menu lived inside a `relative z-10` wrapper — a **stacking context** — so its `z-70` only ordered it *within that wrapper*; the whole wrapper sat at z-10 in the root, below the root-level overlay at z-60. `z-index` is **relative to the stacking context**, and a positioned ancestor with a z-index (or `transform`/`opacity<1`/`filter`/`will-change`/`isolation`) traps every descendant at the ancestor's level. My computed-value check confirmed the number while the real paint order was still wrong. A `document.elementFromPoint()` test over the overlap returned the overlay — exposing it instantly.

## How to apply
- To prove an overlay is on top, test the **rendered outcome**, not a value:
  - `document.elementFromPoint(x, y)` at the overlap point returns the actually-topmost element. (Watch for `pointer-events:none` elements — they're skipped by the hit-test; flip it temporarily or judge by parity.)
  - Or walk the overlay's **ancestor chain** to the root and flag any ancestor that creates a stacking context (positioned + non-auto z-index, `transform`, `opacity<1`, `filter`, `will-change`, `isolation:isolate`, `contain`).
- `getComputedStyle(el).zIndex` proves the value parsed, *not* that the element paints on top. Never conclude layering from it.
- Fix a trap at its source: drop the trapping ancestor's z-index (so it stops creating a context) or portal the overlay to the document root — **not** by raising the trapped element's z-index (which can't escape its context).

## Disposition
First occurrence (a light-theme overlay fix). The proxy-verification flavor — checking a stand-in for the real mechanism — is the same trap as [[verify-tooling-mechanism-not-user-as-test-harness]]; this is its CSS-stacking instance. Caught by an independent skeptic that verified the real outcome. Captured.
