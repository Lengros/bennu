# Reconnaissance Before Decomposition
date: 2026-04-11
scope: process
rule: Read affected code before splitting work; decompose by concern, not by file; cross-cutting concerns become explicit subtasks or constraints.

## Why
Work decomposed without reading the code produced subtasks that split along file boundaries rather than concern boundaries. Cross-cutting concerns (shared types, event contracts, auth) were missed and had to be retrofitted mid-execution.

## How to apply
Before decomposing a task: read the affected files and name the cross-cutting concerns explicitly. Concerns that touch multiple subtasks become either a dedicated up-front subtask or a constraint injected into every dependent brief. If you cannot name the cross-cutting concerns, you have not read enough code.
