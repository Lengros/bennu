# External Adversarial Review for High-Impact Changes
date: 2026-04-17
scope: verification
rule: For ≥5-file changes or CLAUDE.md/core/governance-class changes, run an external cold read after Skeptic: fresh session, no prior context.

## Why
The Skeptic shares the session's context and plausibility heuristics — adversarial in role, not in epistemic position. A Skeptic in the same session cannot surface errors that were invisible to the session that produced the artifact. An external cold read with no prior context provides genuine epistemic diversity.

## How to apply
After a Skeptic PASS on a high-blast-radius change: open a fresh session (no shared context), provide only the artifact + cited source files, task it "open every cited file, verify the plan's assertions." Different model if available. The cold reader's job is not to improve the artifact but to falsify its claims. Results feed back to the author as potential FAIL triggers.
