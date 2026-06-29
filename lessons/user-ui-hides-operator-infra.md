# A user-facing UI shows the user's own resources, never our operator infrastructure
date: 2026-06-11
scope: product-design
rule: In an end-user UI the user authorizes only their own resources; our infra (bots, tokens, SMTP) is assumed present, never user-configured.

## Why
Building the app's Notifications block, a user-facing screen rendered an
operator-only placeholder (an unset service token) because it exposed
backend/operator state the end user can neither see nor set. The user corrected the
whole framing: *the user does not create our tooling.* The delivery service
is the operator's — already created, always present in production.
The user only **enables** delivery and points it at **their own** target — just
as they authorize **their** own external accounts, not ours. Surfacing
an operator/deployment detail (a service token) in the user's face is a category error:
it asks the user to provision infrastructure that is the operator's, not theirs.

## How to apply
- Split every feature's inputs into two buckets before designing the UI:
  **user-owned** (their accounts, their destination, their email → the user
  authorizes/links these) vs **our infrastructure** (the notification service, API keys,
  the SMTP sender, the delivery channel → assumed present, configured by the operator at
  deploy, invisible to the user).
- A user-facing affordance for an infra resource should be "Connect" / "Enable",
  never "set <ENV_VAR>" or "create a service". Design the happy path for production
  where the infra always exists; treat a missing-infra state as a neutral,
  non-leaky degradation ("not available right now"), handled in operator logs.
- Tokens, env-var names, and provisioning steps belong in deploy docs and logs —
  never in the product UI.

Related miss in the same artifact: the section was written in a different language than
the rest of the UI — author UI copy in the surrounding UI's language and
tone, checked first, not the language of the chat.
