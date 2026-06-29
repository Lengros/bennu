# Design regresses to a beautiful-but-bland default attractor — escape it by committing a named direction

date: 2026-06-19
scope: design / visual artifacts
rule: No art direction yields a bland house-default look; lock a NAMED direction before HTML, ban it, then render and LOOK.

## What happened

A product one-pager was generated through the
generic loop and came out "competent but forgettable — looks like every Anthropic page."
Reading it showed why, literally: `--bg:#f4f6f1` cream, `--green:#1f6f54` sage, `--clay:#a25c1d`
terracotta, **Fraunces** serif headings, radius-18 cards, radial-orb blobs + dot-grid. That palette+type+texture *is* the Claude/
Anthropic house aesthetic. When the user took the same content to Codex and **committed an art
direction** (a `cyberpunk-style-reference.md`: near-black + neon, color-role tokens, `radius:0`,
clip-path notches, scanlines, banned the soft-SaaS look), the output became distinctive.

The win came from the *committed constraint package*, not a better model. Absent a direction,
the model regresses to the median of "tasteful product page" in its training — and that median
is a specific, recognizable look.

## The lesson

The model is **beautiful-by-default, therefore bland-by-default.** "Try harder / make it pretty"
does not escape the attractor because the attractor *is* the model's idea of pretty. Three
moves escape it, and all three are needed:

1. **Commit a NAMED direction before a line of HTML** — palette tokens with roles, a type pair,
   one signature mechanic, and a ban-list. A fork with materially different outcomes → present
   directions as a choice, don't divine one.
2. **Name and ban the attractor explicitly** — cream/sage/clay/Fraunces/orbs/soft-rounded. You
   can only refuse a default you can recognize mid-draft.
3. **Render → LOOK → critique → fix** — the agent must SEE its output (headless-Chrome PNG, read
   it back) and judge it against the locked direction, not against "is it nice."

Note the asymmetry with `/diagram`: for **structure** (diagrams) the safe-polished default —
rounded cards, hairline borders, one accent — is *correct*. For **identity** (hero/landing) the
same default is the trap. Same house style, opposite verdict by artifact kind.

## How to apply

- Visual/landing/hero/one-pager work → run `/design`. It hard-gates: no HTML until a direction
  is locked, carries the attractor ban-list, and runs the render-and-look loop. Reusable
  directions live in `.claude/skills/design/styles/` (reuse beats re-synthesize, like personas).
- If you catch a draft using ≥2 attractor tells (cream bg, sage/clay, Fraunces, orbs, dot-grid,
  18px soft cards) and nobody asked for that look — stop, you're in the attractor; commit a real
  direction.
- A subjective bar ("beautiful") is only delegable with a concrete exemplar — give the executor
  actual tokens (bad vs good), not adjectives (`lessons/cold-read-skills-before-registering.md`).

Related: [[cold-read-skills-before-registering]] (this skill was cold-read twice before going live).
