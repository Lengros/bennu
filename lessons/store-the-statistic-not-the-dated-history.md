# Store the Statistic, Not the Dated History
date: 2026-06-15
scope: design
rule: For "learn from history" features, persist only the statistic the purpose needs — a bounded aggregate, not a raw dated behaviour log.

## Why
Asked to build a per-user behavioural model for a time-series feature, I designed an append-only event table holding, per action, the user identifier + per-event timestamps and a derived lag statistic — i.e. the full dated record of when each user did each action. The user (EU, GDPR controller of their users' data) had assumed we'd keep a running adjusted average, and flagged it: storing when every user acted is exactly what data-minimization (GDPR Art. 5(1)(c)) and storage-limitation (5(1)(e)) forbid when the purpose only needs a lag statistic. The user identifier is personal data. I had over-engineered for analytical flexibility and skipped the privacy axis entirely.

The fix: replace the log with a bounded window of the last N lag integers per user (no dates, no per-event refs) + a `lag_folded` boolean so each event folds in exactly once. Median/mean still computable; dated history gone. A privacy-minimal aggregate is self-limiting on retention (old values roll off) for free.

## How to apply
When a feature "learns from" or "tracks" behaviour over time:
1. State the purpose, then name the single statistic it needs (a mean/median/rate/window) — that, not the raw events, is the data model.
2. The privacy cost lives in granularity (dates, identifiers, per-event rows), not in the metric. Drop the dates first; keep an incremental aggregate (EWMA, or a bounded last-N window if you need median/robustness).
3. If accuracy seems to demand the raw sample (e.g. true median needs the distribution), that is a real fork — surface the privacy↔accuracy trade-off to the user, don't silently pick retention.
4. Treat data-minimization as a first-class design axis in INTENT for anything touching user/third-party data, alongside the functional goal. [[apply-user-corrections-session-wide]]
