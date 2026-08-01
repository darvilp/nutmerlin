# ADR 0007: Treat Entware storage as fallible and minimize writes

- Status: Accepted
- Date: 2026-08-01

## Context

USB flash drives used for router addons can fail from write wear, controller quality, unsafe removal, or corruption. Consumer flash drives often expose no useful health or endurance data.

## Decision

- Prefer a USB-attached SSD for always-on deployments.
- Permit qualified flash media for intermittent test rigs.
- Do not require swap.
- Keep high-frequency status in `/tmp`.
- Bound and rotate persistent logs.
- Persist only configuration, migrations, event transitions, and limited audit records.
- Detect missing or read-only `/opt` and fail safely.
- Make installation reproducible and configuration exportable.

## Consequences

Passing media tests can reject obvious defects but does not prove remaining endurance. The software must tolerate storage failure rather than relying on media quality alone.
