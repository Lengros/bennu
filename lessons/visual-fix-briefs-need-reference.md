# Visual Fix Briefs Require Reference Implementation
date: 2026-04-04
scope: delegation
rule: Before delegating a visual fix, diagnose root cause, find a working reference, include file+lines+props; vague style briefs produce hacks.

## Why
A brief containing only "match the standard style" produced a fix using !important overrides rather than using the correct component props. Root cause had not been diagnosed; no reference implementation was provided. The executor improvised and introduced technical debt.

## How to apply
Before delegating any visual fix: (1) diagnose the root cause (read the actual code); (2) find a working example of the correct pattern in the codebase; (3) include the file path, line range, and explicit prop values in the brief. If you cannot diagnose the root cause, delegate investigation as a separate step before delegating the fix.
