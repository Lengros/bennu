# Count Windowed Events by Their Own Timestamp, Not a Downstream Aggregate's

date: 2026-06-19
scope: process
rule: Count windowed events by each event's own ts, not via an aggregate keyed to a later record's ts — a straddling record replays stale events.

## Why
The SessionEnd hook's retro-friction trigger summed the `blocks` integer off each `session_end` record and attributed it to the **session_end's** timestamp. A session that accrued 18 guard blocks on Jun 17 but whose `session_end` fired on Jun 19 — after a completed retro — re-injected all 18 stale blocks as "fresh friction since the last retro," producing a false `RETRO DUE: 19 friction events`. The aggregate (`blocks`) lost the per-event timestamps, and the container record's ts is *when the session ended*, not *when the friction happened*. Resumed/long/compaction-straddling sessions made the container ts an actively wrong proxy.

Fix: count guard blocks straight from `blocks.jsonl` by **each block's own `ts`**, gated by `ts > last_retro` and `ts >= now-14d`. Lessons were already counted by their own ts and were fine. Verified: under the bug the count was 20; after the fix, the same state yields 2 (the stale blocks correctly fall behind `last_retro`).

## How to apply
- When a metric counts events inside a time window relative to a consumption boundary (a retro, a billing cycle, a "since last X"), read the **primitive events with their own timestamps** — don't sum a roll-up attributed to a later record.
- If you must keep an aggregate field on a container record (here, `session_end.blocks` is still useful as a per-session stat), do not reuse it for windowed friction; the two have different time semantics.
- Self-edits to telemetry/enforcement machinery get a mandatory fresh-context cold read (CLAUDE.md §6) AND an end-to-end smoke on a copy of the data before/after the boundary — a counter bug is invisible until it mis-fires.

## Disposition
First occurrence: Bennu `session-end.sh` friction trigger, surfaced by the 2026-06-19 retro (proposal [3]). Extends [[grounded-is-not-validated]] (an aggregate is fidelity to a roll-up, not to the underlying events) and the evidence-rule preference for the primary source over a derived one ([[requirements-trace-to-primary-not-prior-artifact]]).
