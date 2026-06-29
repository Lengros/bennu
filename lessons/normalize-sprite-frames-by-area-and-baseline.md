# Normalizing Animation Sprite Frames: Scale by Silhouette Area, Align to a Baseline (Not Center)

date: 2026-06-12
scope: frontend / image-pipeline / sprites
rule: Unify sprite-frame sizes by scaling to median silhouette area (pose-robust); align to a baseline, not center, else the character bobs.

## Why
An animated character sprite drew the same character at inconsistent scales across its 16 sprite frames (alpha silhouette area ranged 8.5k–21k px, ~2.5×) and at inconsistent placement (sleep/strain/landing sat low or off to one side). Two normalization choices were non-obvious and each had a wrong-looking alternative:
- **Size metric.** Normalizing by bounding-box *height* over-inflates low/stretched poses (a pouncing or crawling character is short and wide → scaled up it becomes huge); by *width* it's the mirror problem. The pose-robust scalar is **silhouette area**: scale each frame by `sqrt(medianArea / frameArea)`. That equalizes "how much character" regardless of whether the pose is tall-compact or low-stretched. After: area spread 1.1× (σ≈2%). (Caveat: area mildly inflates *folded* poses — a curled sleeping pose has little area — so clamp the scale factor, e.g. `[0.70, 1.45]`, and clamp again so nothing exceeds the canvas.)
- **Vertical placement.** The instinct is "center the character in the canvas," but for an animation that's wrong: a tall sitting frame centered and a low crawling frame centered put the feet at different heights, so the character *bobs* as frames cycle. Align the **bbox bottom to a common baseline** instead. Confirm where the baseline belongs from the render code — here `.sprite` uses `transform-origin: 50% 85%`, i.e. the component already assumes feet near the bottom, so baseline-align (median bottom y≈178 on a 192 canvas) matched that and kept the existing feel.

## How to apply
PIL recipe: for each frame, `bbox = alpha.getbbox()`, `area = count(alpha > 16)`; `target = sqrt(median(areas))`; `scale = clamp(target / sqrt(area), lo, hi)`; resize the *cropped* bbox (LANCZOS), paste onto a fresh transparent canvas at `x = (CW-nw)/2` (center) and `y = baseline - nh` (bottom on baseline), clamping so `nw,nh ≤ canvas`. Keep the canvas size unchanged so the render's `object-fit: contain` math is untouched. Verify two ways: (1) re-measure area/bottom of the outputs (they should cluster); (2) montage the outputs at the **actual render size** (e.g. `-geometry 88x88`, which mirrors `object-fit: contain`) — that montage is a faithful preview of the in-app look, so you can judge size/baseline uniformity without a live server. Unused frames (here `landing`, `fall-down` — never returned by the frame selector) needn't be perfect; don't burn effort on a clamped outlier nobody sees.

## Disposition
First occurrence (animated sprite frame normalization, 2026-06-12) — worked first pass, shipped. Reusable recipe for any future sprite/asset-set normalization: area for size, baseline for vertical, render-size montage for verification.
