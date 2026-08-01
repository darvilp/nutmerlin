# ADR 0003: Separate reversible outage actions from committed shutdown

- Status: Accepted
- Date: 2026-08-01

## Context

A short outage grace period should be canceled when utility power returns. NUT FSD is designed for coordinated shutdown and remains latched until the data server is restarted.

## Decision

The policy model has two distinct phases:

1. **Reversible** — pending or active actions may be canceled by recovery.
2. **Committed** — the shutdown sequence completes even if utility returns.

FSD is available only in the committed phase and is an advanced feature.

## Consequences

- The normal three-minute shutdown timer does not use FSD.
- UI, logs, and configuration must show the commit boundary.
- Policy tests must cover power restoration before and after commitment.
