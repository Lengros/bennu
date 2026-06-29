# Verify Tooling Mechanism, Don't Use the User as a Test Harness
date: 2026-06-20
scope: verification
rule: Can't observe a tooling fix? Verify the setting AND its scope from docs first; one decisive change, don't iterate through the user.

## Why
A trivial Zed request — "show the gitignored `.scratch` folder in the project tree" —
took four round-trips because I guessed instead of verifying the mechanism. I tried
`file_scan_inclusions` (wrong: controls scanning, not panel display), then a
project-local `.zed/settings.json` with `hide_gitignore: false` (wrong scope: the
project panel reads `hide_gitignore` from USER/global settings, not project-local),
then told the user to reload/restart twice — making him the test loop for my guesses.
He called it: "I asked for one thing, you didn't do it." I had confirmed the right
*setting* but never its *scope* — a setting name being correct doesn't mean the place
you wrote it is honored. UI/panel-level settings especially are often not overridable
per-project, because the panel is a workspace-global element. Outsourcing each
verification to a user reload reads as flailing and burns their trust on a 5-minute task.

## How to apply
For any tooling fix whose effect I cannot directly observe:
1. Pin down BOTH the setting and its scope (global vs project vs workspace) from the
   docs/source before writing anything — one authoritative lookup, not trial-and-error.
2. Make ONE decisive change at the level actually read, with a backup.
3. State confidence honestly; if a reload/restart is genuinely required, say it once —
   never iterate "try reload" as a substitute for knowing the mechanism.

Concrete facts: Zed `project_panel.hide_gitignore` is read from global
`~/.config/zed/settings.json`; a project-local `.zed/settings.json` does NOT override it
for the panel. `file_scan_inclusions` affects indexing/scanning, not gitignore panel
hiding. There is no per-project way to un-hide gitignored entries in the panel.

## Disposition
First occurrence (Zed `.scratch` visibility, 2026-06-20). Pattern: if I again iterate a
tooling fix through the user instead of verifying scope up front, extract a checklist or
pre-write verification step as standing machinery.
