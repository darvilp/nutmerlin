# ADR 0050: Reject ambiguous cross-policy action conflicts

- Status: Accepted
- Date: 2026-08-02

## Context

Two enabled policies can react to the same UPS episode and address the same logical target. Per-target serialization prevents simultaneous execution but does not prevent duplicate or contradictory commands. An implicit numeric policy priority would make the result depend on configuration order rather than an explicit safety relationship.

## Decision

NUTMerlin analyzes overlapping state-changing action intents before policy activation.

- An action intent canonically identifies its source episode class, logical target, typed operation and version, normalized parameters, commitment semantics, and relevant prerequisites.
- Semantically identical state-changing intents for the same source episode and target are coalesced into one dispatch; audit records link the resulting execution to every originating policy version and action ID.
- Potentially overlapping state-changing intents that differ are rejected unless their ordering, dependency, or supersession is explicitly represented in one validated policy version or a typed contract that defines the relationship.
- Stage order, policy creation time, filename order, or a generic numeric priority does not imply supersession.
- Notification publications are not automatically coalesced because distinct policies may intentionally produce distinct messages; publication rate and payload rules still apply.
- If an overlap not proven safe at activation is discovered at runtime because effective identities or capabilities changed, every conflicting uncommitted state-changing dispatch is inhibited and a diagnostic event is emitted.
- Already committed action intent retains its durable meaning; a newly discovered conflict cannot cause it to be repeated or reinterpreted.

## Consequences

- Enabling a policy cannot silently change which of two shutdown behaviors wins.
- Common duplicate shutdown intent is executed once while remaining attributable to all policies.
- Policy validation needs overlap analysis across event conditions and effective target identities.
- Tests must cover identical coalescing, different parameters, aliases resolving to one target, explicit dependencies, notification exceptions, runtime identity changes, and committed conflicts.

## Rejected alternatives

A global numeric policy priority would resolve conflicts mechanically, but adding or reprioritizing one policy could silently suppress another. Executing serialized actions in arrival order would remain nondeterministic across restart and timing changes.
