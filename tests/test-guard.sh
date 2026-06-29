#!/bin/bash
# test-guard.sh — adversarial tests for .claude/hooks/guard.sh (WP-03).
#
# All 12 spec cases. CLAUDE_PROJECT_DIR is exported to a FIXTURE dir with a
# crafted roots.cache + empty telemetry/ — the real repo's cache/telemetry are
# NEVER touched. bash 3.2 compatible; every expansion quoted.

# Locate guard.sh relative to this test file (not cwd).
TEST_DIR="$(cd "$(dirname "$0")" && pwd)"
GUARD="$TEST_DIR/../.claude/hooks/guard.sh"

PASS=0
FAIL=0

# --- Fixture sandbox ---------------------------------------------------------
# A throwaway dir under $HOME. Holds: the fixture CLAUDE_PROJECT_DIR (crafted
# roots.cache + empty telemetry/), two "registered" project roots, and scratch
# git repos for the worktree cases.
# IMPORTANT: the sandbox must NOT live under a scratch root (/tmp, $TMPDIR) — if
# it did, Allow-check B would auto-allow every path inside it and cases 6/9
# (which must reach the block path) would false-pass. $HOME is neither a scratch
# root nor a registered root, so it is the correct neutral home for the fixture.
SANDBOX="$(mktemp -d "$HOME/.guard-test.XXXXXX")"
cleanup() { rm -rf "$SANDBOX"; }
trap cleanup EXIT

# Physical-resolve helper (match guard.sh's notion of "physical").
phys() { python3 -c 'import os,sys;print(os.path.realpath(sys.argv[1]))' "$1"; }

# Fixture CLAUDE_PROJECT_DIR.
FIXPD="$SANDBOX/projectdir"
mkdir -p "$FIXPD/.claude" "$FIXPD/telemetry"
export CLAUDE_PROJECT_DIR="$FIXPD"

# Two registered project roots (real dirs so realpath resolves them).
ROOT1="$SANDBOX/root1"
ROOT2="$SANDBOX/root2"
mkdir -p "$ROOT1" "$ROOT2"

# Crafted roots.cache: physical paths, one per line, plus a comment line that
# must be skipped.
{
  echo "# generated fixture cache — do not edit"
  phys "$ROOT1"
  phys "$ROOT2"
} > "$FIXPD/.claude/roots.cache"

BLOCKS="$FIXPD/telemetry/blocks.jsonl"
WARNINGS="$FIXPD/telemetry/warnings.log"

# --- Helpers -----------------------------------------------------------------
# run_guard <cwd> <json> : feeds json on stdin with the given cwd, returns exit code.
run_guard() {
  rg_input="$2"
  printf '%s' "$rg_input" | bash "$GUARD" >/dev/null 2>&1
}

# Build a Write tool_input JSON with a given file_path + cwd.
mkjson() {
  # $1 = file_path, $2 = cwd, $3 = tool_name (default Write)
  mj_tool="${3:-Write}"
  printf '{"session_id":"S1","cwd":"%s","hook_event_name":"PreToolUse","tool_name":"%s","tool_input":{"file_path":"%s"}}' \
    "$2" "$mj_tool" "$1"
}

assert_exit() {
  # $1 = label, $2 = expected exit, $3 = actual exit
  if [ "$2" = "$3" ]; then
    PASS=$((PASS + 1))
    printf 'PASS  %s (exit %s)\n' "$1" "$3"
  else
    FAIL=$((FAIL + 1))
    printf 'FAIL  %s (expected exit %s, got %s)\n' "$1" "$2" "$3"
  fi
}

linecount() { [ -f "$1" ] && wc -l < "$1" | tr -d ' ' || echo 0; }

# =============================================================================
# Case 1: write inside fixture-registered root → 0
# =============================================================================
J="$(mkjson "$ROOT1/file.txt" "$ROOT1")"
printf '%s' "$J" | bash "$GUARD" >/dev/null 2>&1
assert_exit "1 write inside fixture-registered root" 0 "$?"

# =============================================================================
# Case 2: write inside a second fixture root → 0
# =============================================================================
J="$(mkjson "$ROOT2/sub/file.txt" "$ROOT2")"
printf '%s' "$J" | bash "$GUARD" >/dev/null 2>&1
assert_exit "2 write inside second fixture root" 0 "$?"

# =============================================================================
# Case 3: write to /tmp/x → 0  (scratch)
# =============================================================================
J="$(mkjson "/tmp/guard-scratch-x" "/tmp")"
printf '%s' "$J" | bash "$GUARD" >/dev/null 2>&1
assert_exit "3 write to /tmp/x (scratch)" 0 "$?"

# =============================================================================
# Case 4: write to ~/Desktop/x → 2 AND blocks.jsonl grew by 1
# =============================================================================
B_BEFORE="$(linecount "$BLOCKS")"
J="$(mkjson "$HOME/Desktop/guard-test-x" "$HOME")"
printf '%s' "$J" | bash "$GUARD" >/dev/null 2>&1
RC=$?
B_AFTER="$(linecount "$BLOCKS")"
if [ "$RC" = "2" ] && [ "$B_AFTER" = "$((B_BEFORE + 1))" ]; then
  PASS=$((PASS + 1)); printf 'PASS  4 ~/Desktop/x blocked + blocks.jsonl grew (exit 2, %s->%s)\n' "$B_BEFORE" "$B_AFTER"
else
  FAIL=$((FAIL + 1)); printf 'FAIL  4 ~/Desktop/x (exit %s, blocks %s->%s)\n' "$RC" "$B_BEFORE" "$B_AFTER"
fi

# =============================================================================
# Case 5: worktree of a registered repo → 0
#   scratch git repo INSIDE a fixture-registered root; worktree added OUTSIDE
#   all roots; write to <wt>/file → allowed via step-6 main re-check.
# =============================================================================
REPO_IN="$ROOT1/scratch-repo"
mkdir -p "$REPO_IN"
git -C "$REPO_IN" init -q
git -C "$REPO_IN" config user.email t@t.t
git -C "$REPO_IN" config user.name t
: > "$REPO_IN/seed"
git -C "$REPO_IN" add seed
git -C "$REPO_IN" commit -qm seed
WT_IN="$SANDBOX/wt-registered"   # outside all roots
git -C "$REPO_IN" worktree add -q "$WT_IN" 2>/dev/null
J="$(mkjson "$WT_IN/file.txt" "$WT_IN")"
printf '%s' "$J" | bash "$GUARD" >/dev/null 2>&1
assert_exit "5 worktree of registered repo" 0 "$?"

# =============================================================================
# Case 6: same setup, main repo OUTSIDE all roots → 2
# =============================================================================
REPO_OUT="$SANDBOX/scratch-repo-out"   # outside all roots
mkdir -p "$REPO_OUT"
git -C "$REPO_OUT" init -q
git -C "$REPO_OUT" config user.email t@t.t
git -C "$REPO_OUT" config user.name t
: > "$REPO_OUT/seed"
git -C "$REPO_OUT" add seed
git -C "$REPO_OUT" commit -qm seed
WT_OUT="$SANDBOX/wt-unregistered"
git -C "$REPO_OUT" worktree add -q "$WT_OUT" 2>/dev/null
J="$(mkjson "$WT_OUT/file.txt" "$WT_OUT")"
printf '%s' "$J" | bash "$GUARD" >/dev/null 2>&1
assert_exit "6 worktree of UNregistered repo" 2 "$?"

# =============================================================================
# Case 7: unparseable stdin → 0 AND warnings.log grew
# =============================================================================
W_BEFORE="$(linecount "$WARNINGS")"
printf '%s' '{this is not valid json' | bash "$GUARD" >/dev/null 2>&1
RC=$?
W_AFTER="$(linecount "$WARNINGS")"
if [ "$RC" = "0" ] && [ "$W_AFTER" -gt "$W_BEFORE" ]; then
  PASS=$((PASS + 1)); printf 'PASS  7 unparseable stdin fail-open + warned (exit 0, %s->%s)\n' "$W_BEFORE" "$W_AFTER"
else
  FAIL=$((FAIL + 1)); printf 'FAIL  7 unparseable stdin (exit %s, warnings %s->%s)\n' "$RC" "$W_BEFORE" "$W_AFTER"
fi

# =============================================================================
# Case 8: cache file absent → 0 + warning
#   Point CLAUDE_PROJECT_DIR at a dir with NO roots.cache.
# =============================================================================
NOCACHE="$SANDBOX/nocache"
mkdir -p "$NOCACHE/telemetry"
W8_BEFORE="$(linecount "$NOCACHE/telemetry/warnings.log")"
J="$(mkjson "$ROOT1/file.txt" "$ROOT1")"
printf '%s' "$J" | CLAUDE_PROJECT_DIR="$NOCACHE" bash "$GUARD" >/dev/null 2>&1
RC=$?
W8_AFTER="$(linecount "$NOCACHE/telemetry/warnings.log")"
if [ "$RC" = "0" ] && [ "$W8_AFTER" -gt "$W8_BEFORE" ]; then
  PASS=$((PASS + 1)); printf 'PASS  8 cache absent fail-open + warned (exit 0, %s->%s)\n' "$W8_BEFORE" "$W8_AFTER"
else
  FAIL=$((FAIL + 1)); printf 'FAIL  8 cache absent (exit %s, warnings %s->%s)\n' "$RC" "$W8_BEFORE" "$W8_AFTER"
fi

# =============================================================================
# Case 9: file_path with ../ escaping a root → 2
#   Target resolves (physically) to a sibling outside ROOT1.
# =============================================================================
J="$(mkjson "$ROOT1/../escapee/file.txt" "$ROOT1")"
printf '%s' "$J" | bash "$GUARD" >/dev/null 2>&1
assert_exit "9 ../ escaping a root" 2 "$?"

# =============================================================================
# Case 10: non-existent deep path inside a fixture root → 0
# =============================================================================
J="$(mkjson "$ROOT1/a/b/c/d/deep.txt" "$ROOT1")"
printf '%s' "$J" | bash "$GUARD" >/dev/null 2>&1
assert_exit "10 non-existent deep path inside fixture root" 0 "$?"

# =============================================================================
# Case 11: non-existent deep path inside the test-5 worktree → 0
#   <wt>/new/sub/dir/file — exercises the step-6 from-ancestor rule.
# =============================================================================
J="$(mkjson "$WT_IN/new/sub/dir/file.txt" "$WT_IN")"
printf '%s' "$J" | bash "$GUARD" >/dev/null 2>&1
assert_exit "11 deep non-existent path inside registered worktree" 0 "$?"

# =============================================================================
# Case 12: relative file_path + cwd inside a fixture root → 0
# =============================================================================
J="$(mkjson "rel/inside.txt" "$ROOT2")"
printf '%s' "$J" | bash "$GUARD" >/dev/null 2>&1
assert_exit "12 relative file_path + cwd inside fixture root" 0 "$?"

# --- Summary -----------------------------------------------------------------
echo "----------------------------------------"
TOTAL=$((PASS + FAIL))
printf '%s/%s PASS\n' "$PASS" "$TOTAL"
[ "$FAIL" -eq 0 ] || exit 1
