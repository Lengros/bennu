#!/bin/bash
# log-run.sh — voluntary run enrichment CLI (Bennu telemetry).
# Appends one {"type":"run",...} line to telemetry/runs.jsonl.
# session_id: $CLAUDE_SESSION_ID, else the NEWEST id in telemetry/current-session
# (the file is this conversation's id chain, one per line), else "manual".
# PHX (repo root) is derived from $0's dirname, NOT cwd (tools/ lives under root).
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
usage: log-run.sh --task "..." --mode embody|delegate \
       --personas "a,b" --skeptic pass|fail|skipped \
       --outcome shipped|partial|abandoned [--from-card "x,y"] [--notes "..."]
  --personas:  comma-separated list (split + trimmed into a JSON array).
  --from-card: comma-separated persona-card slugs (filenames in personas/ minus
               .md) the personas were reused from or synthesized on top of. This
               is the ONLY signal of card reuse — the free-text --personas labels
               are not. Omit when no card seeded the cast.
EOF
}

PHX="$(cd "$(dirname "$0")/.." && pwd)"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
PY="$(command -v python3)"

TASK=""; MODE=""; PERSONAS=""; SKEPTIC=""; OUTCOME=""; NOTES=""; FROM_CARD=""
while [ "$#" -gt 0 ]; do
  case "$1" in
    --task)      TASK="${2:-}"; shift 2 ;;
    --mode)      MODE="${2:-}"; shift 2 ;;
    --personas)  PERSONAS="${2:-}"; shift 2 ;;
    --skeptic)   SKEPTIC="${2:-}"; shift 2 ;;
    --outcome)   OUTCOME="${2:-}"; shift 2 ;;
    --notes)     NOTES="${2:-}"; shift 2 ;;
    --from-card) FROM_CARD="${2:-}"; shift 2 ;;
    *) echo "log-run.sh: unknown argument: $1" >&2; usage; exit 1 ;;
  esac
done

# Enum validation — unknown value → exit 1 + usage.
case "$MODE"    in embody|delegate) ;;            *) echo "log-run.sh: bad --mode '$MODE'" >&2; usage; exit 1 ;; esac
case "$SKEPTIC" in pass|fail|skipped) ;;          *) echo "log-run.sh: bad --skeptic '$SKEPTIC'" >&2; usage; exit 1 ;; esac
case "$OUTCOME" in shipped|partial|abandoned) ;;  *) echo "log-run.sh: bad --outcome '$OUTCOME'" >&2; usage; exit 1 ;; esac

SID="${CLAUDE_SESSION_ID:-$(tail -n 1 "$PHX/telemetry/current-session" 2>/dev/null || echo manual)}"
[ -n "$SID" ] || SID="manual"

mkdir -p "$PHX/telemetry"

# Personas + from-card comma-split → trimmed JSON arrays. All fields JSON-escaped via python3.
"$PY" - "$PHX/telemetry/runs.jsonl" "$TS" "$SID" "$TASK" "$MODE" "$PERSONAS" "$SKEPTIC" "$OUTCOME" "$NOTES" "$FROM_CARD" <<'PYEOF'
import json,sys
out,ts,sid,task,mode,personas,skeptic,outcome,notes,from_card=sys.argv[1:11]
arr=[p.strip() for p in personas.split(",") if p.strip()]
cards=[c.strip() for c in from_card.split(",") if c.strip()]
rec={"ts":ts,"type":"run","session_id":sid,"task":task,"mode":mode,
     "personas":arr,"from_card":cards,"skeptic":skeptic,"outcome":outcome,"notes":notes}
with open(out,"a") as f:
    # Compact separators (no spaces) so run records match the corpus written by
    # session-end.sh / digest-lessons.sh / the retro skill. Mixed formats made
    # run records invisible to string-matching readers (retro 2026-06-13).
    f.write(json.dumps(rec,separators=(",",":"))+"\n")
PYEOF
