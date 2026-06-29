# JSONL telemetry: parse with a JSON reader, never string-match record types

date: 2026-06-13
scope: observability / telemetry tooling
rule: Parse JSONL with a JSON reader (json.loads/jq), match on parsed fields — never grep record types or split on "key":" literals.

## What happened

The `/retro` skill reported "0 run records → R2/R3/card-reuse unmeasurable" while
`telemetry/runs.jsonl` actually held 53 `type:"run"` records. Root cause: `log-run.sh`
emitted **spaced** JSON via `json.dumps(rec)` (`{"ts": "...", "type": "run", ...}`), while
the hooks and the skill emitted **compact** JSON (`{"ts":"...","type":"..."}`). Any reader
that did `grep '"type":"run"'` or `awk -F'"ts":"'` matched the compact shape only and
silently dropped every run record. The hook's `enriched` check survived because it used
`json.loads` — and the `enriched:true` it produced (against records the grep couldn't see)
was the only clue that the records existed.

## The lesson

In a JSONL corpus written by more than one producer, **formatting drifts** — separators,
key order, spacing. A string-matcher keyed on one producer's shape fails *silently* on the
others: it returns a clean empty set, which reads as "nothing happened," not "I couldn't
see it." That's the dangerous failure mode — a blind reader that looks like a quiet one.

**Rule:** parse every JSONL line with a real JSON parser (`json.loads` / `jq`) and match on
the **parsed** field, never on a substring of the raw line. Never `grep '"type":"..."'`,
never field-split on a `"key":"` literal. `json.loads` is whitespace- and order-agnostic;
that is the only safe reader. Belt-and-suspenders: also pin writers to one format
(`json.dumps(rec, separators=(",",":"))`) so the corpus converges — but the reader
discipline is the load-bearing fix, because you cannot retroactively reformat history.

## Tell

A telemetry/aggregation report shows a suspiciously round zero ("0 runs", "0% enrichment")
while a *derived* signal computed by a different code path disagrees (here: `enriched:true`
with zero visible runs). Two readers of the same file disagreeing → suspect a parse gap in
the string-matching one before you suspect missing data. See also
[[trace-derived-values-to-source-constants]].
