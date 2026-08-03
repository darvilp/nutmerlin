# ADR 0083: Require a preexisting healthy Entware installation

- Status: Accepted
- Date: 2026-08-02
- Updated: 2026-08-02 by ADR 0098

## Decision

- Require a preexisting mounted Entware installation with readable consistent `opkg` metadata and enough writable storage for NUTMerlin-owned configuration.
- Read-only checks verify required NUT package presence, binary paths, options, architecture compatibility, and an unprivileged network-facing `upsd` profile.
- Missing or incompatible requirements stop before mutation and provide exact administrator guidance, including a proposed package command for separate review.
- NUTMerlin never downloads or invokes an Entware installer, partitions/formats/remounts storage, changes feeds, repairs `opkg`, or installs/upgrades/removes any Entware package.
- Late `/opt` is retried through the lifecycle path; replaced or ambiguous storage is not adopted.

## Consequences

Entware preparation and dependency changes remain administrator responsibilities. NUTMerlin can be useful without owning shared package lifecycle.
