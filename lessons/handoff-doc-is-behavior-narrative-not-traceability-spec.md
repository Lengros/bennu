# A Hand-off Doc Is a Behavior Narrative, Not a Traceability Spec — Strip the Scaffolding from the Deliverable
date: 2026-06-24
scope: content / hand-off docs / delegation
rule: A hand-off doc is a behavior narrative by the user's journey, not a traceability spec; keep evidence tags and IDs out of the deliverable.

## Why
For a service hand-off, a prior agent produced a "PRD set" (system-brief + per-slice A1/A3/E1, cross-linked to a requirements matrix): `[Observed: path:lines]` tags on most sentences, `§3.2`/`AC-11` cross-refs, "covered requirement IDs" and "seam" tables, premise-status tags, 15-item adversarial AC matrices, and a preamble apologizing for its own numbering. It was *grounded and internally rigorous* — and unreadable. The user's actual need: one document a developer reads (after the vision and a click through the prototype) to **derive the architecture themselves**. The set did the architect's job badly while failing its one job — communicating behavior.

Two deeper traps surfaced:
1. **Bennu's own grounding discipline leaked into the product.** `[Observed:]`/`[ASSUMPTION]` tags ([[derived-content-source-traceability]]) prove fidelity *while drafting*. They are working-notes scaffolding. Left in a human-facing deliverable, they are the tell that the agent confused its notes with the artifact.
2. **The spec-writer persona manufactures this failure.** The `handoff_spec_writer` card's standards *are* reuse-verdicts + `[Observed:]` + decompose-by-slice + ID-traceability. Reusing it for a behavior doc reproduces the exact defect.

## How to apply
- **Pick the genre from the reader's job.** If a human reads it front-to-back to *derive* architecture, write a **behavior narrative**: organize by the user's journey/capabilities, each section *job → flow → rules → not-here*. If a build pipeline consumes it as a contract, a traceability spec may be right — but say which you're writing and don't blend them.
- **Strip the scaffolding from the deliverable.** No `[Observed:]`/`[ASSUMPTION]` tags, no `§`/`AC-`/row-ID cross-refs, no seam/coverage tables in the body. Confine IDs to a single coverage appendix if traceability is needed at all. Do the grounding in your notes; ship the prose.
- **Stack-neutral by silence, not by disclaimer.** Don't list a mechanism (OIDC/PKCE/WebAuthn) then write "but we mandate no library" — that *is* the spec you claim to avoid. State the product rule ("a stolen sign-in does not get in") and leave the mechanism to engineering, explicitly.
- **Cast a product-behavior writer, not a spec writer.** When the deliverable is readable behavior, synthesize a writer whose anti-patterns *ban* the spec instincts; do not reuse `handoff_spec_writer`. Give the brief a fully-worked example section so the genre is unmistakable.
- **Express invariants as plain product rules.** Security/correctness guarantees ("an owner only ever sees their own business's data") belong in a short rules list, not a 15-case adversarial AC matrix — the architect derives the tests.

## Disposition
Refines [[derived-content-source-traceability]]: source-traceability governs your *drafting*, not the *deliverable* — strip the tags before shipping. Sibling to [[requirements-target-production-not-prototype]] (the prototype is reference, never proof) and [[grounded-is-not-validated]] (a cite proves fidelity, not finality).
