# Micro-Execution Threshold for Point UI Changes
date: 2026-03-23
scope: delegation
rule: Inline: ≤3 files/≤10 lines/cosmetic/non-CSS/user verifying; CSS always delegates; first unexpected complexity hit means stop and delegate.

## Why
Inline edits on small UI changes worked well until CSS was included — cascade/specificity/layer blast radius is unbounded and cannot be safely reasoned about without running the app. The lesson: cosmetic scope does not equal safe inline scope when CSS is involved.

## How to apply
Gate for inline: ≤3 files, ≤10 lines, cosmetic only, user verifying visually, AND no CSS. CSS always delegates regardless of line count. Not valid for: logic changes, new components, structural moves, multi-file dependencies. First unexpected-complexity hit (DOM reasoning needed, cross-component state, side effects beyond target file): stop, reclassify, run executor synthesis, delegate.
