# ADR 0030: Import local scripts as owned immutable versions

- Status: Accepted
- Date: 2026-08-02

## Context

Executing an administrator-owned path directly would allow the file, a symlink target, or writable parent path to change after policy validation. Rechecking before every invocation reduces but cannot eliminate path races and also blurs whether uninstall may remove the file.

The architecture already reserves NUTMerlin-owned script storage under `/opt`, whose absence is a degraded condition that disables dependent actions.

## Decision

The local-script executor runs only explicit, immutable script versions imported into NUTMerlin ownership.

- Registration is an explicit administrative operation and is CLI-first unless a later UI design provides an equally constrained flow.
- Import accepts only a regular non-symlink source file and a structured manifest; it never registers a path for later direct execution.
- NUTMerlin copies the bytes atomically into a versioned location under `/opt/etc/nutmerlin/scripts/`, hardens ownership and permissions, computes a cryptographic content hash, and records the artifact in its ownership manifest.
- The manifest declares the supported typed operation versions, structured argument schemas, timeout bounds, harmless test or dry-run behavior, and destructive classification.
- Policies reference the imported script ID and immutable version. Changing the administrator's source has no effect.
- An intended change is a new import version and requires a new policy version before activation.
- Validation and pre-dispatch checks reject a missing, altered, symlinked, unexpectedly writable, or ownership-inconsistent imported artifact.
- Missing, read-only, or integrity-failed `/opt` disables local-script dispatch and never causes fallback to the original source path.
- Clean uninstall removes imported copies and manifests while preserving the administrator's original source file.

## Consequences

- Script updates require an explicit import and policy activation workflow.
- Executed bytes remain reproducible for audit and restart recovery.
- Import, migration, integrity, and ownership tests become part of the P0 executor surface.

## Rejected alternative

Executing an external administrator-owned path after checking its hash, ownership, permissions, and parent directories before every invocation would support live editing, but would retain more path-race, mutation, and uninstall ambiguity.
