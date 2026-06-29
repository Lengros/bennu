# Quality Gate vs Approval Gate
date: 2026-03-06
scope: process
rule: Quality gates (verification) are always mandatory; approval gates (permission) are mode-dependent; never conflate them in documentation.

## Why
Operating model docs accumulated redundant "always confirm before proceeding" language that blurred the distinction between verification (non-negotiable) and permission (mode-dependent). The conflation produced both unnecessary friction in autonomous mode and false confidence that verification had happened when only approval was checked.

## How to apply
When designing a workflow step: explicitly label it as a quality gate (always runs, blocks on failure) or an approval gate (runs only in supervised mode). Verification steps run in both modes. Permission steps are configured per execution context. Do not write "always confirm" unless you mean a quality gate — if you mean it, make it a quality gate.
