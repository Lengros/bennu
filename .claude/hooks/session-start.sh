#!/bin/bash
# session-start.sh — SessionStart hook (Bennu telemetry).
# Links this session for log-run.sh and surfaces a pending retro flag.
# stdout IS injected into the model's context (§0.7) — keep it model-facing.
# Fail-open per §0.6: any tooling error → warn + exit 0. ALWAYS exit 0.
# No set -e (§0.8).

TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
TEL="$CLAUDE_PROJECT_DIR/telemetry"
WARN="$TEL/warnings.log"
JQ="$(command -v jq || true)"

mkdir -p "$TEL" 2>/dev/null

INPUT="$(cat)"

# 1. Parse session_id + source and maintain current-session as this
#    conversation's id CHAIN (one id per line, newest last). Compaction/resume
#    ROTATE the harness session id mid-conversation: those append to the chain;
#    a fresh conversation (startup/clear/unknown source) truncates it. The
#    enrichment/blocks joins in session-end.sh match against the whole chain.
# Known limitations (accepted — observability, not enforcement):
#  - Two concurrent Bennu sessions overwrite each other's linkage → mis-attribution.
#  - Resuming a NON-latest conversation appends to the latest one's chain (merge,
#    not overwrite) → its session_end can over-attribute the other conversation's
#    blocks/runs and double-count blocks into friction.
SID=""
SRC=""
if [ -n "$JQ" ]; then
  SID="$(printf '%s' "$INPUT" | "$JQ" -r '.session_id // ""' 2>/dev/null)" || SID=""
  SRC="$(printf '%s' "$INPUT" | "$JQ" -r '.source // ""' 2>/dev/null)" || SRC=""
else
  printf '%s %s fail-open: %s\n' "$TS" "session-start" "jq missing" >>"$WARN" 2>/dev/null
fi
if [ -n "$SID" ]; then
  case "$SRC" in
    compact|resume)
      # Continuation of an existing conversation — append the rotated id,
      # unless it is already the newest chain entry (resume may reuse the id).
      LAST="$(tail -n 1 "$TEL/current-session" 2>/dev/null || true)"
      if [ "$LAST" != "$SID" ]; then
        printf '%s\n' "$SID" >>"$TEL/current-session" 2>/dev/null \
          || printf '%s %s fail-open: %s\n' "$TS" "session-start" "current-session unwritable" >>"$WARN" 2>/dev/null
      fi
      ;;
    *)
      printf '%s\n' "$SID" >"$TEL/current-session" 2>/dev/null \
        || printf '%s %s fail-open: %s\n' "$TS" "session-start" "current-session unwritable" >>"$WARN" 2>/dev/null
      ;;
  esac
fi

# 2. Surface a pending retro flag (SessionStart stdout reaches the model).
if [ -f "$TEL/retro.flag" ]; then
  cat "$TEL/retro.flag" 2>/dev/null
fi

# 3. Telemetry health line.
if ( : >>"$TEL/runs.jsonl" ) 2>/dev/null; then
  printf 'Bennu: telemetry ok\n'
else
  printf 'Bennu: telemetry WARNING — runs.jsonl not appendable\n'
fi

exit 0
