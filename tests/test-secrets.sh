#!/bin/bash
# test-secrets.sh — DoD harness for WP-05 (scan-secrets.sh + scan-secrets-stop.sh).
# Builds a throwaway git repo in $TMPDIR, drives the Stop hook with crafted
# stdin JSON, asserts exit codes / output / latency. Touches nothing real.
# No real credentials: the AWS keys here are valid-SHAPE fakes.

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
HOOK="$REPO_ROOT/.claude/hooks/scan-secrets-stop.sh"

SCRATCH="$(mktemp -d "${TMPDIR:-/tmp}/wp05.XXXXXX")"
trap 'rm -rf "$SCRATCH"' EXIT

# Telemetry anchor for the hook (so warnings.log lands here, not in the repo).
export CLAUDE_PROJECT_DIR="$SCRATCH/proj"
mkdir -p "$CLAUDE_PROJECT_DIR/telemetry"
WARN_LOG="$CLAUDE_PROJECT_DIR/telemetry/warnings.log"

# Scratch git repo = the session cwd.
GITREPO="$SCRATCH/repo"
mkdir -p "$GITREPO"
git -C "$GITREPO" init -q
git -C "$GITREPO" config user.email t@t.t
git -C "$GITREPO" config user.name t
echo "hello" > "$GITREPO/README.md"
git -C "$GITREPO" add -A && git -C "$GITREPO" commit -qm init

stdin_for() {  # $1 = stop_hook_active (true/false)
  printf '{"cwd":"%s","hook_event_name":"Stop","stop_hook_active":%s}' "$GITREPO" "$1"
}

PASS=0; FAIL=0
ok()   { echo "PASS: $1"; PASS=$((PASS+1)); }
bad()  { echo "FAIL: $1"; FAIL=$((FAIL+1)); }

echo "=================== DoD 1: CLEAN TREE → exit 0, <100ms ==================="
OUT=$(stdin_for false | bash "$HOOK" 2>&1); RC=$?
echo "exit=$RC out=[$OUT]"
[ "$RC" -eq 0 ] && ok "clean tree exits 0" || bad "clean tree exit $RC"
echo "--- timing (clean tree) ---"
time ( stdin_for false | bash "$HOOK" >/dev/null 2>&1 )

echo
echo "============ DoD 2: VALID-SHAPE fake AWS key → exit 2, names pattern, NOT value ============"
# AKIA + exactly 16 uppercase alphanumerics.
SECRET_VALUE="AKIA1234567890ABCDEF"
echo "aws_access_key_id = $SECRET_VALUE" > "$GITREPO/config.txt"
OUT=$(stdin_for false | bash "$HOOK" 2>&1); RC=$?
echo "exit=$RC"
echo "----- stderr/stdout shown to model -----"
echo "$OUT"
echo "----------------------------------------"
[ "$RC" -eq 2 ] && ok "valid AWS key exits 2" || bad "valid AWS key exit $RC (expected 2)"
echo "$OUT" | grep -q "aws_access_key_id" && ok "output names the pattern aws_access_key_id" || bad "pattern name absent"
echo "$OUT" | grep -q "Redact before finishing" && ok "remediation line present" || bad "remediation line absent"
if echo "$OUT" | grep -q "$SECRET_VALUE"; then bad "SECRET VALUE LEAKED into output"; else ok "secret VALUE never appears in output"; fi

echo
echo "================= DoD 3: INVALID shape (AKIA + 15 chars) → exit 0 ================="
git -C "$GITREPO" checkout -q -- . 2>/dev/null; rm -f "$GITREPO/config.txt"
echo "key = AKIA1234567890ABCDE" > "$GITREPO/bad.txt"   # AKIA + 15 chars
OUT=$(stdin_for false | bash "$HOOK" 2>&1); RC=$?
echo "exit=$RC out=[$OUT]"
[ "$RC" -eq 0 ] && ok "invalid-shape key exits 0 (no false block)" || bad "invalid shape exit $RC (expected 0)"

echo
echo "===== DoD 4: stop_hook_active:true WITH real-shape secret present → exit 0 + warnings.log grew ====="
rm -f "$GITREPO/bad.txt"
echo "aws_access_key_id = AKIA1234567890ABCDEF" > "$GITREPO/leak.txt"  # valid shape, still dirty
BEFORE=$( [ -f "$WARN_LOG" ] && wc -l < "$WARN_LOG" | tr -d ' ' || echo 0 )
OUT=$(stdin_for true | bash "$HOOK" 2>&1); RC=$?
AFTER=$( [ -f "$WARN_LOG" ] && wc -l < "$WARN_LOG" | tr -d ' ' || echo 0 )
echo "exit=$RC out=[$OUT]  warnings.log lines: $BEFORE -> $AFTER"
[ "$RC" -eq 0 ] && ok "stop_hook_active true exits 0 (never re-blocks)" || bad "stop_hook_active exit $RC (expected 0)"
[ "$AFTER" -gt "$BEFORE" ] && ok "warnings.log grew under stop_hook_active" || bad "warnings.log did not grow"
echo "--- last warnings.log line ---"; tail -1 "$WARN_LOG"

echo
echo "========================================"
echo "RESULT: $PASS PASS / $FAIL FAIL"
[ "$FAIL" -eq 0 ] && echo "ALL PASS" || echo "FAILURES PRESENT"
exit "$FAIL"
