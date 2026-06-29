# A Narrowed Check Inherits the Shape You Tested It Against
date: 2026-06-10
scope: verification
rule: Before tightening a validator, enumerate every legitimate input shape; a check fitted to one shape fails-closed on the valid others.

## Why
An identifier extractor was tightened to require field A populated with one specific shape — the value the first kind of issuer emits. But a second, equally legitimate issuer carries the same identifier in a different field B, in a different shape, and omits field A entirely — so the "hardened" check rejected a valid credential ("no readable identifier"). The narrowing had been validated only against the first issuer's vector, baking that single shape into a security gate one session before it broke the second path.

## How to apply
When narrowing an accept-rule, first list every legitimate producer and shape of the input (here: issuer A puts the value in field A; issuer B puts it in field B and omits A) and add a test per shape. When identity is already established upstream by a stronger authority, prefer that authority over re-deriving it from a variable artifact like a signed credential's subject. Relate: see "Absence-Based Carve-Outs Are Fail-Open".
