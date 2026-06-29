# A First-Session Reveal Gate Is Not a Permanent Visibility Dependency

date: 2026-06-12
scope: frontend / state
rule: A reveal-order gate (show X only after Y) must not hide X once X is connected; gate the reveal, not the existence.

## Why
The app's onboarding choreography reveals surfaces in order: Stage A (external API) → Stage B (≥1 live channel) → Stage C (resource linked) → Stage D (chart + extras). I encoded this as cumulative gates: `showStageC = hasApi && hasLiveChannel`, `showExtras = showStageC && hasResource`. That made a live channel (Stage B enabled) a PERMANENT precondition for the Stage C tile AND the Stage D chart. A user in Live mode with the external API connected and a resource linked but the Stage B channel off saw no Stage C tile and no chart at all — even though the data endpoint returned a "ready" state instantly (confirmed by an API-level probe: link → finalize → data ready at t+0s, no data race). The reveal rule ("don't overwhelm a first-timer with Stage C before Stage B works") had silently become a runtime visibility dependency: toggling the Stage B channel off erased already-connected resources. Fix: the chart + extras follow a linked resource only (`showExtras = hasApi && hasResource`); the Stage C frame shows once a channel is live OR a resource already exists (`hasLiveChannel || hasResource`), so a connected resource never disappears.

## How to apply
When you express a progressive-disclosure sequence as boolean gates, separate the *reveal trigger* from the *existence condition*. The trigger (a channel went live, an intro was dismissed) belongs only on the EMPTY/invite state; once the downstream thing is actually connected/created, its visibility must depend on its own existence (hasResource), not on the upstream trigger still being true. Test the "upstream toggled back off after downstream exists" path explicitly: connect the resource, then turn off the gating precondition, and assert the resource and everything derived from it stays visible. Also: when a chart/section is "missing," probe the data source directly (here, a raw call to the data endpoint) before assuming a backend/data race — it isolated the bug to pure frontend gating in one step. Same gate-assumption family as [[persistence-desyncs-sequential-gates]].

## Disposition
First occurrence (onboarding reveal gating, 2026-06-12). Fixed in the page component. If a future run again makes a reveal-order gate a permanent visibility condition, extract a standing rule: reveal gates apply to empty states only; connected resources gate on their own existence.
