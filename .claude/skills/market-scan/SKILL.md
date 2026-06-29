---
name: market-scan
description: Scan the public market for evidence on a product hypothesis — competitors and their pricing/coverage (supply lens) and what real users say about the pain in forums, app reviews, FB groups, YouTube/Reddit (demand lens). Spawns a fresh research subagent from a fixed brief template + source playbook, codes findings into ranked failure modes, and returns an artifact that drops into /evidence-ledger as signal rows. Use when you need to test "does a solution already exist", "is this an acute would-pay pain", "what do users of competitor X complain about", or to gather demand/supply signal before building. The discovery-research companion to /evidence-ledger. NOT a substitute for interviews or a willingness-to-pay test. Russian triggers: "просканируй рынок", "что говорят пользователи", "найди конкурентов и отзывы", "есть ли уже решение", "собери сигнал по гипотезе", "голос пользователя", "voice of customer".
---

# /market-scan — hypothesis → coded market signal

Takes a product hypothesis and sweeps public sources for evidence, then returns coded,
ranked, source-tagged signal. It does **not** run the experiment or make the decision — it
gathers found text. The orchestrator fills the brief template below and **delegates to a
fresh research subagent** (the "researcher" — it gets web tools and no drafting context).

The engine, repeated at every stage: **found public text is hypothesis-SHAPING, never
validating. It cannot conclude willingness-to-pay; only a dry-wallet / fake-door test or
real interviews can. Absence of signal is itself a finding. A vendor's marketing, a firm's
voice, and a homeowner's complaint are not your target user's voice.**

Pairs with `/evidence-ledger`: market-scan **produces** signal → the ledger records it as a
`signal` row and **decides** (kill/pivot/double-down) only with a behavioural test.
Different from `/deep-research` (fan-out + adversarial fact-check → cited report):
market-scan adds the two-lens frame (§2), error-analysis *coding* of voices into ranked
failure modes (§4), and discovery honesty (found-text ≠ WTP, absence-as-finding,
selection-bias) — disciplines `/deep-research` has no reason to carry.

Argument (optional): the hypothesis in any convenient form (a sentence, bullets). If absent,
use the bet under discussion.

---

## 1. Intake — normalize the loose ask
Pull these from the input; fill gaps with stated defaults, don't block on them:
- **Hypothesis / premise** — what we believe and want to confirm or kill.
- **Product & segment** — and *precisely* who the target user is (e.g. "SOLO/micro plumber",
  not "trades").
- **Geo + language** — search language(s); name them (the scan reads in that language).
- **Lens** — `supply`, `demand`, or `both` (§2).
- **Feeds which `/evidence-ledger` assumption** — name the row(s) it informs.
- **Seeds** — any known competitors / sources to start from.

## 2. The two lenses (one playbook)
- **Supply** — what solutions/competitors exist, their coverage of the job(s), pricing, and
  geo/language fit. Answers: *is the "no convenient solution" premise true?* Beware: a tool
  *existing* ≠ the target *adopting it conveniently* — say which you've shown.
- **Demand** — what real target users say about the pain in their own words. Answers: *is
  this an acute, would-pay pain? Is there integration pain across current tools?*

## 3. Source playbook (what to pull from each)
- **Google / search aggregators** — entry points, "best X for Y", comparison posts.
- **Competitor sites + pricing pages** — coverage, price tiers, who they target (solo vs firm).
- **App reviews** — Google Play, App Store, Capterra, G2 — *why users adopted / churned / what's missing*. Highest-signal demand source after interviews.
- **Vertical forums** — peer-to-peer pain talk in the segment's own words.
- **Facebook groups** — often the richest peer vein, but usually **login-walled** → flag as inaccessible, don't fake it.
- **Reddit / YouTube vlog comments** — "day in the life" narration of real pain.
- **Marketplaces / lead-gen sites** — distinguish *lead-gen language* ("free slots!") from *pain* — they are not the same.

## 4. Method — error-analysis coding (the rigor)
1. Collect real quotes (original language **and** translation).
2. **Open-code** each fragment into a short failure-mode label.
3. **Axial-code** — group labels into named failure modes.
4. **Rank** — demand: by # distinct target voices per mode; supply: by coverage of the target
   job at the target price point. Tag each mode/assumption with an evidence-strength rung:
   **strong / moderate / weak / absent**.
5. **Stop at saturation** — when new sources stop surfacing new modes; **state the
   source/search count** at which it saturated.
A lens or job that surfaced **zero** target-voice fragments is recorded as an explicit
`absent` row, never omitted.
Throughout: attribute every voice — only the target segment counts as demand signal. A
non-target voice (firm/homeowner/vendor) is context — **except** when it runs *counter* to
the premise (e.g. an adjacent group documenting against your target user): that direction is a finding,
not noise — report it.

## 5. Delegation brief template (fill and send to a fresh subagent)
```
You are a [supply scanner | qualitative VoC researcher] doing a public-source scan of the
[GEO] market in [LANGUAGE]. Use WebSearch/WebFetch (load via ToolSearch:
"select:WebSearch,WebFetch"); search in [LANGUAGE].

WHO (exact target): [precise solo/segment definition — NOT the broad category].
HYPOTHESIS / JOB(S): [the premise + the specific job(s) to probe].
WHY: this feeds assumption [A-n] in a product evidence-ledger. Confirm or KILL it. Be
adversarial toward the founder's premise. [State what a kill looks like.]
WHERE: [the §3 playbook, narrowed to this hypothesis — name concrete competitors/forums to seed].
METHOD: [§4 coding — quotes (orig+translation) → open-code → failure modes → rank + strength rung → stop at saturation and **state the saturation count**].
DELIVERABLE: [the §6 output contract — incl. a per-assumption directional read with evidence strength + a confidence %].
HONESTY (mandatory): found text is hypothesis-shaping, not validating; cannot conclude WTP;
absence of signal is a finding (report it as an explicit `absent` read); state the
**selection-bias direction** for THIS segment (which voices found text over- vs
under-represents); a non-target voice running counter to the premise is a finding;
distinguish target voice from firm/homeowner/vendor; REPORT any source you could not read
(login walls, timeouts) — absence ≠ true absence; tag every claim with a source URL; flag
inference vs citation.
```
Run it as a **background** subagent (these take minutes); drop results into the ledger when
it returns.

## 6. Output contract (the artifact the subagent returns)
1. **Ranked findings** — failure-mode table (demand) or tool-inventory table (supply): item ·
   job · # voices / coverage · representative translated quote(s) · source URL. State the
   **saturation count**. For the supply lens, follow the table with a one-paragraph
   **coverage verdict** — which job(s) are solved, at what price, for the target segment, and
   which job is the weak link.
2. **Per-assumption read** — directional answer for each ledger row it feeds, with explicit
   **evidence strength** (strong / moderate / weak / absent) and a **confidence %**. Every
   assumption the scan found **no** signal on must appear with strength **absent** and a
   one-line note on whether that's true absence or a measurement gap. Flag any off-target
   voice whose direction **contradicts** the hypothesis.
3. **Selection-bias caveat** — found text over-represents complainers/vendors and
   under-represents the silent-satisfied; say plainly what it can and cannot conclude.
4. **Inaccessible-sources report** — what was login-walled / timed out, and which reads rest
   on weaker channels as a result.
5. **Sources** — deduplicated URLs.
The artifact lands in the **target product's docs dir** (e.g. `docs/0N_<NAME>.md`), not in
Bennu.

## 7. Honesty discipline (non-negotiable)
- Hypothesis-shaping, **never validating** — the ledger still needs a behavioural test.
- **Cannot conclude WTP.** Stated interest, clicks, and forum enthusiasm are not money.
- **Absence of signal is a finding** — report it; don't pad to look thorough.
- **No synthetic users** as a substitute for real found/voiced signal.
- **Voice attribution** — the target segment's words only; everything else is context.
- **Report what you couldn't read** — a walled FB group is a measurement gap, not proof of
  absence.

## 8. Handoff to /evidence-ledger
Scan results become `signal` rows with `[Observed: <artifact>, <strength>, <date>]` — never a
`decision`. AI-surfaced themes enter as **new assumption rows to test**, not as findings.

---

## Worked examples (this skill's calibration)
Illustrative pair for a bet like a tutor parent-summary tool — the skill's two lenses in action:
- **Supply lens** → `docs/market-scan.md` (competitor/coverage scan; if rival tools already
  cover the job at the target price, it falsifies the literal "no solution" premise and feeds
  the corresponding ledger assumption).
- **Demand lens** → `docs/voice-of-customer.md` (failure-mode coding of real user voices;
  ranks which pains are acute and which expected pain is absent, feeding the demand assumptions).
Each shows the output shape and honesty reporting this skill expects.
