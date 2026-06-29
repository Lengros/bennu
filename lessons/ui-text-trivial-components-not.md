# UI Work: Text Is Trivial, Components Are Not
date: 2026-04-04
scope: delegation
rule: Text/label/copy is inline-eligible; component props, variants, layout, and component choice always delegate regardless of line count.

## Why
"It's just 3 lines" was used to justify inline edits of component props. The cascade effects of component property changes are not bounded by line count; they ripple through all uses of the component. The line-count heuristic is wrong for components.

## How to apply
Before an inline UI edit: is this changing visible text/labels only? → inline OK. Is it changing any component property, variant, layout relationship, or component selection? → delegate, regardless of how few lines it appears to be.
