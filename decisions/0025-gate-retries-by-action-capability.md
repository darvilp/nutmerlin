# ADR 0025: Gate retries by action capability

- Status: Accepted
- Date: 2026-08-02

## Context

Policies know how many attempts an administrator wants, but an executor can expose actions with different repeatability. A harmless query, a target-state operation, an ordinary webhook POST, and a shutdown command do not share one safe retry rule. Treating timeout as failure can repeat a side effect whose acknowledgement was lost.

## Decision

Retry eligibility is an action-level capability that policy configuration may narrow but cannot broaden.

Every executable action declares exactly one retry classification:

- `nonrepeatable`: no automatic retry after durable dispatch intent; this is the default when unspecified.
- `idempotent`: repeating the action is defined and tested to produce the same safe target state.
- `idempotency_keyed`: the target is defined and tested to honor a stable action-execution key and deduplicate repeats.

Further rules:

- A definite failure before dispatch intent may be retried because no side effect was attempted.
- An unknown action outcome receives zero automatic retries unless the action is declared and tested as `idempotent` or `idempotency_keyed`.
- A keyed retry uses the same action-execution key across all attempts; an attempt identifier remains separate for audit.
- A policy may select zero or fewer attempts than the action permits, but validation rejects a policy that requests broader retry behavior.
- Verification may resolve an unknown outcome only from target evidence; renewed connectivity alone is insufficient.
- Executor capability description exposes the classification for each supported action.
- Numerical attempt and backoff defaults remain a separate bounded-retry decision.

## Consequences

- Adding an executor is insufficient by itself; each action needs explicit repeatability semantics and tests.
- Existing policy schemas that treat retry as an unconstrained integer must be narrowed during reconciliation.
- Unclassified third-party or local-script actions are conservatively nonrepeatable.

## Rejected alternative

Allowing policy authors to select retries regardless of action capability would be simpler, but would turn duplicate shutdowns and other repeated side effects into ordinary configuration errors instead of preventing them structurally.
