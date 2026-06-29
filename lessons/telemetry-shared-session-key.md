# Telemetry Producer and Consumer Must Share One Session Key
date: 2026-06-10
scope: observability
rule: Telemetry keyed by session id needs producer and all consumers resolving it from one agreed source; compaction can rotate the id.

## Why
Bennu keyed run records one way (producer `log-run.sh` → `CLAUDE_SESSION_ID` else `telemetry/current-session`) and read them another (consumers `session-end.sh` / the Stop nudge → the hook's stdin `session_id`). After a `/compact` the two ids diverged, so a logged run never matched the `enriched` check — every session recorded 0% enriched, which looked like "the agent forgot to log" but was a join failure. A Stop-hook nudge firing on a session that *had* logged its run is what surfaced it.

## How to apply
Pick one canonical session key and have the producer and every consumer read it, OR have consumers match against every id the value could take (here: stdin session_id OR current-session, biased to suppression for a nudge). Hooks receive the id on stdin; a CLI only sees the env/file bridge — when those can differ, do not assume they're equal. Before trusting any aggregate (an enrichment rate, a friction count), verify the telemetry joins end-to-end: log a record, then read it back through the consumer's own path. Relate: see "Reproduce Before You Name the Root Cause".
