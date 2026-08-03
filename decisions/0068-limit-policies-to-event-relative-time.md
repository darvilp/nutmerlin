# ADR 0068: Limit policies to event-relative time

- Status: Deferred research - non-authoritative for v0.1
- Date: 2026-08-02

## Context

UPS orchestration requires delays from an observed outage, threshold duration, stage spacing, retry backoff, and verification deadlines. Calendar scheduling adds timezone, daylight-saving transitions, wall-clock synchronization, missed-run, and reboot semantics and would broaden NUTMerlin toward a general automation engine.

## Decision

P0 through P2 policy time is event-relative and monotonic; NUTMerlin provides no calendar scheduler.

- Policy triggers derive from normalized UPS or service events, qualified telemetry thresholds, recovery conditions, and durations measured from those facts.
- Outage delays, stage delays, retry backoff, action budgets, and verification windows use monotonic elapsed time under the applicable restart rules.
- Policies contain no cron expressions, dates, weekdays, time-of-day windows, timezone rules, sunrise/sunset logic, or recurring maintenance schedules.
- Administrators may explicitly activate or deactivate policy versions through management operations.
- External systems may schedule their own independent behavior after consuming NUTMerlin publications, but MQTT remains publish-only and no existing executor becomes an inbound policy-control surface.
- A future maintenance-window feature requires a separate time-authority, boundary-crossing, missed-window, restart, security, and UI decision rather than adding a schedule field to the current policy schema.

## Consequences

- Wall-clock correction cannot make a policy enter or leave an allowed-hours window during an outage.
- Users needing scheduled suppression must manage activation explicitly or use an external orchestrator.
- The policy engine remains focused on power-event semantics and easier to simulate deterministically.
- Tests assert rejection of calendar fields and cover monotonic event-relative durations across wall-clock changes and process/router restart.

## Rejected alternative

A simple allowed-hours or weekday mask would meet common maintenance-window requests, but an outage spanning a boundary, DST fold, clock correction, or reboot would immediately require a much larger scheduling contract.
