# ADR 0083: Require a preexisting healthy Entware installation

- Status: Accepted
- Date: 2026-08-02

## Context

NUTMerlin depends on Entware packages, but creating Entware itself would require selecting and preparing storage, installing another project's bootstrap, choosing feed architecture, managing `/opt` mount behavior, and deciding whether uninstall or repair owns that shared environment. Those responsibilities are broader and more destructive than installing a scoped package cohort into an existing package manager.

## Decision

NUTMerlin requires a preexisting, mounted, and healthy Entware installation and never bootstraps Entware.

- Install and repair preflight validate the expected `/opt` identity, mount and write state, current supported feed architecture, `opkg` executable and database health, feed configuration, package metadata, and available space before proposing NUTMerlin package changes.
- If Entware is absent, not currently mounted during an interactive install, uses an unsupported or mismatched feed, has a broken package database, or resides on failing/read-only storage, NUTMerlin stops before mutation and provides scoped diagnostics and external Entware setup or repair guidance.
- NUTMerlin never downloads or invokes an Entware installer, partitions or formats storage, selects a USB device for Entware, changes Entware feed configuration, repairs the shared `opkg` database, or claims ownership of `/opt` or the Entware installation.
- A normal boot with an already configured but late-mounted `/opt` follows ADR 0051's readiness schedule; it is not treated as permission to create or remount Entware.
- Once shared Entware health is established, NUTMerlin may install or repair only its declared current package cohort under ADR 0014 and records package provenance without claiming exclusive package ownership.
- Package mutation preflight requires enough free space for the complete calculated transaction, rollback or package-manager temporary needs where reported, and ADR 0054's 16 MiB post-transaction safety headroom. If the requirement cannot be calculated conservatively, mutation is refused rather than guessed.
- Disable, uninstall, ownership recovery, and package cleanup never remove Entware, alter its storage setup, or present shared-platform repair as a NUTMerlin-owned rollback.
- A user who intentionally removes or replaces Entware while NUTMerlin is installed triggers the storage fault and ownership rules rather than an automatic reinstallation.

## Consequences

- Initial onboarding has a prerequisite outside NUTMerlin, but storage preparation and Entware lifecycle remain with their established owner.
- Install and uninstall transactions have a defensible ownership boundary.
- A broken Entware environment can block NUTMerlin repair until the administrator repairs the shared layer independently.
- Tests must cover absent, late, wrong-architecture, mixed-feed, read-only, low-space, corrupt-database, unexpected-mount, replaced-storage, and healthy-existing Entware cases and prove that no bootstrap, format, feed rewrite, or shared repair command runs.

## Rejected alternative

An optional guided Entware bootstrap would reduce first-install steps, but would make NUTMerlin responsible for destructive storage selection, another project's installer and feed lifecycle, shared failure recovery, and ambiguous uninstall ownership.
