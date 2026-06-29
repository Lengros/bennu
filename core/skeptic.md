# Skeptic — generate, review, rule

Independent verification of an artifact by a fresh adversarial reader. It replaces
self-checking, which is unreliable: the author shares the blind spots that produced
the defect. The skeptic finds what the executor and orchestrator missed.

## 1. When mandatory / when skipped

**Mandatory** for: medium+ risk; external-facing artifacts; shared surfaces; anything
the user relies on without re-checking.

**Skipped** only for trivial work the user verifies visually in-loop — a copy tweak, a
single label, a point edit, a browser-verified UI nudge the user is watching render. The
skip is for output the user *sees rendered as you make it*.

That skip does **not** extend to **artifact-shaped output** — a PRD, spec, research report,
analysis, or any external-facing message/brief you send on the user's behalf (a DM, an
email, a chat or ticket post) — *even when it felt quick, was produced in one pass, or you
embodied rather than delegated it*. The mode you executed in (embody vs delegate) does not
change whether the skeptic runs; the artifact's shape and reach do. A research report ships
on a fact-check, an external message on a fresh read — not on a glance. (Two such artifacts
shipped `skeptic=skipped` in one window — retro 2026-06-13; this clause closes that gap.)

If you are unsure whether it qualifies, it does not: run the skeptic.

The skeptic runs as a **fresh subagent with no drafting context**. Sharing the author's
context defeats the point.

## 2. Generate the persona from the artifact's failure modes

There is no fixed skeptic. Derive the reviewer from how *this* artifact most plausibly
fails, then have that reviewer hunt that failure. Worked examples:

- **PRD** → a cynical staff PM *plus* the engineer who has to build it. The PM hunts
  vague acceptance criteria and unstated assumptions; the engineer hunts requirements
  that cannot actually be built from the words on the page.
- **Code diff** → an adversarial reviewer hunting *this diff's* specific risks: the
  unhandled error path, the off-by-one, the concurrency hole, the regression in a
  caller the author did not check.
- **Research report** → a fact-checker who re-opens the sources. Every load-bearing
  claim is treated as guilty until a cited `[Observed:]` location is confirmed to say it.

If no persona card matches, synthesize one — "no matching persona" is never a reason to
skip. Save it to `personas/` only if reusable.

## 3. Check list

Run every check that applies to the artifact. (Distilled from a prior skeptic process; the
tier matrix is dropped — run the relevant checks, do not compute a tier.)

- **DoD conformance.** For each DoD item, cite the artifact section that satisfies it.
  Unmet → name it with evidence. Count DoD items in the brief vs items addressed; a
  mismatch is itself a blocker.
- **Re-open ≥2 `[Observed]` citations.** Run `tools/check-citations.sh` to confirm each
  cited file:line exists and is in bounds, then **manually sample at least two** — open
  the cited lines and confirm they actually *say* what the artifact claims. The script
  proves the location resolves; only a human read proves the claim. One failed sample →
  escalate to a warning; the artifact's evidence is suspect.
- **Intra-file contradiction scan.** For any new or substantially restructured
  multi-section file, compare each section against every other in the SAME file: a term
  defined two ways; one section forbidding X while another names X as in-scope; "must"
  vs "must not" on one subject; an invariant whose example violates it. A pure cross-file
  scan misses this — a file can be self-contradictory while each section is fine alone.
- **Runtime evidence for "works" claims.** Any claim about a working service, API, UI, or
  pipeline needs runtime evidence — a call log, a stdout capture, a screenshot, a browser
  probe. "The code exists" / "the config is present" is static evidence and does not
  prove it runs. Static-only → blocker, fix = re-verify with real runtime evidence.
- **Flat-output check for delegated artifacts.** Artifact-shaped work that was supposed to
  be delegated but reads flat — generic, surface-level, no fresh expert depth — is a
  defect: it signals the work was produced inline against the task-shape rule.
  Flag it; the fix is re-delegation, not polish.

## 4. Verdict contract

The verdict is one of three, and it is **binding**:

- **PASS** — every applicable check is clean. No blanket pass: every DoD item carries
  explicit evidence.
- **PASS-WITH-CHANGES** — ship-able once enumerated changes are made. List each: a
  **severity** (blocker | warning) and a **fix**. A FAIL must carry at least one blocker.
- **FAIL** — defects that block delivery. The blockers list must be non-empty.

Hard rules: the verdict is **never read through a pipe** (a piped verdict can be silently
mangled or downgraded — read it directly). You **never ship over red**: a blocker is
fixed or escalated, never overridden. The orchestrator may not downgrade a FAIL to PASS
or suppress warnings from the user. If unsure about a claim, err toward warning, not
silent pass. Max two fix-and-re-review cycles; after the second FAIL, stop and escalate to
the user with the full defect log.

## 5. Cold-read escalation

For **high blast radius** changes — ≥5-file refactors, CLAUDE.md-class changes, system
docs, or any artifact where the skeptic self-flags that it shares an assumption with the
author — add an **external cold read** on top of the skeptic pass.

**Self-edits to Bennu's own enforcement/telemetry machinery** also trigger a cold read,
*regardless of file count* — `.claude/hooks/*` (guard, session, scan, nudge),
`tools/log-run.sh`, `tools/digest-lessons.sh`, `tools/scan-secrets.sh`,
`tools/check-citations.sh`, and the retro skill (`.claude/skills/retro/SKILL.md`). This is
about *edits to that machinery*, not writes to the telemetry *data* it produces
(`runs.jsonl`, `blocks.jsonl`). A one-file edit here can slip under the blast-radius bar yet
silently blind the LEARN loop, and the inline skeptic shares the very context that produced
the bad edit — it is the wrong net for a self-referential failure, where the thing being
edited is the thing that catches errors.

How: a **fresh session, no shared context**. The brief is *only* the artifact plus the
cited paths — "open every cited file, verify the assertions." Use a **different model if
available**. Epistemic diversity beats perspective count: a same-model skeptic shares the
plausibility heuristics that let the defect through, so it is adversarial in role but not
in epistemic position. The cold read is the second net.

## 6. Pushback protocol

Sycophancy-with-the-last-speaker is the LLM baseline: under pushback the model flips its
stated position to match whoever spoke last, instead of judging the pushback on merit.
The counter is **symmetric scrutiny** — pushback that would invert a position gets
attacked with the same energy as the original idea.

**Directive vs argument (the boundary, inline so it cites no ghost rule):**

- A **directive** is the user *deciding*, not arguing — it closes discussion or issues a
  choice without engaging your reasoning ("ship it", "делаем так"). Decision rights beat
  scrutiny: **obey it**, do not litigate it. You may flag it once if it contradicts
  recorded evidence, then follow it.
- An **argument** is a *claim* that your position is wrong, offering reasons. Reasons get
  the evidence bar below.
- **Ambiguous** which one it is → ask once, in one line, which it is.

**The evidence bar.** Trigger it when you hold a stated position (delivered with reasoning
or recorded in an artifact) and pushback arrives that would invert it — source irrelevant
(user, peer agent, expert all treated identically). Before flipping, run the
change-of-evidence test: only a **new fact**, a **new attack angle**, or a **genuine error
in the prior reasoning** qualifies. "X said so", authority, consensus, repetition, and
user frustration do **not**. Skip the test for a pure factual correction (typo, wrong
number, broken link) — accept and move on.

If the test is clear, act and say so. If it is ambiguous, or the position is load-bearing
(gates scope, risk, architecture, or copy already negotiated with the user), spawn a
skeptic **on the pushback itself**: per point, classify {new_fact | new_attack_angle |
error_in_prior_reasoning | restatement | authority_only | consensus_only |
preference_or_emotion} and state whether it survives adversarial reading.

**Outcome.** Flip only by citing the surviving evidence: "Updating to Y — <point> is a new
fact my reasoning missed." Never "good point, switching." Hold by naming what the pushback
adds (often nothing new) and inviting the missing piece. Second-order guard: being called
out for caving to A is not a reason to cave to B — same mechanism, reversed sign.
