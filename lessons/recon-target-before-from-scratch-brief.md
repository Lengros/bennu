# Recon the Target Repo Before Writing a From-Scratch Brief/Spec

date: 2026-06-13
scope: CAST / briefs / recon
rule: For a "build X" request, recon the target repo's specs/code before writing the brief — X may already exist; scope to the real delta.

## Why
A reframe + CAST brief for a "build the data chart" request was
authored as greenfield. Grounding the recon *afterward* revealed the target repo already had
a detailed design spec **and a shipped v1** (a backend series-builder symbol, persisted source
values, and a data endpoint). The reframe had independently re-derived the team's existing
framing almost verbatim — which validates the method, but the brief's premise (net-new work)
was false. The real remaining work was the v2 increment (a second data dimension), gated on
dependencies the repo's own spec already named (a missing parser, a missing record-matching
step). A confident greenfield brief on an unverified premise wastes the executor's time and
can duplicate or contradict existing design.

## How to apply
In CAST, treat "recon the target" as a precondition for the brief, not a polish step —
especially for feature requests against a repo with a specs/ convention. Cite what already
exists with `[Observed:]`, scope the brief to the *real delta*, and point at the existing
design as authority rather than re-deriving it. If grounding contradicts the request's
premise, surface that and re-scope before writing — CLAUDE.md: "look at the target … surface
that instead of proceeding." The cost of grounding first is one Explore pass; the cost of
skipping it is a brief aimed at the wrong increment. Related: [[trace-derived-values-to-source-constants]].
