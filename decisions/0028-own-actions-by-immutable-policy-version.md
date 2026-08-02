# ADR 0028: Own actions by an immutable policy version

- Status: Accepted
- Date: 2026-08-02

## Context

Targets are reusable logical destinations, but an action's operation, ordering, timeout, retry, verification, and commitment settings form part of one policy's safety meaning. A live shared action definition would allow one edit to alter several enabled policies or an outage episode already in progress.

## Decision

Every executable action is owned by exactly one immutable policy version.

- Each action has a stable ID within its owning policy version.
- Enabling or changing policy behavior creates a new immutable version rather than mutating the active version in place.
- A new event episode captures the applicable policy version and complete ordered action configuration.
- An in-progress episode continues with its captured version despite later policy edits, disablement rules excepted only where an explicit emergency-stop contract permits them.
- Reusable action templates are copy-on-create authoring aids and are never live executable references.
- Actions reference logical target and eligible binding IDs but do not embed endpoint credentials or secret values.
- Deleting a target or binding referenced by an enabled or retained in-progress policy version is refused until the dependency is safely removed or resolved.
- Audit records identify the exact policy version and action ID used.
- Prospective emergency inhibition follows ADR 0092, and immutable-version retention follows ADR 0094.

## Consequences

- Policy behavior is reproducible across restart and auditable after later edits.
- Repeating similar actions across policies duplicates some non-secret configuration.
- Storage, migration, and UI flows need explicit draft, validation, activation, and version identity.

## Rejected alternative

A live shared action library would reduce repeated configuration, but a single edit could change several active safety policies without each policy receiving a visible new version.
