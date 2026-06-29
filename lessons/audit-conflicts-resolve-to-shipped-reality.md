# Audit Conflicts Resolve to Shipped Reality — and a Documented Decision May Never Have Shipped
date: 2026-06-24
scope: audit / reconciliation / epistemics
rule: On a conflict between overlapping authorities, the tiebreaker is shipped reality; verify a documented decision shipped before trusting it.

## Why
Auditing a new official brand book against an existing internal design system, the framing handed in was "which guide is better — pick a winner." Wrong frame, two ways:
1. **They governed different layers.** The brand book is a *brand-identity* book (logo, colour story, typeface, photography, voice); the design system is a *product design system* (token scale, spacing, components, motion, a11y). Most documents that look like competitors actually govern different layers and only truly collide on a few axes — here, exactly one: the accent colour (one value in the brand book vs a different value in the internal canon).
2. **The decisive evidence was conformance, not aesthetics.** On the one real conflict, the product shipped the brand-book value. The internal canon's defining decision — a documented accent swap to a different value — had **never shipped**: one real-UI reference (a hover tint), zero semantic tokens wired to the new value, and a focus ring literally tagged with that decision's ID still rendering the old value. The most carefully-maintained document we owned was the one *most* out of sync with reality.

## How to apply
- **Don't pick a winner — map the layers.** When a new authoritative artifact overlaps an existing one, list what each governs. Default to *layered authority* (each canonical for its layer), and reconcile only the axes where they genuinely conflict.
- **Tiebreaker on a real conflict = shipped reality, not the newer/prettier doc.** Grep the product. The doc that matches what ships wins; the other doc is the migration debt, not the source of truth.
- **Verify a documented decision actually shipped before citing the doc as canon.** A doc can faithfully describe a decision that never landed. Check the running code (usage greps, semantic-token wiring, "was this tagged-but-not-applied"). A documented-but-unshipped decision is *canon rot* — it makes your canon contradict both its authority and its product, silently, for as long as no one re-checks.
- **A layer-jumping unilateral decision is the failure mode.** The accent swap was a *brand* decision made unilaterally inside the *product* canon with no brand mandate — so it satisfied no one and shipped nowhere. Route such decisions back to the owning layer (e.g. a brand RFC), don't entrench the divergence by "fixing" the product to match.

## Disposition
Complements [[grounded-is-not-validated]]: that lesson says carry a premise's *status* (DRAFT/REVIEWED/RATIFIED) because `[Observed:]` proves fidelity, not finality. This adds the next link — even a *ratified-looking* documented decision may be **unshipped**, so shipped reality (code/product) is the final arbiter when docs disagree.
