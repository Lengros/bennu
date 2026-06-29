# Shell ${var#pattern} expands the pattern — quote a literal tilde/glob
date: 2026-06-11
scope: tooling
rule: ${var#pattern} and ${var%pattern} expand the pattern (tilde + glob); quote a literal pattern or it silently fails to strip.

## Why
`guard.sh` expanded a leading tilde with `TARGET="$HOME/${TARGET#~/}"`. Bash performs
**tilde expansion on the word in `${var#word}`**, so the pattern `~/` became `/home/user/`,
which doesn't prefix-match a literal `~/...` target — nothing was stripped, and the result
was a malformed `/home/user/~/.config/...` path. The bug was silent: no error, just a wrong
path that then failed the boundary check. Found only by an executable test matrix on the gate,
not by reading.

## How to apply
- When the pattern in `${var#...}` / `${var%...}` is meant **literally**, quote it:
  `${var#"~/"}`, `${var%".bak"}`. Quoting suppresses tilde and glob expansion of the pattern.
- This bites any of this system's bash hooks/tools that strip prefixes/suffixes (`~`, `*`, `?`,
  `[...]` in a pattern all expand otherwise).
- Verify shell path-munging with a real **input/output table on bash 3.2** (macOS `/bin/bash`),
  never by inspection — silent no-strip looks fine in the source. See [[recon-on-flow-base-branch]]
  for the broader "reproduce/verify, don't infer" theme.
