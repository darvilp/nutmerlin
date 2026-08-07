# ADR 0083: Require healthy Entware and confirm a bounded NUT package refresh

- Status: Accepted
- Date: 2026-08-02
- Updated: 2026-08-06

## Decision

- Require a preexisting mounted Entware installation with readable consistent `opkg` metadata and enough writable storage for NUTMerlin-owned configuration.
- Before package mutation, read-only checks verify ownership, foreign-NUT state, writable storage, `opkg` metadata and executable, package metadata/architecture, required binaries/options, and an unprivileged NUT identity.
- The only mutable roots are `nut`, `nut-common`, `nut-server`, `nut-upsc`, `nut-driver-dummy-ups`, and `nut-driver-usbhid-ups`.
- Interactive installation asks `Refresh the six required Entware NUT packages? [y/N]`; the default is no. A noninteractive refresh requires `--install-dependencies`.
- Affirmative authorization runs `/opt/bin/opkg update`, then exactly one `/opt/bin/opkg install` naming all six roots. Normal dependency resolution for those roots is allowed.
- Compatible decline proceeds without package mutation. Missing or incompatible decline stops with exact administrator guidance.
- Existing NUTMerlin service, periodic recovery, listener, and firewall admission stop before package mutation. Mutation or post-refresh incompatibility leaves NUTMerlin disabled and stopped.
- After mutation, NUTMerlin re-runs package, binary, option, architecture, and unprivileged-identity checks before proceeding.
- NUTMerlin never downloads or invokes an Entware installer, partitions, formats, or remounts storage, changes feeds, repairs `opkg`, invokes a blanket package upgrade, downgrades/removes packages, or installs unrelated optional roots.
- Late `/opt` is retried through the lifecycle path; replaced or ambiguous storage is not adopted.

## Consequences

The administrator still owns Entware installation, feeds, repair, broad upgrades, downgrades, and package removal. NUTMerlin provides the conventional amtm-style convenience of explicitly refreshing its small fixed dependency set. Installed dependencies remain shared Entware packages and are retained on NUTMerlin uninstall under ADR 0013.
