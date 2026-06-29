# Casting — pick the persona, write the brief

Before any delegated (or embodied) execution, construct the executor context. Four steps:
**REASON → CHECK `personas/` → SYNTHESIZE → BRIEF.**

## 1. REASON — what THIS task needs

Define, for the subtask in front of you:

- **Deliverable** — the artifact, stated as an outcome.
- **Critical competencies** (2–4) — what the executor must actually be good at.
- **Working mode** — research | generation | critique | optimization | synthesis.
- **Cognitive approach** — audit existing | build new | refactor | extend.
- **Security surface.** If the task touches enforcement gates, input validation, auth,
  command execution, hook infrastructure, or any cross-boundary trust — mark it
  **security-relevant**, and adversarial scenarios in the brief are **mandatory**, not
  optional happy-path checks.

## 2. CHECK `personas/`

Scan existing persona cards for a match on competency, mode, and approach. A match lets
you inherit its `required_context` and `avoid_for` guardrails. No match is the normal
path, not an exception — proceed to synthesize. "No matching persona" is never a reason to
embody work that should be delegated, and never a reason to skip the brief.

**Record provenance.** When a card matched, or seeded a synthesized persona, pass its slug
to `log-run.sh --from-card <slug>[,<slug>]` at SHIP. The run's free-text `--personas`
label is not evidence a card was used (it rarely matches the filename); `from_card` is the
only reuse signal `/retro` can see, and a card that never shows up there reads as dead
weight. No card involved → omit the flag.

## 3. SYNTHESIZE

Construct a custom persona card from the competencies in step 1. Save it to `personas/`
**only if it is reusable** — a one-off framing stays in the brief and is not persisted.

**Trust-sensitive work:** for trust / consent / permission surfaces where user anxiety is
the primary constraint, synthesize a user-advocate persona (emotional-journey mapping,
trust-signal strategy, psychology-grounded anti-patterns). Writing such briefs from a
generic persona produces flat results — validated both ways in one session.

## 4. BRIEF — WHAT + WHY, never HOW

The brief carries: **goal + DoD + constraints + persona card + recon excerpts.** Thin —
do not duplicate what is already on disk; point at it. State WHAT to produce and WHY it
matters; never prescribe HOW (no component trees, layouts, palettes, class names,
methodology). If you want to control the HOW, draw it inline yourself, then hand off the
artifact.

- **Recon as Observed excerpts.** Embed your reconnaissance as `Observed: <path>:<lines>`
  claims in the brief; the executor spot-checks ≥3 rather than cold-re-reading everything.
- **Evidence rule (both modes).** Every claim about existing code or docs carries an
  `Observed: <path>:<lines>` tag or an `ASSUMPTION` tag. Untagged claims about current
  files are a defect.

### Execution-order rules for structured-output briefs

- **Hero frame + execution order.** A design or multi-frame brief completes **one hero
  frame before the others**, with an explicit execution order (atoms → hero → rest), zero
  open design-domain questions, and ≤3 frames per run. Custom elements appearing in
  multiple frames are listed once in `components_to_define` and specced canonically before
  any frame is composed — defined once, reused without re-derivation.
- **Document/review order.** When the brief is a review pass, order it persona test →
  structural fixes → editor polish → coherence pass. Never the reverse: structural changes
  invalidate any polish done before them.

### Reference-implementation rule

Before delegating a **visual fix**: diagnose the root cause, identify a **working
reference**, and include its **file path + line range + explicit prop values** in the
brief. "Match the standard style" briefs produce `!important` hacks. If you cannot diagnose
the cause, delegate the investigation as a **separate step first** — do not ship a blind
fix brief.
