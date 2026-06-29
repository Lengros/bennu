#!/usr/bin/env python3
"""Normalize a set of animation sprite frames to a uniform character size.

Two non-obvious choices (see lessons/normalize-sprite-frames-by-area-and-baseline.md):
  * SIZE metric = silhouette AREA, not bbox height/width. Area is pose-robust: a
    crouched/stretched pose has the same "amount of character" as a tall one, so
    scaling by sqrt(medianArea/area) equalizes apparent size across poses. Height
    or width over-inflates low/wide poses.
  * VERTICAL placement = align the bbox BOTTOM to a common baseline, NOT center.
    Centering makes feet sit at different heights → the character bobs as frames
    cycle. Baseline-align so the feet stay put. Pick the baseline to match the
    render's transform-origin (e.g. transform-origin: 50% 85% → feet near bottom).

Usage:
  python3 normalize_frames.py SRC_DIR DST_DIR [--clamp LO HI] [--baseline auto|N]
                              [--align-x center|N] [--pad N]

  --clamp LO HI   clamp the per-frame scale factor (default 0.70 1.45). Stops a
                  folded pose (curled sleeper = little area) from blowing up and a
                  sprawled pose from vanishing. Output is re-clamped to the canvas.
  --baseline      common bbox-bottom Y on the output canvas. 'auto' = median of the
                  inputs' bbox bottoms (default). An int pins it explicitly.
  --align-x       horizontal placement: 'center' (default) or an explicit left X.
  --pad           ignore alpha <= this when computing the silhouette (default 16),
                  i.e. treat near-transparent fringe as empty.

Canvas size is taken from the first input and kept unchanged for every frame, so the
render's object-fit math is untouched. Verify the result two ways: re-measure (areas
should cluster, σ ≈ a few %), and montage at the ACTUAL render size to eyeball it:
  magick montage DST/*.png -tile 4x -geometry 88x88+3+3 -background '#888' \\
    -font /System/Library/Fonts/Helvetica.ttc -label '%f' /tmp/preview.png
(the -font flag is required on macOS or montage errors; -geometry WxH must mirror the
in-app rendered box — that montage is then a faithful no-server preview of the look.)
"""
import argparse, glob, math, os, statistics, sys
from PIL import Image


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("src")
    ap.add_argument("dst")
    ap.add_argument("--clamp", nargs=2, type=float, default=[0.70, 1.45], metavar=("LO", "HI"))
    ap.add_argument("--baseline", default="auto")
    ap.add_argument("--align-x", default="center")
    ap.add_argument("--pad", type=int, default=16)
    args = ap.parse_args()

    files = sorted(glob.glob(os.path.join(args.src, "*.png")))
    if not files:
        sys.exit(f"no PNGs in {args.src}")
    os.makedirs(args.dst, exist_ok=True)

    # First pass: measure bbox + silhouette area for every frame.
    data = {}
    for f in files:
        im = Image.open(f).convert("RGBA")
        alpha = im.split()[3]
        bbox = alpha.getbbox()
        if bbox is None:  # fully transparent frame — copy through untouched
            data[f] = (im, None, 0)
            continue
        mask = alpha.point(lambda p: 255 if p > args.pad else 0)
        area = sum(mask.histogram()[1:])  # opaque pixel count
        data[f] = (im, bbox, area)

    cw, ch = Image.open(files[0]).size
    areas = [a for *_, a in data.values() if a > 0]
    bottoms = [b[3] for _, b, a in data.values() if b is not None]
    tgt_lin = math.sqrt(statistics.median(areas))
    baseline = round(statistics.median(bottoms)) if args.baseline == "auto" else int(args.baseline)
    lo, hi = args.clamp
    print(f"canvas={cw}x{ch}  target linear={tgt_lin:.1f}  baseline y={baseline}")

    # Second pass: scale to median area, seat the bbox bottom on the baseline.
    for f in files:
        im, bbox, area = data[f]
        if bbox is None or area == 0:
            im.save(os.path.join(args.dst, os.path.basename(f)))
            continue
        l, t, r, b = bbox
        scale = max(lo, min(hi, tgt_lin / math.sqrt(area)))
        nw, nh = max(1, round((r - l) * scale)), max(1, round((b - t) * scale))
        if nw > cw or nh > ch:  # never exceed the canvas
            k = min(cw / nw, ch / nh)
            nw, nh = round(nw * k), round(nh * k)
        crop = im.crop(bbox).resize((nw, nh), Image.LANCZOS)
        canvas = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
        px = round(cw / 2 - nw / 2) if args.align_x == "center" else int(args.align_x)
        py = min(ch - nh, baseline - nh)  # bbox bottom on the baseline
        canvas.paste(crop, (px, py), crop)
        canvas.save(os.path.join(args.dst, os.path.basename(f)))

    print(f"wrote {len(files)} frames -> {args.dst}")


if __name__ == "__main__":
    main()
