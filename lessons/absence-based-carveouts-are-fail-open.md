# Absence-Based Carve-Outs Are Fail-Open
date: 2026-04-27
scope: verification
rule: Carve-outs must state positive conditions; write adversarial test first; no step in a chain inherits another's exemption.

## Why
A carve-out written as "allowed when X is not blocked" permitted a bypass because the absence condition was satisfied in an unintended way. Absence-based conditions are fail-open: any new condition that satisfies the absence grants unintended access.

## How to apply
When writing any exemption or carve-out: express it as a positive condition ("allowed when <explicit context> is true"). Before shipping: write the adversarial test ("does this carve-out applied to an attacker payload get allowed?"). In multi-step chains: each step passes enforcement individually; no step inherits a preceding step's exemption.

## Disposition
Split from "Enforcement carve-outs must scope to explicit context" (2026-04-27). Portable principle (this file): positive-condition carve-outs + adversarial-test-first + no inheritance in chains. Legacy hook/gate implementation details: dropped.
