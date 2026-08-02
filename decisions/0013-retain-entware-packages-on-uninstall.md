# ADR 0013: Retain Entware packages during normal uninstall

- Status: Accepted
- Date: 2026-08-01

## Context

NUTMerlin can record that it installed an Entware package, but package installation does not grant exclusive ownership. Administrators, scripts, and other addons may use a package without declaring a package-manager dependency, so automatic removal can disrupt unrelated services.

## Decision

Normal uninstall removes zero Entware packages.

- Record for every dependency whether it predated NUTMerlin or was installed by this installation, including the observed version.
- Normal uninstall removes only NUTMerlin-owned services, files, hook blocks, firewall rules, generated configuration, and other managed integration artifacts.
- Uninstall reports retained packages and their recorded provenance.
- Package removal is available only through a separate explicit package-cleanup operation with a mandatory dry-run and administrator confirmation.
- Cleanup may consider only packages installed by the same NUTMerlin installation, with intact provenance, no declared reverse dependencies, no detected foreign NUT deployment or process, and no conflicting evidence.
- Any uncertainty retains the package.
- A package that predated NUTMerlin is never eligible merely because it appears in a generated dependency manifest.

## Consequences

- A normal uninstall can leave unused NUT packages on Entware storage.
- Removing addon integration is safer and repeatable without relying on incomplete package-usage metadata.
- Users who want package removal receive an auditable, separately confirmed cleanup path.

## Rejected alternative

Automatically removing packages recorded as NUTMerlin-installed would produce a tidier default uninstall, but package-manager dependency checks cannot prove that no administrator script or unrelated addon uses them.
