# NUTMerlin repository and release policy

## Repository

- GitHub: `darvilp/nutmerlin`
- Visibility: public
- License: GPL-3.0-or-later
- CI: GitHub Actions
- Default branch: `main`
- Workflow: focused feature branch, review, normal push, pull request, merge by maintainer

Do not force-push, merge automatically, publish a release without its release ticket, delete preserved WIP branches, or close umbrella issue #2.

## Ticket delivery

GitHub native issue dependencies are the blocking authority. Work one reachable ticket at a time. A completed ticket has:

- recorded starting commit;
- red/green evidence where a useful seam exists;
- applicable full checks;
- separate Standards and Specification review;
- one focused commit;
- successful normal push;
- issue evidence comment and closure after acceptance.

Planning-only authority resets and final ticket-independent integration fixes remain separate commits and do not masquerade as implementation tickets.

## CI and evidence separation

Ordinary pull requests run hardware-free POSIX/static, unit/golden, real host dummy NUT, simulated Merlin, security, documentation, and deterministic-package checks.

The real host dummy gate is introduced and becomes mandatory in issue #14; its absence is expected only on the planning-reset commit preceding that ticket.

Exact-router and physical-UPS workflows are manual, gated, and separately reported. Their absence does not block ordinary development, but both are required for the first alpha hardware claim.

## Packages

The core package is deterministic and contains only the installer, CLI, shell libraries, fixed dummy fixture, version/ownership metadata, license, and concise documentation required at install time.

NUTMerlin releases no WebUI, policy, executor, dependency snapshot, support-bundle tool, or configuration-export component in v0.1.

## Updates

Updates are administrator-initiated from a local archive. There is no automatic check, download, catalog, stream-to-shell path, or Entware package mutation.

## Alpha integrity

The first alpha requires:

- a tagged source commit;
- deterministic artifact reproduction;
- fixed archive inventory and path-safety checks;
- SHA-256 published with the GitHub release;
- automated evidence and exact hardware report;
- install, update, and known-limitations documentation.

The checksum is transport-integrity evidence, not an independent publisher-authentication channel. OpenPGP roots, independent fingerprint publication, emergency replacement, full feed locking, and catalog publication are later broad-release work.
