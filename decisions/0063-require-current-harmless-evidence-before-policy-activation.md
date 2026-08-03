# ADR 0063: Require current harmless evidence before policy activation

- Status: Deferred research - non-authoritative for v0.1
- Date: 2026-08-02

## Context

Static validation can prove schema and policy relationships but not target identity, transport trust, credentials, or executor capability. A real shutdown trial would provide stronger evidence but is inappropriate as an activation prerequisite. Allowing unreachable or untested bindings to become active would turn later outage execution into their first integration test.

## Decision

Every executable policy version requires current harmless activation evidence.

- Mutable policy drafts are never executable and cannot receive event episodes.
- Static validation covers schemas, operation versions, thresholds, conflicts, dependencies, action budgets, target protections, feature gates, and current platform capabilities.
- Every referenced executor binding and required verification path must pass its contract's harmless `test` operation.
- The exact candidate policy version must complete a dry-run that evaluates representative trigger, cancellation, ordering, conflict, dependency, budget, commitment, and redaction behavior without target side effects.
- Blocking findings must be resolved. Nonblocking warnings require explicit acknowledgement recorded with the candidate version.
- Binding-test and dry-run evidence remains usable for 24 hours and expires immediately if the candidate, target identity, binding configuration, credential, trust material, discovered capability, operation contract, or relevant platform state changes.
- Activation atomically records the evidence and creates the immutable enabled policy version; it never mutates the draft into executable state in place.
- A dry-run establishes planning and adapter behavior only. UI, CLI, documentation, and audit output must not describe it as proof that a host will shut down or a downstream effect will complete.
- An active policy does not expire merely because its activation evidence becomes older than 24 hours. Runtime capability or trust drift inhibits affected dispatch and requires revalidation before a new version or reactivation.
- Offline provisioning may create complete drafts, but an unreachable binding cannot receive active policy authority.

## Consequences

- Outage execution is not the first time NUTMerlin validates a credential, certificate, host key, forced command, or endpoint capability.
- Activation requires targets to be available within the preceding day, while normal operation does not depend on daily testing.
- Tests and UIs need evidence provenance, invalidation causes, warning acknowledgements, exact candidate hashes, and dry-run limitations.
- Imported, restored, or migrated policies naturally remain inert until they establish current evidence.

## Rejected alternatives

Warning-only activation while a target is unreachable would support more offline setup but could create active automation with no connection evidence. Requiring a real shutdown or service stop would provide stronger proof but would make safe routine activation impractical.
