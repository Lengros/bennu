---
name: design
description: Design a distinctive, heart-winning visual artifact — landing/marketing page, one-pager, hero, product page, pitch deck slide, theme — by first committing to a NAMED art direction, then hand-coding self-contained HTML/CSS, rendering it to a PNG via headless Chrome, and LOOKING at it to critique and fix. Use when the user wants something beautiful, on-brand, or visually distinctive — not the safe default look. Its whole reason to exist is to escape the model's beautiful-but-bland default attractor (warm cream + sage/clay + Fraunces serif + soft rounded cards + radial orbs — the "looks like Claude/Anthropic" look). NOT for structural diagrams (use /diagram) or pure copy/IA (use the doc flow). Russian triggers — "сделай красиво", "нужен крутой дизайн", "не дефолтный вид", "запили лендинг", "сделай one-pager красивым", "подбери стиль/палитру", "сделай необычный дизайн", "оформи визуально".
---

# /design — commit to an art direction, then render and LOOK

This skill makes visual artifacts that **win hearts**, not "tasteful default" ones. It owns
the part the generic loop keeps fumbling: the model is **beautiful-by-default, which means
bland-by-default**. Asked to "make it nice" with no art direction, it regresses to the
median of "tasteful product page" in its training — and that median is a specific look.

**Core principle:** *Beauty that wins hearts is not "try harder" — it's a committed,
named direction chosen BEFORE a line of HTML, an explicit ban on the default attractor,
and a render→look→critique loop so the agent actually SEES what it made.* Remove those
three blockers and the same model that produced bland produces distinctive.

This is the **identity** counterpart to `/diagram` (which owns **structure**). For a
diagram, the safe-polished default — rounded cards, hairline borders, dotted bg, one
accent — is *correct*. For a hero/landing, that same default is the trap.

---

## ⛔ The default attractor — name it so you can escape it

Absent a committed direction, the model reaches for this exact combination. It is
competent and forgettable. **Recognize it and refuse it unless it is the chosen direction:**

| Tell | The default (BAN unless chosen) |
|---|---|
| Background | warm cream `#f4f6f1` / off-white, with faint radial-gradient "orb" blobs + dot-grid texture |
| Accent palette | sage green `#1f6f54` + clay/terracotta `#a25c1d` (the "Claude/Anthropic" pairing) |
| Display type | **Fraunces** (or another opsz serif) for headings + Inter body |
| Cards | `border-radius:18–22px`, hairline `#d9e0da` border, soft `0 8px 26px rgba(...,.07)` shadow |
| Mood | calm, editorial-SaaS, "thoughtful startup", safe |

When you catch your draft using ≥2 of these rows *and nobody asked for that look*, you are
in the attractor. Stop and commit a real direction.

> **Worked exemplar — the gap this skill closes.** Same content, two outcomes.
> *Bland (default attractor):* `--bg:#f4f6f1; --green:#1f6f54; --clay:#a25c1d`, Fraunces
> headings, radius-18 cards, radial orbs. Reads "competent, generic, like every Claude page."
> *Distinctive (committed direction — "cyberpunk control room"):* `--bg:#07090d` near-black,
> neon `--cyan:#2ef7ff` / `--magenta:#ff3df2` with **color roles** (cyan=system, magenta=AI),
> `border-radius:0`, `clip-path` corner notches, layered grid+scanline background, mono
> technical labels, a one-word glitch. Reads "mission systems online." The win came from the
> *committed package*, not a better model. The full package lives in `styles/cyberpunk.md`.

---

## How to run

Stages in order. **Hard gate: no HTML until a direction is locked (Stage 2).** That single
rule is what this skill buys you.

### 1. Brief (intake — keep it to these lines)

Settle before designing. Ask only what's missing from context; don't interrogate.

- **artifact** — landing page / one-pager / hero section / pitch slide / theme-on-existing-markup
- **audience & job** — who looks at it, what they should feel and do
- **content** — the real copy/sections (use what exists; this skill does **not** rewrite IA/copy)
- **mood words** — 2–4 adjectives the user actually wants (e.g. "tactical, premium, alive")
- **medium** — screen only / also PDF-export / embeds in an existing app (inherits its tokens?)
- **hard constraints** — brand colors that must appear, existing markup to theme, must-fit-on-one-screen
- **working path** — where the draft lives, settled now: default `.scratch/design/<slug>.html`
  for exploration, or the target project's docs home for real work. Stages 3–6 (the brief's
  `<path>`, the render commands, the final landing) all use this one path.

### 2. Art-direction gate (the heart — interactive, never skip)

Before any drafting, propose **2–4 named, genuinely distinct directions**. This is a fork
with materially different outcomes → use the platform's **multiple-choice question prompt**
so the user picks rather than free-types. Lead with your recommended direction (marked),
offer real alternatives, always include "or your own".

Each direction is one tight block:

```
NAME — one-line mood ("cyberpunk control room: mission systems online, not a marketing hero")
palette: 5–7 tokens with ROLES (bg / surface / ink / muted + 1–2 accents, each accent = a job)
type:    display family + body family + label treatment (e.g. mono uppercase labels)
signature mechanic: the ONE move that makes it unmistakable (clip-path notches / brutalist
        hairlines / oversized editorial serif / glass + grain / terminal scanlines)
bans:    what this direction explicitly refuses (so it can't drift back to default)
```

Sourcing directions:
- **Catalog first.** Check `styles/` for a proven package that fits. A match → pull it whole.
- **Synthesize the rest.** Riff named starting points from `styles/INDEX.md`, or invent. Make
  them *different from each other* — not three shades of the same idea.
- **Each direction must be escapable-from-default:** if a proposed direction is just the
  attractor with a new accent, cut it.
- **Each direction must fit the AUDIENCE, not just be distinctive.** A bold aesthetic that
  would intimidate or confuse the actual user (a neon/terminal console for a non-technical
  owner; a playful look for a compliance tool) is the *wrong* kind of distinctive. Name the
  audience in Stage 1 and weigh every direction against "would this person feel at home, or
  bounce at the door?" Distinctive ≠ appropriate. (`lessons/distinctive-is-not-usable.md`)

**Divergence mode (offer when the user is unsure or wants to compare):** instead of picking
from descriptions, render the top 2–3 directions as **real comps** — run Stage 3–4 (delegate
+ render + look) on each, in parallel — and let the user choose from actual PNGs. The
binding skeptic (Stage 5) runs **once, on the chosen comp after selection**, not per-comp —
you don't gate throwaways. This is how the cyberpunk-vs-CS comps were chosen. More tokens,
far better calibration — use it when the look matters and the user can't decide blind. Give
each comp its own slug (`<slug>-cyberpunk`, `<slug>-swiss`, …) so parallel renders don't
collide on one path.

**Lock the direction.** If it's a fresh synthesis worth reusing, save it as a style-reference
in `styles/<name>.md` (the `styles/cyberpunk.md` shape) so the next session inherits it.

### 3. Execute — delegate to the landing-designer persona

Design is **artifact-shaped** → delegate to a fresh subagent (CLAUDE.md §5). Inline drafting
reads flat. **Use the paste-ready brief below — it restates the persona inline** (a fresh
agent given only a path to a 13-line metadata card produces thin, un-embodied work; cold-read
lesson). Fill every `<bracket>`; embed your locked direction verbatim.

> ```
> You are a SENIOR CONVERSION-LANDING DESIGNER. You craft distinctive, high-converting
> visual artifacts where aesthetics serve the goal. Operate to these standards:
>  • Commit to ONE strong direction. A coherent token set (bg/surface/line/ink/accent)
>    drives EVERY section — zero ad-hoc colors.
>  • Aesthetics never cost the funnel: the primary action, proof, and any form/demo stay
>    unmissable and readable.
>  • Premium = restraint + craft (type scale, optical spacing, layered shadow, considered
>    motion) — NOT effect-salad.
>  • Hand-code self-contained HTML/CSS. No external fonts/images/CDNs unless the brief
>    says so — system font stacks only. Theme via token overrides + a deliberate visual layer.
> Anti-patterns you must avoid:
>  • Default/templated look when a distinctive identity was asked for. SPECIFICALLY BANNED
>    here: warm-cream bg, sage-green + clay accents, Fraunces serif, radial-orb blobs,
>    dot-grid texture, soft 18px rounded cards — that is the attractor we are escaping.
>  • Beautiful-but-illegible: low-contrast text, decorative type on body copy, motion that
>    hides content.
>  • Rewriting the copy or information architecture — only the VISUAL layer is in scope.
>
> ART DIRECTION (locked — follow exactly, do not drift):
> <paste the full locked direction block from Stage 2: name, mood, palette tokens with
>  roles, type, signature mechanic, bans>
>
> CONTENT (use verbatim, do not rewrite):
> <the real sections/copy>
>
> CONSTRAINTS: <brand colors / existing markup to theme / one-screen / PDF-export / 390px mobile, no horizontal overflow>
> DELIVER: one self-contained .html file at <working path from Stage 1>. Verify contrast, and check
>  mobile overflow at 390px via CDP device emulation (NOT a 390px render.sh window — see Stage 4)
>  before returning. Tag any claim about existing markup [Observed: path:lines].
> ```

For a **theme-on-existing-markup** job, hand the agent the markup and have it deliver token
overrides + a visual layer, not a rewrite.

### 4. Render → LOOK → fix (the loop that makes it good)

You can SEE the output — use it. Reuse the diagram pipeline; do not reinvent a renderer.

```
# render.sh <in.html> <out.png> [W] [H] [bg].  bg is RRGGBBAA (rgb + alpha LAST) under
# --headless=new — set it to the page background so any excess window space is seamless.
P=.scratch/design/<slug>          # the working path from Stage 1
.claude/skills/diagram/render.sh $P.html $P.png  1440 1800 07090dff   # desktop only — see the mobile note below
```

- **Read the desktop PNG.** Critique against the *locked direction*, not against "is it nice":
  did it commit to the mechanic, or soften back toward default? Is the hierarchy unmissable?
  Contrast on body text?
- **Mobile: do NOT judge it from `render.sh` at a 390px width.** render.sh runs under
  `--force-device-scale-factor=2` and sizes the OS window, so a `390` request does NOT yield a
  true 390-CSS-px viewport — the `@media` breakpoint may not fire and you'll see a clipped
  *desktop* layout that fakes overflow (or hides real overflow) (verified 2026-06-19,
  `lessons/render-sh-is-not-a-true-mobile-viewport.md`). Check mobile via CDP device emulation:
  adapt the committed harness `.claude/skills/sprite-anim/verify-anim.mjs`
  (`Emulation.setDeviceMetricsOverride` with `width:390, mobile:true`), then compare
  `documentElement.scrollWidth` vs `clientWidth` (equal = no overflow) and screenshot. Keep a
  `<meta name="viewport" content="width=device-width,initial-scale=1">` in the file or the
  breakpoints are moot on real devices.
- **Iterate the generator, re-render, re-look.** Don't ship a frame you haven't looked at.
- **Render gotcha:** `render.sh` screenshots the *window viewport*, not full page (see its
  header). For a tall page, set a tall `H` and iterate; or render section-by-section. Set the
  `bg` arg to the page background so excess space is seamless. `@2x` is already on.

### 5. Skeptic — design-failure-tuned, fresh, binding

A visual artifact is external-facing → run the skeptic (CLAUDE.md §6) as a fresh subagent
with no drafting context. Tune it to how *design* fails — and judge **fitness for the actual
audience, not just craft.** Put who the audience is in the brief so the skeptic can ask
"would *this* person get it, or bounce?" Give it the rendered PNGs:

> Verify this design artifact for its stated audience (<who they are>). Look at the attached
> desktop + 390px PNGs. Check:
>  1. **Did it commit?** Or regress to the default attractor (cream/sage/clay/Fraunces/orbs/
>     soft-rounded)? Name any tell.
>  2. **First impression / intimidation** — would the stated audience feel "this is for me, I
>     get it", or "too technical/complex, I'm out"? Rate Low/Med/High and say why. A
>     distinctive look that *intimidates its own user* is a FAIL, not a win — cool ≠ usable.
>  3. **Comprehension (5 sec)** — can a first-timer tell what it is, what the key number/state
>     means, and what (if anything) needs their action? What's confusing?
>  4. **Color encodes meaning, not just style** — does a signal color mean ONE thing (red =
>     the one action) or are loud colors sprayed decoratively so nothing reads as "this is
>     what matters"? Decorative-only signal color is a defect.
>  5. **Hierarchy/funnel** — primary action/message unmissable, or everything one flat weight?
>     Does decoration ever bury content?
>  6. **Contrast** — body text and labels readable (≥4.5:1 body, WCAG AA)? Any text lost on bg?
>  7. **Mobile** — horizontal overflow at 390px (measure via CDP at a true 390 viewport, NOT a
>     390px render.sh window)? H1 readable? Stacking sane?
>  8. **Coherence + fidelity** — every section on the same token set, no ad-hoc colors; matches
>     the LOCKED direction; copy unchanged.
> Verdict: PASS / PASS-WITH-CHANGES / FAIL, with specific fixes. Never pass over an attractor
> regression, a contrast failure, OR a design that is distinctive-but-intimidating for its
> actual audience.

Verdict is binding. Never ship over red. (Skip the skeptic only for a throwaway the user is
watching render in-loop.)

### 6. Ship

Paths first; state verified-vs-assumed; the artifact is turnkey (it actually opens and
renders, mobile included). Land it in the target project's home, not `.scratch/`, unless it's
an experiment. Record the run (`tools/log-run.sh`).

---

## The style catalog (`styles/`)

Reusable art-direction packages — the same idea as `personas/`: **reuse beats re-synthesize.**

- `styles/INDEX.md` — one line per direction + a roster of named starting points the gate
  can propose even before a full package exists.
- `styles/<name>.md` — a full package (palette tokens with roles, background recipe, type +
  signature mechanic, component patterns, responsive + print rules, a reuse checklist).
  `styles/cyberpunk.md` is the proven seed; copy its shape.

A full package is *earned by use*: when a synthesized direction ships and is worth repeating,
save it. Don't pre-fabricate a dozen thin entries.

---

## Reach past this skill when

- **Structural diagram** (architecture, data flow, lifecycle) → `/diagram`. There the
  safe-polished default is right; here it's the trap.
- **Pure copy / IA / messaging** (no visual layer) → the doc/PRD flow. This skill themes
  given content; it does not write it.
- **Raster illustration / photographic hero** → hand off a prompt (`/diagram` §"Reach past"):
  image-gen is UI-only here, no API. This skill is for hand-coded, exact, editable HTML/CSS.
- **Production component in a live app** → the visual exploration can happen here, but the
  real change goes through the app's repo + `frontend_engineer`, never a one-off HTML file
  merged blind.

---

## Files in this skill

| File | What it is |
|---|---|
| `styles/INDEX.md` | catalog index — proven packages + roster of named directions to propose |
| `styles/cyberpunk.md` | proven art-direction package (the worked exemplar's "good" side) |
| (renderer) | reuse `.claude/skills/diagram/render.sh in.html out.png [W] [H] [bg]` — no own renderer |

When a new design surprise appears, fold the fix back here — don't let the skill calcify.
