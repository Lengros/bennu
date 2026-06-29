#!/bin/bash
# test-digest-lessons.sh — fixture test for tools/digest-lessons.sh
#
# Builds a throwaway fixture repo (its own tools/ + lessons/ + telemetry/) so
# PHX (derived from the script's $0 dirname) points at the fixture and the real
# repo's telemetry/runs.jsonl is never touched. Asserts the WP-07 DoD:
#   - 2 valid + 1 malformed (no rule) + 1 over-140 rule -> INDEX has 2 entries,
#     exit 1, two SKIP lines;
#   - second run idempotent AND emits zero lesson events;
#   - add a 3rd valid lesson, re-run WITHOUT --no-events -> exactly 1 event;
#   - WITH --no-events -> 0 events.
set -euo pipefail

src_repo="$(cd "$(dirname "$0")/.." && pwd)"
src_script="$src_repo/tools/digest-lessons.sh"

fix="$(mktemp -d)"
trap 'rm -rf "$fix"' EXIT
mkdir -p "$fix/tools" "$fix/lessons" "$fix/telemetry"
cp "$src_script" "$fix/tools/digest-lessons.sh"
chmod +x "$fix/tools/digest-lessons.sh"
digest="$fix/tools/digest-lessons.sh"
index="$fix/lessons/INDEX.md"
runs="$fix/telemetry/runs.jsonl"

pass=0; fail=0
check() { # check <label> <expected> <actual>
  if [ "$2" = "$3" ]; then pass=$((pass+1)); echo "PASS: $1 ($3)"
  else fail=$((fail+1)); echo "FAIL: $1 — expected [$2] got [$3]"; fi
}

# --- fixtures: 2 valid, 1 malformed (no rule), 1 over-140-char rule ----------
cat > "$fix/lessons/delegate-artifact-work.md" <<'EOF'
# Delegate artifact-shaped work
date: 2026-03-14
scope: delegation
rule: Artifact-shaped work goes to a Specialist; embody only synthesis-shaped tasks.

## Why
Inline edits to deliverables read flat.

## How to apply
If the output is a deliverable artifact, cast a Specialist.
EOF

cat > "$fix/lessons/verify-with-runtime.md" <<'EOF'
# Verify works claims with runtime evidence
date: 2026-04-01
scope: verification
rule: Back every "it works" claim with pasted runtime output, never assertion.

## Why
"Should work" shipped a broken build once.

## How to apply
Run it; paste the output in the handoff.
EOF

# Malformed: no rule: line.
cat > "$fix/lessons/malformed-no-rule.md" <<'EOF'
# Missing the rule line
date: 2026-04-02
scope: process

## Why
This file has no rule field.
EOF

# Over-140-char rule (rule value below is 150 ASCII chars).
over="$(printf 'x%.0s' $(seq 1 150))"
cat > "$fix/lessons/over-long-rule.md" <<EOF
# Rule far too long
date: 2026-04-03
scope: tooling
rule: $over

## Why
Rule exceeds the 140-char budget.
EOF

echo "=== RUN 1: 2 valid + 1 no-rule + 1 over-140 ==="
set +e
out1="$("$digest" 2>"$fix/err1")"; ec1=$?
set -e
echo "--- stderr (run 1) ---"; cat "$fix/err1"
echo "--- INDEX.md (run 1) ---"; cat "$index"

check "run1 exit code" "1" "$ec1"
entries1="$(grep -c '^- \*\*' "$index")"
check "run1 INDEX entry count" "2" "$entries1"
skips1="$(grep -c '^SKIP ' "$fix/err1")"
check "run1 SKIP line count" "2" "$skips1"
events_after_run1="$(grep -c '"type":"lesson"' "$runs" 2>/dev/null || true)"
check "run1 lesson events (no prev INDEX -> all new = 2)" "2" "$events_after_run1"

echo "=== RUN 2: idempotent, zero new events ==="
before2="$(wc -l < "$runs" | tr -d ' ')"
index_before2="$(cat "$index")"
set +e
"$digest" 2>"$fix/err2"; ec2=$?
set -e
after2="$(wc -l < "$runs" | tr -d ' ')"
events2=$((after2 - before2))
check "run2 exit code" "1" "$ec2"
check "run2 emitted zero new events" "0" "$events2"
if [ "$index_before2" = "$(cat "$index")" ]; then
  pass=$((pass+1)); echo "PASS: run2 INDEX idempotent"
else
  fail=$((fail+1)); echo "FAIL: run2 INDEX changed"
fi

echo "=== RUN 3: add a 3rd valid lesson, no --no-events -> exactly 1 event ==="
cat > "$fix/lessons/thin-briefs.md" <<'EOF'
# Keep briefs thin
date: 2026-05-01
scope: process
rule: Point briefs at the ticket and overrides; never re-state the goal verbatim.

## Why
Fat briefs duplicated the ticket and drifted.

## How to apply
Reference ticket_path + runtime + deltas only.
EOF
before3="$(wc -l < "$runs" | tr -d ' ')"
set +e
"$digest" 2>"$fix/err3"; ec3=$?
set -e
after3="$(wc -l < "$runs" | tr -d ' ')"
events3=$((after3 - before3))
check "run3 exit code" "1" "$ec3"
check "run3 emitted exactly 1 event" "1" "$events3"
entries3="$(grep -c '^- \*\*' "$index")"
check "run3 INDEX entry count" "3" "$entries3"
last_event="$(grep '"type":"lesson"' "$runs" | tail -1)"
case "$last_event" in
  *'"slug":"thin-briefs.md"'*) pass=$((pass+1)); echo "PASS: run3 event slug is thin-briefs.md" ;;
  *) fail=$((fail+1)); echo "FAIL: run3 event slug — got [$last_event]" ;;
esac

echo "=== RUN 4: add a 4th valid lesson WITH --no-events -> 0 events ==="
cat > "$fix/lessons/show-paths-first.md" <<'EOF'
# Show file paths first
date: 2026-05-02
scope: content
rule: After creating or editing a file, lead the report with its absolute path.

## Why
Users could not find changed files.

## How to apply
First line of the handoff is the path.
EOF
before4="$(wc -l < "$runs" | tr -d ' ')"
set +e
"$digest" --no-events 2>"$fix/err4"; ec4=$?
set -e
after4="$(wc -l < "$runs" | tr -d ' ')"
events4=$((after4 - before4))
check "run4 exit code" "1" "$ec4"
check "run4 --no-events emitted 0 events" "0" "$events4"
entries4="$(grep -c '^- \*\*' "$index")"
check "run4 INDEX entry count" "4" "$entries4"

echo
echo "$pass/$((pass+fail)) PASS"
[ "$fail" -eq 0 ]
