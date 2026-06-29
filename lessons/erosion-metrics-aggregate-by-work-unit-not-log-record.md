# Erosion metrics aggregate by unit of work, not by raw log-record count

date: 2026-06-26
scope: observability / telemetry tooling
rule: Aggregate drift metrics by unit of work (session/task), not raw log-record count; uneven logging granularity false-flags drift.

## What happened

The `/retro` skip-rate watch (R2 erosion guardrail) computed
`skipped_share = count(skeptic=="skipped") / count(run_records)` and reported **71%**
current vs **36%** prior — tripping both rising-trend criteria and reading as live skeptic
erosion. The honest cause was logging granularity, not discipline: two landing-polish
sessions emitted **13 and 12 separate run records** (point edits the user watched land,
legitimately skeptic-skipped per CLAUDE.md §6), 45% of the window. Recomputed by **session**
— a session counts as skipped only if *every* run in it skipped the skeptic — the same
window read **29% current vs 29% prior**: flat, no drift. The 35-point "spike" was entirely
denominator pollution from two verbose sessions.

## The lesson

A ratio is only honest when its denominator counts the thing you actually care about. The
skip-rate watch cares about *units of work that bypassed independent review* — but the run
log records *edits*, and a session can emit one edit or thirteen for the same amount of
judgment exercised. Dividing skips by raw record count lets a single chatty session swamp
the metric and manufacture a trend.

**Rule:** when a telemetry metric is meant to detect behavioral *drift*, aggregate by the
unit of work (session, task, loop), not by raw log-record count. Collapse multi-record
sessions to one unit before taking the ratio. Pick the per-unit verdict so that
demonstrated discipline counts as discipline — here, a session that ran the skeptic even
once is "ran-skeptic," because the point-edits around it are legitimately skipped.

**Keep the complementary specific-miss detector.** Per-session aggregation deliberately
masks a single high-stakes skip inside an otherwise-disciplined session — so the
artifact-shaped `embody + skeptic==skipped` check stays as a separate signal. Trend metric
(population drift) and miss detector (one bad call) answer different questions; you need
both.

## Tell

A guardrail ratio jumps sharply between windows while the underlying behavior feels
unchanged. Before believing the trend, check whether one window is dominated by a single
high-volume producer — re-run the metric at one-level-coarser granularity and see if the
spike survives. If it collapses, the denominator was the bug, not the behavior. Sibling to
[[jsonl-telemetry-parse-never-string-match]] and [[count-windowed-events-by-own-timestamp]]
— all three are "the telemetry reader lied about what happened."
