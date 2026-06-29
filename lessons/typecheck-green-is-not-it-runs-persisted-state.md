# Type-check Green Is Not "It Runs" — Persisted/Hydrated State Can Violate Its Own Type

date: 2026-06-26
scope: frontend / verification / state
rule: Type-check green ≠ runs; persisted/hydrated values can violate their cast type — browser-run stateful UI, heal old snapshots on new fields.

## Why
Added a new channel to a typed frontend app: a new **required** field on a config type, supplied by the mock fixture and the backend adapter. I declared it verified off the type-checker (0 errors) + 20 passing unit tests. The running app threw immediately: `Cannot read properties of undefined (reading 'available')` on the new field access. Root cause: mock state rehydrates from a **localStorage snapshot** (a hydrate-from-localStorage step), gated only by a version check. The user's browser held a snapshot persisted *before* the new field existed — same version, so it loaded as-is, carrying the prior channels but not the new one. The value was cast to the config type, so the compiler believed the field was present; the on-disk JSON disagreed. Static checks and unit tests both passed because neither exercises rehydration of a stale persisted blob — the defect lives *only* in runtime state crossing a trust boundary the compiler can't see (localStorage, the wire, any `JSON.parse(...) as T`).

## How to apply
- **A new required field on a persisted/hydrated shape is a migration, not just a type edit.** Either bump the storage/schema version (discards old blobs) or **heal** on load — backfill absent fields from current defaults (`{ ...defaults(), ...parsed }`). Preserve the user's state where cheap; healing beats a version bump that nukes everyone's session.
- **`as T` / typed `JSON.parse` is an assertion, not a guarantee.** Anywhere data enters from localStorage, the network, or a file, the type describes intent, not reality. Treat those boundaries as untrusted and normalize.
- **For stateful UI, "verified" requires a real run** — load the app (or drive it via CDP), don't stop at the type-checker + unit tests. The turnkey rule ("walk the user's launch path yourself") is not optional for frontend: type-green + tests-green is necessary, never sufficient.
- Pin the failure mode with a test at the right seam: extract the heal as a **pure exported helper** and unit-test it directly, rather than fighting the `browser`/localStorage I/O guard (which makes the real load path untestable in a node env).

## Disposition
First occurrence (a new channel, delegated build + warm review). Same proxy-verification trap as [[verify-stacking-outcome-not-zindex-value]] and [[verify-tooling-mechanism-not-user-as-test-harness]] — I checked a stand-in (the static type) for the real mechanism (the runtime value). Fixed with a heal helper in the hydrate-from-localStorage step + two regression tests. Captured.
