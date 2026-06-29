# Requirements Target Production From Scratch — the Prototype Is Reference Only

date: 2026-06-18
scope: content
rule: Write tickets as production requirements from scratch; the product prototype is intent reference only, never proof a feature exists.

## Why
Breaking a redesign ticket into stories, I grounded the breakdown on a repo and used "it already exists → smaller story" reasoning. The user stopped me with a structural fact: there are TWO codebases — the product team's clickable prototype (built quickly by product) and production (owned by engineers). What product "накликали" in the prototype is NOT available to engineers. Requirements describe a change to *production*; the prototype only shows intent. Conflating the two either under-scopes (assuming prod already has what only the prototype has) or smuggles prototype implementation into a spec engineers must own.

## How to apply
- A ticket states the desired *production* behavior + acceptance criteria as if building from scratch. No "move component X", no "reuse the existing flag/store", no prototype file paths.
- The prototype + mockups are a labelled visual/intent reference ("target design follows the prototype"); the requirement text stands alone if the prototype didn't exist.
- Keep two evidence buckets: `[Production: path:lines]` (real baseline, OK to scope the delta) vs `[Concept]` (prototype — intent only, never "already done").
- Don't shrink story scope because the prototype already shows it working. Accomplished-in-prototype ≠ smaller production task.
- Identify which repo you explored before citing "current state": confirm the git remote, don't assume from a directory name.

## Disposition
Reinforces ported feedback "PRD = requirements, not prototype observation" and "Ground PRD claims on the real design", and extends [[grounded-is-not-validated]] (a cite proves fidelity to a source, not that the source is production truth).
