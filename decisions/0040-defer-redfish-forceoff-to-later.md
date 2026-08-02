# ADR 0040: Defer Redfish ForceOff to Later

- Status: Accepted
- Date: 2026-08-02

## Context

The initial P2 design allows escalation from Redfish `GracefulShutdown` to `ForceOff` after a timeout and opt-in. Failure to observe `Off` does not establish that a host is safe to power off: the host may still be flushing data, the BMC may expose stale state, or verification may have failed independently.

## Decision

Redfish `ForceOff`, hard reset, and equivalent abrupt power operations are `Later`, outside the P2 executor contract.

- P2 Redfish may discover capabilities, query power state, request `GracefulShutdown`, and perform bounded polling for the `Off` state.
- Failure or timeout while verifying `Off` ends as failed or unknown, emits diagnostics or notification according to policy, and never authorizes escalation.
- P2 operation schemas contain no `ForceOff`, hard-reset, or equivalent typed operation.
- Graceful-shutdown credentials and enablement do not confer future force-operation authority.
- Power-on and target restoration are deferred to `Later` by ADR 0071 and cannot be inferred from graceful-shutdown permission.
- A future force-operation phase requires its own ADR, exact BMC and firmware qualification, dedicated least-privilege credentials, explicit data-corruption warning, and global, target, and action gates.

## Consequences

- P2 cannot guarantee that an unresponsive host powers off.
- Redfish remains useful for out-of-band observation, graceful action, and cross-protocol verification.
- Tests assert absence of force operations as well as timeout behavior.

## Rejected alternative

Retaining `ForceOff` in P2 behind a configured timeout and dual opt-in would improve unattended escalation, but would convert ambiguous shutdown progress into immediate power removal.
