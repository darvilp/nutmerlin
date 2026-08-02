# ADR 0042: Default to monitoring only

- Status: Accepted
- Date: 2026-08-02

## Context

The initial architecture shows read-only NUT access enabled with empty policy and target collections, but does not establish whether installation, import, or upgrade may activate policy behavior. Even a notification-only publisher sends operational information off the router, while a state-changing executor can interrupt a target. Examples and migrations must not silently cross that boundary.

## Decision

NUTMerlin defaults to monitoring only.

- A fresh installation may collect UPS status, serve separately authorized NUT access, display diagnostics, and maintain bounded local event and audit history.
- It has no enabled policy action, executor dispatch, shutdown-client credential, webhook publication, or MQTT publication.
- Examples, templates, imported policies, and restored policy definitions are inert until explicitly validated and activated by an administrator.
- An upgrade preserves an already enabled immutable policy version only when the upgrade does not change that version's executable semantics or required security contract.
- A migration or release that adds, broadens, or reinterprets an operation leaves the affected capability disabled until explicit validation and activation.
- Dry-run and harmless tests do not constitute activation and cannot silently transition a policy into active execution.
- Internal status collection and bounded local event history are observation facilities, not implicitly enabled policy actions.

## Consequences

- Fresh installation and newly introduced features cannot cause target changes or outbound disclosure without an explicit administrator decision.
- Onboarding must make activation state visible and distinguish observation, testing, and execution.
- Some upgrades may require administrators to review and reactivate affected policies rather than preserving automation silently.
- Installation, import, restore, and migration tests must prove that inert definitions remain inactive.

## Rejected alternative

Enabling a built-in local-only notification policy would demonstrate policy behavior immediately without outbound traffic or target changes, but would blur the boundary between passive observation and explicitly activated automation.
