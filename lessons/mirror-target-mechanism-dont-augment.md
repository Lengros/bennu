# Mirror a Target Mechanism Faithfully — Don't Augment It

date: 2026-06-19
scope: delegation
rule: "Make X like Y" is a fidelity constraint: copy Y's fields and affordances; don't surface extra data-model fields or keep controls Y dropped.

## Why
The user asked to rework one record editor to use "the same mechanism as" an existing editor elsewhere in the app. In my build brief I told the executor to mirror the target's inline ghost-row editor **but to add two fields the target never showed** — a "set as default" toggle and an optional label. Neither belonged:
- The target flow has **no** "set as default" control in the editor — it promotes the default via a hover action in the list. I kept a toggle the target pattern had already replaced.
- The label is a latent field on the data model that the original editor **never surfaced**. I rendered it as UI just because the data model had it; the title should simply be the canonical name.

The user caught both, asking why I'd surfaced a field the target never showed. I had read "same mechanism" as license to improve. Cost: a third rework round for what should have been a faithful copy.

## How to apply
- Read "make X work like Y" / "same mechanism as Z" as **fidelity, not invitation**. Derive the field set and affordances from the target (and the thing being replaced), not from what the data model *could* support.
- A field existing in the data model/API is **not** a reason to render it. Surface only what the target pattern shows.
- When the target **replaced** a control with a different interaction (checkbox → hover action), carry the replacement — don't keep both.
- Before writing a mirror/port brief, list the target's exact fields and affordances as the spec. Any addition you're tempted to make is a proposal — flag it to the user, don't fold it in silently.

## Disposition
Reinforces ported feedback "PRD scope discipline — one feature per PRD" and the [[design-defaults-to-the-house-attractor]] pattern (the model embellishes toward a fuller-looking default). Extends [[requirements-target-production-not-prototype]] (the target is the spec) and [[grounded-is-not-validated]] (a field's existence is fidelity to a data model, not evidence it's wanted in the UI).
