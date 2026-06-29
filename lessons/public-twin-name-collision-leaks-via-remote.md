# Publishing a Public Twin: a Name Collision With a Private Repo Leaks Through the Shared Remote

date: 2026-06-17
scope: security / publication
rule: Verify a public repo name is free before creating it; if a private repo holds it, repoint that remote first or its next push leaks publicly.

## Why
Told to "create the GitHub repo and push" the sanitized public fork, the obvious move
was `gh repo create <owner>/<repo> --public --push`. A pre-flight check found the name was
already taken — by the user's **private** backup of the *live* system, whose HEAD matched the
working commit and whose tree held every client/domain detail the fork had just been scrubbed
of. Two failure modes were one command away: a plain push would reject on unrelated histories,
but a `--force` (or a tool that retries with one) would have **destroyed the private backup
and exposed its full contents publicly**. Worse and subtler: the *live* repo's `origin` still
pointed at that name. Had I renamed the private repo and recreated a public repo under the old
name without touching the live clone, GitHub's redirect would resolve the live `origin` to the
**new public** repo — so the user's next routine `git push` from their working OS would silently
ship all private content into the public twin. The collision wasn't visible from the fork's
directory at all; only querying the remote surfaced it.

## How to apply
Before `gh repo create <name> --public`, query the target name (`gh repo view <owner>/<name>`)
and the live repo's remotes (`git remote -v`). If the name is free, proceed. If it's held by a
private repo: rename the private one, **then immediately repoint any local clone whose `origin`
used the old URL** (`git remote set-url origin <new-url>`) *before* creating the public
same-name repo — the GitHub redirect re-binds the old URL to whatever takes the name next, so a
stale `origin` becomes a leak channel. Never `--force`-push onto a non-empty repo you didn't
just create. Surface the collision to the user and let them choose the name (a separate
`-public`/`-os` repo avoids the rename-and-repoint dance entirely). This is the irreversible-
publication sibling of [[sanitization-fingerprints-survive-token-swap]]: the content was clean;
the *plumbing* was the leak.
