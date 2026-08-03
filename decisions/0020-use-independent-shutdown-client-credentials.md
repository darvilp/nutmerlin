# ADR 0020: Use independent credentials for shutdown clients

- Status: Accepted
- Date: 2026-08-02
- Updated: 2026-08-02 by ADR 0098

## Decision

- Every registered standard secondary has a stable non-secret client ID, bounded display label, unique generated username, and unique secret.
- The server grant is only `upsmon secondary`.
- A credential is never reused across clients or installations.
- Revocation atomically activates a complete new NUT configuration and cannot be undone by last-known-good recovery.
- Read-only NUT status remains credential-free within the admitted LAN scope.
- Ownership/status may inventory the non-secret client ID and username but never the secret.

## Consequences

One client can be removed without disrupting others. There is no shared household credential or two-phase credential framework in v0.1.
