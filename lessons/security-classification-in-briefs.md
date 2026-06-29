# Security Classification in Executor Synthesis
date: 2026-04-11
scope: delegation
rule: In REASON ask 'is this enforcement or security code?'; if yes, require adversarial test scenarios in the Specialist brief.

## Why
Hooks, gates, validators, and auth code were briefed the same way as feature code. Security-relevant executors need adversarial scenarios (attacker inputs, bypass attempts) that generic briefs do not include — and this cannot be added after the brief is written.

## How to apply
In the REASON step of executor synthesis: add the question "is this enforcement, security, auth, gate, validator, or whitelist code?" If any answer is yes: set security_relevant:true in the brief, add at least two adversarial scenarios (what does this look like with an attacker payload?), and require justification for any "don't change X" constraints on the security surface.
