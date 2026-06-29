---
name: motion
description: How a UI element should MOVE — the craft layer of web motion. Decide whether a thing should animate at all, then pick the easing, duration, spring, origin, and interruptibility that make it feel right instead of generic. Use when building or polishing any interaction with motion — modals, drawers, toasts, dropdowns, tooltips, buttons, list enter/exit, drag/swipe, scroll reveals — or when an animation feels sluggish, janky, or "comes from nowhere" and you need to know why. The MOTION sibling of /design (static identity), /prototype (clickable flow), and /diagram (structure): /motion owns how things move once they're on screen. For reviewing existing motion against this bar, use /review-motion. Russian triggers — "как анимировать", "какой easing/кривая", "тайминг анимации", "сделай моушен", "оживить интерфейс", "spring анимация", "почему анимация тормозит/лагает", "анимация ощущается дёшево".
---

# /motion — how UI should move

This skill owns the layer none of the other design skills cover: **how an element should
move once it's on screen.** `/design` commits a static look, `/prototype` wires a clickable
flow, `/diagram` draws structure — none of them tell you whether a dropdown should use
`ease-out` or a custom curve, how long a drawer should take, or why an entrance from
`scale(0)` looks broken. That motion-craft gap is what this fills.

**Core principle:** *Good motion is mostly subtraction and exact values, not flourish.* The
agent's default failure isn't "too little animation" — it's animating the wrong things, with
weak built-in easings, wrong durations, and wrong origins. The aggregate of small invisible
correctness (right easing, right timing, right origin, interruptible, GPU-only) is what makes
an interface feel expensive. The catalog below is that aggregate.

**Attribution.** Adapted from Emil Kowalski's design-engineering philosophy
([animations.dev](https://animations.dev/)) — ex-Vercel/Linear, author of Sonner and Vaul.
Ported into Bennu 2026-06-20.

**Scope in Bennu — which advice applies where:**
- **`/prototype` (vanilla, no framework):** the CSS sections apply directly — custom easing
  variables, `transition` vs `@keyframes`, `@starting-style`, `clip-path`, WAAPI, transforms.
- **Production web (a React app):** also use the React / Framer Motion (Motion) and
  Radix/Base-UI sections — `useSpring`, hardware-acceleration caveat, `prefers-reduced-motion`
  hooks.
- **Pairs with `/review-motion`:** this skill is the knowledge; `/review-motion` is the
  binding reviewer that checks code against it.

---

## Core philosophy

### Taste is trained, not innate

Good taste is a trained instinct: the ability to see what elevates and recognize what cheapens.
When building UI, don't just make it work — study *why* the best interfaces feel the way they
do. Reverse-engineer animations, inspect interactions, be curious.

### Unseen details compound

Most details users never consciously notice — that is the point. When something functions
exactly as assumed, they proceed without a second thought. Every rule below exists because the
aggregate of invisible correctness creates interfaces people love without knowing why.

### Beauty is leverage

People pick tools on the overall experience, not just function. Good defaults and good motion
are real differentiators and are underused in software. Use them to stand out.

## The animation decision framework

Before writing any animation code, answer these in order.

### 1. Should this animate at all?

**Ask: how often will users see it?**

| Frequency | Decision |
| --- | --- |
| 100+ times/day (keyboard shortcuts, command-palette toggle) | No animation. Ever. |
| Tens of times/day (hover effects, list navigation) | Remove or drastically reduce |
| Occasional (modals, drawers, toasts) | Standard animation |
| Rare / first-time (onboarding, feedback, celebrations) | Can add delight |

**Never animate keyboard-initiated actions** — repeated hundreds of times daily, animation
makes them feel slow and disconnected. Raycast has no open/close animation: correct for
something used hundreds of times a day.

### 2. What is the purpose?

Every animation must answer "why does this animate?" Valid purposes:

- **Spatial consistency** — toast enters and exits from the same direction, making
  swipe-to-dismiss intuitive
- **State indication** — a morphing button shows the state change
- **Explanation** — a marketing animation that shows how a feature works
- **Feedback** — a button scales down on press, confirming the interface heard the user
- **Preventing jarring change** — elements appearing/disappearing without transition feel broken

If the purpose is "it looks cool" and the user sees it often, don't animate.

### 3. What easing should it use?

```
Is the element entering or exiting?
  Yes → ease-out (starts fast, feels responsive)
  No →
    Moving / morphing on screen?  → ease-in-out (natural accel/decel)
    Hover / color change?         → ease
    Constant motion (marquee, progress)? → linear
    Default → ease-out
```

**Use custom easing curves — built-in CSS easings are too weak.** They lack the punch that
makes motion feel intentional.

```css
--ease-out:    cubic-bezier(0.23, 1, 0.32, 1);     /* strong ease-out for UI */
--ease-in-out: cubic-bezier(0.77, 0, 0.175, 1);    /* strong ease-in-out for on-screen movement */
--ease-drawer: cubic-bezier(0.32, 0.72, 0, 1);     /* iOS-like drawer curve (Ionic) */
```

**Never `ease-in` on UI.** It starts slow — delaying the exact moment the user is watching
most. A dropdown with `ease-in` at 300ms *feels* slower than `ease-out` at the same 300ms.
Find stronger curves at [easing.dev](https://easing.dev/) or [easings.co](https://easings.co/)
rather than hand-rolling.

### 4. How fast?

| Element | Duration |
| --- | --- |
| Button press feedback | 100–160ms |
| Tooltips, small popovers | 125–200ms |
| Dropdowns, selects | 150–250ms |
| Modals, drawers | 200–500ms |
| Marketing / explanatory | Can be longer |

**Rule: UI animations stay under 300ms.** A 180ms dropdown feels more responsive than a 400ms
one.

### Perceived performance

Speed in animation directly shapes how users perceive your app's performance:
- A **fast-spinning spinner** makes loading feel faster (same load time, different perception).
- A **180ms select** feels more responsive than a **400ms** one.
- **Instant tooltips** after the first one is open (skip delay + skip animation) make the whole
  toolbar feel faster.

`ease-out` at 200ms *feels* faster than `ease-in` at 200ms because the user sees immediate
movement.

## Spring animations

Springs feel natural because they simulate real physics; they have no fixed duration — they
settle on parameters.

**When to use:** drag with momentum, elements that should feel "alive" (Apple's Dynamic
Island), interruptible gestures, decorative mouse-tracking.

```js
// Apple-style (easier to reason about) — recommended
{ type: "spring", duration: 0.5, bounce: 0.2 }

// Traditional physics (more control)
{ type: "spring", mass: 1, stiffness: 100, damping: 10 }
```

Keep bounce subtle (0.1–0.3); avoid it in most UI — reserve for drag-to-dismiss and playful
interactions. Springs **maintain velocity when interrupted** (keyframes restart from zero), so
they're ideal for gestures a user may reverse mid-motion: click an expanded item, hit Escape,
and the spring smoothly reverses from its current position.

**Mouse interactions:** tying a value directly to mouse position feels artificial (no
momentum). Interpolate with `useSpring` instead — but only when the motion is *decorative*. A
functional graph in a banking app should not have it.

```jsx
import { useSpring } from 'motion/react'; // package renamed from 'framer-motion' (old alias still resolves)
const springRotation = useSpring(mouseX * 0.1, { stiffness: 100, damping: 10 });
```

## Component building principles

### Buttons must feel responsive

```css
.button { transition: transform 160ms ease-out; }
.button:active { transform: scale(0.97); }   /* subtle: 0.95–0.98 */
```

Instant feedback makes the UI feel like it's truly listening. Applies to any pressable element.

### Never animate from scale(0)

Nothing in the real world appears from nothing. Start from `scale(0.9–0.97)` + opacity — even
a barely-visible initial scale makes the entrance feel natural, like a balloon that has shape
even when deflated.

```css
/* Bad */  .entering { transform: scale(0); }
/* Good */ .entering { transform: scale(0.95); opacity: 0; }
```

### Make popovers origin-aware

Popovers/dropdowns/tooltips should scale in **from their trigger**, not from center. The
default `transform-origin: center` is wrong for almost every popover. **Exception: modals** —
not anchored to a trigger, they appear centered, so keep `transform-origin: center`.

```css
.popover { transform-origin: var(--radix-popover-content-transform-origin); }  /* Radix */
.popover { transform-origin: var(--transform-origin); }                        /* Base UI */
```

### Tooltips: skip delay on subsequent hovers

Delay before the first tooltip to prevent accidental activation — but once one is open,
hovering adjacent tooltips should open them instantly with no animation. Feels faster without
defeating the initial delay.

```css
/* data-* here are Base UI's emitted attributes; the native CSS at-rule is @starting-style (see below) */
.tooltip { transition: transform 125ms ease-out, opacity 125ms ease-out; transform-origin: var(--transform-origin); }
.tooltip[data-starting-style], .tooltip[data-ending-style] { opacity: 0; transform: scale(0.97); }
.tooltip[data-instant] { transition-duration: 0ms; }
```

### Transitions over keyframes for interruptible UI

CSS transitions can be interrupted and retargeted mid-animation; keyframes restart from zero.
For anything triggered rapidly (adding toasts, toggling states), transitions are smoother.

```css
.toast { transition: transform 400ms ease; }                 /* interruptible — good */
@keyframes slideIn { from { transform: translateY(100%); } to { transform: translateY(0); } }  /* restarts from zero — avoid for dynamic UI */
```

### Blur to mask imperfect transitions

When a crossfade feels off despite tuning easing/duration, you're seeing two distinct states
overlapping. A subtle `filter: blur(2px)` during the transition blends them into one perceived
transformation. Keep blur < 20px (heavy blur is expensive, especially in Safari).

### Animate entry with @starting-style

The modern, JS-free way to animate element entry:

```css
.toast {
  opacity: 1; transform: translateY(0);
  transition: opacity 400ms ease, transform 400ms ease;
  @starting-style { opacity: 0; transform: translateY(100%); }
}
```

Legacy fallback where support is missing: `useEffect(() => setMounted(true), [])` + a
`data-mounted` attribute.

## CSS transform mastery

- **`translate` percentages** are relative to the element's own size — `translateY(100%)` moves
  it by its own height regardless of dimensions (how Sonner positions toasts, how Vaul hides
  the drawer). Prefer over hardcoded px.
- **`scale()` scales children too** (font, icons, content) — a feature for press feedback.
- **3D**: `rotateX/Y` + `transform-style: preserve-3d` give real depth/orbit/flip without JS.
- **`transform-origin`** is the anchor every transform executes from. Default is center; set it
  to match where the trigger lives for origin-aware interactions.

## clip-path for animation

`clip-path: inset(top right bottom left)` defines a rectangular clip; each value eats in from
that side. One of the most powerful animation tools in CSS:

- **Reveal on scroll** — start `inset(0 0 100% 0)` (hidden from bottom) → `inset(0 0 0 0)` when
  in viewport (`IntersectionObserver` / `useInView { once: true, margin: "-100px" }`).
- **Hold-to-delete** — colored overlay `inset(0 100% 0 0)` → `inset(0 0 0 0)` over 2s linear on
  `:active`; snap back 200ms ease-out on release.
- **Seamless tab color transition** — duplicate the tab list, style the copy as active, clip so
  only the active tab shows, animate the clip on change. Beats timing individual color
  transitions.
- **Comparison sliders** — overlay two images, clip the top with `inset(0 50% 0 0)`, drive the
  right inset from drag position. No extra DOM, fully hardware-accelerated.

## Gesture & drag interactions

- **Momentum dismissal** — don't require crossing a distance threshold. Compute velocity
  (`Math.abs(distance) / elapsedMs`); dismiss if `> ~0.11`. A quick flick should be enough.
- **Damping at boundaries** — dragging past a natural edge moves less the further you go (real
  things slow before stopping).
- **Pointer capture** once dragging starts, so it continues when the pointer leaves bounds.
- **Multi-touch protection** — ignore extra touch points after the drag begins
  (`if (isDragging) return`) to prevent jumps.
- **Friction over hard stops** — allow over-drag with rising resistance, not an invisible wall.

## Performance rules

- **Only animate `transform` and `opacity`** — they skip layout and paint and run on the GPU.
  `padding`/`margin`/`height`/`width`/`top`/`left` trigger all three rendering steps.
- **Don't drive child transforms via a CSS variable on the parent** — it recalcs styles for all
  children. Set `transform` directly on the element.
  ```js
  element.style.setProperty('--swipe-amount', `${d}px`); // bad: recalc on all children
  element.style.transform = `translateY(${d}px)`;        // good: only this element
  ```
- **Framer Motion shorthands (`x`/`y`/`scale`) are NOT hardware-accelerated** — they run on the
  main thread via rAF and drop frames under load. Use the full transform string:
  ```jsx
  <motion.div animate={{ x: 100 }} />                          // drops frames under load
  <motion.div animate={{ transform: "translateX(100px)" }} />  // hardware accelerated
  ```
- **CSS animations beat JS under load** — they run off the main thread; rAF-based animations
  stutter while the browser loads/scripts/paints. Use CSS for predetermined motion, JS for
  dynamic/interruptible.
- **WAAPI** gives JS control with CSS performance (hardware-accelerated, interruptible, no lib):
  ```js
  element.animate([{ clipPath: 'inset(0 0 100% 0)' }, { clipPath: 'inset(0 0 0 0)' }],
    { duration: 1000, fill: 'forwards', easing: 'cubic-bezier(0.77, 0, 0.175, 1)' });
  ```

## Accessibility

```css
@media (prefers-reduced-motion: reduce) {
  .element { animation: fade 0.2s ease; }   /* keep opacity/color, drop transform-based motion */
}
@media (hover: hover) and (pointer: fine) {
  .element:hover { transform: scale(1.05); } /* gate hover motion — touch fires false hovers on tap */
}
```

```jsx
const reduce = useReducedMotion();
const closedX = reduce ? 0 : '-100%';
```

Reduced motion means **fewer and gentler** animations, not zero — keep transitions that aid
comprehension, remove movement/position changes.

## Asymmetric enter/exit timing

Slow where the user is deciding, fast where the system responds. A hold-to-delete is slow and
deliberate (2s linear); the release always snaps (200ms ease-out).

```css
.overlay { transition: clip-path 200ms ease-out; }            /* release: fast */
.button:active .overlay { transition: clip-path 2s linear; }  /* press: slow, deliberate */
```

## Stagger

When multiple elements enter together, stagger them — each animates in a small delay after the
previous, a cascade that feels more natural than everything at once.

```css
.item { opacity: 0; transform: translateY(8px); animation: fadeIn 300ms ease-out forwards; }
.item:nth-child(2) { animation-delay: 50ms; }
.item:nth-child(3) { animation-delay: 100ms; }
@keyframes fadeIn { to { opacity: 1; transform: translateY(0); } }
```

Keep delays short (30–80ms between items) — long delays feel slow. Stagger is decorative; never
block interaction while it plays.

## The Sonner principles (building loved components)

From building Sonner (13M+ weekly downloads); applies to any component:

1. **Developer experience is key.** No hooks, no context, no setup — drop `<Toaster />` once,
   call `toast()` anywhere. Less adoption friction → more use.
2. **Good defaults matter more than options.** Ship beautiful out of the box; most users never
   customize.
3. **Naming creates identity.** "Sonner" (French "to ring") beats "react-toast" — sacrifice
   discoverability for memorability when it fits.
4. **Handle edge cases invisibly.** Pause toast timers when the tab is hidden, fill gaps
   between stacked toasts to keep hover state, capture pointer events during drag. Users never
   notice — exactly right.
5. **Transitions, not keyframes, for dynamic UI.** Toasts are added rapidly; keyframes restart
   from zero, transitions retarget smoothly.
6. **Build a great docs site.** Let people touch the product before they adopt it.

**Cohesion matters.** Match motion to the component's personality and the rest of the product —
a playful component can be bouncier, a professional dashboard stays crisp. Sonner uses `ease`
(not `ease-out`) and is slightly slower than typical UI to feel elegant; the motion, the
design, and even the name are in harmony.

## Debugging motion

- **Slow motion** — bump duration 2–5× or use DevTools' animation inspector. Check: colors
  crossfade cleanly (no two overlapping states), easing doesn't stop abruptly, `transform-origin`
  is right, coordinated properties (opacity/transform/color) stay in sync.
- **Frame-by-frame** — Chrome DevTools Animations panel reveals timing drift between
  coordinated properties.
- **Real devices** for gestures (drawers, swipe) — connect a phone, hit the dev server by IP,
  use Safari remote devtools.
- **Fresh eyes next day** — imperfections invisible during development surface later.
- For Bennu sprite/decorative animations, the on-screen verification mechanics (CDP measurement,
  drift/jump/stall checks) live in `/sprite-anim` — a code read is not evidence about pixels.

---

To review existing motion code against this bar (10 standards, escalation triggers,
Before/After table + Block/Approve verdict), use **`/review-motion`**.
