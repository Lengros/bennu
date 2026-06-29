# Bennu

**A thin orchestration operating system for [Claude Code](https://claude.com/claude-code).**
Bennu keeps the *epistemics* — the discipline that makes
agent output trustworthy — and discards the enforcement machinery that grew up around them.
The platform owns the mechanics (worktrees, plan mode, subagents, skills, memory); Bennu
adds only judgment and domain knowledge.

---

## Why it exists

An earlier iteration of this system concentrated its real value in ~600 lines of epistemics —
evidence tags, a fresh-context skeptic, external cold-read, the retro→lessons loop, a
pushback protocol — buried under ~17,000 lines of enforcement: hooks, markers, lanes,
checkpoint YAMLs, and their tests. An audit found that **~76% of tickets and ~95% of recent
commits serviced the machinery itself**, the system fought itself far more often than it
caught a real external problem, and startup cost ~38.7k tokens per session.

Bennu keeps the 600 lines that worked and throws away the rest. The bet: on a 2026-era
agent platform, **judgment beats gates**, and most of the scaffolding was compensating for
capabilities the platform now provides natively.

## What it gives you

- **Trustworthy output, not just fast output.** Every claim about existing code carries an
  `[Observed: path:lines]` evidence tag or is marked `[ASSUMPTION]`. Medium-or-higher-risk
  work is verified by a *fresh-context skeptic* that never saw the drafting — the author
  never grades their own homework.
- **Right-sized process.** Risk is classified per task (blast radius × reversibility ×
  external visibility). Low-risk work just goes; medium+ work runs through the platform's
  plan mode and an independent review. No ceremony where it isn't earned.
- **A system that learns.** Surprises, failures, and user corrections become **lessons** on
  first occurrence; patterns seen twice become a **tool or skill**. A scheduled `/retro`
  turns telemetry + lessons into a friction report with prune proposals.
- **Cheap startup.** ≤ 8k token budget at session start (vs ~38.7k before): load a one-line
  lesson index, pull bodies only on demand.
- **Domain memory.** Project map, branch/flow policies, and behavioral feedback persist
  across sessions so the agent doesn't relearn your conventions every time.

## The operating loop

Every piece of work runs the same six stages. Judgment, not gates, carries it:

```
INTENT → CAST → EXECUTE (embody | delegate) → SKEPTIC → SHIP → LEARN
```

| Stage | What happens |
|---|---|
| **INTENT** | Settle the *true* goal (not the literal ask), name the user-visible result + a 3–7 item definition of done, classify risk. Medium+ risk runs inside plan mode. |
| **CAST** | Hire the right executor: reason out the competencies this task needs, check `personas/` for a reusable card, synthesize one if none fits. |
| **EXECUTE** | **Embody** synthesis-shaped work (analysis, decisions, point edits the user verifies in-loop); **delegate** artifact-shaped work to a fresh subagent (specs, production code, research). Tiebreak: embody the judgment, delegate the artifact. |
| **SKEPTIC** | An independent reviewer tuned to how *this* artifact fails, run with no drafting context. Its verdict (PASS / PASS-WITH-CHANGES / FAIL) is binding. |
| **SHIP** | Deliver turnkey: paths first, verified-vs-assumed stated plainly, the user's launch path walked end-to-end. Record the run. |
| **LEARN** | Capture lessons, extract tools/skills on repeat, feed the retro loop. |

## Hard rules

1. **Never self-review** medium+ artifacts — fresh subagent or cold read.
2. **Never fabricate** — evidence tags on every claim about existing state.
3. **No secrets in artifacts** — enforced by a scan hook.
4. **Code changes → branch/worktree; docs/config-of-this-system → direct edit.**
5. **Apply user corrections session-wide and durably** — corrections become lessons same-day.

Everything else is judgment, informed by lessons.

## Repository layout

| Path | What it holds |
|---|---|
| `CLAUDE.md` | The operating system itself — the instructions the orchestrator follows. |
| `core/` | The expandable guides: `casting.md` (persona + brief), `skeptic.md` (review). |
| `lessons/` | `INDEX.md` (one line per lesson, loaded at startup) + per-lesson bodies. |
| `personas/` | Reusable persona cards for casting. |
| `tools/` | Shell utilities: run logging, lesson digest, secret/citation scans. |
| `tests/` | Test suites for the hooks and tools. |
| `.claude/` | Hooks (path guard, secret scan, telemetry) and the `/retro` skill. |
| `PROJECT_REGISTRY.yaml` | Per-project paths, branch policies, and flow blocks. |

## Setup

After cloning, run the bootstrap once (per clone — `core.hooksPath` is local config and
isn't carried by the repo):

```sh
./setup.sh
```

It points git at the versioned hooks and restores their executable bit. Equivalent to
`git config core.hooksPath .githooks`, just idempotent and re-runnable.

This activates a **pre-commit secret scan**: `.githooks/pre-commit` runs
`tools/scan-secrets.sh` over the *staged* content of each commit and blocks it if a
vendor-credential shape (AWS/OpenAI/GitHub/Slack/Google/PEM) is found. It fails open on any
tooling error (tripwire, not jail). To bypass when knowingly committing a test fixture:
`git commit --no-verify`.

## Telemetry & retro

Hooks record session and run events to `telemetry/*.jsonl` (gitignored — never pushed). The
`/retro` skill consumes that telemetry plus the lessons index to produce a six-section
friction/health report with prune proposals. It *proposes*; the user decides — nothing is
auto-applied or auto-archived.

---

*Bennu adds only what the platform doesn't: epistemics and domain memory. Where Claude Code
already does the job, Bennu stays out of the way.*
