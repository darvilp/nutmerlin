# ADR 0057: Distinguish same-boot restart from router reboot

- Status: Superseded by ADR 0098
- Date: 2026-08-02

## Context

Pending policy timers use monotonic time so wall-clock correction cannot fire them early. Monotonic values remain comparable across an ordinary process restart in the same boot but not across router reboot. Forgetting all durable state can repeat an action; resuming from wall-clock time can make an incorrect clock authorize one.

## Decision

Every policy-engine start performs restart reconciliation before enabling dispatch.

- The safety journal records the router boot identity, source episode identity, immutable policy version, monotonic timing facts, completed actions, dispatch intent, attempt state, and unresolved outcomes needed for recovery.
- Within the same boot, pending reversible timers and remaining eligible retry budgets resume from persisted monotonic facts after configuration validation and two fresh observations confirm the applicable condition.
- Across a router reboot, an uncommitted reversible timer never derives elapsed duration from wall-clock time. If its condition is freshly confirmed, it restarts the full configured delay from zero.
- An action recorded as terminal success or terminal failure remains terminal for the persisted source episode and is not re-dispatched merely because the router rebooted.
- A durable dispatch intent without conclusive execution and verification evidence becomes an unknown outcome after reboot and is not automatically repeated.
- No new state-changing action that conflicts with or depends on unresolved committed state may run until explicit reconciliation records the outcome or safely abandons dependent work.
- Complete FSD recovery follows its separately qualified latched lifecycle and cannot use ordinary restart reset behavior.
- Missing, corrupt, internally inconsistent, or future-unsupported journal records set the storage fault latch and leave automation inhibited.
- Wall-clock time may label records and help administrators investigate, but never supplies elapsed outage or retry authority across boot.

## Consequences

- Router reboot can lengthen an uncommitted outage delay, favoring false-negative over false-positive shutdown.
- Completed and possibly dispatched actions are not repeated after reboot.
- Same-boot service recovery retains useful continuity without weakening monotonic-time guarantees.
- Tests need boot-identity changes, wall-clock jumps, every crash point around dispatch intent, pending and completed actions, corrupt and future journal formats, and explicit reconciliation.

## Rejected alternative

Resuming timers from persisted wall-clock deadlines when the clock appears plausible would improve outage continuity, but plausibility checks cannot establish elapsed time accurately enough to authorize state-changing work after router boot.
