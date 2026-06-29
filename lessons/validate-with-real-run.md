# Validate New Processes With a Real Run
date: 2026-03-28
scope: process
rule: Design → implement → exercise on one real task (explicitly labeled as validation) → accept; design validation is not operational validation.

## Why
A new process was accepted after passing a design review and internal consistency check. It failed on the first real use because design validation cannot surface operational friction that only appears with actual inputs and actual actors under real time pressure.

## How to apply
After implementing any new process or protocol: run it explicitly on one real task (not a toy scenario) before treating it as validated. Label the run "validation run" so the results are evaluated against the process's intentions. Only after a clean validation run does the process graduate to standard procedure.
