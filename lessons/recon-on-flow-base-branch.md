# Recon (and worktree) from the flow's base branch, not the main checkout's current branch
date: 2026-06-10
scope: orchestration
rule: Recon and cut the worktree from the flow's pinned base branch, not the main checkout's current branch — it may sit on a different tree.

**Surprise (2026-06-10, a web app's Stage B block):** recon was run against the
main checkout, which happened to be sitting on
`feature-x`. But the project's `flow:` pins **`base`** as the base branch.
The recon's cited line numbers and frontend map (a single types module, a single
backend module) were off from the base branch's actual structure — base uses an
`api/` facade with a **mock + backend split** and types in a separate `api/types` module. The
implementer had to re-locate the real files. It only survived because `base` turned out
to be a *superset* of the feature branch, and because the `[Observed: path:lines]`
spot-check-≥3 norm forced the implementer to verify against the worktree before editing.

**Lesson:** when a project's `flow:` block names a base branch, the surface you recon and
the surface you edit must both be **that base branch's tree** — not whatever the shared
main checkout currently has checked out. A multi-worktree repo flips the main checkout's
HEAD between sessions; recon against it silently maps the wrong branch.

**How to apply:**
- Before recon on a `flow:`-pinned project, run the branch-topology check first:
  `git log --oneline <base>..<checkout>` and `<checkout>..<base>` — know whether they
  diverge, and which files differ — *then* point recon at the base (or at the worktree you
  just cut from it).
- Create the worktree from the base branch first, and recon **inside the worktree** when
  the structure is uncertain. Cheaper than re-deriving paths mid-implementation.
- The `[Observed:]` spot-check is the backstop that caught this — it is not optional even
  when the brief embeds the orchestrator's recon excerpts.

Related: the registry `flow:` gotcha already anticipates the *push* side of concurrent
sessions (`git push origin <sha>:<base>` when HEAD is elsewhere). This is the *read* side
of the same multi-worktree hazard.
