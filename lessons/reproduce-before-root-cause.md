# Reproduce Before You Name the Root Cause
date: 2026-06-10
scope: diagnosis
rule: A root-cause verdict on a failure is unshippable until reproduced under trusted inputs; reproduction may overturn the verdict.

## Why
A live external API error was first attributed to the user's credentials, with advice to switch to a different code path. Reproducing it with the project's own trusted test credentials under controlled inputs disproved that verdict and exposed a request-construction bug in our own code. The first explanation was confident and wrong; only reproduction found the real cause. Had the user accepted the verdict, the bug would have shipped.

## How to apply
Before telling the user "X is at fault, do Y," reproduce the failure yourself under inputs you control and trust. If you cannot reproduce, label the verdict explicitly unverified rather than asserting it. Treat a user's "let me actually test this" as a signal you concluded too early — the reproduce step belongs before the verdict, not after their pushback.
