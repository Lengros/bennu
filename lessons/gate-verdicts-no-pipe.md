# Gate Verdicts Must Not Pass Through a Pipe Before a Mutating Action
date: 2026-06-05
scope: verification
rule: Run validators bare (no pipe, no filter); gate check and gated action in separate Bash calls; pipe exit != gate exit.

## Why
A gate check piped through tail reported the pipe's exit code, not the gate's. The mutating action that followed was supposed to be blocked but ran because the pipe exit was 0. "cmd && echo OK" after a pipe reports whether the pipe succeeded, not whether the gate passed.

## How to apply
Validator calls: run bare, capture output to a variable or file if you need to trim it, then check the captured result. Gate check and gated action must be in separate Bash calls — never in one "check && act" pipeline chain. Honest form: run cmd, then echo "exit=$?" separately.

## Disposition
Split from "Gate verdicts must never pass through a pipe before a mutating action" (2026-06-05). Portable principle (this file): run validators bare, separate gate check from gated action. Legacy hook/gate wiring details: dropped.
