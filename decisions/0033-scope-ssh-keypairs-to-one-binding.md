# ADR 0033: Scope each SSH keypair to one binding

- Status: Deferred research - non-authoritative for v0.1
- Date: 2026-08-02

## Context

The initial security notes allow a dedicated SSH key per deployment or target group. A policy target group is an orchestration concept, however, and can span destinations with different administrators and trust. Sharing a key couples compromise, rotation, and retirement across every target that accepts it.

## Decision

Each restricted SSH executor binding owns one unique keypair.

- A private key is never reused by another binding, target, installation, or administrator workflow.
- NUTMerlin-generated keys are the standard onboarding path; any future import path must require a binding-dedicated key and cannot turn an existing general-purpose key into a supported configuration.
- Batch or group onboarding may automate creation and display of several distinct public keys but never shares private material.
- The public key may be redisplayed for target setup; the private key is never returned by normal product interfaces or included in export.
- Removing a binding removes its project-owned private key only after policy and in-progress action dependency checks succeed.
- Key replacement affects one binding and preserves the old binding configuration only for an explicitly designed cutover interval; automatic group rotation is not implied.
- Clean uninstall removes all project-owned SSH private keys.

## Consequences

- Fleets require more target-side public-key entries and secret files.
- Disclosure and revocation remain isolated to one execution path.
- Tests must prove key inequality, secret redaction, and target-group independence.

## Rejected alternative

One keypair per administrator-defined trust group would reduce setup work, but would make every group member depend on the same private-key lifecycle and expand the impact of disclosure.
