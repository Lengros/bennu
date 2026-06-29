#!/bin/bash
# test-telemetry.sh — WP-04 DoD (a)-(d). Runs against a FIXTURE CLAUDE_PROJECT_DIR
# under $TMPDIR — NEVER the real telemetry. Timestamps are crafted, not waited on.
set -uo pipefail

SRC="$(cd "$(dirname "$0")/.." && pwd)"

# Stage script copies INTO the fixture so that log-run.sh's PHX (derived from
# $0's dirname, NOT cwd/env — per spec) resolves to the fixture, and the hooks'
# $CLAUDE_PROJECT_DIR resolves to the same fixture. Both then share $FIX/telemetry
# and we never touch the real repo's telemetry.
FIX="$(mktemp -d "${TMPDIR:-/tmp}/bennu-tel.XXXXXX")"
export CLAUDE_PROJECT_DIR="$FIX"
TEL="$FIX/telemetry"
mkdir -p "$TEL" "$FIX/.claude/hooks" "$FIX/tools"
cp "$SRC/.claude/hooks/session-end.sh"   "$FIX/.claude/hooks/"
cp "$SRC/.claude/hooks/session-start.sh" "$FIX/.claude/hooks/"
cp "$SRC/tools/log-run.sh"               "$FIX/tools/"
SE="$FIX/.claude/hooks/session-end.sh"
SS="$FIX/.claude/hooks/session-start.sh"
LR="$FIX/tools/log-run.sh"
trap 'rm -rf "$FIX"' EXIT

PASS=0; FAIL=0
ok(){ echo "PASS: $1"; PASS=$((PASS+1)); }
no(){ echo "FAIL: $1"; FAIL=$((FAIL+1)); }

# ts N days in the past, Zulu format (portable: GNU date -d / BSD date -v).
past_ts(){
  local d="$1"
  date -u -v-"${d}"d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null \
    || date -u -d "${d} days ago" +%Y-%m-%dT%H:%M:%SZ
}

echo "=== fixture: $FIX ==="

# ---------- (a) 3 blocks for S1 + session_end → blocks:3 + RETRO DUE ----------
NOWTS="$(past_ts 0)"
{
  printf '{"ts":"%s","session_id":"S1","path":"/x/a","tool":"Write"}\n' "$NOWTS"
  printf '{"ts":"%s","session_id":"S1","path":"/x/b","tool":"Edit"}\n'  "$NOWTS"
  printf '{"ts":"%s","session_id":"S1","path":"/x/c","tool":"Write"}\n' "$NOWTS"
  printf '{"ts":"%s","session_id":"S9","path":"/x/z","tool":"Write"}\n' "$NOWTS"
} >"$TEL/blocks.jsonl"

printf '{"session_id":"S1","reason":"clear"}\n' | "$SE"
LINE="$(grep '"session_id":"S1"' "$TEL/runs.jsonl" | grep '"type":"session_end"' | tail -1)"
echo "  runs line: $LINE"
echo "$LINE" | python3 -c 'import json,sys; o=json.loads(sys.stdin.read()); sys.exit(0 if o["blocks"]==3 else 1)' \
  && ok "(a) session_end blocks:3" || no "(a) session_end blocks:3 (got: $LINE)"
echo "$LINE" | python3 -c 'import json,sys; json.loads(sys.stdin.read())' >/dev/null 2>&1 \
  && ok "(a) runs line is valid JSON" || no "(a) runs line valid JSON"
if [ -f "$TEL/retro.flag" ] && grep -q '^RETRO DUE: 3 friction events since last retro (14d cap) — run /retro$' "$TEL/retro.flag"; then
  ok "(a) retro.flag has 'RETRO DUE: 3 ...'"; echo "  flag: $(cat "$TEL/retro.flag")"
else
  no "(a) retro.flag content"; cat "$TEL/retro.flag" 2>/dev/null
fi

# ---------- (b) rewrite runs.jsonl ts to 15d past, S2 zero blocks → flag removed ----------
OLDTS="$(past_ts 15)"
python3 - "$TEL/runs.jsonl" "$OLDTS" <<'PYEOF'
import json,sys
path,old=sys.argv[1],sys.argv[2]
out=[]
with open(path) as f:
    for line in f:
        line=line.strip()
        if not line: continue
        o=json.loads(line); o["ts"]=old; out.append(json.dumps(o))
with open(path,"w") as f:
    f.write("\n".join(out)+"\n")
PYEOF
# S2 has no blocks rows at all.
printf '{"session_id":"S2","reason":"exit"}\n' | "$SE"
S2LINE="$(grep '"session_id":"S2"' "$TEL/runs.jsonl" | tail -1)"
echo "  S2 line: $S2LINE"
echo "$S2LINE" | python3 -c 'import json,sys; o=json.loads(sys.stdin.read()); sys.exit(0 if o["blocks"]==0 else 1)' \
  && ok "(b) S2 session_end blocks:0" || no "(b) S2 blocks:0"
if [ ! -f "$TEL/retro.flag" ]; then
  ok "(b) retro.flag removed (all friction >14d old)"
else
  no "(b) retro.flag still present: $(cat "$TEL/retro.flag")"
fi

# ---------- (c) log-run.sh --mode wrong → exit 1 ----------
OUT="$("$LR" --mode wrong --task t --personas a --skeptic pass --outcome shipped 2>&1)" && RC=0 || RC=$?
echo "  log-run rc=$RC"
if [ "$RC" -eq 1 ]; then ok "(c) bad --mode → exit 1"; else no "(c) bad --mode exit (got $RC)"; fi
echo "$OUT" | grep -q 'comma-separated' && ok "(c) usage states comma rule" || no "(c) usage comma rule"

# ---------- (d) session-start writes current-session; log-run picks it up ----------
unset CLAUDE_SESSION_ID 2>/dev/null
printf '{"session_id":"SX-LINK","hook_event_name":"SessionStart"}\n' | "$SS" >/dev/null
CUR="$(cat "$TEL/current-session" 2>/dev/null)"
echo "  current-session: $CUR"
[ "$CUR" = "SX-LINK" ] && ok "(d) current-session = SX-LINK" || no "(d) current-session content"
LROUT="$("$LR" --task "wire up" --mode delegate --personas " p1 , p2 " --skeptic pass --outcome shipped --notes "n" 2>&1)" && LRRC=0 || LRRC=$?
[ "$LRRC" -eq 0 ] || { echo "  log-run failed rc=$LRRC: $LROUT"; no "(d) log-run exited 0"; }
RUNLINE="$(grep '"type": *"run"' "$TEL/runs.jsonl" 2>/dev/null | tail -1)"
echo "  run line: $RUNLINE"
echo "$RUNLINE" | python3 -c 'import json,sys; o=json.loads(sys.stdin.read()); sys.exit(0 if o["session_id"]=="SX-LINK" and o["personas"]==["p1","p2"] else 1)' \
  && ok "(d) log-run used current-session + trimmed personas array" || no "(d) log-run linkage/personas"
# backward-compat: --from-card omitted → from_card defaults to []
echo "$RUNLINE" | python3 -c 'import json,sys; o=json.loads(sys.stdin.read()); sys.exit(0 if o.get("from_card")==[] else 1)' \
  && ok "(d) from_card defaults to [] when --from-card omitted" || no "(d) from_card default"

# ---------- (e) log-run.sh --from-card → trimmed slug array ----------
"$LR" --task "cast from card" --mode delegate --personas "p" --skeptic pass --outcome shipped --from-card " frontend_engineer , deep_researcher " >/dev/null 2>&1
FCLINE="$(grep '"type": *"run"' "$TEL/runs.jsonl" 2>/dev/null | tail -1)"
echo "  from-card line: $FCLINE"
echo "$FCLINE" | python3 -c 'import json,sys; o=json.loads(sys.stdin.read()); sys.exit(0 if o["from_card"]==["frontend_engineer","deep_researcher"] else 1)' \
  && ok "(e) --from-card → trimmed slug array" || no "(e) from_card array"

echo "=== $PASS PASS / $FAIL FAIL ==="
[ "$FAIL" -eq 0 ]
