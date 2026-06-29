#!/bin/bash
# session-end.sh — SessionEnd hook (Bennu involuntary record).
# Appends a session_end line to runs.jsonl, then recomputes the retro trigger.
# SessionEnd output goes NOWHERE visible (§0.7) — emit no model-facing text.
# Fail-open per §0.6: tooling errors → warn + continue. ALWAYS exit 0.
# No set -e (§0.8). Concurrent appends: single-line >>, no locks (documented).

TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
TEL="$CLAUDE_PROJECT_DIR/telemetry"
RUNS="$TEL/runs.jsonl"
BLOCKS="$TEL/blocks.jsonl"
FLAG="$TEL/retro.flag"
WARN="$TEL/warnings.log"
JQ="$(command -v jq || true)"
PY="$(command -v python3 || true)"

mkdir -p "$TEL" 2>/dev/null

INPUT="$(cat)"

# 1. Parse session_id + reason (best effort; failures still attempt step 2).
SID=""
REASON="unknown"
if [ -n "$JQ" ]; then
  SID="$(printf '%s' "$INPUT" | "$JQ" -r '.session_id // ""' 2>/dev/null)" || SID=""
  REASON="$(printf '%s' "$INPUT" | "$JQ" -r '.reason // "unknown"' 2>/dev/null)" || REASON="unknown"
else
  printf '%s %s fail-open: %s\n' "$TS" "session-end" "jq missing" >>"$WARN" 2>/dev/null
fi
[ -z "$REASON" ] && REASON="unknown"

# log-run.sh keys run records on telemetry/current-session when CLAUDE_SESSION_ID
# is unset. Compaction/resume ROTATE the harness id mid-conversation, so
# current-session holds the conversation's id CHAIN (one per line, newest last;
# session-start.sh maintains it). Join blocks + enrichment against the stdin id
# PLUS every chain id — keyed on one id, a pre-compact run/block reads as
# unattributed forever (the bug behind the first retro's 0% enrichment).
CHAIN="$(cat "$TEL/current-session" 2>/dev/null || true)"

# 2. blocks = blocks.jsonl lines whose session_id matches the chain (absent → 0).
#    enriched = a type:"run" line keyed to the stdin id or any chain id.
N=0
ENRICHED="false"
if [ -n "$SID" ] && [ -n "$PY" ]; then
  N="$("$PY" - "$SID" "$CHAIN" "$BLOCKS" <<'PYEOF' 2>/dev/null
import json,sys
sid,chain,path=sys.argv[1],sys.argv[2],sys.argv[3]
keys={k.strip() for k in [sid]+chain.splitlines() if k.strip()}
c=0
try:
    with open(path) as f:
        for line in f:
            line=line.strip()
            if not line: continue
            try:
                o=json.loads(line)
            except Exception:
                continue
            if o.get("session_id") in keys: c+=1
except FileNotFoundError:
    pass
print(c)
PYEOF
)" || N=0
  [ -z "$N" ] && N=0
  ENRICHED="$("$PY" - "$SID" "$CHAIN" "$RUNS" <<'PYEOF' 2>/dev/null
import json,sys
sid,chain,path=sys.argv[1],sys.argv[2],sys.argv[3]
keys={k.strip() for k in [sid]+chain.splitlines() if k.strip()}
found=False
try:
    with open(path) as f:
        for line in f:
            line=line.strip()
            if not line: continue
            try:
                o=json.loads(line)
            except Exception:
                continue
            if o.get("type")=="run" and o.get("session_id") in keys:
                found=True; break
except FileNotFoundError:
    pass
print("true" if found else "false")
PYEOF
)" || ENRICHED="false"
  [ -z "$ENRICHED" ] && ENRICHED="false"
elif [ -z "$PY" ]; then
  printf '%s %s fail-open: %s\n' "$TS" "session-end" "python3 missing" >>"$WARN" 2>/dev/null
fi

# Append the involuntary record (append failure → warn, continue).
printf '{"ts":"%s","type":"session_end","session_id":"%s","reason":"%s","blocks":%s,"enriched":%s}\n' \
  "$TS" "$SID" "$REASON" "$N" "$ENRICHED" >>"$RUNS" 2>/dev/null \
  || printf '%s %s fail-open: %s\n' "$TS" "session-end" "runs.jsonl append failed" >>"$WARN" 2>/dev/null

# 3. Retro trigger: friction = sum(blocks) over session_end lines + count of
#    type:"lesson" lines, counting ONLY events AFTER the last type:"retro" line
#    (a completed retro consumes the friction before it), capped at 14d back
#    when no retro exists in the window. Read ONLY runs.jsonl.
if [ -n "$PY" ]; then
  RESULT="$("$PY" - "$RUNS" <<'PYEOF' 2>/dev/null
import json,sys,datetime
path=sys.argv[1]
now=datetime.datetime.utcnow()
cutoff=now-datetime.timedelta(days=14)
def parse(ts):
    # ISO8601 Zulu: YYYY-MM-DDTHH:MM:SSZ
    try:
        return datetime.datetime.strptime(ts,"%Y-%m-%dT%H:%M:%SZ")
    except Exception:
        return None
events=[]
last_retro=None
try:
    with open(path) as f:
        for line in f:
            line=line.strip()
            if not line: continue
            try:
                o=json.loads(line)
            except Exception:
                continue
            ts=parse(o.get("ts",""))
            if ts is None: continue
            t=o.get("type")
            if t=="retro":
                if last_retro is None or ts>last_retro: last_retro=ts
            else:
                events.append((ts,o))
except FileNotFoundError:
    pass
friction=0
for ts,o in events:
    if ts < cutoff: continue
    if last_retro is not None and ts <= last_retro: continue
    t=o.get("type")
    if t=="session_end":
        b=o.get("blocks",0)
        if isinstance(b,bool): b=0
        if isinstance(b,int): friction+=b
    elif t=="lesson":
        friction+=1
# Calendar trigger (monthly cadence, Open item 5): due if the last retro is
# older than 30d, or — when no retro has ever run — the system has activity
# older than 30d. This fires the loop in a low-friction month; the only gap is
# a >30d span with no session at all, which is a span with no work to retro.
cal_cutoff=now-datetime.timedelta(days=30)
cal_due=False
if last_retro is not None:
    cal_due = last_retro < cal_cutoff
else:
    oldest=None
    for ts,o in events:
        if oldest is None or ts < oldest: oldest=ts
    cal_due = oldest is not None and oldest < cal_cutoff
print("%d %s" % (friction, "calendar" if cal_due else "-"))
PYEOF
)" || RESULT=""
  if [ -z "${RESULT:-}" ]; then
    printf '%s %s fail-open: %s\n' "$TS" "session-end" "friction compute failed" >>"$WARN" 2>/dev/null
  else
    FRICTION="${RESULT%% *}"; CAL="${RESULT##* }"
    case "$FRICTION" in ""|*[!0-9]*) FRICTION=0 ;; esac
    if [ "$FRICTION" -ge 3 ]; then
      printf 'RETRO DUE: %s friction events since last retro (14d cap) — run /retro\n' "$FRICTION" >"$FLAG" 2>/dev/null \
        || printf '%s %s fail-open: %s\n' "$TS" "session-end" "retro.flag write failed" >>"$WARN" 2>/dev/null
    elif [ "$CAL" = "calendar" ]; then
      printf 'RETRO DUE: >30 days since last retro (monthly cadence) — run /retro\n' >"$FLAG" 2>/dev/null \
        || printf '%s %s fail-open: %s\n' "$TS" "session-end" "retro.flag write failed" >>"$WARN" 2>/dev/null
    else
      rm -f "$FLAG" 2>/dev/null
    fi
  fi
fi

exit 0
