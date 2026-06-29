# A Translucent Theme Token Goes See-Through When Reused as an Opaque Surface — Floating UI Needs Its Own Opaque/Popover Token

date: 2026-06-24
scope: frontend / theming / design-tokens
rule: A translucent surface token reused for a knob/menu/tooltip goes see-through in a light theme; floating/opaque UI needs its own opaque token.

## Why
A new light theme set `--color-card` to a near-transparent value (~3% opacity) — a faint raised tint that is correct for in-flow card panels on a white page. But three components reused `bg-card` as if it were an opaque surface: the switch knob, the dropdown menu, and the chart hover tooltip. At 3% opacity the knob became a washed blob on the accent track, and the menu/tooltip were strongly see-through — the row content and chart curve bled through. The bug was **invisible in the original dark theme**, where `--color-card` was effectively opaque, so it only surfaced once a light theme made the tint nearly transparent. It took three rounds to clear: the user found the knob, then the menu; a proactive grep of `bg-card` then caught the tooltip before they hit it.

## How to apply
- When a surface token's value is **translucent in any theme**, treat every component that consumes it as suspect: a tint meant for layering is wrong anywhere an opaque background is assumed.
- Give **knobs, dropdowns/menus, tooltips, popovers, modals** a dedicated token — `--color-knob`, `--color-popover` — opaque, or near-opaque + `backdrop-blur` for an intentional frosted glass ("mini-transparent"). Don't reuse the card-surface tint there.
- **A dark theme hides this class of bug** (its surfaces are usually opaque). Always verify floating UI in the **light** theme, rendered **over busy content** — that's the only place the see-through shows.
- **Fix the whole class on first report.** The user reported one (knob), then a second (menu). Per "apply corrections session-wide," grep the offending token across the codebase and fix every at-risk use in one sweep rather than waiting for the user to find each one. In-flow surfaces (the actual cards) keep the tint; only floating/opaque uses switch.

## Disposition
Third instance in a single session (knob → menu → swept tooltip). Pattern is stable → captured here. The opaque/popover tokens and inline stylesheet comments document the split in-project; this lesson generalizes it.
