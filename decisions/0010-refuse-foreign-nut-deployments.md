# ADR 0010: Refuse foreign or ambiguously owned NUT deployments

- Status: Accepted
- Date: 2026-08-01
- Updated: 2026-08-02 by ADR 0098

## Decision

v0.1 does not adopt an existing NUT deployment.

- Classify relevant files, configuration, processes, listeners, hooks, and ownership evidence as absent, consistently NUTMerlin-owned, foreign, or ambiguous.
- Foreign and ambiguous state causes read-only refusal before mutation.
- Do not stop, rename, back up, import, merge, overwrite, or delete foreign or ambiguous artifacts.
- Installed Entware packages alone do not establish deployment ownership.
- Repair is idempotent only for complete consistent owned evidence.

## Consequences

Existing NUT users must migrate manually. False refusal is preferable to overwriting or later deleting administrator-owned state.
