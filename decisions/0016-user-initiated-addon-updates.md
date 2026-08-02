# ADR 0016: Make addon updates user-initiated only

- Status: Accepted
- Date: 2026-08-02

## Context

NUTMerlin controls monitoring and optional power-event actions. Even an authentic update can introduce a regression, change compatibility, or activate at an unsafe time. The addon must also remain useful without runtime internet access.

## Decision

Addon update checks and installations are user-initiated only.

- Make no background outbound update request by default.
- Explicit CLI and, when installed, WebUI actions may check the authenticated release channel.
- Before confirmation, show the candidate version, release notes, compatibility changes, dependency plan, integrity result, and rollback availability.
- Support offline installation from a locally supplied authenticated release archive.
- Do not automatically download or activate addon updates, including security releases.
- A later opt-in scheduled check may provide notification only; it never installs an update.
- Future AMTM or catalog integration may advertise a release but cannot bypass NUTMerlin verification, staging, health checks, or rollback.
- Monitoring and policy operation do not depend on internet access.

## Consequences

- Administrators control the timing of every addon change.
- Security-patch adoption depends on visible notices and administrator action.
- Update tooling needs equally safe online and offline paths.
- Automatic rollback remains available after a user-initiated activation failure under ADR 0012.

## Rejected alternative

Opt-in signed automatic installation would improve update uptake, but could still introduce a validly signed regression or change policy behavior while no administrator is present.
