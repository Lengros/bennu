# Porting an external skill into Bennu — strip the chrome, attribute, cold-read

date: 2026-06-20
scope: skills
rule: port an external skill as raw material: strip its marketing chrome, refit to Bennu naming/voice, attribute the source, then cold-read.

## What happened

Evaluated `emilkowalski/skills` (Emil Kowalski's design-engineering skills, no LICENSE file)
against Bennu's design skills. Found a real gap: nothing covered web **motion craft** (easing,
timing, springs, origin, interruptibility) — `sprite-anim` is only frame-normalization + CDP
verification. Ported the two donors into `/motion` (knowledge) + `/review-motion` (a SKEPTIC
variant with its own `STANDARDS.md`). Cold-read by a fresh subagent returned PASS with 3 nits.

## The recipe (reusable)

1. **Confirm the gap first** — grep our own skills for the capability before porting. A donor
   that duplicates what we have is not reuse.
2. **Strip authorial chrome** — the donor's `emil-design-eng` had an "Initial Response" that
   forced a canned ad for the author's course. Marketing gates, first-person pitches, and
   "subscribe / take my course" lines never survive the port. A single *attributional* citation
   to the source is fine and expected; a sales pitch is leakage.
3. **Refit to Bennu conventions** — unprefixed-verb name matching the dir; a description with a
   NOT-for cross-ref and EN+RU triggers; a sibling-positioning paragraph (how it relates to
   `/design`, `/prototype`, `/diagram`, `/sprite-anim`); "Core principle" framing.
4. **Attribute in-body** like `/sprite-anim` ("Adapted from … , ported YYYY-MM-DD"). No LICENSE
   in the source repo → adapt-with-attribution, not a verbatim copy.
5. **Split knowledge from reviewer** — donor mixed craft knowledge with a review checklist. In
   Bennu that's two skills: a knowledge skill (auto-discoverable) and a review skill
   (`disable-model-invocation: true`, mapped onto our PASS / PASS-WITH-CHANGES / FAIL).
6. **Cold-read before live** (mandatory — [[cold-read-skills-before-registering]]). The skill is
   live the moment the file exists, so the cold read happens right after writing; catch and fix
   leakage/broken cross-refs immediately.

## Why it matters

Memory flagged external-skill-acquisition as an unbuilt pipeline (the Scout gap). This run shows
the **manual** port is cheap and clean when you treat the donor as raw material, not a finished
part. The failure mode to avoid is dropping a foreign skill in whole — its naming, voice, and
marketing then propagate to every future session.
