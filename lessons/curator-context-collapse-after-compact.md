# Curator Context Collapse After Context-Compact
date: 2026-05-27
scope: process
rule: After context-compact, name what working context was lost and rebuild it; do not act confidently on artifact-residue alone.

## Why
After a context-compact, Curator proceeded with design+PRD work as if the session context was intact. It began auditing the prototype against its own same-session document, treating divergence as a compliance violation rather than a thinking opportunity. Collapse signals: phrasing findings as "X violates §Y of my own doc"; asking A/B/C questions you could decide; following checklist form over intent of the goal.

## How to apply
After any context-compact: before substantive work, explicitly name what was lost (design decisions, iteration history, user judgments). Rebuild the working context or flag it as missing. If a collapse signal appears during execution — reaching for audit/measure when the call is think/decide/propose, following form over intent — stop and re-enter the Curator frame before continuing.
