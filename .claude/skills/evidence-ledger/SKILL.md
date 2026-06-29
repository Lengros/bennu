---
name: evidence-ledger
description: Maintain a living evidence ledger for a product bet — a portfolio of risky assumptions, each with a pre-registered success/kill threshold, an experiment matched to the exact question it can answer, the observed signal with provenance, and a forced kill/pivot/double-down decision. Use when validating a product idea, sequencing discovery experiments, deciding what to test next, or recording what an experiment actually proved. The discovery-mode counterpart to /reframe: reframe sharpens ONE task into falsifiable acceptance criteria; evidence-ledger manages the whole campaign of assumptions over time. Russian triggers: "проверить ценность", "какие гипотезы тестировать", "что докажет этот эксперимент", "kill или pivot", "собери evidence ledger", "что мы реально знаем про эту ставку".
---

# /evidence-ledger — living portfolio of risky assumptions

Maintains one artifact that tracks every load-bearing assumption a product bet depends on,
in test order, with a **threshold pre-registered before the data is seen** and a forced
decision after. It does **not** run the experiments. It keeps you honest about what each
experiment can prove and stops you moving the goalposts once results arrive.

The engine, repeated at every stage: **a believable surface is now free to produce, so the
only thing that separates a real bet from a pretty one is a falsifiable threshold set in
advance and a signal with something at stake.** Curiosity is not commitment; an AI summary
is not a finding; a threshold chosen after the data is rationalization.

Argument (optional): the bet/outcome, or a path to an existing ledger to update. If absent,
use the bet under discussion in context.

Relationship to `/reframe`: `/reframe` regresses one request to a falsifiable outcome (the
INTENT stage). `/evidence-ledger` sits one level up — it holds the set of assumptions behind
a bet and sequences the experiments. A single assumption's experiment can itself be run
through `/reframe`. Use reframe for "what does *this task* have to achieve"; use
evidence-ledger for "what do we actually know about *this bet*, and what do we test next."

---

## How to run

Work the seven stages in order. Append to the ledger artifact (§Schema); never rewrite a
pre-registered threshold after a signal lands — supersede the row and keep the original.

1. **Frame the bet** — one line: the outcome the whole ledger serves (a result in the
   world, not a feature). May be lifted from a prior `/reframe` `outcome`.

2. **List load-bearing assumptions** — everything that must be true for the bet to pay off.
   State each so it *can be wrong* ("tutors will write up every lesson the day it happens"),
   not as a goal ("great onboarding"). Surface the assumptions that would *kill the bet* if
   false, not the convenient ones you already believe.

3. **Rank by risk** — `risk = (damage if wrong) × (how unknown)`. The riskiest-and-least-
   known assumption is tested first. Most-uncertain-most-fatal beats easy-and-comforting.
   This ordering *is* the discovery plan.

4. **Match the experiment to the question** — see the matching table below. Interest ≠
   willingness-to-pay ≠ can-we-deliver ≠ retention. Pick the cheapest experiment that can
   actually answer *this* assumption's question, and write down what it can and **cannot**
   conclude. Reject any experiment/question mismatch on the spot.

5. **Pre-register the threshold** — *before running*, write the number that means pass and
   the number that means kill, plus the sample/significance condition that makes the result
   readable ("≥ N in segment, do not read before significance"). Pass and kill must be the
   **same measure** and cover the whole range — no unverdicted gap; any deliberate middle
   band must be named as an explicit third verdict (a **pivot**), never left blank. This is
   the anti-self-deception lock. If you cannot name a threshold in advance, the experiment is
   theater — redesign it until you can.

6. **Record the signal** — the experiment runs outside this skill. Record the observed
   result with provenance (`N`, the real artifact, the date) and its **commitment
   strength** (see ladder below). A `[PENDING]` row is fine; an untagged signal is not.

7. **Force the decision** — put the signal next to the pre-registered threshold and call it:
   **kill** / **pivot** / **double-down**. No "let's keep watching." If the signal is below
   the kill line, the row is killed even if you still like the idea — that is the whole point
   of pre-registering.

---

## Experiment → question matching

| Experiment | The one question it answers | What it CANNOT conclude |
|---|---|---|
| **error-analysis** (read 50–100 real traces, code failure modes) | *Where does quality actually fail, and how often?* | nothing about demand or price; it is about a thing that already runs |
| **interview** (continuous-discovery, their words) | *Does this pain exist, and in what shape?* | demand size, WTP — a theme is a hypothesis, not a finding |
| **fake-door** (labeled CTA → interstitial + email capture) | *Is there interest in this specific trigger?* | willingness to pay; a click is "curious," not "will buy" |
| **concierge** (deliver value manually, charge, log every step) | *Can we deliver it, what breaks, do they come back?* | scalability; it is deliberately unscaled |
| **Wizard-of-Oz** (real front end, manual fulfilment behind it) | *Does the end-to-end flow complete, do they return?* | unit economics at scale |
| **dry-wallet** (real Stripe checkout / refundable charge / booking) | *Will they actually pay / commit?* | long-term retention — commitment ≠ habit |

**Error-analysis is yours and undelegable.** For an AI-feature bet, the "experiment" for a
quality assumption is *you* reading the real traces and naming the failure modes — not a
generic metric and not an agent's summary. The ledger holds the ranked failure modes; an
agent may cluster and pivot them, never replace your read.

## Commitment-strength ladder (weak → strong signal)

`stated-WTP survey  <  click  <  email capture  <  booking / time spent  <  money on the line`

Prefer the strongest signal the question allows. With AI making a believable surface free,
re-adding real cost (a payment gate, a booking, manual delivery the user must wait for) is
how you buy a signal that means commitment instead of curiosity.

---

## Schema (the living ledger artifact)

```markdown
# Evidence Ledger — <bet name>

**Bet:** <one-line outcome the whole ledger serves>
**Updated:** <date>

| id | assumption (stated so it can be wrong) | risk = damage × unknown | experiment | threshold (PRE-REGISTERED) | signal | decision |
|----|----------------------------------------|-------------------------|------------|----------------------------|--------|----------|
| A-1 | <belief the bet depends on> | <high/med/low + why> | <type from matching table> | pass ≥ X / kill < Y; read at N, after significance | [PENDING] or <result> [Observed: N, artifact, date] (commitment: <ladder rung>) | kill / pivot / double-down / [open] |
```

Rules baked into the shape:
- One row per assumption; ranked top-to-bottom by risk (test order).
- `threshold` is written at creation and **never edited after a signal** — supersede with a
  new row, keep the original, so the goalpost move is visible.
- `signal` carries `[Observed: …]` provenance and a commitment rung, or it is `[ASSUMPTION]`.
- AI-surfaced themes enter as **new assumption rows** to test, never as a `signal`.

---

## Discipline (the parts that make it work, not decoration)

- **Pre-register or it's theater.** The threshold set after seeing the data is the most
  common form of product self-deception. The lock is writing pass/kill *before* running.
- **Match experiment to question.** A fake-door click means "curious." Read it as demand and
  you ship a thing nobody pays for. Name the can't-conclude every time.
- **Re-add real cost.** Free believable surfaces inflate every signal. Push each assumption
  down the commitment ladder toward money/booking/manual delivery wherever the question
  allows.
- **AI is augmentation, the human owns the tree.** Summaries lose 20–40% of detail; an
  AI-surfaced theme is a hypothesis to test live, never a finding. Validate the transcript
  before you build the branch.
- **Forced decision beats a watchlist.** "Keep watching" is how dead bets survive. Below the
  kill line is killed.
- **Do not build:** synthetic-user "signal," generic off-the-shelf metric dashboards as
  evidence, or a would-you-pay survey standing in for a payment gate. They manufacture
  confidence that correlates with nothing.

---

## Reference example

**Bet:** independent tutors will pay for a tool that auto-writes their post-lesson parent
summaries instead of typing them by hand after every session.

| id | assumption | risk | experiment | threshold (pre-registered) | signal | decision |
|----|------------|------|------------|----------------------------|--------|----------|
| A-1 | Tutors will pay a monthly subscription to automate parent summaries rather than keep typing them free after each lesson | **high** — if false, the whole paid-product bet dies; and we don't know it | dry-wallet: self-serve "start automating" page that takes a real (refundable) $15 first-month charge | pass ≥ 4 of first 15 / kill < 4 of first 15 targeted tutors complete the charge; read only after all 15. **Can't conclude:** a sub-threshold result can't separate "won't pay" from "won't self-serve" — below kill, open an assisted-onboarding row before killing the bet | [PENDING] | [open] |
| A-2 | The auto-written summaries are accurate enough to send to a parent unattended | **high** — a wrong summary about a child burns trust irrecoverably | error-analysis: read 80 real generated summaries, code every mismatch into failure modes, rank by frequency | same measure = top failure mode's rate over 80 summaries: pass ≤ 5% / pivot 5–15% (narrow unattended scope, retest) / kill > 15%; read only after all 80 are coded | [PENDING] | [open] |
| A-3 | There's interest in "auto-write my parent summaries" at all | med — cheap to learn, lowest fatality | fake-door: labeled CTA on the dashboard → interstitial + email capture | pass ≥ 8% / kill < 3% click→capture in the tutor segment; read only after ≥ 200 segment impressions — **note: this proves curiosity, not WTP; A-1 is the real money test** | [PENDING] | [open] |

A-1 is tested first (most fatal × least known). A-3's threshold explicitly records that a
click cannot conclude payment — the money question lives in A-1. No row's threshold may be
edited once its signal lands.
