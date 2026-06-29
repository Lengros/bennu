# Blast-Radius Grep Is Two-Pass
date: 2026-04-17
scope: process
rule: Two-pass blast radius: forward (where is X mentioned?) plus reverse (who references the edited files?); merge hits into one table.

## Why
A single forward-concept grep missed files that referenced the edited file by path under a different vocabulary. The reverse pass (who imports or calls this file?) surfaced the missing entries. Both passes together constitute a complete blast radius.

## How to apply
For any change with external dependencies: (1) forward pass — grep for the concept names, type names, function names being changed; (2) reverse pass — grep for the path of every file being edited (who imports it? who references it by name?). Merge all hits into a single blast table. Use both for every medium+ risk change.
