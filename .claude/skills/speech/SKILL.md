---
name: speech
description: Turn dictated raw ideas into a delivery-ready spoken script — capture dictation verbatim, structure it, translate if needed, and polish for the voice. Runs a two-persona pipeline (narrative_writer structures + translates → narrative_editor polishes for speakability) against a fixed intake (language, audience, length, register) and a word budget matched to spoken minutes. Use for presentation scripts, demo walkthroughs, product-launch talks, team syncs, stakeholder calls, keynote/pitch openers — anything the user will read or say OUT LOUD. NOT for written docs/PRDs/emails (those read silently — use the doc/PRD flow). Russian triggers: "готовлю речь", "буду диктовать речь", "собери выступление", "скрипт презентации", "речь для демо", "оформи в речь", "питч-спич", "текст для выступления".
---

# /speech — dictation → delivery-ready spoken script

Takes raw, dictated, out-of-order ideas (often voice-to-text, often in one language for
delivery in another) and returns a script the user can read **aloud**. It does the
structuring, translation, and verbal polish — it does **not** invent content the speaker
didn't give.

The engine, repeated at every stage: **this text will be spoken, not read.** Every choice
serves the ear and the speaker's authentic voice — never the page. Preserve the speaker's
own honesty (tentative claims stay tentative) and deliberate humor/attribution; written-doc
register and pitch-deck clichés are the failure modes.

Argument (optional): a topic/title, or pre-existing notes. If absent, the user is about to
dictate — set up to capture (§2) and wait.

This is **artifact-shaped** work: delegate the writer/editor passes to fresh subagents in
persona (`personas/narrative_writer.md`, `personas/narrative_editor.md`) — inline production
reads flat. The orchestrator runs intake + capture + delivery; the personas produce the prose.

---

## How to run

### 1. Intake — settle the load-bearing parameters BEFORE capture
The first three shape the whole script and **must not be guessed** — ask (AskUserQuestion is
ideal) unless already stated. The fourth (register) is **derived**, not asked.
- **Language** of the final script (dictation language may differ → translation needed).
- **Audience** — who's in the room (internal team / clients / investors / conference / public).
  Drives register and what can be assumed vs explained.
- **Length** in minutes → convert to a **word budget at ~130–150 words/min**
  (e.g. 5 min ≈ 650–750 words). The budget is a **ceiling** — cut to fit.
- **Register** — live demo-walkthrough (first person, "let me show you") vs polished talk vs
  internal update. **Infer it from Audience + Length** rather than asking a separate
  question: short internal talk → loose first-person; investor/keynote/press → tighter and
  more composed. Only ask if genuinely ambiguous. Never over-structure a casual talk.

### 2. Capture — accumulate dictation verbatim, do NOT structure on the fly
- Open a scratch log (`.scratch/<slug>-dictation.md`) with the intake params at the top.
  (`<slug>` = kebab-cased title or topic, e.g. `brief-launch`; **reuse the same slug at
  delivery** so the dictation log and final script stay paired.)
- **If the optional argument supplied a title/notes:** use it for the slug, and treat a
  complete note-block as a finished dictation — log it and skip straight to §3. Otherwise
  derive the slug from the first chunk (confirm if unsure) and run the live-capture loop below.
- As the user dictates (usually in chunks), **append each chunk**, fixing **only**
  speech-to-text recognition errors (product names, tech terms, garbled words). Do not
  reorder, summarize, or polish — that's the writer's job and doing it early loses material.
- **Flag uncertain recognition inline, don't guess** — names, niche terms, anything
  ambiguous get a `[recognition-note: heard X → probably Y?]` to confirm at assembly.
- Acknowledge each chunk briefly (what arc-position it fills) so the user sees it landed.
- **Proceed when the user signals they're done** — any clear "go / done / собирай / всё /
  готово", in any language. A **single complete dictation** (one pasted block, or a user who
  says "that's everything, go") can proceed immediately; only the **multi-chunk** case waits
  for the signal. Don't hang waiting for a magic word the user never learned.

### 3. Structure + translate — delegate to `narrative_writer`
Spawn a **fresh subagent** and brief it. **Loading the persona = paste the framing below,
which embeds the card** — the persona files (`personas/*.md`) are 13-line metadata cards, not
"you are…" prompts, so reference the path AND restate role/standards/anti-patterns in the
brief. WHAT + WHY, never HOW. Fill the brackets:

```
You are narrative_writer (Bennu persona; see personas/narrative_writer.md — embody its
role, standards, anti-patterns). You structure scattered ideas into a coherent presentation
script: group by theme with natural transitions, preserve the speaker's intent, adapt
formality to the audience. Anti-patterns: over-structuring a casual talk; drifting into
formal-doc or ad-copy register.

Read [.scratch/<slug>-dictation.md] IN FULL — it's a verbatim dictation log.
FINAL LANGUAGE: [x] (translate, don't transliterate; render product/tech terms naturally).
AUDIENCE: [x].   REGISTER: [x].   WORD CEILING: [n] (cut to fit; it's a ceiling).
The dictation's natural arc is [hook → body blocks → close] — follow it; group by theme
with real transitions, NOT a transcript reflow.
PROTECT verbatim-in-spirit: [the specific jokes / attributions / tentative claims, named].
Add NO facts not in the dictation. Where the speaker was tentative, stay tentative.
Return: the clean script ready to read aloud (light *(click)* stage cues only where they aid
pacing), THEN a short notes section citing key claims [Observed: <dictation-file>].
```

### 4. Polish for the voice — delegate to `narrative_editor`
Fresh subagent, briefed the same way (paste framing + the full draft from §3). Fill brackets:

```
You are narrative_editor (Bennu persona; see personas/narrative_editor.md). You polish an
EXISTING script for verbal delivery — clarity, flow, speakability. You do NOT restructure
(that was narrative_writer's job) and you do NOT add new content. Edit what's here.

Test every line for speakability — read it as if aloud. Break semicolon list-work into
short spoken sentences, kill written-only constructions, smooth breath points, cut filler.
  e.g. turn "We shipped three things: A, with a caveat; B; and C, also caveated;" into
  "We shipped three things. A — with one caveat. B. And C, also caveated."  ← spoken rhythm.
WORD CEILING: [n] — trim toward it; report the final count.
PROTECT (do not touch): [the same jokes / attributions / tentative claims from §3].
Return: the polished script ready to read aloud, then a 3–6 bullet change rationale + count.

--- DRAFT TO EDIT ---
[paste narrative_writer's full output]
```

### 5. Deliver
- Write the final script to `.scratch/<slug>-<LANG>.md` with a one-line header
  (title · minutes · audience · language · word count). Keep light `*(click)*` / stage cues
  only where they help pacing.
- **Paths first.** Lead with the file path(s).
- Surface every `[recognition-note:]` and any **user-owned decision** the personas couldn't
  resolve (a name they dropped rather than guess, a vague number to confirm against the live
  demo). Don't bury these — they're the one thing only the speaker can settle.
- Offer the obvious next steps without doing them unasked: another register pass, a second
  language version, a clean copy without stage-cues, moving the file to its real home
  (Google Drive / repo) once the user picks the final form.

---

## Skip / scope notes
- **Risk is usually low** (internal, reversible, the user rehearses it = their own verify
  loop) → no separate skeptic; the narrative_editor pass is the independent polish. Escalate
  only if the speech is high-stakes external (board, press, public keynote) — then add a cold
  read in a fresh session.
- The scratch log is a working artifact; the user moves the final script to its real home.
- Record the run on completion (`tools/log-run.sh`, mode delegate, personas
  narrative_writer,narrative_editor).
