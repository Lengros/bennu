#!/bin/bash
# learn-nudge.sh — Stop hook: LEARN-loop enrichment nudge (tripwire, not jail).
#
# Fires when the model tries to end its turn. If this session changed code (a
# dirty working tree) but logged no enriched run record, nudge ONCE to run
# tools/log-run.sh, then never again this session. The retro found 0/0 enriched
# runs: the §8 LEARN logging was reliably skipped because nothing surfaced it at
# the moment of shipping. This is that surface.
#
# Mirrors scan-secrets-stop.sh exactly: exit 2 ONLY for the single intentional
# nudge; re-entry (stop_hook_active) AND a per-session marker both yield exit 0,
# so the session can ALWAYS end after one nudge (tripwire, not jail).
#
# Posture (§0.6 fail-open, §0.7 Stop contract): ANY tooling error → exit 0.
# No `set -e` (§0.8). Conversational sessions (clean tree) are never nudged.

HOOK_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$HOOK_DIR/../.." && pwd)"          # <root> from .claude/hooks
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$REPO_ROOT}"     # telemetry anchor (§0.11)
WARN_LOG="$PROJECT_DIR/telemetry/warnings.log"
RUNS="$PROJECT_DIR/telemetry/runs.jsonl"
SELF="learn-nudge"

warn() {
  mkdir -p "$PROJECT_DIR/telemetry" 2>/dev/null
  printf '%s %s fail-open: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$SELF" "$1" >> "$WARN_LOG" 2>/dev/null
}

INPUT=$(cat)
JQ="$(command -v jq || true)"
[ -n "$JQ" ] || { warn "jq missing"; exit 0; }

# Stop-loop guard (§0.7): re-entry sets stop_hook_active — never re-block.
STOP_ACTIVE=$(printf '%s' "$INPUT" | "$JQ" -r '.stop_hook_active // false' 2>/dev/null)
[ "$STOP_ACTIVE" = "true" ] && exit 0

SID=$(printf '%s' "$INPUT" | "$JQ" -r '.session_id // ""' 2>/dev/null)
[ -n "$SID" ] || SID="${CLAUDE_SESSION_ID:-}"
[ -n "$SID" ] || { warn "no session_id"; exit 0; }

# Already nudged this session → silent (one nudge per session, ever).
MARKER="$PROJECT_DIR/telemetry/.learn-nudged-$SID"
[ -f "$MARKER" ] && exit 0

# Already enriched → never nag. Two subtleties:
#  (1) runs.jsonl is mixed-format — log-run.sh writes spaced JSON, the other
#      hooks write compact — so parse with jq, never a literal grep.
#  (2) the live stdin session_id and telemetry/current-session (what log-run.sh
#      keys on when CLAUDE_SESSION_ID is unset) can DIVERGE — compaction rotates
#      the id, and current-session holds the conversation's whole id CHAIN (one
#      per line, newest last; session-start.sh maintains it). Match a run under
#      the stdin id OR ANY chain id. Bias: a false match suppresses a nudge
#      (benign); we never want to nag a session already logged under an
#      earlier key.
CHAIN="$(cat "$PROJECT_DIR/telemetry/current-session" 2>/dev/null || true)"
if [ -f "$RUNS" ]; then
  ENRICHED=$("$JQ" -s --arg a "$SID" --arg b "$CHAIN" \
    '($b | split("\n") | map(select(length > 0))) as $chain
     | any(.[]; .type=="run"
         and ((.session_id == $a) or (.session_id as $s | $chain | index($s) != null)))' \
    "$RUNS" 2>/dev/null)
  [ "$ENRICHED" = "true" ] && exit 0
fi

# Only nudge if the session did code work — proxy: a dirty working tree in cwd.
# A clean tree (conversational session, or everything already committed) → no nudge.
CWD=$(printf '%s' "$INPUT" | "$JQ" -r '.cwd // ""' 2>/dev/null)
[ -n "$CWD" ] && [ -d "$CWD" ] || { warn "no cwd from stdin"; exit 0; }
command -v git >/dev/null 2>&1 || { warn "git missing"; exit 0; }
git -C "$CWD" rev-parse --is-inside-work-tree >/dev/null 2>&1 || exit 0  # not a repo
[ -n "$(git -C "$CWD" status --porcelain 2>/dev/null | head -1)" ] || exit 0  # clean → no nudge

# One nudge, then yield. Touch the marker BEFORE exit 2 so even an unexpected
# re-entry path cannot re-nudge this session.
: > "$MARKER" 2>/dev/null
cat >&2 <<'EOF'
LEARN nudge (tripwire, fires once per session): this session changed code but
logged no enriched run record. If a Bennu loop completed (INTENT→…→SHIP), record
it before finishing:
  tools/log-run.sh --task "<short>" --mode embody|delegate \
    --personas "<a,b>" --skeptic pass|fail|skipped --outcome shipped|partial|abandoned
If this turn did not complete a loop (work-in-progress, scratch, exploration),
just stop again — this nudge will not repeat.
EOF
exit 2
