---
name: retro
description: Run when telemetry/retro.flag exists (RETRO DUE) or on the monthly scheduled cadence. Reads runs.jsonl + blocks.jsonl + lessons/INDEX.md, produces a 6-section friction/health report with proposals, and resets the retro trigger.
---

# /retro — LEARN-loop consumer

## When to run

- `telemetry/retro.flag` exists in this project (session-start.sh injects its content; CLAUDE.md startup reads it as fallback).
- Monthly cadence: `session-end.sh` also sets `retro.flag` when the last `type:"retro"`
  marker is >30 days old (or, with no retro ever, the oldest activity is >30d), so the loop
  turns even in a low-friction month. No external cron — the calendar check rides the
  existing flag mechanism.

Arguments: none.

---

## Parsing discipline — read before any step

**Parse every telemetry line with a real JSON parser** (`python3 -c 'json.loads(...)'`
or `jq`), then match on the **parsed** `type` field. **Never** select records by
string-matching `"type":"run"` with `grep`, and **never** field-split on a `"key":"`
literal (e.g. `awk -F'"ts":"'`). The corpus is NOT uniformly formatted: `log-run.sh`
historically emitted spaced JSON (`{"ts": "...", "type": "run", ...}`) while the hooks
emit compact JSON (`{"ts":"...","type":"..."}`). A string-matcher keyed on the compact
shape silently drops **every** run record — which produces a false "0 runs / R2,R3,reuse
unmeasurable" report even when dozens of runs exist (this exact failure occurred 2026-06-13).
`json.loads` is whitespace-agnostic and reads both shapes; that is the only safe reader.
The two `"type":"..."` and `ts >= window_start` comparisons named in the steps below are
logical predicates over parsed objects, not grep patterns.

---

## Step 1 — Determine the review window

Read `telemetry/runs.jsonl` and parse each line as JSON (see *Parsing discipline* above).
Scan all parsed records for `type == "retro"` events.
The session-end record shape is defined in
[Observed: .claude/hooks/session-end.sh:93-95].
Take the most recent one's `ts` field as `window_start`. If none found, set
`window_start = now − 30 days`. Also record `prior_retro_ts` = the **second**-most-recent
`type:"retro"` ts if one exists (consumed by the skip-rate watch in section d); if there are
fewer than two retro markers, `prior_retro_ts` is undefined.

Also compute `stale_cutoff = now − 90 days` (used in section c).

---

## Step 2 — Load telemetry in the window

**runs.jsonl** (`$CLAUDE_PROJECT_DIR/telemetry/runs.jsonl`):
Collect all lines with `ts >= window_start` into three buckets:

| Variable | Match (predicate over the parsed object) |
|---|---|
| `session_ends` | `type == "session_end"` |
| `run_records` | `type == "run"` |
| `lesson_events` | `type == "lesson"` |

Fields used from each record type:

- `session_end`: `ts`, `session_id`, `blocks` (integer ≥ 0), `enriched` (bool)
  [Observed: .claude/hooks/session-end.sh:93-95]
- `run`: `ts`, `session_id`, `task`, `mode` (`embody`|`delegate`), `personas`
  (array, free-text labels), `from_card` (array of persona-card slugs the cast was
  reused from / synthesized on top of — the reuse signal; absent on records written
  before the field existed), `skeptic`, `outcome`
  [Observed: tools/log-run.sh:53-57]
- `lesson`: `ts`, `slug` [Observed: tools/digest-lessons.sh:92-99]

**blocks.jsonl** (`$CLAUDE_PROJECT_DIR/telemetry/blocks.jsonl`):
Collect all lines with `ts >= window_start`.
Fields [Observed: .claude/hooks/guard.sh:223-228]:
`ts`, `session_id`, `path`, `tool`

**lessons/INDEX.md**: read the full file. Each bullet has the form:
`- **Title** — rule (scope, date, [body](filename))`

---

## Step 3 — Produce the 6-section report

Output all sections to the user. The skill NEVER auto-deletes or auto-archives anything.

### (a) Friction summary

- Total session_end records in window and count of those with `blocks > 0`.
- Aggregate blocks by `path` (descending) and by `tool` (descending).
- List each blocked session: `session_id`, `blocks` count.
- If no blocks: "No blocks recorded in window."

### (b) Enrichment rate — R3 watch

Enrichment rate = (count of session_ends where `enriched == true`) / (total session_ends).

- Report the fraction and percentage.
- If rate < 50%: flag as R3 threshold exceeded; propose adding a Stop-hook nudge
  OR accepting involuntary record as sufficient — decide now, not ad hoc.
- If rate ≥ 50%: "OK — above R3 threshold."

### (c) Lesson activity

- List `lesson` events in window (ts + slug).
- **Review candidates (age is a prompt, not a verdict).** A lesson's `date` is when it was
  *written*, not when it was last useful — and lessons ported from an earlier system carry origin
  dates that predate Bennu, so they look ancient on day one. Age alone never proves
  staleness: an evergreen rule (delegation, quality-vs-approval gate) stays true at any age.
  List INDEX entries where `date < stale_cutoff` AND the slug did not appear in
  `lesson_events` this window as **review candidates** — name slug, scope, date, and ask
  "does this still hold, or has a newer lesson superseded/contradicted it?"
- **Archive proposals need a supersession signal, not bare age.** Propose
  `lessons/archive/<slug>` only for a candidate you can pair with a concrete reason it no
  longer applies — a newer lesson asserting the opposite, a rule the system has dropped, a
  scope that no longer exists. Do **not** propose archiving a lesson solely because its date
  is old; that heuristic false-flags ported evergreen rules (retro 2026-06-13).
- If no review candidates: say so.
- Close with: "The skill never auto-archives. User decides."

### (d) Rule-erosion check — R2

Compare `run_records` by mode:

- Count mode=`embody` and mode=`delegate`.
- List each embody run: session_id, task, skeptic, outcome.
- R2 signal: any embody run where `skeptic == "skipped"` and the task description
  is artifact-shaped (document, profile, spec, PRD, analysis — judge by keywords).
  If found: flag it and propose adding the task class to the delegate-only list
  in `core/` or CLAUDE.md §5.
- **Skip-rate watch — aggregate by SESSION, never by raw run count.** Compute
  `skipped_share = skipped_sessions / total_sessions` over the window, where
  `total_sessions` = the count of distinct `session_id`s among `run_records`, and a session
  is a `skipped_session` **iff every one of its runs has `skeptic == "skipped"`** — a single
  run with `skeptic ∈ {pass, fail}` proves the session knows how to invoke the skeptic, so
  it does not count as a skip. `log-run.sh` requires `--skeptic` (enum `pass|fail|skipped`;
  the empty default hits the reject branch) [Observed: tools/log-run.sh:26,42], so every run
  carries the field. **Why per-session, not per-run:** a single session doing N point-edits
  emits N run records, and a per-run denominator inflates the share and trips this flag
  spuriously — observed 2026-06-26, where one window read 71% per-run but 29% per-session
  (two landing-polish sessions alone emitted 13 + 12 records, 45% of the window) and the
  per-run number false-flagged erosion that did not exist
  (`lessons/erosion-metrics-aggregate-by-work-unit-not-log-record.md`). Report
  `skipped_sessions/total_sessions` and percentage. Then compute the same **per-session**
  ratio for the **prior window** = `[prior_retro_ts, window_start]` — the two most-recent
  `type:"retro"` markers, where `prior_retro_ts` is recorded in Step 1. **Flag a rising
  trend** when EITHER: (i) the current share exceeds the prior by more than ~10 percentage
  points AND the current window has ≥3 sessions (else the ratio is noise); OR (ii) the
  absolute count of skipped *sessions* is ≥3 and exceeds the prior window's. A flag means
  legitimate in-loop skips ("browser-verified") may be drifting into a silent skeptic bypass
  — propose tightening the skip criteria in `core/skeptic.md §1`. This trend watch is
  **complementary** to the artifact-shaped embody+skipped check above: that check catches a
  single high-stakes miss *inside* an otherwise-disciplined session (which per-session
  aggregation would mask), while this watch catches a population-wide drift. **If
  `prior_retro_ts` is undefined** (fewer than two retro markers ever), there is no bounded
  prior window — report the current share only and note the trend is not yet computable.
  Likewise, if the prior window contains **zero** run records (a low-activity or
  all-unenriched span), `skipped_share_prior` is 0/0 — treat criterion (i) as not computable
  and rely on criterion (ii) (absolute skipped-session count) alone.
- If no run records in window: note that all sessions are unenriched and R2
  cannot be assessed from voluntary data alone.

### (e) Prune proposals — persona cards and tools unused in window

**Card reuse is measured ONLY by `from_card`, never by `personas` name-matching.**
The `personas` field holds free-text, per-run labels (kebab, ad-hoc) that almost never
equal a card filename even when a card seeded the cast — so a `personas`-vs-`personas/`
string diff measures naming, not reuse, and systematically reports live cards as dead.
Use the explicit provenance field instead.

- Collect card slugs from `run_records[].from_card` (flattened) → the set of cards that
  actually earned their keep in the window.
- List the card files: `ls personas/*.md 2>/dev/null | xargs -I{} basename {} .md`
  (exclude `README`).
- **Review candidates** = cards in `personas/` whose slug is absent from the `from_card`
  set across the window.
- **Backward-compat guard.** Records predating the `from_card` field (no key, or you are
  also seeing pre-field runs) carry *unknown* provenance, not "unused." Count how many
  in-window runs lack `from_card` and state it; do not conclude a card is dead weight on a
  window where most runs cannot report provenance. A clean unused-verdict needs a window
  where runs actually populate `from_card`.
- If no run records, or none carry `from_card`: state that card reuse is not yet
  measurable from this window — do NOT fall back to `personas` name-matching.
- Same pattern for `tools/` scripts: list files; tools are hook/on-demand invoked and
  rarely named in records, so flag a tool only when you have positive evidence it is
  obsolete, not merely on absence from this window.

### (f) System-change proposals

Synthesize 1–5 concrete proposals, each with:

```
[N] Proposal statement (imperative, ≤ 1 sentence)
    Evidence: specific session IDs, counts, or lesson slugs from this window.
    Severity: LOW | MEDIUM | HIGH — one sentence justifying the level.
```

Draw proposals from signals in sections a–e. Do not invent proposals without
telemetry evidence. Each proposal requires user decision; none are auto-applied.

---

## Step 4 — Completion

After presenting the report and proposals to the user:

1. Append the retro event to `telemetry/runs.jsonl`:
   ```
   printf '{"ts":"%s","type":"retro"}\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
     >> "$CLAUDE_PROJECT_DIR/telemetry/runs.jsonl"
   ```
2. Remove `telemetry/retro.flag` if it exists:
   ```
   rm -f "$CLAUDE_PROJECT_DIR/telemetry/retro.flag"
   ```
3. Confirm to the user: "Retro event recorded. Flag cleared."

---

## Invariants

- All paths anchored to `$CLAUDE_PROJECT_DIR/telemetry/`.
- Timestamp format everywhere: `date -u +%Y-%m-%dT%H:%M:%SZ`.
- Shell constraints: bash 3.2; no `mapfile`, no `declare -A`, no `${var,,}`.
- The skill reads files; all decisions and deletions require explicit user confirmation.
- Missing telemetry files (runs.jsonl absent, blocks.jsonl absent): treat as empty — report "no data" for the affected section, do not error.
