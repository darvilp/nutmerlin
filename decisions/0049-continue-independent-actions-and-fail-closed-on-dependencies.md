# ADR 0049: Continue independent actions and fail closed on dependencies

- Status: Deferred research - non-authoritative for v0.1
- Date: 2026-08-02

## Context

A policy-wide continue-or-stop switch cannot distinguish an independent workstation failure from a safety prerequisite for a dependent operation. Stopping every later stage after one unreachable noncritical target can prevent useful graceful shedding, while blindly continuing can escalate from an unverified result.

## Decision

Policy error behavior is expressed through action dependencies rather than one global `continue_on_error` boolean.

- Actions without a dependency relationship are independent, even when grouped in the same ordered stage.
- A stage waits until each started action reaches success, failure, unknown, skipped, or another operation-defined terminal result within its action budget.
- Failure or unknown outcome for one independent target does not prevent other independent targets or later independent graceful stages from running.
- A policy may declare an action result as a prerequisite and identify the exact evidence required, such as delivery acceptance, action acceptance, or verified target state.
- Dependent work runs only when every required prerequisite provides the declared successful evidence.
- Failure, unknown outcome, timeout, skip, loss of reachability, or weaker-than-required evidence fails the dependency closed.
- An unknown or failed action never authorizes an escalation, abrupt operation, output control, or cross-target inference.
- Policies cannot declare two actions dependent merely by their stage order; dependencies are explicit, acyclic, and validated at activation.
- Recovery cancellation and committed-action rules still apply independently of dependency outcome.

## Consequences

- A failed noncritical host does not strand unrelated critical hosts as an outage worsens.
- Safety-sensitive sequences must state what evidence they actually depend on.
- The UI needs a dependency view and worst-case stage-duration summary rather than a single continue-on-error checkbox.
- Tests must cover sibling independence, failed prerequisites, insufficient evidence classes, unknown outcomes, cycles, canceled actions, and later-stage progression.

## Rejected alternatives

Default stop-on-any-error is simple but makes unrelated availability depend on the least reliable target. Default continue-on-error preserves progress but cannot safely represent verification-gated sequencing.
