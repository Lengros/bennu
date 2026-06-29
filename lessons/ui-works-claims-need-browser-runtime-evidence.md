# UI "Works" Claims Need Browser Runtime Evidence
date: 2026-06-11
scope: verification
rule: Don't call a UI "verified" on static gates + code-trace — run it in a real browser, in the Live data mode, before PASS.

## Why
A card redesign passed two skeptic rounds (build + type-check + unit tests all green, code traced line-by-line) and was reported "verified". The user then found, in seconds of real use: a reactive effect fired a side-effecting connect call on mount and on dependency churn — auto-enabling a channel with no user action and coupling unrelated toggles (flipping one control silently moved another). This is a class of bug that is INVISIBLE to static checks: it type-checks, builds, and unit tests pass, because the defect only exists at runtime in the browser's reactivity graph. The skeptic checklist explicitly demands "runtime evidence for works claims — a screenshot, a browser probe; the code exists is static evidence and does not prove it runs." Both the executor and the skeptic skipped it and substituted static green for runtime truth. Live mode was never opened at all, so a second (data-source-dependent) defect surfaced only on the user's screen.

## How to apply
For any UI change, before PASS: (a) actually load it in a browser, not just `build`/`check`/`test`; (b) drive the real user sequences — toggle A, then toggle B, and assert B did not move A; (c) test the data mode the user will use (Live/backend), not only mock, because availability/empty states differ and mock hides them; (d) reactive effects that trigger side-effects (network calls, state writes) on dependency change are a top suspect for spooky cross-control coupling — prefer user-event handlers over effects for actions. If the environment cannot drive a browser, say so explicitly and DO NOT report "verified" — hand the user a precise click-test or stand up a component-test harness (jsdom + testing-library) so the sequence is asserted automatically. Static-only evidence for a UI "works" claim is a blocker, not a pass.

## Disposition
First occurrence (notifications redesign, 2026-06-11). Pattern: if a future run again substitutes static gates for browser runtime evidence on a UI, extract a SKEPTIC checklist enforcement (a required "browser-probed in mode=___" line in the verdict) or a component-test harness as standing machinery.
