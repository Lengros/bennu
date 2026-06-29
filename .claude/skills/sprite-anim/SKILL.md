---
name: sprite-anim
description: Process and verify sprite/animation work for web UIs — normalize a set of animation frames to a uniform character size (area-scale + baseline-align) and verify CSS/JS animations in a real browser via the Chrome DevTools Protocol. Use when a task touches sprite frames, sprite-sheet alignment, or a decorative/UI animation whose on-screen motion must be confirmed (drift, jump, stall, fade). Distilled from animated-character-sprite work, 2026-06-12.
---

# /sprite-anim — sprite frames & browser-verified animation

Two capabilities that recur together when polishing a sprite-driven UI animation:
**(A)** make a set of frames look like one consistent character, and **(B)** prove the
animation actually behaves on screen — not just in the code. Both ship as runnable
scripts beside this file; the gotchas that make them non-obvious live in two lessons.

The cardinal rule for both: **a code read is not evidence about pixels.** Re-measure the
output, and verify motion in a real browser. The session that produced this skill burned
an iteration dismissing real drift as a "measurement artifact" — don't.

---

## A — Normalize sprite frames to a uniform character size

**When:** frames of the same character render at visibly different sizes or bob
vertically as the animation cycles (sitting frame bigger than running frame; feet at
different heights).

**Two choices, each with a wrong-looking default — see
`lessons/normalize-sprite-frames-by-area-and-baseline.md`:**

1. **Size by silhouette AREA, not bbox height/width.** Area is pose-robust — a crouched
   or stretched pose holds the same "amount of character" as a tall one. Scale each frame
   by `sqrt(medianArea / frameArea)`. Height-normalizing inflates low/wide poses into
   giants. Clamp the factor (default `[0.70, 1.45]`) so a folded pose (curled sleeper =
   little area) doesn't blow up, and re-clamp to the canvas.
2. **Align the bbox BOTTOM to a baseline, not center.** Centering puts feet at different
   heights → the character bobs frame-to-frame. Seat every bbox bottom on one baseline.
   Pick the baseline to match the render's `transform-origin` (e.g. `50% 85%` → feet near
   bottom → baseline low on the canvas).

**Run:**
```
python3 .claude/skills/sprite-anim/normalize_frames.py SRC_DIR DST_DIR \
    [--clamp LO HI] [--baseline auto|N] [--align-x center|N] [--pad N]
```
Canvas size is preserved per frame, so the render's `object-fit` math is untouched. Write
to a scratch DST first, verify, then copy into the repo's frames dir (in a worktree, per
the code-changes-go-to-worktree rule).

**Verify two ways (do both):**
- **Re-measure:** opaque-pixel area of the outputs should cluster (spread ≈ 1.1×, σ ≈ a
  few %). The script prints `target linear` + `baseline y`; a quick re-measure loop
  confirms the cluster.
- **Montage at the ACTUAL render size** — a faithful no-server preview of the in-app look:
  ```
  magick montage DST/*.png -tile 4x -geometry 88x88+3+3 -background '#888' \
      -font /System/Library/Fonts/Helvetica.ttc -label '%f' /tmp/preview.png
  ```
  `-geometry WxH` must mirror the in-app rendered box (it mirrors `object-fit: contain`).
  The `-font` flag is **required** on macOS or montage errors "unable to read font".
  `-append`/`+append` operators go AFTER the input filenames, not before.
- Don't burn effort on a clamped outlier the frame selector never renders — check which
  frames the code actually uses first.

---

## B — Verify a CSS/JS animation in a real browser (CDP)

**When:** an animation's on-screen behavior must be confirmed — does it drift to a
corner, jump, snap back, stall, or fade correctly? A code read cannot answer this.

**Run:** edit the `CONFIG` block (url, setup, trigger, probe, assertions) in
`.claude/skills/sprite-anim/verify-anim.mjs`, then `node verify-anim.mjs`. It launches
headless Chrome, samples the element's transform + `getBoundingClientRect` + opacity
across the whole animation window, screenshots chosen frames, and prints a verdict. No
Playwright, no test framework.

**Gotchas baked into the harness — and two binding lessons:**
- **Trust `getBoundingClientRect`, not the matrix.**
  `DOMMatrix(getComputedStyle(el).transform).m41` reflects only the `transform`
  *property* — NOT the separate CSS `scale`/`translate`/`rotate` properties. When the
  rect and the matrix disagree, the **rect is the truth** and the gap is real motion, not
  noise. See `lessons/css-scale-property-multiplies-translate.md`. (That same lesson: the
  individual `scale` property *multiplies* a `transform: translate()` offset per spec
  composition order → a "shrink in place" drifts toward 0,0. Shrink via
  `transform: translate() scale()` in one property, or split parent/child, or just fade.)
- **Verify on the main-checkout dev server, not a worktree.** A bundler's out-of-tree
  file-access allowlist can block a worktree's symlinked `node_modules` → blank page. Edit
  in the worktree, run your framework's codegen + type-check, merge to the working branch,
  then verify HMR on the single main-checkout dev server.
- **Navigate + sleep BEFORE touching `localStorage`** — the blank initial document throws
  a `SecurityError`. The harness does this; keep it if you adapt the flow.
- If the feature is gated on app state (e.g. an animated character that only mounts
  when `app.ready:true`), the seeded mock must satisfy the gate or the element never
  mounts.

---

## Lessons this skill is built on

| Lesson | What it locks in |
|---|---|
| `normalize-sprite-frames-by-area-and-baseline.md` | area for size, baseline for vertical, render-size montage to verify |
| `css-scale-property-multiplies-translate.md` | `scale` multiplies `translate`; trust `getBoundingClientRect` over the matrix |

If a new sprite/animation surprise appears, add a lesson and (on the second occurrence)
fold the fix back into the scripts here — don't let this skill calcify.
