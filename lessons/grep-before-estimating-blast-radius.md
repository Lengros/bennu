# Grep Before Estimating Blast Radius
date: 2026-03-28
scope: process
rule: Real scope equals the grep hit count for the entity being changed, not the files you remember; always grep before estimating blast radius.

## Why
Estimated 5 files affected by a change; grep found 16. The discrepancy caused under-scoped planning and rework when the un-anticipated files surfaced mid-execution.

## How to apply
Before planning any change to a named entity (function, type, config key, rule, interface): grep for the entity name (and its variants) across the repo. Use the hit count as your blast radius baseline. Do not accept memory-based scope estimates.
