# Grounded Is Not Validated — Carry Premise Status, Not Just Source
date: 2026-06-17
scope: epistemics
rule: Grounded isn't true: an [Observed:] cite proves fidelity to a source, not finality; carry each premise's STATUS, not just its location.

## Why
Building a PRD set on a draft requirements matrix, the evidence system (`[Observed:]` tags + skeptic citation re-open) guaranteed faithfulness-to-source but not truth-of-source. A faithfully-cited chain can still be a chain of unvalidated decisions — "grounded ≠ true." The dominant risk is not fabrication (a thin tail) but premise-inheritance: unratified choices (target architecture, sequencing) and soft estimates (de-risking percentages) harden into "fact" through repetition across document layers. The user named this directly: "галлюцинируем что-то, потом на основе галлюцинации строим новые галлюцинации."

## How to apply
- Two provenance tags: `[Observed: path:lines]` = re-checkable code/reality fact; `[Asserted: source — STATUS]` = traces to a Product decision, STATUS ∈ {DRAFT, REVIEWED, RATIFIED}.
- Any artifact built on draft sources carries a **load-bearing premises register**: premise · status · what rests on it · what flips downstream if it changes. Make the dependency visible, never silent.
- Target rule: load-bearing structure should rest on ≥REVIEWED sources. When it rests on DRAFT, the whole artifact is explicitly proposal-grade; human ratification is the gate that converts proposal into buildable contract.
- Mark soft estimates (percentages, "cheapest path") as UNVERIFIED at every restatement; never let them travel as facts.
- One section owns premise status as single source of truth; sections that state a premise "plainly" reference it as a working assumption, not settled fact.

## Disposition
Extends "Derived Content Requires Source Traceability" (2026-04-05): that lesson ensures a claim cites a source; this one adds that the source's *status* (draft vs ratified) must travel with the claim.
