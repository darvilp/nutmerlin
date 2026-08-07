# ADR 0013: Retain Entware packages during normal uninstall

- Status: Accepted
- Date: 2026-08-01
- Updated: 2026-08-06 by ADR 0083

## Decision

NUTMerlin v0.1 may install or refresh only its six required NUT package roots after the explicit confirmation defined by ADR 0083. It never performs a blanket Entware upgrade, repairs `opkg`, changes feeds, downgrades packages, or removes Entware packages. It records only the required package names, versions, and architecture observed by its compatibility check.

Disable, repair, update, and uninstall modify only attributable NUTMerlin code, configuration, credentials, hook blocks, scheduled job, firewall objects, and volatile state. Every Entware package is retained. There is no package-cleanup operation.

## Consequences

Uninstall may leave packages that are no longer needed, including packages installed during confirmed NUTMerlin setup. This avoids disrupting shared package users and keeps package ownership with the Entware administrator.
