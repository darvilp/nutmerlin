# ADR 0003: Separate reversible outage actions from committed shutdown

- Status: Deferred research - non-authoritative for v0.1
- Date: 2026-08-01

## Context

A short outage grace period should be canceled when utility power returns. NUT FSD is designed for coordinated shutdown and remains latched until the data server is restarted.

## Decision

The policy model has two distinct phases:

1. **Reversible** — pending or active actions may be canceled by recovery.
2. **Committed** — the shutdown sequence completes even if utility returns.

FSD is available only in the committed phase and is an advanced feature.

## Consequences

- No reversible outage timer or duration is enabled or prefilled by default.
- A 180-second delay may appear only as a clearly labeled workstation example that requires explicit configuration and harmless validation; it is not a general recommendation.
- Reversible outage timers do not use FSD.
- UI, logs, and configuration must show the commit boundary.
- Policy tests must cover power restoration before and after commitment.
