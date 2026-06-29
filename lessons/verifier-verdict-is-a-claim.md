# A Verifier's Verdict Is Also a Claim
date: 2026-06-05
scope: verification
rule: When a verifier contradicts another observation, reproduce the disputed fact yourself with the cheapest direct probe before propagating.

## Why
A verifier's factual finding contradicted a prior observation. Accepting the verifier's verdict by role authority (it's a verifier, it should know) propagated an error. The actual fact was determined in seconds by running the relevant command directly.

## How to apply
When two observations conflict: do not arbitrate by role authority. Identify the cheapest direct probe (one grep, one curl, one run) and execute it. "Verified empirically" without a re-runnable artifact is unverified. Long-lived reference documents get the highest bar: require direct confirmation before editing them on any agent's report.
