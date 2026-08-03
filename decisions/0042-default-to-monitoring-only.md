# ADR 0042: Default to monitoring only

- Status: Accepted
- Date: 2026-08-02
- Updated: 2026-08-02 by ADR 0098

## Decision

Fresh install and update may run the selected NUT driver, serve status, authenticate explicitly registered standard secondaries, and expose local diagnostics. They create no client credential or LAN admission until the administrator explicitly configures it.

v0.1 has no router-side policy, executor, outbound publication, FSD, writable UPS variable, instant command, output control, or remote action. Dummy remains loopback-only.

## Consequences

Installing or updating cannot directly change a remote host or UPS output. Standard secondary-client local behavior remains outside router authority.
