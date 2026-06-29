# Requirements Work Traces to Primary Sources — a Cite to a Prior Artifact Is Not Grounding

date: 2026-06-18
scope: epistemics
rule: Ground requirements on PRIMARY sources (code, domain doc), not a prior artifact; an [Observed:] cite to a derived doc isn't grounding.

## Why
Asked to produce a high-level requirements matrix for a service, I rewrote the previous agent's domain rows for altitude, atomicity, and narrative — without opening the code or the domain inventory I *knew* existed. I tagged the resulting formulations `[Observed: matrix.md:NN]`. Technically true — those strings were in the file — but it reads as "verified against reality" and manufactured false confidence. The domain model came from a subagent's *training knowledge*, not any source. Net: polish applied to unverified prior text, presented as requirements work. Had the user not asked where the formulations came from, the slop would have propagated across every domain into a production doc — polished nonsense built on prior nonsense. The matrix even *claimed* "verified against current code" — but that was the previous agent's claim, inherited untested.

## How to apply
- **Requirements work starts at primary sources**: the actual code/behaviour, the authoritative domain documentation, the live prototype/data — *not* a prior draft of the same document.
- **`[Observed: path:lines]` is legitimate only when `path` is primary.** Citing a derived/intermediate artifact (a prior requirements matrix, a research summary, another agent's notes) is `[Asserted: <source> — UNVERIFIED]`, never `[Observed]`. Rephrasing for altitude is not grounding.
- **A prior artifact is a starting point, not evidence.** You may inherit its text, but every factual claim must be re-grounded on a primary source before you carry it forward.
- **Domain facts from model/subagent training knowledge are `[ASSUMPTION]`** until checked against the official source. Flag them (⚠), don't state them as fact.
- **Smell test:** if asked "where did this come from," the honest answer must point at code or an authoritative doc you opened *this session* — not "the previous version said so."

## Disposition
Sibling to [[grounded-is-not-validated]] (2026-06-17): that lesson says a source's STATUS (draft vs ratified) must travel with the claim; this one says the source must be PRIMARY in the first place — a cite to a derived artifact is not grounding at all. Sharpens [[observed-tags-on-code-claims]] (the tag must point at primary reality, not an intermediate doc) and [[facts-before-text]] (facts → structure → draft).
