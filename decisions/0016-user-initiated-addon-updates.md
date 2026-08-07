# ADR 0016: Make addon updates user-initiated only

- Status: Accepted
- Date: 2026-08-02
- Updated: 2026-08-07 by issue #53

## Decision

v0.1 updates only from a local archive supplied explicitly to the CLI.

- Make no background update check, download, network request, or package-manager request.
- Validate the fixed archive inventory, safe paths/types/modes, checksum, version, and local compatibility before mutation.
- Use one private staged code directory and one temporary backup, perform an immediate smoke check, restore on failure, and delete the backup on success.
- Provide no WebUI update path, long-lived release slot, rollback command, quarantine, transaction journal, or catalog integration.

The release-specific fresh-install launcher is an installation transport, not an installed update path. It may download only its pinned core archive into private temporary storage, verify it, and enter the existing menu. Once installed, NUTMerlin retains the local-archive-only update decision above.

## Consequences

Administrators control every update. The first alpha uses deterministic artifacts and SHA-256 transfer-integrity evidence; stronger publisher authentication is later work.
