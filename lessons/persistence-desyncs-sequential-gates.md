# Persistence Can Satisfy a Gate Out of Order — Make Gating Chains Cumulative

date: 2026-06-12
scope: frontend / state
rule: When persisted state drives a staged reveal, gate each surface on the full upstream prefix, not just its immediate predecessor.

## Why
In the app's first-session flow, surfaces reveal in a chain: Stage A (external API connected) → Stage B → (≥1 live channel) → Stage C → (≥1 resource) → Stage D (chart + extras). Two features were built in the same session: (1) localStorage persistence of the mock demo state, and (2) the gate that reveals Stage C once a channel is live (a derived "has-live-X" flag, true when the channel is both linked and enabled). Each was verified in isolation and passed. Together they produced a bug the user caught immediately: Stage C appeared on the external-API *connect* screen — before the external API was even connected. Root cause: the Stage C gate was `hasLiveChannel` ALONE. Persistence kept a previously-enabled channel across reloads, so starting a fresh onboarding left `hasLiveChannel === true` while `api.connected === false` — the gate fired with its upstream prerequisite unmet. The chain implicitly assumed strictly-sequential progress (a channel can only go live *after* connect), an assumption that holds only when state is ephemeral and resets on reload. Persistence breaks it.

## How to apply
When you add persistence to any state that drives a staged/gated UI, audit every gate: a gate written as "show X when its immediate predecessor Y is true" silently assumes Y can only become true after everything before Y — which persistence invalidates. Make gates cumulative instead: `showStageC = hasApi && hasLiveChannel`, `showExtras = showStageC && hasResource`, each re-asserting the full prefix, hung off the chain's spine (here, `hasApi`). Test the cross-feature interaction explicitly, not just each feature alone: restore a persisted *downstream* flag (channel live, account linked) while an *upstream* prerequisite is reset (disconnected, mid-onboarding) and assert no downstream surface leaks. This is the same failure family as the browser-runtime lesson — the defect is invisible until two correct-in-isolation features meet at runtime. See [[ui-works-claims-need-browser-runtime-evidence]].

## Disposition
First occurrence (reveal gate × mock persistence, 2026-06-12). Fixed in the page component by making the reveal chain cumulative off `hasApi`. If a future run again ships a gate that assumes ephemeral sequential state after introducing persistence, extract a standing check (a "persisted downstream flag + reset upstream → no leak" assertion in the component test harness).
