# ADR 0054: Separate the safety journal from operational history

- Status: Accepted
- Date: 2026-08-02

## Context

Operational event and diagnostic history must rotate when bounded storage fills and must not stop monitoring. Nonrepeatable dispatch, policy activation, and crash recovery require durable facts that cannot be discarded by ordinary log rotation. Combining both purposes would either make diagnostics safety-critical or make recovery evidence expendable.

## Decision

NUTMerlin separates volatile status, operational history, and its safety journal.

- Current high-frequency status and polling state remain under `/tmp` and are not persisted per sample.
- Bounded event, action-result, and diagnostic history lives under `/opt` and may rotate or drop its oldest resolved records according to the retention decision.
- A distinct atomic and fsync-capable safety journal records active policy-version transitions, event-episode commitment, dispatch intent, unknown outcome, and recovery reconciliation.
- Operational logs cannot consume the safety journal's reserved 4 MiB storage budget.
- Configuration activation, addon update, migration, and a new committed or nonrepeatable dispatch require a successful journal write and fsync.
- These operations also require at least 16 MiB of filesystem headroom remaining after their conservatively estimated write set; otherwise they fail before mutation or commitment.
- If the safety journal is unwritable, missing, corrupt, or out of reserved capacity, monitoring and read-only status may continue but new state-changing commitment is inhibited and recovery diagnostics are raised.
- An action whose dispatch intent was already committed and fsynced may continue under its captured contract. Failure to persist a later result creates unresolved recovery state and never authorizes repetition.
- Journal compaction is atomic, retains every active or unresolved record, and may discard only terminal records already represented in retained audit history.
- Rare JFFS-resident lifecycle latches contain no secret or high-frequency history and do not replace the `/opt` safety journal.

## Consequences

- Log exhaustion does not block ordinary monitoring, while missing recovery evidence blocks new risky action.
- The storage design needs reserved capacity, atomic compaction, corruption detection, and explicit unresolved-state tooling.
- A nearly full volume can remain useful for read-only NUT service but cannot safely update or commit new orchestration.
- Tests must fill history and journal independently, exercise the 16 MiB boundary, interrupt fsync and compaction, corrupt records, and prove that committed intent is never repeated.

## Rejected alternative

One rotating audit log would reduce file and recovery mechanisms, but normal rotation or log exhaustion could erase the only proof that a nonrepeatable action was authorized or dispatched.
