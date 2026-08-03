# ADR 0024: Commit before nonrepeatable action dispatch

- Status: Deferred research - non-authoritative for v0.1
- Date: 2026-08-02

## Context

A target may accept a shutdown or other nonrepeatable action while the router loses the response or restarts. If the policy remains reversible until acknowledgement, recovery can incorrectly cancel or repeat an action that already took effect. No local transaction can atomically combine a durable router record with a remote side effect.

## Decision

NUTMerlin crosses the durable commit boundary immediately before the first non-dry-run dispatch of a noncancelable or nonrepeatable action.

- Immediately before commitment, revalidate the normalized event, data freshness, policy prerequisites, target eligibility, feature gates, and executor capability.
- Persist a redacted dispatch-intent record containing the event, policy, target, action, executor, and attempt identity before invoking the executor.
- Recovery after the dispatch-intent record does not cancel the committed action merely because utility power or telemetry recovers.
- A timeout, response loss, or restart after dispatch intent is an unknown action outcome unless later verification establishes a stronger result.
- Unknown outcome is not equivalent to failure and does not by itself authorize another non-idempotent attempt.
- State before the durable dispatch intent remains reversible and may be canceled by its declared recovery event.
- Client-local shutdown owns its commit boundary on the client; this decision governs actions dispatched by NUTMerlin, including an FSD request.

## Consequences

- A crash after durable dispatch intent but before the network or process call may conservatively suppress an action that never reached its target.
- Executors and audit records need an explicit unknown-outcome state rather than only success and failure.
- Safe retry depends on declared and tested action idempotency or target-supported deduplication.

## Rejected alternative

Committing only after executor acknowledgement would preserve cancellation for slightly longer, but a lost acknowledgement could cause NUTMerlin to cancel or repeat an action that the target had already accepted.
