---
name: reframe
description: Turn a request into a verifiable problem statement before any work starts. Treats the literal ask as a proposed solution (output) and regresses it to the real result the user wants (outcome), then makes that outcome falsifiable. Use when a request arrives as an already-chosen action ("congratulate a teammate", "build a dashboard", "add a button", "send a reminder"), when the true goal is fuzzy, or when you want an intent spec a fresh executor could pick up cold. Russian triggers: "переосмысли задачу", "что на самом деле нужно", "собери ТЗ", "outcome не output", "разбери задачу до корня".
---

# /reframe — output → outcome problem framer

Produces one structured artifact that converts a request into a verifiable problem
statement. It does **not** do the work. It specifies what the work must achieve so it can
be checked, delegated, or argued about before a single hour is spent executing.

The engine, repeated at every stage: **the request is an output (a chosen action). The task
is the outcome behind it (an observable change in the world).** Never execute the output
until the outcome is named and made falsifiable.

Argument (optional): the raw request. If absent, use the most recent user ask in context.

---

## How to run

Work the stages in order. Each feeds the next. Output the YAML-style artifact in
§Schema. Most stages are 1–3 sentences — resist padding; one idea per line. One stage
(Validate direction) is an interactive checkpoint — it can hand control back to the user
mid-pass.

1. **Capture** — record the request verbatim in `original_request`. Do not improve it.

2. **Root cause (5 Whys)** — `root_cause`. Name what the request *is* ("congratulate" is an output — a
   chosen action), then ask why until you hit the driver — the change the user actually
   wants in the world. Stop when the next "why" would leave this person's actual situation.
   Tag the driver: `[Observed: …]` if the conversation supplies it, `[ASSUMPTION]` if you
   inferred it. An untagged root cause is a defect.

3. **Validate direction (interactive, fires on a fork)** — before spending criteria on the
   root cause, enumerate the *candidate readings* of it. Then:
   - If two or more readings lead to **materially different acceptance criteria** → this is
     a fork. **Stop and ask the user.** Surface your lead hypothesis first (marked), 1–3
     genuine alternatives, and "or your own". Use the platform's multiple-choice question
     prompt so the user picks rather than free-types. Iterate up to ~2 rounds — each round
     narrows from the user's answer — until they confirm or correct the direction. Converge
     in one round when the lead hypothesis is confirmed.
   - If only one reading survives → proceed, but record the alternatives you considered and
     rejected so the user can object, and keep the `[ASSUMPTION]` tag.
   **Bias: when unsure whether a fork is material, treat it as material and ask.** Divining
   the wrong root cause produces confident, precisely-wrong ACs — the exact failure this
   skill exists to prevent. Skip this stage only when the user has already pinned the
   outcome explicitly in the conversation. Record the settled direction in `validated`.

4. **Outcome (JTBD)** — `outcome` as three lines:
   - `when:` the situation/trigger that makes this needed (job context, not "always")
   - `need:` the observable end state the user wants (a result, not an action)
   - `so_that:` the larger payoff that result unlocks
   This is the Jobs-To-Be-Done frame; keep that shape exactly.

5. **Acceptance criteria** — `acceptance_criteria`, the heart of the artifact. Each AC has:
   - `subject` — what is being judged
   - `state` — the condition it must be in (concrete, not "good")
   - `measure` — the **objective check** that settles it (a grep, a parse, an observed
     reaction, "opened on phone → visible"). If you can't name a check, the AC is not done.
   - `boundary` — scope/coverage the check applies over
   **Hard rule: zero subjective criteria.** No "beautiful", "heartfelt", "clean". If it
   can't be falsified, cut it or rewrite it until it can. Aim for 3–7.

6. **Invariants** — `invariants`. What must stay true regardless of solution — the guard
   rails ("doesn't create a new gap", "doesn't spend trust on fake metrics"). These bound
   the solution space; they are not acceptance criteria.

7. **Solution + cuts** — `solution` is the *minimal critical chain* that delivers the
   outcome, named in one line (what it is and, sharper, what it is **not**). `out_of_scope`
   lists what you deliberately drop and why ("the cake is an output", "cut 90% of the scaffolding").
   Cutting is signal, not laziness — make the cuts explicit.

8. **Delta** — `delta`. State plainly how the understood task differs from the original
   request: what was output, what became outcome, what got newly verifiable. If the delta
   is empty, the pass did nothing — push the root cause harder.

---

## Schema (output shape)

```yaml
original_request: >
  <the literal ask, verbatim>

root_cause: >
  <"<ask>" is an output. Behind it: <the driver>. The real want = <one sentence>.
   [Observed: …] or [ASSUMPTION]>

validated: >
  <only if a fork fired: the readings you offered, and the direction the user confirmed
   or corrected — in their words. "n/a — single reading, [ASSUMPTION] carried" if no fork.>

outcome:
  when: >
    <situation/trigger that makes this needed>
  need: >
    <observable end state — a result, not an action>
  so_that: >
    <the larger payoff>

acceptance_criteria:
  - id: AC-1
    subject: <what is judged>
    state: <concrete condition it must be in>
    measure: <objective check that settles it>
    boundary: <scope the check covers>
  # ... 3–7 total, every one falsifiable

invariants:
  - <must stay true regardless of solution>

solution: >
  <minimal critical chain — what it is, and what it is NOT>

out_of_scope:
  - <deliberately dropped + why>

delta: >
  <output → outcome: what changed in understanding, what became verifiable>
```

---

## Discipline (the parts that make it work, not decoration)

- **Distrust the formulation.** The user almost always brings a pre-chosen solution. Your
  job is to regress to the result before executing. Obedience to the literal ask is the
  failure mode this skill exists to prevent.
- **Validate, don't divine.** The root cause is a hypothesis until either the conversation
  grounds it or the user confirms it. When candidate readings split into different ACs,
  present them as a choice and let the user steer the vector — don't build a second guess on
  top of the first. This is *not* a license to ask trivia: a single surviving reading
  proceeds (tagged `[ASSUMPTION]`, alternatives noted), and the fork resolves in one round
  when the lead hypothesis is confirmed. Ask where the answer changes the criteria, decide
  where it only changes the wording.
- **Falsifiability is the test of a good AC.** A criterion with no `measure` is a wish.
- **Cut hard, cut explicitly.** A short `out_of_scope` is a weak pass — most of a request
  is usually scaffolding around one critical thing.
- **Speak the team's language.** If the conversation has a shared vocabulary of metaphors
  (e.g. a shared metaphor the team already uses), use it — the artifact is read
  by people who think in those terms.
- **This is a thinking pass, not a deliverable.** The artifact is the spec; the work comes
  after, against these criteria. In Bennu terms it is a formalized INTENT stage — hand its
  ACs to CAST/EXECUTE, verify against them in SKEPTIC.

---

## Reference example

A "congratulate a colleague on their birthday" request, run through the pipeline, regresses
to: the outcome is not the act of congratulating (output) but the colleague *feeling they
changed the system* (outcome) — and every AC becomes checkable (grep for clichés → 0; names
≥1 concrete thing they actually changed; opens on phone without auth; draws a reply-reaction
same day). The shape above reproduces this worked example.
