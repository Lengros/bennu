#!/bin/bash
# scan-secrets-stop.sh — Stop hook: secret-exposure tripwire.
#
# Fires when the model tries to end its turn. Scans the dirty working tree for
# structured vendor credential shapes (AWS/OpenAI/GitHub/Slack/Google/PEM) via
# tools/scan-secrets.sh. A finding → exit 2 (the model is NOT allowed to stop;
# stderr is fed back). Everything else → exit 0.
#
# Posture (§0.6 fail-open, §0.7 Stop contract): exit 2 ONLY for an intentional,
# successfully-computed block. ANY tooling error → warn + exit 0. On Stop
# re-entry stdin carries "stop_hook_active": true — we warn once and exit 0, so
# the session can always end (tripwire, not jail). No `set -e` (§0.8).

HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$HOOK_DIR/../.." && pwd)"          # <root> from .claude/hooks
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$REPO_ROOT}"     # telemetry anchor (§0.11)
WARN_LOG="$PROJECT_DIR/telemetry/warnings.log"
SCANNER="$REPO_ROOT/tools/scan-secrets.sh"
SELF="scan-secrets-stop"

warn() {
  mkdir -p "$PROJECT_DIR/telemetry" 2>/dev/null
  printf '%s %s fail-open: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$SELF" "$1" >> "$WARN_LOG" 2>/dev/null
}

INPUT=$(cat)
JQ="$(command -v jq || true)"
[ -n "$JQ" ] || { warn "jq missing"; exit 0; }

# Stop-loop guard (§0.7): re-entry sets stop_hook_active — warn once, never re-block.
STOP_ACTIVE=$(printf '%s' "$INPUT" | "$JQ" -r '.stop_hook_active // false' 2>/dev/null)
if [ "$STOP_ACTIVE" = "true" ]; then
  warn "stop_hook_active — not re-blocking"
  exit 0
fi

CWD=$(printf '%s' "$INPUT" | "$JQ" -r '.cwd // ""' 2>/dev/null)
[ -n "$CWD" ] && [ -d "$CWD" ] || { warn "no cwd from stdin"; exit 0; }

command -v git >/dev/null 2>&1 || { warn "git missing"; exit 0; }
git -C "$CWD" rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0  # not a repo

# Hot path: clean tree → bail immediately (keep <100ms). Plain --porcelain
# here is fine: we only test emptiness, not parse paths.
[ -n "$(git -C "$CWD" status --porcelain 2>/dev/null | head -1)" ] || exit 0

# Collect modified/added files (skip deleted), absolutize, filter size/binary,
# cap 50. Accumulate into the positional params ($@) so the scanner gets each
# path as one argv slot — paths with spaces survive, and we read the scanner's
# OWN exit code (no xargs masking it to 123).
#
# Parse `git status --porcelain -z` (NUL-terminated): paths are emitted RAW (no
# quoting / C-escapes), so spaces and unicode survive. A string variable cannot
# hold NULs, so git is piped STRAIGHT into the loop via process substitution.
# Record format: "<XY> <path>\0". For renames/copies the new path is in THIS
# record; the OLD path follows as a separate bare record — we flag-skip it.
set --
COUNT=0
CAPPED=0
SKIP_NEXT=0
while IFS= read -r -d '' rec; do
  [ -n "$rec" ] || continue
  if [ "$SKIP_NEXT" -eq 1 ]; then SKIP_NEXT=0; continue; fi   # old-path of a rename/copy
  xy="${rec:0:2}"
  rel="${rec:3}"                       # strip 2-char XY status + 1 space
  case "$xy" in
    R*|C*) SKIP_NEXT=1 ;;               # next record is the source path; skip it
    *D*) continue ;;                    # deleted in index or worktree
  esac
  f="$CWD/$rel"
  [ -f "$f" ] || continue
  bytes=$(wc -c < "$f" 2>/dev/null | tr -d ' ')
  [ -n "$bytes" ] && [ "$bytes" -le 1048576 ] || continue   # skip >1MB
  grep -Iq . "$f" 2>/dev/null || continue                   # skip binary
  if [ "$COUNT" -ge 50 ]; then CAPPED=1; break; fi
  set -- "$@" "$f"
  COUNT=$((COUNT + 1))
done < <(git -C "$CWD" status --porcelain -z 2>/dev/null)

[ "$CAPPED" -eq 1 ] && warn "dirty-file cap (50) reached; scanned first 50"
[ "$COUNT" -gt 0 ] || exit 0   # nothing scannable

[ -f "$SCANNER" ] || { warn "scanner missing: $SCANNER"; exit 0; }

# Run scanner over the collected files; capture its SECRET: lines from stderr.
# Scanner exit: 1=finding, 2=usage, 0=clean. 2>&1 >/dev/null keeps only the
# SECRET: stderr lines; $? is the scanner's own code (direct call, no xargs).
SECRETS=$(bash "$SCANNER" "$@" 2>&1 >/dev/null)
RC=$?

if [ "$RC" -eq 1 ]; then
  printf '%s\n' "$SECRETS" >&2
  echo "Redact before finishing. If the value is real: rotate the credential." >&2
  exit 2
fi
if [ "$RC" -ne 0 ]; then
  warn "scanner exit $RC"
  exit 0
fi
exit 0
