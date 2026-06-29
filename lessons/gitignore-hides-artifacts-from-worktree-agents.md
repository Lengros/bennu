# Gitignore Hides Internal Artifacts From Worktree-Delegated Agents — Fence by Folder, Not .gitignore

date: 2026-06-26
scope: project-structure / delegation
rule: Don't .gitignore internal artifacts; they vanish in fresh worktrees, hidden from delegated agents. Fence in a tracked folder instead.

## What happened

A docs cleanup. The user proposed two ways to separate dev-facing product docs
from internal AI-working artifacts: (A) move the internal set into a **gitignored**,
local-only folder ("только для нас, для локальной разработки через AI-агентов"), or (B) split
into two **tracked** folders. The stated purpose of (A) — feed local AI-agent development — is
exactly the workflow gitignore breaks.

The service's registry `flow:` delegates work to **git worktrees** from a working branch. A
`git worktree add` checks out *tracked* files at a commit; untracked/ignored files in the
original working dir are **not** copied into the new worktree. So gitignoring research/,
evidence-ledger, market-scans, and design rationale would make every delegated subagent (and
the fresh-context skeptic, and any cold-read) **blind to precisely the grounding meant for
them**. Plus: no history, no backup, lost if the machine dies.

Chose (B): both tiers tracked — `docs/` = product canon, `workshop/` = internal — and keep
`workshop/` off `main` via the PR/merge boundary, not gitignore.

## The lesson

When the goal is "available to us and to agents, but not part of the dev-facing/shipped
surface," the reflex to `.gitignore` is wrong for any system that delegates into worktrees.
Gitignore buys local-only + no history + no backup **and** worktree-invisibility — the
opposite of what an agent-grounding artifact needs. **Fence by folder instead:** track the
internal tier in a clearly-named directory (e.g. `workshop/`) and keep it out of the shipped
branch via the branch/merge boundary. Tracked-but-fenced gives durability, history, and
worktree/agent reachability; gitignore gives none of them. Same reasoning applies to any
worktree-isolation delegation (`isolation: "worktree"`), not just this repo.
