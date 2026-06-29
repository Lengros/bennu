# Match Research Depth to Decision Stakes
date: 2026-06-16
scope: delegation
rule: deep-research costs 10-100x a subagent -- reserve for high-stakes decisions; for picking a tool, one Explore subagent is enough.

## Why
A "which diagram tool is best" question was run through the full `deep-research` harness (fan-out web search + adversarial verification of every claim in separate subagents) and burned ~2.7M tokens. The decision was low-stakes and reversible; the harness was sized for a high-stakes, source-critical question. The telemetry note records only the symptom — *"deep-research synthesis failed on API-overload; report+update built from 24 verified (3-0) claims"* (runs.jsonl 2026-06-15) — not the disproportion. Bennu logs task/mode/persona/outcome but not token cost, so over-spend leaves no automatic trace.

## How to apply
Before reaching for `deep-research`, classify the decision: **high stakes** (cost of being wrong is large, choice is hard to reverse, needs citeable primary sources) → deep-research is justified. **Low/medium stakes** (picking a tool, comparing options, scoping a build) → one `Explore` or `market-scan` subagent is enough. Symptom of overkill: the synthesis step falls over on API-overload — that's the harness too big for the task, not a transient error to retry.

## Disposition
New in Bennu, 2026-06-16. First occurrence of research-depth miscalibration captured as a lesson per CLAUDE.md §8.
