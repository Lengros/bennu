# Observed Tags on Every Claim About Existing Code
date: 2026-04-17
scope: verification
rule: Every code-state claim in a plan must carry [Observed: path:lines] (read this session) or [ASSUMPTION]; untagged claims make review vacuous.

## Why
An implementation plan contained assertions about existing code behavior that no one had verified this session. The Skeptic could not meaningfully check these assertions because there was no evidence they had been observed. Tagging at production time (writing the plan) rather than only at consumption time (reading it) is what makes the tag load-bearing.

## How to apply
When writing any plan that makes claims about existing code: for each factual claim about current state, either (a) read the relevant file section this session and tag it [Observed: path:lines], or (b) mark it [ASSUMPTION] and flag it for the Skeptic. The Skeptic validates evidence-tagged plans; untagged plans require a full re-read pass first.
