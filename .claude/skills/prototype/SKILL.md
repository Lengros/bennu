---
name: prototype
description: Wire several screens into ONE self-contained, multi-screen, CLICKABLE HTML prototype the user opens in a browser and clicks through — no build, no server, no deploy, no framework. Its job is to validate a FLOW / interaction fast and one-shot a clickable mockup for a PM or design decision. Use when the user wants to feel a flow end-to-end before anyone builds it — an onboarding sequence, a checkout, a multi-step form, a navigation between states. The INTERACTION sibling of /design (which makes ONE beautiful static frame) and /diagram (which draws STRUCTURE): /prototype makes SCREENS that link and respond to clicks with simulated state. NOT for production app code (that goes to the app's repo + frontend_engineer) and NOT for pure visual identity (use /design). Russian triggers — "сделай кликабельный прототип", "прототип флоу", "собери интерактивный макет", "прокликать сценарий", "мокап с переходами между экранами", "прототип онбординга", "покажи как работает флоу", "интерактивный прототип без бэкенда".
---

# /prototype — wire screens into one clickable flow, render and CLICK it

This skill makes a **navigable flow you can click through**, not a pretty dead-end frame.
It owns the gap `/design` leaves: `/design` hand-codes ONE static screen and renders it to a
PNG; `/diagram` draws how a system is wired. Neither lets a PM open a file and *walk the
path* — tap a button, land on the next screen, watch a value update. That clickable-prototype
gap is real and Bennu had not closed it before this skill.

**Core principle:** *A clickable prototype validates a FLOW, not a look — so the thing you
must lock before any HTML is the SCREEN MAP and the NAVIGATION GRAPH, not the art direction.*
Get the inventory of screens and, for every hotspot, which screen it leads to and what state
it changes — then the same self-contained-HTML discipline `/design` already uses produces a
working flow instead of pretty cul-de-sacs.

This is the **interaction** counterpart to `/design` (**identity**) and `/diagram`
(**structure**). It reuses their renderer and skeptic loop; the only new thing it teaches is
**multi-screen wiring inside one file**.

---

## The one thing that makes this not /design

`/design`'s hard gate is "lock the art direction before HTML." **`/prototype`'s hard gate is:
lock the SCREEN MAP + NAVIGATION GRAPH before HTML.** Skip it and you get beautiful screens
that go nowhere — the exact failure this skill exists to prevent. Fidelity is a *dial*, not
the point: default to the lowest fidelity that proves the flow.

---

## How to run

Stages in order. **Hard gate: no HTML until the screen map + nav graph are locked (Stage 2).**

### 1. Brief (intake — keep it to these lines)

Settle before building. Ask only what's missing from context; don't interrogate.

- **flow** — the one user journey to validate (e.g. "first-run onboarding", "add a payee and pay")
- **key path** — the single end-to-end sequence the prototype MUST demo, screen by screen.
  This is the spine everything else hangs off; without it the prototype sprawls.
- **actors & decision** — who clicks through it, and what PM/design decision it must unblock
- **fidelity** — **lo-fi** wireframe (greyscale boxes, prove the flow) / **mid** (real layout,
  placeholder polish) / **hi-fi** (looks shippable). Default lo-fi; raise only with a reason.
  Hi-fi visual identity is `/design`'s job, not this skill's — borrow tokens, don't compete.
- **simulated state** — what must *change* on interaction (a form value echoed back, a toggle,
  a list that grows, a "logged-in" flag that persists across a reload)
- **working path** — settled now: default `.scratch/prototype/<slug>.html` for exploration, or
  the target project's home for real work. Every later command uses this one path.

### 2. Screen-map + nav-graph gate (the heart — interactive, never skip)

Before any HTML, present the map and **get confirmation**. Two artifacts:

**A. Screen inventory** — every screen, one line each:
```
id            purpose (what the user sees / does here)         simulated state it reads/writes
------------  ----------------------------------------------   -------------------------------
start         entry / value prop                                —
form          enter amount + payee                              writes amt, payee
review        confirm before commit                             reads amt, payee
done          success + receipt                                 reads amt, payee
```

**B. Navigation graph** — every hotspot → target + state change. This is what stops dead ends:
```
from    hotspot              → to       state change on click
-----   ------------------   --------   ---------------------
start   [Begin]              → form     —
form    [Confirm]            → review   commit amt, payee from inputs
review  [Edit]               → form     —
review  [Pay now]            → done     mark paid=true
done    [Start over]         → start    clear state
```

Then state **the key path** as a literal click sequence:
`start → [Begin] → form → [Confirm] → review → [Pay now] → done`.

This is a fork with real consequences → present it and confirm before building (use the
platform's plan mode for medium+ risk, per CLAUDE.md §3). Check every screen is reachable on
the key path and every hotspot has a target. **Lock the map**, then build.

### 3. Execute — delegate to the prototyping engineer persona

A clickable prototype is **artifact-shaped** → delegate to a fresh subagent (CLAUDE.md §5).
Inline drafting reads flat. **Use the paste-ready brief below — it restates the persona inline**
(a fresh agent handed only a path to a thin card produces un-embodied work;
`lessons/cold-read-skills-before-registering.md`). Fill every `<bracket>`; embed the locked map.
Point the agent at `scaffold.html` so it starts from a proven skeleton, not a blank page.

> ```
> You are a SENIOR INTERACTION-PROTOTYPING ENGINEER. You wire multiple screens into ONE
> self-contained clickable HTML prototype that validates a user FLOW. Operate to these
> standards:
>  • ONE file, opens straight from disk (file://). NO build, NO server, NO framework, NO
>    npm, NO CDN, NO external fonts/images. System font stack; inline SVG / data-URIs only.
>  • Each screen = one <section class="screen" id="…">; exactly one is active at a time.
>  • Navigation via a tiny JS hash router (in the scaffold) that reads BOTH `?screen=ID`
>    (so a single screen can be rendered headless) AND `#hash` (so clicks and browser
>    back/forward work). Hotspots are <a href="#id"> or elements that set location.hash.
>  • Simulated state, NO backend: JS toggles classes, form inputs reflected into displayed
>    values, localStorage for state that must survive a reload. Seed fake data inline.
>  • Fidelity = <lo-fi / mid / hi-fi>. Do not over-polish; the flow is the deliverable, not
>    the pixels. (Visual identity is /design's job.)
>  • A persistent on-screen PROTOTYPE banner so no one mistakes fake state for a real product.
> Anti-patterns you must avoid:
>  • A real app / backend / build step / multiple files / a bundler — that is NOT this task.
>  • Dead-end screens: every screen on the key path links forward; no hotspot points nowhere.
>  • Bare CSS `:target` show/hide — it does not activate under headless --screenshot, so a
>    single screen can't be rendered. Use the JS router from the scaffold.
>  • Polishing visuals at the cost of completing the flow.
>
> START FROM: .claude/skills/prototype/scaffold.html (copy it; keep the <script> router intact).
>
> SCREEN MAP + NAV GRAPH (locked — build exactly this):
> <paste the full Stage-2 inventory + nav graph + the literal key-path click sequence>
>
> FIDELITY: <lo-fi / mid / hi-fi>.  SIMULATED STATE: <what changes, what persists>.
> CONTENT: <real fake-data / copy to seed>.
> DELIVER: one self-contained .html at <working path from Stage 1>. Verify it opens on
>  file:// and the key path clicks through end-to-end before returning. Render-test at least
>  the entry and the final screen with `?screen=ID` (desktop). Check mobile overflow via CDP
>  device emulation at 390px, NOT a 390px render.sh window (see Stage 4).
>  Tag any claim about existing markup [Observed: path:lines].
> ```

### 4. Render → LOOK, then CLICK → fix (the loop that makes it real)

Two loops, because a prototype has two failure surfaces: how each screen **looks**, and
whether the flow **behaves**. A code read is not evidence about either —
`a code read is not evidence about pixels/behavior` (the cardinal rule `/sprite-anim` states).

**Look loop — per-screen screenshot.** Reuse the diagram renderer; don't reinvent it
[Observed: .claude/skills/diagram/render.sh]. Render a specific screen with the `?screen=ID`
query param (verified to activate the right screen headless, 2026-06-19):

```
P=.scratch/prototype/<slug>          # the working path from Stage 1
.claude/skills/diagram/render.sh "$P.html?screen=start" "$P-start.png" 1440 1000 f5f6f7ff
.claude/skills/diagram/render.sh "$P.html?screen=done"  "$P-done.png"  1440 1000 f5f6f7ff
```

- **Use `?screen=ID`, not `#id`, for rendering.** Verified empirically (2026-06-19): bare
  CSS `.screen:target` show/hide does **not** activate under headless `--screenshot`, so a
  prototype built on `:target` renders **blank** when you screenshot one screen. The fix is
  the scaffold's JS router, which reads `?screen=ID` on load and shows the right screen. (The
  URL fragment itself reaches the page fine — it's `:target` that won't fire under capture;
  query params are simply unambiguous.) Confirm on the first render that the right screen appeared.
- **Mobile overflow: do NOT judge it from `render.sh` at a narrow width.** `render.sh` runs
  under `--force-device-scale-factor=2`, so a `390` window does NOT yield a true 390-CSS-px
  viewport — the `@media (max-width:…)` breakpoint may not fire and you'll see a clipped
  **desktop** layout that looks like overflow when there is none (it fooled this skill's own
  first run; verified 2026-06-19, `lessons/render-sh-is-not-a-true-mobile-viewport.md`). Judge
  mobile in the click loop below via CDP device emulation (`Emulation.setDeviceMetricsOverride`,
  `mobile:true`, width 390), comparing `documentElement.scrollWidth` vs `clientWidth`. Always
  keep `<meta name="viewport" content="width=device-width,initial-scale=1">` in the file.
- Read the desktop PNGs; critique the flow + chrome; fix the generator; re-render.

**Click loop — prove the flow behaves (when the flow logic is non-trivial).** A static
screenshot cannot prove a hotspot navigates or that state updates on click. Drive a real
browser via the Chrome DevTools Protocol — the proven, committed harness is
`.claude/skills/sprite-anim/verify-anim.mjs` [Observed: .claude/skills/sprite-anim/verify-anim.mjs:103-119; sprite-anim/SKILL.md:75-93];
it already does navigate → seed `localStorage` → `click()` → probe, with the right gotchas
baked in (navigate + settle BEFORE touching `localStorage`, else `SecurityError`). Adapt its
`CONFIG`: navigate to the `file://` prototype, `click()` each hotspot on the key path, and
**assert the landed screen** (`document.querySelector('.screen.active').id`) **and the state
change** after each click. (Prefer the CDP harness above.) Walk the whole key path; a hotspot that
looks right but lands on the wrong screen is the defect this loop exists to catch.

### 5. Skeptic — interaction-failure-tuned, fresh, binding

A clickable prototype is external-facing and shared → run the skeptic (CLAUDE.md §6) as a
fresh subagent with no drafting context. Tune it to how a **flow** fails, not just how a
frame looks. Seed it with Bennu's two directly-relevant gating lessons
(`lessons/seed-reviewer-briefs-with-domain-lessons.md`):

> Verify this clickable prototype. You have the file, the locked screen map + nav graph, and
> the stated key path. Open it on file:// and click through. Check:
>  1. **Key path completes** — does `<the literal key-path click sequence>` run end-to-end
>     with every step landing on the intended screen? A break here is a FAIL.
>  2. **Dead / wrong-target hotspots** — does every hotspot navigate, and to the RIGHT screen?
>     Any element that looks clickable but does nothing, or lands on the wrong screen?
>  3. **Back / forward** — do browser back/forward move through the screen history sanely, or
>     break the flow?
>  4. **State desync / out-of-order reachability** — can a screen be reached in a state that
>     shouldn't exist? Two gating traps to probe explicitly:
>       • a reveal-order gate that becomes a *permanent* visibility dependency — a downstream
>         surface vanishes when an upstream trigger toggles off, even though its own resource
>         still exists (`lessons/reveal-gates-arent-runtime-dependencies.md`);
>       • persisted state satisfying a gate out of order — restore a persisted downstream flag
>         (via localStorage) while an upstream prerequisite is reset, and confirm no downstream
>         screen leaks (`lessons/persistence-desyncs-sequential-gates.md`). Reload mid-flow and
>         re-walk; if localStorage carries stale state into a fresh start, that's a defect.
>  5. **Fidelity honesty** — is it obvious this is a prototype with fake state (the PROTOTYPE
>     banner present, no claim of real data)? A mockup that reads as a finished product is a
>     defect — it will be mistaken for "done."
>  6. **Mobile** — horizontal overflow at 390px (measure via CDP at a true 390 viewport, NOT a
>     390px render.sh window)? Tap targets reachable? Key screens readable?
> Verdict: PASS / PASS-WITH-CHANGES / FAIL, with specific fixes. Never pass over a broken key
> path, a dead/wrong-target hotspot, or a prototype that masquerades as a real product.

Verdict is binding. Never ship over red. The **cold read before going live also applies to
this skill itself** the first time it (or a material change to it) ships
(`lessons/cold-read-skills-before-registering.md`). Skip the skeptic only for a throwaway the
user is clicking through with you in-loop.

### 6. Ship

Paths first; state verified-vs-assumed (you *clicked* the key path — say so). Turnkey: the
file opens straight from disk and the key path actually clicks through — a render is not a
delivery. Land it in the target project's home, not `.scratch/`, unless it's an experiment.
Record the run (`tools/log-run.sh`).

---

## The wiring method (this is the skill's teachable core)

Everything lives in ONE `.html` file. `scaffold.html` beside this skill is the proven seed —
copy it; the pieces:

- **Screens.** Each screen is `<section class="screen" id="…">`; CSS shows only `.screen.active`.
- **Router (~15 lines, in the scaffold).** On load and on `hashchange`, read `?screen=ID`
  first (render-friendly), then `location.hash` (click-friendly), then fall back to the first
  screen. An unknown id falls back rather than showing a blank page. **Use this JS router, not
  bare CSS `:target`** — `:target` does not activate under headless render (verified blank,
  2026-06-19), so you could never screenshot a single screen.
- **Hotspots.** `<a href="#screen-id">` for pure navigation; for navigate-AND-mutate, an
  element with `onclick` that updates state then sets `location.hash`.
- **Simulated state, no backend.** JS toggles classes; form inputs are reflected into
  displayed values; `localStorage` holds anything that must survive a "reload"/session. Seed
  fake/demo data inline.
- **Hard constraints.** One file. No build, no framework, no CDN/external fonts/images
  (system font stack; inline SVG / data-URIs only). Works on `file://` straight from disk.
- **Working path.** `.scratch/prototype/<slug>.html` for exploration; the target project's
  home for real work — same convention as `/design`.

---

## Reach past this skill when

- **Production app code** (a real backend, framework, build step, a component that ships) →
  `personas/frontend_engineer.md` + the app's own repo, never a one-off HTML file merged blind
  into production.
- **Pure visual identity / one beautiful static frame** → `/design`. Borrow its tokens for
  hi-fi fidelity here; don't re-litigate art direction in this skill.
- **Structural diagram** (architecture, data flow, lifecycle) → `/diagram`.
- **Multiple files / a bundler / npm** — that breaks "open from disk, no build." If a flow
  genuinely needs that, it's no longer a prototype — it's app work; see the first bullet.

---

## Files in this skill

| File | What it is |
|---|---|
| `scaffold.html` | proven one-file seed — JS router + simulated-state pattern; copy and fill |
| (renderer) | reuse `.claude/skills/diagram/render.sh in.html?screen=ID out.png [W] [H] [bg]` — no own renderer |
| (click harness) | reuse `.claude/skills/sprite-anim/verify-anim.mjs` (CDP) to click hotspots + assert landed screen/state |

When a new prototyping surprise appears, fold the fix back here (and into `scaffold.html` on
the second occurrence) — don't let this skill calcify.
