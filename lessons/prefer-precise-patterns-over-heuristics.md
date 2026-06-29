# Prefer Precise Structured Patterns Over Heuristics for High-Precision Gates
date: 2026-06-09
scope: verification
rule: One realistic false-positive from a heuristic gate: replace with precise signatures, not retune; external cold-read finds blind spots.

## Why
A precision-first gate (false-block is the cardinal sin) was tuned twice after false-positives. A third false-positive appeared after the second tuning. The lesson: a green test suite encodes the heuristic's intent, not its blind spots; external cold-read by a fresh reader is the only way to find realistic false-positives. Structured signatures have defined scope; heuristics have undefined edge cases.

## How to apply
When a heuristic gate produces a false-positive even once: don't retune — replace with precise structured signatures plus an honestly-documented out-of-scope boundary. Commission an external cold-read per revision. After merging to main, re-run the full suite on main — cross-ticket regressions live at the merge point, not in the feature branch.

## Disposition
Split from "A precision-absolute gate that keeps re-finding false-positives" (2026-06-09). Portable principle (this file): prefer precise patterns over heuristics + external cold-read discipline. Legacy gate mechanics: dropped.
