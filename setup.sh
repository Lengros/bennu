#!/bin/bash
# setup.sh — one-time per-clone bootstrap for Bennu.
#
# Enables the versioned git hooks (core.hooksPath isn't carried by the repo, so a
# fresh clone has to opt in). Idempotent: safe to re-run. Run from anywhere.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO_ROOT"

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
  echo "setup.sh: not inside a git work tree ($REPO_ROOT)" >&2; exit 1; }

# 1. Point git at the versioned hooks dir.
git config core.hooksPath .githooks

# 2. Make every tracked hook executable (a fresh clone may drop the +x bit).
if [ -d .githooks ]; then
  chmod +x .githooks/* 2>/dev/null || true
fi

echo "Bennu setup complete."
echo "  core.hooksPath = $(git config core.hooksPath)"
echo "  active hooks:    $(ls .githooks 2>/dev/null | tr '\n' ' ')"
echo "Enabled: pre-commit secret scan (blocks vendor-credential shapes in staged content)."
