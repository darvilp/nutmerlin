# ADR 0052: Bound NUT and USB recovery with a circuit breaker

- Status: Accepted
- Date: 2026-08-02

## Context

USB devices can disconnect transiently, drivers can crash, and `upsd` can fail while the router otherwise remains healthy. Immediate manual intervention would make the monitoring service brittle, but unbounded restart loops can consume CPU, flood logs, contend for USB, and obscure a wrong or unstable device.

## Decision

NUT driver and data-server recovery uses a per-service restart circuit breaker.

- The normal automatic budget is three start attempts in a rolling 5-minute window, delayed 5 seconds, 15 seconds, and 60 seconds after successive failures.
- After the budget is exhausted, automatic restart pauses for 15 minutes and then permits one health-probe start attempt.
- An explicit administrator retry, validated relevant configuration change, or hotplug event for the expected USB identity may trigger an earlier serialized attempt without creating parallel restart loops.
- Five continuous minutes of qualified service health resets the failure window and backoff state.
- A driver or `upsd` failure enters communication-loss behavior under ADR 0047; cached telemetry cannot authorize ordinary dispatch.
- Recovery becomes action-eligible only after the two fresh observations required by ADR 0045.
- NUTMerlin never switches between a real source and `dummy-ups` automatically. Simulation selection is an explicit operational change with active-policy safeguards.
- A missing, changed, duplicate, or ambiguous USB identity is unavailable and cannot be rebound merely because a compatible driver can open it.
- A known invalid configuration does not consume restart attempts; activation rolls back to last known good where available or remains stopped with diagnostics.
- Restart diagnostics are emitted on state transitions and bounded summaries, not on every failed poll.

## Consequences

- Common transient USB and process failures recover unattended without producing a permanent restart storm.
- Persistent faults become visible and quiet while still receiving occasional recovery probes.
- Stable device identity and hotplug behavior become part of source qualification.
- Tests must cover exact rolling-window boundaries, simultaneous hooks, recovery reset, wrong and duplicate USB devices, config failure, source-switch refusal, and post-recovery confirmation.

## Rejected alternatives

Continuous exponential retry would eventually recover without a quiet state, but would maintain indefinite resource and log churn. Manual-only recovery would eliminate restart ambiguity but make ordinary USB reconnects unnecessarily disruptive.
