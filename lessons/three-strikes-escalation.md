# Three-Strikes Escalation for Tooling Failures
date: 2026-04-06
scope: process
rule: After 3 consecutive failures of the same class, stop, classify root cause, present ≤3 options; no approach #4 without user choice.

## Why
Repeated attempts to fix the same category of tooling failure consumed time and context without progress. Each attempt was slight variation on the prior approach. The problem was that the root cause had not been classified — attempts 1-3 were all within the same assumption set.

## How to apply
Count consecutive failures by class (not by specific error). At the third: stop all attempts. Classify the root cause into one of: context (insufficient information), logic (the approach is wrong), tooling (the tool has a limitation), platform (environmental constraint). Present ≤3 distinct options with tradeoffs. Do not start approach #4 until the user has chosen.
