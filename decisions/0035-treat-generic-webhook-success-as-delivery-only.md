# ADR 0035: Treat generic webhook success as delivery acceptance only

- Status: Deferred research - non-authoritative for v0.1
- Date: 2026-08-02

## Context

A generic webhook receiver can return an HTTP success response after parsing, queueing, or discarding work without establishing the state of any downstream target. Treating a configurable status code as completed shutdown or load shedding could advance a safety sequence on an assertion the receiver never made.

## Decision

A successful generic webhook response establishes delivery acceptance only.

- An allowed HTTP `2xx` response records `delivery_accepted`, not verified target-state success.
- Generic webhook operations publish normalized notifications that an external system may consume and act on independently, but carry no NUTMerlin typed target-action request and retain the delivery-only vocabulary.
- A generic response cannot verify host shutdown, service stop, outlet state, or any other downstream side effect.
- A generic webhook result cannot satisfy a destructive escalation prerequisite.
- Policies requiring target-state evidence use another eligible binding or a separately qualified webhook action protocol.
- A qualified webhook action protocol must define authenticated HTTPS transport, versioned typed operations, stable idempotency and correlation IDs, structured response meanings, and a status-verification mechanism.
- Configuration cannot relabel an arbitrary status code or response body as verified completion without selecting and validating such a protocol profile.

## Consequences

- Generic Home Assistant, Node-RED, and notification integrations remain straightforward but cannot overstate what NUTMerlin observed.
- Action-capable webhook integrations require a stronger interoperable contract or cross-protocol verification.
- UI and audit result schemas distinguish delivery, action acceptance, and verified target state.

## Rejected alternative

Allowing each webhook binding to declare selected HTTP status codes as completed action would integrate arbitrary services easily, but would make safety semantics depend on unstructured administrator assertions.
