# ADR 0036: Make the MQTT integration publish-only

- Status: Deferred research - non-authoritative for v0.1
- Date: 2026-08-02

## Context

The requirements call for publishing normalized events and results, while the initial plan also mentions optional command topics. Subscribing would turn an outbound integration into a router control plane whose safety depends on broker ACLs, publisher identity, retained-message replay, duplicate delivery, expiration, and message authorization.

## Decision

The P1 MQTT integration is publish-only.

- NUTMerlin does not subscribe to command, configuration, policy, or action topics.
- Each MQTT binding uses a credential whose broker ACL permits publication only to that deployment's configured topic prefix and grants no subscribe or administrative privilege.
- Broker publication acknowledgement records delivery acceptance only and never verifies downstream automation or target state.
- External systems may subscribe and act independently, but their behavior and messages do not become NUTMerlin policy authorization.
- MQTT input cannot enable features, cross a commit boundary, retry an action, or satisfy verification.
- Any future inbound protocol requires a separate feature surface, credential, threat model, replay design, and ADR rather than an option on this binding.
- Optional command/result topics are removed from the current P1 plan; action-result publication remains outbound telemetry.

## Consequences

- MQTT has a smaller credential and message-processing attack surface.
- Bidirectional orchestration requires another explicitly designed integration.
- Tests must prove the client never subscribes and that broker ACLs reject subscription with its credential.

## Rejected alternative

A secured command prefix with distinct credentials, schemas, signatures, nonces, expiration, and idempotency could support remote orchestration, but would add a substantial inbound authorization surface unrelated to notification publishing.
