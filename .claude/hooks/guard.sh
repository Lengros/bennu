#!/bin/bash
# guard.sh — Bennu PreToolUse path-boundary tripwire (WP-03).
#
# POSTURE (authoritative):
#   - Binds Write / Edit / NotebookEdit ONLY. No other tool reaches this hook
#     (see .claude/settings.json matcher "Write|Edit|NotebookEdit").
#   - Bash bypass is ACCEPTED by design: a Bash write can escape this
#     boundary. This is a tripwire against ACCIDENTAL writes, not a sandbox.
#   - Subagent calls get NO exemption (§0.7): the path boundary binds subagent
#     tool calls EXACTLY like main-session calls. We do not read agent_type.
#   - FAIL-OPEN on ALL tooling errors (§0.6): missing binary, crashed
#     sub-command, unparseable stdin, unreadable file → warn to
#     telemetry/warnings.log and exit 0. Exit 2 is reserved EXCLUSIVELY for an
#     intentional, successfully-computed block decision (§0.6).
#   - NO PATH CARVE-OUTS MAY EVER BE ADDED TO THIS FILE. A false-block is fixed
#     by generalizing the algorithm or registering the project in
#     PROJECT_REGISTRY.yaml — NEVER by a special case. (R1.)
#
# Hooks do NOT use `set -e` (§0.8): a failed sub-command must not silently flip
# the allow/deny decision. Every command result is checked explicitly.
# Target: macOS /bin/bash 3.2 — no mapfile, no declare -A, no ${var,,}, no &>>.

# --- Helpers -----------------------------------------------------------------

# §0.11 timestamp format, everywhere.
ts() { date -u +%Y-%m-%dT%H:%M:%SZ; }

# §0.6 fail-open: warn one line to telemetry/warnings.log and exit 0.
# Path is anchored to $CLAUDE_PROJECT_DIR/telemetry (§0.11). The warn append
# itself must never abort the exit-0 (best-effort; ignore its failure).
warn_fail_open() {
  reason="$1"
  if [ -n "${CLAUDE_PROJECT_DIR:-}" ]; then
    wdir="$CLAUDE_PROJECT_DIR/telemetry"
    mkdir -p "$wdir" 2>/dev/null
    printf '%s %s fail-open: %s\n' "$(ts)" "guard" "$reason" >> "$wdir/warnings.log" 2>/dev/null
  fi
  exit 0
}

# realpath of an EXISTING path via python3 (macOS has no realpath binary).
# Prints the physical path on stdout; non-zero exit on failure.
phys() {
  python3 -c 'import os,sys;print(os.path.realpath(sys.argv[1]))' "$1" 2>/dev/null
}

# --- Step 1: read stdin JSON, extract tool_name / session_id / cwd / target --

# Reference parser — stdin-JSON parsing only, NOT
# blocking logic.
JQ="$(command -v jq || true)"
[ -n "$JQ" ] || warn_fail_open "jq not found"

INPUT="$(cat)"
[ -n "$INPUT" ] || warn_fail_open "empty stdin"

TOOL="$(printf '%s' "$INPUT" | "$JQ" -r '.tool_name // ""' 2>/dev/null)" \
  || warn_fail_open "jq failed parsing tool_name (bad JSON)"
SESSION_ID="$(printf '%s' "$INPUT" | "$JQ" -r '.session_id // ""' 2>/dev/null)" \
  || warn_fail_open "jq failed parsing session_id"
CWD="$(printf '%s' "$INPUT" | "$JQ" -r '.cwd // ""' 2>/dev/null)" \
  || warn_fail_open "jq failed parsing cwd"

# Target: tool_input.file_path (Write/Edit) or tool_input.notebook_path
# (NotebookEdit). NotebookEdit is in the matcher, so check both keys.
# Subagent calls are NOT exempt (§0.7): we never inspect agent_type.
TARGET="$(printf '%s' "$INPUT" \
  | "$JQ" -r '.tool_input.file_path // .tool_input.notebook_path // ""' 2>/dev/null)" \
  || warn_fail_open "jq failed parsing target path"

# Empty target → not a file write → allow (exit 0, not a block).
[ -n "$TARGET" ] || exit 0

# --- Step 2: relative → prepend <cwd>/ ; leading ~ → $HOME --------------------

# A leading ~ is expanded first (the stdin field may carry a literal tilde).
case "$TARGET" in
  "~") TARGET="$HOME" ;;
  "~/"*) TARGET="$HOME/${TARGET#"~/"}" ;;   # quote pattern: else ~/ tilde-expands and never strips
esac

# Relative target → make absolute against the stdin cwd field (§0.11).
case "$TARGET" in
  /*) : ;;                       # already absolute
  *)  TARGET="$CWD/$TARGET" ;;   # relative — anchor to cwd
esac

# --- Step 3: resolve_target — walk to an EXISTING ancestor, realpath, re-tail -

# The file may not exist yet. Walk up to the nearest existing directory, realpath
# THAT, then re-append the non-existing tail by string substitution. Keep BOTH
# `resolved` (full physical-prefixed path) and `anc_real` (physical existing
# ancestor — step 6 runs git from there).
resolve_target() {
  rt_target="$1"
  anc="$rt_target"
  # Loop floor is "/" (always a dir), so this terminates.
  while [ ! -d "$anc" ]; do
    anc="$(dirname "$anc")"
  done
  # realpath the existing ancestor. Failure on an EXISTING dir (permissions,
  # etc.) is a tooling error → fail-open + warn (§0.6).
  anc_real="$(phys "$anc")"
  if [ -z "$anc_real" ]; then
    warn_fail_open "realpath failed on existing ancestor: $anc"
  fi
  # Re-append the tail: the part of the original target below the ancestor.
  if [ "$anc" = "$rt_target" ]; then
    # Target itself already existed as a directory.
    resolved="$anc_real"
  else
    tail="${rt_target#$anc}"          # leading portion stripped → "/sub/dir/file"
    case "$tail" in
      /*) resolved="$anc_real$tail" ;;
      *)  resolved="$anc_real/$tail" ;;
    esac
  fi
}
resolve_target "$TARGET"

# --- Step 4: Allow-check A (cache roots) -------------------------------------

CACHE="${CLAUDE_PROJECT_DIR:-}/.claude/roots.cache"
# Missing/empty cache → fail-open + warn (cache is rebuildable; its absence
# must not paralyze work — §WP-03 step 4).
if [ -z "${CLAUDE_PROJECT_DIR:-}" ]; then
  warn_fail_open "CLAUDE_PROJECT_DIR unset"
fi
if [ ! -f "$CACHE" ]; then
  warn_fail_open "roots.cache absent: $CACHE"
fi
if [ ! -s "$CACHE" ]; then
  warn_fail_open "roots.cache empty: $CACHE"
fi

# in_roots: 0 = matched a cache root, 1 = no match. Reads $CACHE line by line.
# Used for both Allow-check A and the step-6 worktree main re-check.
in_roots() {
  ir_path="$1"
  ir_hit=1
  while IFS= read -r r || [ -n "$r" ]; do
    case "$r" in
      ""|"#"*) continue ;;        # skip blank + comment lines
    esac
    r="${r%/}"                    # strip trailing / defensively
    case "$ir_path" in
      "$r"|"$r"/*) ir_hit=0; break ;;
    esac
  done < "$CACHE"
  return "$ir_hit"
}

if in_roots "$resolved"; then
  exit 0
fi

# --- Step 5: Allow-check B (scratch) -----------------------------------------

# Scratch roots: /tmp /private/tmp ${TMPDIR%/}. realpath EACH first — on macOS
# /tmp → /private/tmp and $TMPDIR → /private/var/folders/...; comparing a
# physical target against a raw symlinked root would false-block every TMPDIR
# write. Then prefix-match as in A.
SCRATCH_RAW="/tmp /private/tmp ${TMPDIR%/}"
for s in $SCRATCH_RAW; do
  [ -n "$s" ] || continue
  [ -d "$s" ] || continue
  s_real="$(phys "$s")"
  [ -n "$s_real" ] || continue    # realpath failure on a scratch root: just skip it
  s_real="${s_real%/}"
  case "$resolved" in
    "$s_real"|"$s_real"/*) exit 0 ;;
  esac
done

# Harness-owned scratch: the platform's plan-mode directory (~/.claude/plans).
# Plan files are harness-managed ephemeral working files, NOT project content —
# the same class as /tmp, so this is a generalizing scratch rule, not a per-project
# carve-out (R1). Scoped to ~/.claude/plans ONLY (not the rest of ~/.claude),
# phys-resolved (symlink-safe — a symlinked tail resolves out of this prefix), and
# the "/*" pattern requires a trailing slash so a sibling like plans-evil/ misses.
# Handled outside SCRATCH_RAW's word-split loop so a space in $HOME is safe.
if [ -n "${HOME:-}" ] && [ -d "$HOME/.claude/plans" ]; then
  plan_real="$(phys "$HOME/.claude/plans")"
  if [ -n "$plan_real" ]; then
    plan_real="${plan_real%/}"
    case "$resolved" in
      "$plan_real"|"$plan_real"/*) exit 0 ;;
    esac
  fi
fi

# --- Step 6: Allow-check C (worktrees) — only if A and B failed --------------

# git BINARY missing = tooling error → fail-open (§0.6).
command -v git >/dev/null 2>&1 || warn_fail_open "git binary not found"

# Run git FROM the existing ancestor anc_real — NEVER from dirname of a
# possibly-non-existent target (a new nested dir inside a worktree must not
# false-block — that is exactly test 11).
gcd="$(git -C "$anc_real" rev-parse --git-common-dir 2>/dev/null)"
git_rc=$?
if [ "$git_rc" -eq 0 ] && [ -n "$gcd" ]; then
  # If --git-common-dir is relative, resolve it against --show-toplevel.
  case "$gcd" in
    /*) : ;;
    *)
      toplevel="$(git -C "$anc_real" rev-parse --show-toplevel 2>/dev/null)"
      if [ -n "$toplevel" ]; then
        gcd="$toplevel/$gcd"
      fi
      ;;
  esac
  # main="${gcd%/.git*}" — ONE expansion that handles all three layouts:
  #   linked worktree   <main>/.git              → <main>
  #   main checkout      <toplevel>/.git          → <toplevel>
  #   submodule          <super>/.git/modules/<n> → <super>
  main="${gcd%/.git*}"
  main_real="$(phys "$main")"
  if [ -n "$main_real" ]; then
    main_real="${main_real%/}"
    # Re-check the worktree's main repo against Allow-check A's cache roots.
    if in_roots "$main_real"; then
      exit 0
    fi
  fi
  # git answered successfully but the main repo is not a registered root →
  # fall through to the block path (this is a real answer, not a tooling error).
fi
# git_rc != 0 here means git ANSWERED "not a repository" (a real answer, not a
# missing binary — that was caught above). Block path continues. (§WP-03 step 6:
# distinguish git-binary-missing = fail-open vs git-says-not-a-repo = block.)

# --- Step 7: Block -----------------------------------------------------------

# Append a structured block event to telemetry/blocks.jsonl. Append failure
# must NOT abort the block — still block, plus warn (best-effort).
BLOCKS="$CLAUDE_PROJECT_DIR/telemetry/blocks.jsonl"
mkdir -p "$CLAUDE_PROJECT_DIR/telemetry" 2>/dev/null
# Build the JSON via jq for correct escaping of the path/session values.
block_line="$(printf '%s' "$INPUT" | "$JQ" -nc \
  --arg ts "$(ts)" \
  --arg sid "$SESSION_ID" \
  --arg path "$resolved" \
  --arg tool "$TOOL" \
  '{ts:$ts,session_id:$sid,path:$path,tool:$tool}' 2>/dev/null)"
if [ -n "$block_line" ]; then
  printf '%s\n' "$block_line" >> "$BLOCKS" 2>/dev/null || \
    printf '%s %s fail-open: blocks.jsonl append failed (still blocking)\n' \
      "$(ts)" "guard" >> "$CLAUDE_PROJECT_DIR/telemetry/warnings.log" 2>/dev/null
else
  printf '%s %s fail-open: blocks.jsonl jq-encode failed (still blocking)\n' \
    "$(ts)" "guard" >> "$CLAUDE_PROJECT_DIR/telemetry/warnings.log" 2>/dev/null
fi

# Block message (§0.9: ≤6 lines, what/why/one next step, NO destructive command).
{
  echo "BLOCKED: write outside registered roots: $resolved"
  echo "This is a tripwire against accidental writes, not a punishment."
  echo "If this project is legitimate: add it to PROJECT_REGISTRY.yaml, run tools/build-roots-cache.sh, retry."
  echo "Otherwise: write inside an existing project root or /tmp."
} >&2
exit 2
