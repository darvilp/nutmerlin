# ADR 0071: Defer target restoration actions to Later

- Status: Deferred research - non-authoritative for v0.1
- Date: 2026-08-02

## Context

The P2 Redfish sketch includes optional power-on after restoration, but the policy model does not yet establish that NUTMerlin caused a target to stop, that utility power is durably stable, that dependencies are ready, or that booting the target is operationally safe. A recovery event is evidence that one UPS observation changed; it is not authorization to restart workloads or hosts.

## Decision

Automatic target restoration is `Later`, outside P0 through P2.

- The P0 through P2 operation registries contain no operation whose primary effect is to power on a host, boot a target, start a previously shed workload, or reverse a shutdown action in response to `online` or `communication_restored`.
- Recovery may cancel eligible uncommitted outage work, update current state, publish explicitly enabled notifications, and satisfy observation-only policy transitions.
- Recovery does not create an implied inverse action for a completed service stop, host shutdown, FSD request, or unknown action outcome.
- Redfish P2 remains limited to discovery, power-state query, `GracefulShutdown`, and bounded `Off` verification under ADR 0040; `On`, `PowerCycle`, reset, and automatic restoration are absent.
- NUTMerlin's own bounded service recovery under ADRs 0051 and 0052 is lifecycle supervision, not target restoration, and cannot be generalized into a policy executor.
- Complete production FSD remains unavailable until its separately qualified output and power-restoration lifecycle is defined; this decision does not supply that missing lifecycle.
- Documentation may describe administrator-managed recovery outside NUTMerlin but cannot claim an automated round trip.

A future restoration design requires a separate ADR covering at least:

- durable proof that NUTMerlin successfully stopped the exact target or workload
- fresh, qualified utility-stability and source-health criteria with explicit anti-flap timing
- dependency-aware startup order and target protections
- idempotency, retry, unknown-outcome, and reboot reconciliation
- least-privilege startup credentials distinct from shutdown credentials where possible
- harmless tests plus exact-protocol and hardware qualification
- manual override, audit, and an explicit decision about whether restoration survives router restart

## Consequences

- Load shedding through P1/P2 is one-way; an administrator or independent system restores shed targets.
- A transient online observation cannot unexpectedly boot machines, storage, or workloads.
- P2 requirements and backlog entries for optional Redfish `On` move to `Later` during reconciliation.
- Recovery tests must prove cancellation and notification without inverse dispatch, including after completed and unknown shutdown outcomes.

## Rejected alternative

A paired service-start or Redfish `On` action after 120 seconds of confirmed online state, limited to targets successfully stopped in the current episode, would make unattended load shedding more convenient. It is rejected for P0 through P2 because it still requires durable stop provenance, startup dependency ordering, boot verification, and restart semantics that the present policy contract does not define.
