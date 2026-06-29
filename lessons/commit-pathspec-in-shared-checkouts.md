# Commit with an explicit pathspec in checkouts the user also works in

date: 2026-06-11
scope: orchestration
rule: In user-shared checkouts commit via explicit pathspec (`git commit -- <paths>`) — a bare commit sweeps the user's staged work into yours.

**Surprise (2026-06-11, a shared checkout):** committing the new `scope.md` via
`git add scope.md && git commit` silently swept in the user's *previously staged but
uncommitted* `hypothesis.md` edit (v0.1→v0.2). The commit message described only scope.md;
the stat line ("2 files changed" for one created file) was the only tell. Caught
post-commit, fixed by `git reset --soft HEAD~1` and re-committing as two honest commits —
safe only because nothing had been pushed.

**Lesson:** `git commit` commits the whole index, not the file you just added. A shared
checkout's index is user state you did not create — the same class of hazard as the
multi-worktree HEAD flip ([[recon-on-flow-base-branch]]), but on the *write* side of the
index instead of the read side of the branch.

**How to apply:**
- Default commit form in any user-shared checkout: `git commit -m "…" -- <explicit paths>`.
  A pathspec'd commit takes only the named paths, regardless of what else is staged.
- Or check first: `git diff --cached --stat` before every commit in such repos; anything
  staged that you didn't stage belongs to the user — leave it or commit it separately
  under its own accurate message.
- Tell: a "N files changed" count larger than what you touched. Read the stat line of
  every commit you make; it is the cheapest post-condition check.
- If a sweep happens and the commit is unpushed: `git reset --soft HEAD~1`, then re-commit
  in honest units. Disclose it to the user either way — it is their work.
