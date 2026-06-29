#!/usr/bin/env bash
# scan-secrets.sh — deterministic secret-exposure scanner.
#
# A high-precision, conservative secret-pattern scan over a set of files.
# Standalone + callable on its own so it is unit-testable and reusable (used by
# the Stop hook scan-secrets-stop.sh).
#
# Usage:
#   scan-secrets.sh <file> [<file> ...]
#
# Exit 0 = clean (no secret found in any given file).
# Exit 1 = at least one secret found. For each hit, prints to stderr ONE line:
#     SECRET: <file>: <pattern_name>
#   It NEVER echoes the matched secret VALUE — only the pattern NAME and the
#   file. (Logging the value would re-leak the credential into hook stderr /
#   blocks.jsonl / the user's terminal scrollback.)
# Exit 2 = usage error (no files given). Missing/unreadable files are SKIPPED
#   (conservative: a file we cannot read cannot be proven to hold a secret).
#
# ── DESIGN: STRUCTURED VENDOR PATTERNS ONLY ───────────────────────────────────
# This is enforcement code. The mandate is PRECISION-ABSOLUTE: a false block
# that quarantines an honest delivery is the cardinal sin; a missed generic
# secret is acceptable (the structured vendor patterns are the real safety net).
#
# It therefore detects ONLY structured vendor credential patterns + PEM keys —
# recognizable, exact-shape credential SHAPES with low collision probability:
#   - AWS access key id (AKIA/ASIA + 16 upper-alnum)
#   - OpenAI api key (sk- + >=20 base62/underscore/dash)
#   - GitHub token (gh[porus]_ + >=20 base62)
#   - Slack token (xox[baprs]- + body)
#   - Google api key (AIza + 35 url-safe chars)
#   - PEM private-key header (RSA/EC/OPENSSH/DSA/PGP)
# These are anchored to vendor prefixes / fixed-length bodies / PEM headers —
# not loose "looks random" heuristics — so a legitimate artifact is never
# mistaken for a credential.
#
# ── OUT OF SCOPE BY DESIGN: generic/unstructured secrets ──────────────────────
# Arbitrary high-entropy `key: value` assignments (e.g. a bare hex blob or a
# random token on a credential-named key like `token:`/`secret:`/`api_key:`) are
# OUT OF SCOPE. A generic key:value high-entropy rule once existed here but was
# REMOVED: three independent adversarial cold-reads each found that every
# heuristic it could use (length, character-class-mix, pronounceability) produced
# realistic FALSE-BLOCKS of legitimate values on credential-named keys — long
# prose, Title/camelCase phrases, and vowel-poor identifiers such as
# `token: NXP-RFID-MFRC522-V2`, `private_key: PKCS8-DER-X509-CRT`,
# `access_key: s3-cdn-assets-bkt`. Under the precision-absolute mandate a rule
# that cannot avoid false-blocking honest deliveries cannot ship, so it was
# removed entirely. Catching generic secrets is left to upstream review; this
# scanner guarantees only that it never false-blocks a legitimate delivery.
#
# ── PORTABILITY ──────────────────────────────────────────────────────────────
# macOS bash 3.2 + BSD grep. NO GNU-only flags: `grep -P` (PCRE) is unavailable
# on darwin, so every pattern is POSIX ERE via `grep -E`. We pin LC_ALL=C for
# the grep pass so byte classes behave predictably and fast.
#
# Shell options are set ONLY when this file is executed directly (the CLI path).
# When SOURCED we must NOT touch the caller's shell options — flipping
# `set -e`/`pipefail` on a sourcing caller would silently change its control
# flow. The direct-exec block at the bottom sets them.

# ---------------------------------------------------------------------------
# Structured high-precision vendor/format patterns. Each is "<NAME>=<ERE>".
# These match recognizable credential SHAPES with low collision probability.
# The matched value is never printed — only NAME + file.
#
#   pem_private_key     -----BEGIN [...] PRIVATE KEY-----  (RSA/EC/OPENSSH/DSA/PGP)
#   aws_access_key_id   AKIA + 16 upper-alnum (also ASIA temp keys)
#   openai_api_key      sk- + >=20 base62/underscore/dash (covers sk-, sk-proj-)
#   github_token        gh[porus]_ + >=20 base62  (ghp_/gho_/ghr_/ghu_/ghs_)
#   slack_token         xox[baprs]- + token body
#   google_api_key      AIza + 35 url-safe chars
# ---------------------------------------------------------------------------
_SS_PATTERNS=(
  'pem_private_key=-----BEGIN ([A-Z0-9]+ )?PRIVATE KEY-----'
  'aws_access_key_id=\b(AKIA|ASIA)[0-9A-Z]{16}\b'
  'openai_api_key=\bsk-[A-Za-z0-9_-]{20,}\b'
  'github_token=\bgh[porus]_[A-Za-z0-9]{20,}\b'
  'slack_token=\bxox[baprs]-[A-Za-z0-9-]{10,}\b'
  'google_api_key=\bAIza[0-9A-Za-z_-]{35}\b'
)

# scan_secrets_file <file> — scan ONE file. Echoes "SECRET: <file>: <name>" to
# stderr for each distinct pattern that hits, and returns 1 if any hit; 0 if
# clean. Unreadable/missing -> 0 (skip; cannot prove a secret). Used by the
# CLI loop below and sourceable by callers.
scan_secrets_file() {
  local file="$1"
  [[ -r "$file" ]] || return 0

  local found=0 entry name re hit

  # --- structured vendor/format patterns ---
  for entry in "${_SS_PATTERNS[@]}"; do
    name="${entry%%=*}"
    re="${entry#*=}"
    # Pull the matching LINES (not values). grep -E, byte locale, case-sensitive
    # (these formats are case-significant). -h: no filename prefix. Guard
    # no-match under pipefail with || true.
    while IFS= read -r hit; do
      [[ -z "$hit" ]] && continue
      # Structured vendor patterns are unambiguous credential SHAPES (AKIA…,
      # sk-…, ghp_…, xox.-…, AIza…, PEM header). A real vendor key is NEVER a
      # placeholder, and a placeholder WORD in a trailing comment ("# example",
      # "# todo: rotate") or embedded in the key body ("AKIAFAKE…", "AKIANONE…")
      # must NOT suppress a genuine leak. So NO structured pattern is
      # placeholder-exempted: any line matching the vendor shape blocks.
      echo "SECRET: $file: $name" >&2
      found=1
      break   # one hit per pattern is enough to block
    done < <(LC_ALL=C grep -hE -e "$re" "$file" 2>/dev/null || true)
  done

  return "$found"
}

# When executed directly (not sourced), run the CLI over the argument list.
# Detection: BASH_SOURCE[0] == $0 means we are the top-level script.
if [[ "${BASH_SOURCE[0]:-$0}" == "${0}" ]]; then
  set -uo pipefail
  if [[ $# -lt 1 ]]; then
    echo "Usage: scan-secrets.sh <file> [<file> ...]" >&2
    exit 2
  fi
  rc=0
  for f in "$@"; do
    if ! scan_secrets_file "$f"; then
      rc=1
    fi
  done
  exit "$rc"
fi
