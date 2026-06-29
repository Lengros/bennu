# Rule Rollout Requires Entrypoint Sweep by Old-Behavior Vocabulary
date: 2026-04-18
scope: process
rule: When deploying a superseding rule, grep the OLD vocabulary; every hit needs triage: edit/out-of-scope/deprecated.

## Why
A new rule was deployed while multiple existing files still described the old behavior in their prose. Users encountering the old vocabulary followed outdated instructions. The same-session Skeptic cannot catch un-updated entrypoints because they share the author's blind spot.

## How to apply
After implementing a new rule that supersedes existing behavior: (1) grep for the old behavior's vocabulary (the phrases and terms that described the old way); (2) for each hit, triage: (a) edit now, (b) explicitly out-of-scope with written justification in the plan, (c) explicitly deprecated. "Mentioned in passing" is not acceptable — read the file and make a call. Use an external cold read to catch entrypoints the author's session cannot see.
