# Verification Calibration: Match Depth to Risk
date: 2026-06-05
scope: verification
rule: Shared/medium-risk: full independent audit; local low-risk: spot-check; always re-run the agent's claimed test yourself.

## Why
A full diff-audit after each executor pass found nothing wrong on shared components — the correct bar. Re-running the typecheck myself overturned the executor's pessimistic self-report (it claimed 10 errors; there were zero in the target files). Trusting the claimed result either way would have been wrong.

## How to apply
Shared component / medium+ risk / external-facing: full independent diff-audit + verify the default path is preserved. Local, isolated, low-risk: spot-check the load-bearing lines only. Either way: reproduce the agent's claimed pass/fail yourself before accepting. Over-auditing low-risk edits is its own waste.
