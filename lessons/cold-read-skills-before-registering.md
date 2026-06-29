# Cold-read a new skill before trusting it — author-context leakage is invisible warm

date: 2026-06-16
scope: skills
rule: cold-read a new skill in a fresh subagent before registering; delegation skills embed the brief as a paste-ready template, not a reference.

## What happened

Built `/speech` (dictation → spoken script). User asked: "would a fresh agent with no
context run this as you intended?" A cold-read subagent (only the skill file + referenced
personas, no session context) returned PASS-WITH-GAPS and found two blocking leaks.

When a model authors a skill, it silently encodes its own session knowledge. The author
reads the draft and it "obviously works" — because the author supplies the missing context
from their own head. A fresh agent in a new session does not have that head.

Concrete leaks the cold read caught in `/speech`:
- **Delegation described, not templated.** `/speech` said *"delegate to a fresh subagent in
  the narrative_writer persona"* — relying on the author's standing knowledge of the house
  convention (CLAUDE.md §5) for HOW to put a persona into a subagent. The persona files are
  13-line metadata cards (`role:`, `standards:`), not "you are…" prompts. A cold agent would
  cite the path and produce thin, un-embodied prose — exactly the "inline reads flat" failure
  the skill warned against.
- **No output exemplar.** The skill turned on a subjective quality ("speakable") with nothing
  concrete to calibrate against → a cold agent over-polishes into the banned register.

## The lesson

**A skill that codifies delegation must embed the full prompt-framing of the persona/brief
INSIDE itself — a paste-ready template with brackets — never a reference to a convention or a
metadata card.** And any skill turning on a subjective quality bar needs at least one
concrete before/after exemplar.

**Verify every new/edited skill with a cold-read subagent before registering it** — fresh
session, given ONLY the skill file + what it references, asked "could you run this end-to-end
as intended, and what would you have to guess?" This is the same principle as Hard Rule #1
(never self-review): the author cannot see their own context leakage warm. Re-run the cold
read after fixing, to confirm the gaps closed and no new ones opened (the `/speech` re-audit
returned PASS).

## How to apply

- After writing a `.claude/skills/<name>/SKILL.md`, before announcing it's ready: spawn a
  general-purpose subagent, point it at the file + referenced files, instruct "you have no
  prior context, walk every stage, flag what you'd guess." Treat findings as binding.
- For delegation skills specifically: the brief goes in as a fill-in template with the
  persona's role/standards/anti-patterns restated inline (see `/speech` §3–§4 for the shape).
- Compare against `market-scan` — the house bar already has fill-in brief templates (§5),
  output contracts (§6), and worked examples (§7). New skills should match that bar.

Related: [[match-research-depth-to-stakes]] (calibrating verification effort to stakes).
