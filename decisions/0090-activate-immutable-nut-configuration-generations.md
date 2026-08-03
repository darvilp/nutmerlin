# ADR 0090: Activate immutable NUT configuration generations

- Status: Superseded by ADR 0098
- Date: 2026-08-02

## Context

`ups.conf`, `upsd.conf`, `upsd.users`, and related files form one security and lifecycle unit but cannot be atomically overwritten as separate paths. A crash between file writes can combine a new listener with old credentials or a new driver with old server state. Current NUT supports selecting a complete configuration directory through `NUT_CONFPATH`, so managed processes need not consume Entware's ambient configuration directory.

## Decision

NUTMerlin renders and activates immutable complete NUT configuration generations.

- Each generation has a unique non-secret ID, versioned model and renderer schema, exact file manifest and hashes, required owner/group/mode metadata, and the complete files needed by all managed NUT processes.
- Generations live in a NUTMerlin-owned protected directory outside Entware's ambient `/opt/etc/nut` configuration. NUTMerlin does not overwrite or merge a foreign default-path deployment.
- Candidate rendering writes a new directory, validates every field and file, checks paths and permissions, performs available NUT syntax/configuration probes and harmless isolated smoke checks, then seals the generation against mutation before activation.
- A small owned current-generation selector is replaced atomically on `/opt`. Managed launch wrappers resolve and validate that exact ID and set `NUT_CONFPATH` to the resolved immutable directory for `upsdrvctl`, drivers, `upsd`, and any later managed NUT component.
- Every managed process in one service epoch uses the same resolved generation ID. No process follows a moving symlink or rereads an unvalidated current selector independently.
- Activation requires the applicable safe state, closes external exposure during the service transition, stops affected managed processes, atomically selects the candidate, starts the full NUT stack, and revalidates listener/firewall scope before reopening permitted access.
- A generation change passes 120 continuous healthy seconds and at least 24 fresh observations, including driver, `upsd`, query, source identity, privilege, file-integrity, listener, firewall, and journal checks.
- At most two sealed generations are retained after staging: active and last-known-good. Candidate failure receives one selector rollback and full restart/health attempt; failure of that attempt leaves services and exposure closed with both generations preserved for CLI recovery.
- Manual last-known-good selection is a new explicit activation transaction and begins monitoring-only; it is not a direct pointer edit and cannot silently restore old policy authority.
- Generated secrets remain protected owned runtime material in both active and last-known-good generations, not user backups. They are excluded from export and support bundles and removed by clean uninstall.
- Any missing, altered, unsealed, symlinked, ownership-inconsistent, or future-schema generation fails integrity checks. NUTMerlin never adopts the edited bytes or regenerates over them without an explicit validated candidate transaction.
- Release updates pair their release slot with a tested compatible configuration generation under ADRs 0012, 0067, and 0088; code and configuration rollback cannot be selected independently when their schemas differ.

## Consequences

- NUT never observes a mixed set of separately replaced configuration files.
- Applying settings takes at least the two-minute health gate before finalization, favoring rollback evidence over immediate UI completion.
- Entware package defaults and manual NUT files remain outside NUTMerlin ownership and cannot be a fallback.
- Tests must interrupt every render, seal, selector, stop/start, exposure, health, and rollback phase; launch mixed-generation attempts; mutate every file and metadata field; test ambient config isolation; enforce two-generation retention; and verify secret protection and exact code/config pairing.

## Rejected alternative

Writing each file to a temporary sibling, renaming them sequentially, and keeping `.bak` copies would be simpler and use conventional paths, but interruption could expose a cross-file mixture and make it ambiguous which credentials, listeners, and driver settings form the last-known-good unit.
