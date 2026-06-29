# Simulated Eval Is Not Eval
date: 2026-03-28
scope: verification
rule: Eval must produce actual artifacts and scores; imagined runs are fiction — give the protocol to an agent on a real scenario and observe.

## Why
A protocol change was evaluated by mentally simulating what an agent would do. The simulation matched intent, not behavior. When the protocol was actually run, the agent produced outputs the simulation had not predicted.

## How to apply
To evaluate a protocol or process rule: (1) give it to an agent with a concrete test scenario; (2) observe the actual output and behavior; (3) score against explicit criteria. "It should work because the logic is sound" is not a passing eval. Artifacts and scores required.
