# ADR 0044: Protect external network infrastructure by default

- Status: Deferred research - non-authoritative for v0.1
- Date: 2026-08-02

## Context

External network equipment may be essential to dispatch and verify later actions, receive notifications, or let NUT clients observe the UPS. Permanently excluding every switch, access point, gateway, and similar device would nevertheless prevent legitimate terminal shedding of noncritical lab or secondary network equipment.

The repository calls for target exclusions but has no topology or dependency contract.

## Decision

External network-infrastructure targets are protected by default but may be made eligible in an explicit terminal infrastructure stage.

- The administrator must explicitly classify the target as infrastructure and explicitly remove its default shedding protection for the selected immutable policy version.
- Activation requires a declaration that the target is not needed to dispatch, observe, or verify any remaining work in the policy episode.
- NUTMerlin validates declared dependencies and any control-path facts it can establish; a declared, detected, or ambiguous dependency remains protected.
- A terminal infrastructure stage is last. It cannot be followed by another remote action, required remote verification, or notification whose delivery depends on a target in that stage.
- The coordinator router remains absolutely excluded under ADR 0043.
- P1 infrastructure actions remain host- or service-level graceful typed operations. UPS and PDU output-cutting operations remain `Later` under ADR 0039.
- Loss of reachability after dispatch does not by itself prove that an infrastructure target shut down successfully.

## Consequences

- Common configurations retain the network path needed for shutdown coordination and diagnostics.
- Advanced users can shed clearly noncritical network equipment without making every network device action-capable by default.
- Target configuration and policy activation need explicit infrastructure roles and dependency validation.
- Tests must cover protected defaults, explicit terminal eligibility, dependency conflicts, ambiguous topology, ordering, and post-dispatch reachability loss.

## Rejected alternative

Structurally excluding all external network infrastructure through P2 would simplify validation and maximize availability, but would unnecessarily prohibit safe terminal shutdown of independently connected noncritical equipment.
