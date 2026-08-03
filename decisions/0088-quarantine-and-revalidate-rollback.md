# ADR 0088: Quarantine and revalidate rollback

- Status: Superseded by ADR 0098
- Date: 2026-08-02

## Context

Two-slot update rollback restores bytes, but it does not by itself prove that the previous code can read the current journal, that the rollback configuration remained exact, or that state-changing policies should resume. Conversely, permanently discarding prior activation after a candidate fails during a safe online update would unnecessarily remove known protection. Automatic and later administrator-requested rollback have different evidence.

## Decision

Every rollback enters a monitoring-only rollback quarantine before any prior authority can return.

- Rollback may select only the immediately previous locally retained release slot whose manifest and artifacts were authenticated when installed and whose backward configuration representation passed candidate preflight. Arbitrary-version downgrade is not a rollback operation.
- Switching the release pointer restores the exact paired last-known-good configuration and begins with policies, executors, shutdown-client service, and external NUT access closed.
- The restored slot must reconcile update and safety journals, ownership, storage, privileges, configuration, source identity, listener/firewall state, and schema hashes, then pass 120 continuous healthy seconds and at least 24 fresh observations under the same health basis as ADR 0067.
- One automatic rollback after candidate activation failure may restore the previously active policy and external-access state only after that gate, and only when exact policy/config hashes, credentials, operation versions, gates, and pre-update activation state are unchanged and there is no active, committed, unknown, or unreconciled action state.
- Any mismatch leaves definitions present but inactive and requires explicit administration. Automatic rollback never migrates a policy forward or substitutes a binding to make it resume.
- A manual rollback requested after update finalization always remains monitoring-only after health validation. Policies, executors, shutdown clients, and external access require explicit revalidation and re-enablement because the administrator is intentionally leaving the supported current release.
- A signed candidate manifest may identify the previous release as unsafe for state-changing or externally exposed recovery. In that case rollback may provide local diagnostic/repair capability only; those surfaces cannot resume even automatically.
- A rolled-back release is labeled recovery compatibility, not the latest supported release. It never becomes a new update baseline or triggers automatic forward/rollback oscillation.
- If restored-slot health or reconciliation fails, the one automatic attempt ends with both slots preserved, all NUTMerlin network and action surfaces closed, and local CLI recovery required under ADR 0012.
- Rollback cannot erase an `outcome_unknown`, reopen a completed retry budget, undo a commit boundary, or infer that a pre-update episode is safe from wall time.

## Consequences

- A bad candidate can recover the exact prior protected state, but only after two minutes of proved health and state continuity.
- Manual downgrades do not silently reactivate old automation or broaden support claims.
- Critical security releases can retain diagnostic rollback without reopening the vulnerable action or network surface.
- Tests must cover exact hash continuity and every mismatch, 120-second and 24-poll boundaries, previous active/inactive state, manual versus automatic rollback, signed unsafe-previous metadata, external NUT and client credentials, policy versions, journal unknown/commit states, second rollback refusal, and failed restored-slot health.

## Rejected alternative

Restoring code, configuration, network listeners, and policy activation atomically in one pointer switch would minimize monitoring interruption, but could resume state-changing authority before proving that downgraded code and durable state still have identical meaning.
