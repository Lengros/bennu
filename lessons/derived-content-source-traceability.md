# Derived Content Requires Source Traceability
date: 2026-04-05
scope: content
rule: Every factual claim in agent-generated text must reference its source location (section/line/field) or be marked [ASSUMPTION].

## Why
An agent generating documentation from a source document invented plausible-sounding details that were not in the source. Without source references, reviewers could not distinguish facts from inventions.

## How to apply
Brief any content-generating agent: every factual claim cites the source location (section name, line range, field name) or is explicitly tagged [ASSUMPTION]. At review: any untagged factual claim that you cannot verify from the source is treated as [ASSUMPTION] until traced.
