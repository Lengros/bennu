# Seed Reviewer/Grading Briefs With the Relevant Domain Lessons

date: 2026-06-18
scope: delegation
rule: Seed review/grading briefs with the relevant domain lessons — a fresh agent inventing its own criteria can contradict a recorded lesson.

## Why
Comparing two versions of a requirements matrix, I cast a `requirements_quality_reviewer` and let it "augment the rubric with comparison-specific axes." Both the persona card I synthesized AND the delegated audit invented an axis — "honesty-about-reality: does the matrix show what is built vs greenfield" — and graded the version that kept a per-row prototype-maturity column as *better* for it. That directly contradicts [[requirements-target-production-not-prototype]]: a requirements matrix is a production scope contract, engineering owns HOW, and carrying prototype de-risking misleads the team into reading scope as done. The reviewer couldn't have known — I never put the lesson in the brief. The wrong verdict then propagated into the audit artifact and the persona card before the user caught it.

## How to apply
- Before delegating a review/audit/grading task, list the domain lessons that bound *what good looks like* for this artifact type, and embed them in the brief as constraints (not just the rubric).
- Treat "augment the criteria yourself" as a licence to add anti-lesson axes unless the agent is told which axes are already settled (and forbidden).
- A rubric is not self-sufficient: a rubric clause like "grounded — traceable to prototype" gets read by a cold reader as "show maturity." Pair the rubric with the lesson that disambiguates it (grounding = sourced/real, not built).
- When a delegated review's verdict hinges on a criterion, check that criterion against the lesson index before accepting it.

## Disposition
Extends [[always-synthesize-executor-context]] (REASON→CHECK→BRIEF) to review tasks: the BRIEF must carry settled domain lessons, not only the goal + rubric. Sharpens the application of [[requirements-target-production-not-prototype]] to requirements-matrix grading: a per-row maturity/build-status column is a defect in a requirements matrix, not a strength.
