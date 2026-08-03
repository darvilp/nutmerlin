# ADR 0094: Bound immutable policy-version retention

- Status: Deferred research - non-authoritative for v0.1
- Date: 2026-08-02

## Context

Immutable policy versions make execution reproducible, but retaining every draft and activated version forever creates an unbounded configuration store. Deleting an old version too aggressively can remove the only exact definition for an in-progress, committed, unknown, or recently audited action. Re-activating an old version directly would also bypass current binding tests and activation evidence.

## Decision

Policy versions have bounded ordinary retention and an unbounded-in-time safety protection rule.

- One serialized immutable policy version is limited to 256 KiB, including its explicit target/action snapshots and schemas but excluding credential values.
- The ordinary full policy-version store has an 8 MiB default capacity on `/opt`, separate from operational history and the safety journal.
- A version is protected from pruning while active, captured by an in-progress episode, committed, associated with an unknown outcome, referenced by unresolved restart/rollback state, or named by the detailed safety journal.
- Protected versions are never deleted, compacted into a weaker representation, or counted as eligible merely because they are old. If protected versions consume the store budget, monitoring and current work continue but new policy activation is refused until safe reconciliation or explicit storage expansion under a future decision.
- For each policy, NUTMerlin retains the newest 10 inactive terminal versions plus any full version referenced by still-retained action/audit history, whose default action-history horizon is 180 days under ADR 0061.
- Older unprotected full versions may be pruned after those rules. Their audit records retain immutable policy/version IDs, cryptographic digest, safety-class summary, exact target/action result references, and deletion timestamp, but do not claim the full policy remains reconstructable.
- Mutable abandoned drafts are not immutable history. They are size-bounded, never executable, and may be explicitly discarded without affecting active or historical versions.
- Selecting an old inactive version copies its non-secret definition into a new draft. It must expand current targets, resolve credentials, pass current schemas, conflicts, harmless tests, dry-run, and explicit activation; historical evidence is never reused.
- Configuration export includes selected current non-secret definitions, not an automatic archive of every historical version. An administrator who needs long-term full history exports it before pruning.
- Pruning is journaled metadata work, cannot run during unresolved storage or action recovery, and never deletes a version whose references cannot be proven terminal.

## Consequences

- Normal edits remain bounded while every version needed for safe execution or recent detailed audit remains available.
- Heavy policy churn can reach 8 MiB and block new activation rather than delete protected evidence.
- Very old audit entries may prove which digest and actions ran without retaining the complete authoring document.
- Tests must cover exact 256 KiB, 10-version, 180-day, and 8 MiB boundaries; every protection reason; churn and capacity refusal; audit-summary preservation; draft deletion; old-version copy and full revalidation; restart references; and pruning interruption.

## Rejected alternative

Retaining every immutable policy version indefinitely would maximize forensic convenience, but would give routine editing and imports an unbounded persistent-storage cost and eventually compete with safety and configuration headroom.
