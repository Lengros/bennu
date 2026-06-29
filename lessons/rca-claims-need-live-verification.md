# RCA Claims Need Live Verification Before Scoping Fixes
date: 2026-06-09
scope: verification
rule: Reproduce each RCA claim against live code before scoping; a test asserting 'broken' behavior marks an intentional invariant.

## Why
Two of three findings in one RCA were falsified by a 10-minute live reproduction. The RCA had been written under frustration; its "obvious" fix would have collided with a test-locked invariant. Scoping work from an unverified RCA wastes effort and risks breaking valid constraints.

## How to apply
When an RCA proposes a fix: (1) run the blocked or broken command against live code; (2) grep the tests guarding the affected surface; (3) tag each RCA finding as confirmed/falsified based on what you observe — not what the RCA claims. When your assessment diverges from the RCA, tell the user. A user-approved fix shape re-confirmed on new evidence is updating, not position drift. When an RCA proposes extending a gate or carve-out, recon must ask "does the capability already exist?" — grep the carve-out and its tests first.
