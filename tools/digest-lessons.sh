#!/bin/bash
# digest-lessons.sh [--no-events]
#
# Regenerates lessons/INDEX.md from every lessons/*.md (except TEMPLATE.md and
# INDEX.md) and emits a telemetry "lesson" event for each newly-indexed file.
#
# Per lesson file:
#   1. Require `# title` on line 1 AND a `rule:` line; rule must be <=140 chars.
#      Any failure -> "SKIP <file>: <reason>" on stderr, skip the file, and the
#      script exits 1 at the end (valid entries are still written).
#   2. INDEX.md gets one bullet per valid lesson, sorted by scope then date.
#   3. Event emission (suppressed by --no-events): diff the new [body](...) link
#      set against the PREVIOUS INDEX.md's links; every file present now but
#      absent before appends {"ts":...,"type":"lesson","slug":"<file>"} to
#      $PHX/telemetry/runs.jsonl. No previous INDEX -> all files are "new".
#
# PHX (repo root) is derived from $0's dirname, never from cwd (telemetry is
# anchored to the script's own repo).
set -euo pipefail

emit_events=1
case "${1:-}" in
  --no-events) emit_events=0 ;;
  "") : ;;
  *) echo "usage: digest-lessons.sh [--no-events]" >&2; exit 2 ;;
esac

PHX="$(cd "$(dirname "$0")/.." && pwd)"
lessons_dir="$PHX/lessons"
index="$lessons_dir/INDEX.md"
runs="$PHX/telemetry/runs.jsonl"
ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# Temp files (declared before the trap so `set -u` never trips inside it).
prev_links="$(mktemp)"
entries="$(mktemp)"     # "scope<TAB>date<TAB>bullet" lines, sorted later
new_links="$(mktemp)"   # filenames included in this run
trap 'rm -f "$prev_links" "$entries" "$new_links"' EXIT

# Capture the PREVIOUS index's [body](<file>) links before we overwrite it.
if [ -f "$index" ]; then
  grep -oE '\[body\]\([^)]+\)' "$index" 2>/dev/null \
    | sed -E 's/^\[body\]\(//; s/\)$//' | sort -u > "$prev_links" || true
fi

rc=0

for f in "$lessons_dir"/*.md; do
  [ -e "$f" ] || continue            # no matches -> literal glob, skip
  base="$(basename "$f")"
  case "$base" in
    TEMPLATE.md|INDEX.md) continue ;;
  esac

  title="$(sed -n '1p' "$f")"
  case "$title" in
    "# "*) title="${title#\# }" ;;
    *) echo "SKIP $base: missing '# title' on line 1" >&2; rc=1; continue ;;
  esac
  [ -n "$title" ] || { echo "SKIP $base: empty title" >&2; rc=1; continue; }

  rule_line="$(grep -m1 '^rule:' "$f" || true)"
  if [ -z "$rule_line" ]; then
    echo "SKIP $base: missing 'rule:' line" >&2; rc=1; continue
  fi
  rule="${rule_line#rule:}"
  rule="${rule# }"
  if [ "${#rule}" -gt 140 ]; then
    echo "SKIP $base: rule is ${#rule} chars (>140)" >&2; rc=1; continue
  fi

  scope_line="$(grep -m1 '^scope:' "$f" || true)"
  scope="${scope_line#scope:}"; scope="${scope# }"
  [ -n "$scope" ] || scope="unknown"
  date_line="$(grep -m1 '^date:' "$f" || true)"
  date="${date_line#date:}"; date="${date# }"
  [ -n "$date" ] || date="unknown"

  printf '%s\t%s\t- **%s** — %s (%s, %s, [body](%s))\n' \
    "$scope" "$date" "$title" "$rule" "$scope" "$date" "$base" >> "$entries"
  printf '%s\n' "$base" >> "$new_links"
done

# Write INDEX.md: header + bullets sorted by scope then date.
{
  printf '# Lessons Index (generated — edit bodies, not this file)\n'
  if [ -s "$entries" ]; then
    sort -t '	' -k1,1 -k2,2 "$entries" | cut -f3-
  fi
} > "$index"

# Emit a lesson event for each file present now but absent from the prev index.
if [ "$emit_events" -eq 1 ] && [ -s "$new_links" ]; then
  mkdir -p "$PHX/telemetry"
  sort -u "$new_links" | while IFS= read -r slug; do
    [ -n "$slug" ] || continue
    if ! grep -qxF "$slug" "$prev_links" 2>/dev/null; then
      printf '{"ts":"%s","type":"lesson","slug":"%s"}\n' "$ts" "$slug" >> "$runs"
    fi
  done
fi

exit "$rc"
