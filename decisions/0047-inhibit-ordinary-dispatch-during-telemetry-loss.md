# ADR 0047: Inhibit ordinary dispatch during telemetry loss

- Status: Deferred research - non-authoritative for v0.1
- Date: 2026-08-02

## Context

Communication loss is evidence about the monitoring path, not current evidence that utility power is absent or the battery is low. Freezing every possible action indefinitely can nevertheless allow an already observed outage to end in abrupt power loss. NUT's local `upsmon` resolves this tradeoff aggressively for its own host, but router-driven orchestration needs explicit scope and consent.

## Decision

Ordinary uncommitted state-changing dispatch is inhibited while UPS telemetry is stale or unavailable.

- Pending reversible timers retain their monotonic elapsed time but cannot dispatch while the source is stale.
- A fresh contradictory or recovery observation continues to inhibit dispatch, and confirmed online state cancels the applicable reversible episode.
- If confirmed telemetry returns on battery after the timer deadline, the action may proceed only after full prerequisite revalidation.
- Notification-only actions may report `communication_lost` because they describe the monitoring failure rather than infer UPS state.
- Actions that crossed their durable commit boundary before communication loss continue according to their captured policy version.
- NUTMerlin never converts communication loss itself into `low_battery` or FSD.

An administrator may separately activate a telemetry-loss fail-safe:

- The last confirmed state before loss must be on battery.
- Communication loss must remain continuous for at least `max(30 seconds, 2 * source freshness deadline)`; longer configured delays are permitted.
- The policy and every eligible action must be explicitly labeled and validated for telemetry-loss use.
- Eligible effects are notification publication, graceful service stop, and graceful host shutdown through otherwise qualified bindings.
- FSD, abrupt power operations, UPS/PDU output control, coordinator-router actions, retry expansion, and escalation from an unknown result remain prohibited.
- A fresh observation immediately inhibits fail-safe dispatch until the resulting state is confirmed.
- No telemetry-loss fail-safe exists or is prefilled by default.

## Consequences

- Brief USB, driver, or server interruptions do not silently trigger ordinary host actions.
- Installations with short runtime can explicitly choose a bounded last-known-on-battery fail-safe without imposing that risk on everyone.
- Restored telemetry can cause an overdue reversible timer to proceed after confirmation and revalidation, so the UI must show retained elapsed time and inhibition state.
- Tests must cover loss from online and on-battery states, exact delay boundaries, recovery races, already-committed actions, restart, and forbidden fail-safe operation classes.

## Rejected alternatives

Always treating a dead last-known-on-battery source as low battery would protect hosts aggressively but could fan out shutdowns after an ordinary monitoring failure. Permanently forbidding every action during indefinite loss would maximize false-positive resistance but remove an important explicit data-protection option.
