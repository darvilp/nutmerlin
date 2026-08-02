# ADR 0078: Use explicit action evidence grades

- Status: Accepted
- Date: 2026-08-02

## Context

Executor outcomes currently include an exit or result status, while the design separately warns that network disconnect, HTTP success, MQTT acknowledgement, or NUT-client disappearance does not prove a target effect. A single success/failure flag cannot distinguish a request rejected before dispatch, a request accepted without observed completion, a verified effect, and a response lost after a side effect may have begun.

## Decision

Every execution result carries an explicit evidence grade independent of its diagnostic status:

- `not_dispatched` — validation, precondition, connection, rate, or authorization failure proves that no effecting request was sent.
- `dispatch_rejected` — the target conclusively rejected the request before accepting the operation.
- `dispatch_accepted` — the target or protocol conclusively accepted the request, but the requested target effect has not been observed.
- `effect_verified` — an operation-specific verifier observed the declared effect through a qualified evidence path.
- `outcome_unknown` — a request may have reached or affected the target, but available evidence cannot establish acceptance, rejection, or completion.

The contract has these rules:

- Evidence grade, operation result code, protocol details, and policy progression are separate structured fields; no executor invents a generic `success=true` that hides the distinction.
- `execute()` can establish at most `dispatch_accepted`. Only the declared `verify()` strategy can establish `effect_verified`.
- Process exit zero, HTTP 2xx, MQTT PUBACK, Redfish task acceptance, and wrapper acknowledgement may establish delivery or dispatch acceptance according to their contracts, not target-state verification.
- TCP close, timeout, ping failure, route loss, SSH or WinRM disconnect, NUT-client disconnect, and absence of a later status sample never establish shutdown, service stop, or power-off.
- A same-channel state query may verify an effect such as a still-reachable service being inactive. Host `Off` normally requires an independently qualified out-of-band observation such as a Redfish binding pinned to the same logical target.
- A policy prerequisite declares the minimum exact evidence grade it needs under ADR 0049. `dispatch_accepted` cannot satisfy a prerequisite requiring `effect_verified`.
- `outcome_unknown` blocks dependent or conflicting state-changing work and follows ADRs 0024, 0025, 0050, and 0057. It never becomes `not_dispatched` merely because time passes or connectivity returns.
- `dispatch_accepted` for a nonrepeatable action also forbids automatic repeat, even when verification times out. A conclusive `not_dispatched` or `dispatch_rejected` may retry only within the operation's classification and action budget.
- UI, CLI, notifications, and audit use the exact vocabulary: for example, "shutdown request accepted; power-off not verified," never "shutdown succeeded".
- Dry-run and harmless tests carry separate simulated or test markers and cannot produce production `dispatch_accepted` or `effect_verified` evidence.

## Consequences

- Users can distinguish delivery, intent, and observed state without reading protocol diagnostics.
- Cross-binding verification becomes useful without making it mandatory for every graceful shutdown.
- Policy dependencies and unknown-outcome recovery have deterministic evidence inputs.
- Tests must cover every evidence transition and explicitly reject false verification from disconnect, timeout, ping, client disappearance, accepted HTTP/MQTT responses, and stale observations.

## Rejected alternative

A boolean result with `success`, `failure`, and a free-text warning would be easier for executor authors and dashboards, but could not safely drive dependencies or retries and would repeatedly invite delivery or reachability evidence to be presented as completed action.
