# When Blocked, Return to Dialogue
date: 2026-06-08
scope: process
rule: A block before the task is confirmed means intent isn't settled — stop touching machinery and return to dialogue.

## Why
A gate block before the task was confirmed with the user triggered attempts to resolve the block mechanically — adjusting schemas and retrying. The real issue was that intent had not been established. Fixing the machinery without confirming the goal wastes effort and can cement the wrong direction.

## How to apply
When a tool, gate, or schema error occurs before the user's goal is confirmed: stop. Do not attempt to resolve the technical error. Return to the conversation: restate what you understood the goal to be, raise any open questions, sketch the approach, get explicit confirmation. Only then address the technical error in the context of the confirmed task.

## Disposition
Split from "A gate block is never a reason to grind on mechanics in silence" (2026-06-08). Portable principle (this file): confirm intent before fixing machinery. Legacy predecessor-specific references: dropped.
