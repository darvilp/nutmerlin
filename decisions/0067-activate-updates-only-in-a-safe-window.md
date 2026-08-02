# ADR 0067: Activate updates only in a safe window

- Status: Accepted
- Date: 2026-08-02

## Context

Two-slot staging makes interrupted file replacement recoverable but does not make every activation time safe. Restarting NUT, migrating policy state, or changing privilege and firewall behavior during an outage can remove observation or alter action meaning. A process-start check alone cannot establish that the candidate is healthy enough to finalize rollback state.

## Decision

Release staging and verification may occur during any explicit administrator update session, but activation requires a safe update window.

Normal activation requires:

- confirmed online UPS state under ADR 0045
- no active event episode, pending state-changing action, committed sequence, unknown outcome, storage fault latch, or unresolved restart reconciliation
- healthy writable storage and safety journal with required headroom
- currently satisfied listener/firewall and privilege-separation gates

Maintenance activation is permitted when the real source is unavailable only if:

- the administrator explicitly disables NUTMerlin before activation
- policies, executors, shutdown-client service, and external NUT access remain closed
- candidate health uses local `dummy-ups` and harmless probes
- the updated addon remains disabled until the administrator resolves the real source and explicitly enables it

Candidate health requires 120 continuous seconds and, at the default interval, at least 24 consecutive fresh observations. It also requires stable driver and `upsd` processes, validated generated configuration, working CLI and web-status adapters, privilege-boundary probes, safety-journal writes, ownership checks, and exact listener/firewall validation applicable to the activation mode.

- Failure during this window receives the single automatic rollback attempt defined by ADR 0012.
- A later failure after successful finalization raises diagnostics and leaves manual rollback available; it does not cause unattended version oscillation.
- The previous release slot remains intact until a later authenticated update needs its space.
- Every schema or data migration must retain or generate a validated representation usable by the previous release. A candidate without a tested rollback representation is ineligible for activation.
- Activation never enables a new policy or capability under ADR 0042.

## Consequences

- Updates may be downloaded and prepared without disrupting a live outage, but activation waits or enters explicit disabled maintenance.
- Health finalization takes at least two minutes.
- Migration formats need backward rollback fixtures, not merely forward conversion tests.
- Tests must interrupt every journal phase, exercise both activation modes, fail each health probe, cross the 120-second boundary, and prove absence of late rollback loops or capability activation.

## Rejected alternative

Activating immediately after process-start checks would shorten updates but could restart monitoring during an outage and finalize a release before data freshness, firewall, policy, privilege, or rollback health was established.
