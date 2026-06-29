# Delegation Transport: In-Session Default
date: 2026-06-05
scope: delegation
rule: Default to in-session subagents for code/spec/analysis/doc; reserve tmux for specialist MCP toolsets, live observation, or outliving runs.

## Why
Four increments were shipped through tmux (designer + executor panes, send-keys, callback polling) for work that needed only file + bash tools. The transport rig — not the kernel — was the bottleneck: ~9 dispatches, each costing 3-5 pure-plumbing tool calls, with context lost between increments. None of the specialist MCP tools were actually used.

## How to apply
Default: in-session Agent subagent — brief delivered atomically, result returns in-turn, parallel fan-out via concurrent Agent calls. Encode specialist framing in the subagent prompt. Switch to tmux only when one holds: (a) task exercises a specialist MCP toolset the subagent lacks; (b) user wants live-pane observation; (c) run must outlive the Curator session. When user says "the system feels slow", diagnose: kernel governance (often dormant) vs. inter-agent transport (often the actual load).

## Disposition
Kept verbatim per Bennu §3.3.
