# ADR 0013: Retain Entware packages during normal uninstall

- Status: Accepted
- Date: 2026-08-01
- Updated: 2026-08-02 by ADR 0098

## Decision

NUTMerlin v0.1 never installs, upgrades, repairs, or removes Entware packages. It records only the package names and versions observed by its read-only compatibility check.

Disable, repair, update, and uninstall modify only attributable NUTMerlin code, configuration, credentials, hook blocks, scheduled job, firewall objects, and volatile state. Every Entware package is retained. There is no package-cleanup operation.

## Consequences

Administrators manage Entware dependencies separately. Uninstall may leave packages that are no longer needed, avoiding disruption to shared package users.
