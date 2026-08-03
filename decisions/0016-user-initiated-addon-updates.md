# ADR 0016: Make addon updates user-initiated only

- Status: Accepted
- Date: 2026-08-02
- Updated: 2026-08-02 by ADR 0098

## Decision

v0.1 updates only from a local archive supplied explicitly to the CLI.

- Make no background update check, download, network request, or package-manager request.
- Validate the fixed archive inventory, safe paths/types/modes, checksum, version, and local compatibility before mutation.
- Use one private staged code directory and one temporary backup, perform an immediate smoke check, restore on failure, and delete the backup on success.
- Provide no WebUI update path, long-lived release slot, rollback command, quarantine, transaction journal, or catalog integration.

## Consequences

Administrators control every update. The first alpha uses deterministic artifacts and SHA-256 transfer-integrity evidence; stronger publisher authentication is later work.
