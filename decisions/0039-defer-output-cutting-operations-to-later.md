# ADR 0039: Defer UPS and PDU output-cutting operations to Later

- Status: Accepted
- Date: 2026-08-02

## Context

The initial roadmap places outlet-group shedding in P1 and SNMP/PDU or UPS administrative commands in P2. Physical output-off, delayed load-off, and power-cycle operations can remove power from routers, storage, or every device on a UPS, while ordinary automated tests are prohibited from invoking them and simulators cannot establish device-specific timing or restoration behavior.

Production FSD also now requires a separately complete and qualified output/power-restoration design.

## Decision

All UPS or PDU operations capable of cutting, cycling, or delaying output are `Later`, outside P1 and P2 release commitments.

- P1 load shedding uses host- or service-level graceful actions only.
- P2 may display read-only UPS/PDU status supplied through an installed validated NUT driver profile, but provides no direct SNMP/PDU discovery and exposes no output-changing typed operation under ADRs 0073 and 0074.
- Ordinary releases contain no policy operation or executor mapping for `load.off`, `shutdown.return`, `shutdown.stayoff`, PDU outlet-off, or equivalents.
- Existing general administrative-command gates do not authorize output control.
- `NUTMERLIN_ALLOW_UPS_COMMANDS` continues not to authorize an output-cutting command.
- Harmless administrative operations such as a qualified self-test or beeper control require their own classification and do not imply output authority.
- A future output-control phase requires a separate ADR, exact device and firmware qualification, disposable-load physical tests, restoration tests, explicit release support tier, and at least global, target, and action enablement before policy reference.
- The future phase must reconcile complete FSD workflow requirements before claiming coordinated power cycling.

## Consequences

- P1/P2 cannot provide UPS outlet load shedding or a complete production FSD power cycle.
- Read-only discovery can inform later research without creating a dormant destructive command path.
- Roadmap and requirements language that implies nearer output control must move to `Later` during reconciliation.

## Rejected alternative

Keeping output control in P2 behind capability discovery, device allowlists, and triple opt-in would preserve roadmap momentum, but would create pressure to ship behavior that cannot receive ordinary automated safety coverage and lacks broad hardware qualification.
