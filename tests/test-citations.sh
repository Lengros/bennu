#!/bin/bash
# test-citations.sh — DoD test for tools/check-citations.sh (WP-06).
#
# Builds a fixture with 5 citations (2 valid, 1 nonexistent path, 1 out-of-range,
# 1 inside a ``` fence) plus 2 [ASSUMPTION] tags (1 outside, 1 inside a ~~~ fence),
# runs the tool, and asserts: exit 1; exactly 2 MISS lines; summary exactly
# "OK: 2 citations verified, 1 assumptions declared".
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
tool="$here/../tools/check-citations.sh"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

# A target file with exactly 10 lines (line count = 10).
target="$work/target.md"
i=1
: > "$target"
while [ "$i" -le 10 ]; do
  printf 'line %d\n' "$i" >> "$target"
  i=$((i + 1))
done

# The fixture file. Citations resolve relative to --root = $work.
fixture="$work/fixture.md"
{
  printf '# Fixture\n'
  printf '\n'
  printf 'Valid one: [Observed: target.md:3] confirms it.\n'           # valid (single line)
  printf 'Valid range: [Observed: target.md:2-8] also fine.\n'         # valid (range)
  printf 'Bad path: [Observed: nope.md:1] missing file.\n'             # MISS: file not found
  printf 'Out of range: [Observed: target.md:5-99] too far.\n'         # MISS: exceeds length
  printf '\n'
  printf 'An [ASSUMPTION] declared outside a fence.\n'                 # counted assumption
  printf '\n'
  printf '```\n'
  printf 'Fenced cite [Observed: target.md:4] must be IGNORED.\n'      # ignored (in fence)
  printf '```\n'
  printf '\n'
  printf '~~~\n'
  printf 'Fenced [ASSUMPTION] must be IGNORED.\n'                      # ignored (in fence)
  printf '~~~\n'
} > "$fixture"

set +e
out="$(bash "$tool" --root "$work" "$fixture")"
code="$?"
set -e

echo "--- tool output ---"
printf '%s\n' "$out"
echo "--- exit code: $code ---"

fail=0

if [ "$code" -ne 1 ]; then
  echo "FAIL: expected exit 1, got $code" >&2
  fail=1
fi

miss_lines="$(printf '%s\n' "$out" | grep -c '^MISS ' || true)"
if [ "$miss_lines" -ne 2 ]; then
  echo "FAIL: expected exactly 2 MISS lines, got $miss_lines" >&2
  fail=1
fi

summary="$(printf '%s\n' "$out" | grep '^OK: ' || true)"
expected='OK: 2 citations verified, 1 assumptions declared'
if [ "$summary" != "$expected" ]; then
  echo "FAIL: summary mismatch" >&2
  echo "  expected: $expected" >&2
  echo "  got:      $summary" >&2
  fail=1
fi

# Usage-error contract: no FILE args -> exit 2.
set +e
bash "$tool" --root "$work" >/dev/null 2>&1
usage_code="$?"
set -e
if [ "$usage_code" -ne 2 ]; then
  echo "FAIL: expected usage exit 2 with no FILE args, got $usage_code" >&2
  fail=1
fi

if [ "$fail" -eq 0 ]; then
  echo "PASS: all DoD assertions met"
  exit 0
fi
echo "TEST FAILED" >&2
exit 1
