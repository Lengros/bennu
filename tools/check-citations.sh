#!/bin/bash
# check-citations.sh — verify [Observed: <path>:<lines>] citations in markdown.
#
# Usage: check-citations.sh [--root DIR] FILE...
#   Scans each FILE for [Observed: <path>:<lines>] citations and [ASSUMPTION] tags.
#   <lines> is N or N-M (digits only); 12-, -12, empty = malformed (MISS).
#   Each citation is parsed FROM THE RIGHT: the text between the LAST ':' and ']'
#   is the line spec; everything between '[Observed: ' and that ':' is the path
#   (paths may contain spaces). Relative paths resolve against --root (default cwd).
#   Checks: cited file exists; max(N,M) <= cited file's line count.
#   Fenced code (lines starting with ``` or ~~~) is skipped entirely for BOTH
#   citations and [ASSUMPTION] tags — items inside fences appear in no count.
#
# Output: one "MISS <scanned-file>:<citation> — <reason>" line per failed citation,
#   then "OK: <n> citations verified, <m> assumptions declared".
# Exit: 0 all pass; 1 any MISS; 2 usage error.
set -euo pipefail

usage() {
  echo "usage: check-citations.sh [--root DIR] FILE..." >&2
  exit 2
}

root="$(pwd)"

# --- argument parsing: pull off options, leave FILE... in the positional list ---
files_n=0
opts_done=0
# Append survivors to the end of the positional list, then drop the originals.
orig_count="$#"
i=0
while [ "$i" -lt "$orig_count" ]; do
  arg="$1"
  shift
  i=$((i + 1))
  if [ "$opts_done" -eq 0 ]; then
    case "$arg" in
      --root)
        [ "$#" -ge 1 ] || usage
        root="$1"
        shift
        i=$((i + 1))
        continue
        ;;
      --root=*)
        root="${arg#--root=}"
        continue
        ;;
      --)
        opts_done=1
        continue
        ;;
      -?*)
        usage
        ;;
    esac
  fi
  set -- "$@" "$arg"
  files_n=$((files_n + 1))
done

[ "$files_n" -ge 1 ] || usage

verified=0
assumptions=0
miss=0

# Resolve a cited path against --root (absolute kept as-is).
resolve_path() {
  case "$1" in
    /*) printf '%s' "$1" ;;
    *)  printf '%s/%s' "$root" "$1" ;;
  esac
}

# Process one citation occurrence. Args: scanned_file, citation (path:lines).
check_citation() {
  scanned="$1"
  cite="$2"
  # Parse from the right: line spec = after last ':'; path = before it.
  lines="${cite##*:}"
  path="${cite%:*}"

  # Validate the line spec: N or N-M, digits only.
  lo=""
  hi=""
  case "$lines" in
    *[!0-9-]* | "" | -* | *- )
      printf 'MISS %s:[Observed: %s] — malformed line spec\n' "$scanned" "$cite"
      miss=$((miss + 1))
      return
      ;;
  esac
  case "$lines" in
    *-*)
      # Split on the single hyphen. Use %-* / #*- so a SECOND hyphen survives
      # in one half (e.g. 1-2-3 -> lo="1-2") and is caught by the dash check.
      lo="${lines%-*}"
      hi="${lines#*-}"
      # Reject a second hyphen (N-M-K) or empty halves.
      case "$lo" in ""|*-*) bad=1 ;; *) bad=0 ;; esac
      case "$hi" in ""|*-*) bad=1 ;; esac
      if [ "$bad" -ne 0 ]; then
        printf 'MISS %s:[Observed: %s] — malformed line spec\n' "$scanned" "$cite"
        miss=$((miss + 1))
        return
      fi
      ;;
    *)
      lo="$lines"
      hi="$lines"
      ;;
  esac

  target="$(resolve_path "$path")"
  if [ ! -f "$target" ]; then
    printf 'MISS %s:[Observed: %s] — file not found\n' "$scanned" "$cite"
    miss=$((miss + 1))
    return
  fi

  # max(N,M)
  max="$lo"
  [ "$hi" -gt "$max" ] && max="$hi"

  count="$(wc -l < "$target" | tr -d ' ')"
  # wc -l counts newlines; a trailing line without newline still cited — treat
  # last line as count+0; use count as authoritative line count.
  if [ "$max" -gt "$count" ]; then
    printf 'MISS %s:[Observed: %s] — line %s exceeds file length %s\n' "$scanned" "$cite" "$max" "$count"
    miss=$((miss + 1))
    return
  fi

  verified=$((verified + 1))
}

# Scan one file line by line, tracking fence state.
scan_file() {
  scanned="$1"
  if [ ! -f "$scanned" ]; then
    echo "check-citations: cannot read file: $scanned" >&2
    exit 2
  fi
  in_fence=0
  while IFS= read -r line || [ -n "$line" ]; do
    # Fence toggles on a line starting with ``` or ~~~ (leading whitespace allowed).
    trimmed="${line#"${line%%[![:space:]]*}"}"
    case "$trimmed" in
      '```'* | '~~~'*)
        if [ "$in_fence" -eq 0 ]; then in_fence=1; else in_fence=0; fi
        continue
        ;;
    esac
    [ "$in_fence" -eq 0 ] || continue

    # Count [ASSUMPTION] tags on this line.
    rest="$line"
    while case "$rest" in *'[ASSUMPTION]'*) true ;; *) false ;; esac; do
      assumptions=$((assumptions + 1))
      rest="${rest#*'[ASSUMPTION]'}"
    done

    # Extract each [Observed: ... ] citation on this line (non-greedy via ']').
    rest="$line"
    while case "$rest" in *'[Observed: '*) true ;; *) false ;; esac; do
      rest="${rest#*'[Observed: '}"
      case "$rest" in
        *']'*)
          cite="${rest%%]*}"
          rest="${rest#*]}"
          check_citation "$scanned" "$cite"
          ;;
        *)
          # No closing bracket on this line — stop.
          rest=""
          ;;
      esac
    done
  done < "$scanned"
}

# Iterate the collected files in the current shell (no pipe — counters must persist).
for f in "$@"; do
  scan_file "$f"
done

printf 'OK: %d citations verified, %d assumptions declared\n' "$verified" "$assumptions"

[ "$miss" -eq 0 ] || exit 1
exit 0
