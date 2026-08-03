# ADR 0074: Defer all writable UPS administration

- Status: Deferred research - non-authoritative for v0.1
- Date: 2026-08-02

## Context

After output-cutting operations moved to `Later`, the P2 sketch still permits "harmless" UPS administration such as beeper control, battery self-test, variable writes, and capability discovery. NUT instant-command names and writable variables do not establish uniform physical behavior across drivers, UPS firmware, battery condition, or current power state. A generic command surface would also require a high-authority NUT credential on the router.

## Decision

P0 through P2 expose no writable UPS or PDU administrative operation.

- NUTMerlin does not provide raw `upscmd`, raw `upsrw`, arbitrary instant-command names, arbitrary variable writes, or a normal UI/CLI pass-through.
- The installed P0 through P2 operation registries contain no beeper, battery-test, calibration, bypass, outlet, shutdown, startup, delay, or other device-write operation.
- NUTMerlin does not create or retain a general NUT `actions = SET` or `instcmds = ALL` administrative credential for future convenience.
- Registered secondary shutdown-client credentials remain limited to their `upsmon secondary` role and cannot perform administration. Any future complete FSD primary authority remains a separate lifecycle role rather than a generic administrative credential.
- Read-only NUT status and capability observations may be displayed and included in hardware evidence, but discovery never grants write authority or promises that a reported command is safe.
- `NUTMERLIN_ALLOW_UPS_COMMANDS=1` is a test-stage confirmation only where a future explicitly registered non-output operation requires it; in current milestones it enables no product operation and never authorizes output control.
- Future writable administration is `Later` and requires one typed operation per normalized effect, exact UPS/driver/firmware qualification, qualified preconditions, independent least-privilege credentials, harmless simulation, manually gated physical tests, audit, and its own UI/CLI interaction decision.
- Output-changing commands additionally remain subject to ADRs 0039 and 0070 and cannot be admitted by a lower-risk future administrative ADR.

## Consequences

- NUTMerlin cannot silence a UPS alarm or initiate a battery self-test through P2.
- A compromised P0 through P2 addon credential cannot be reused for arbitrary NUT variable or instant-command writes because no such credential is provisioned.
- UPS compatibility work remains focused on observing status and qualifying telemetry rather than interpreting vendor command behavior.
- Requirements, security examples, plan, and backlog entries for optional P2 UPS commands move to `Later` during reconciliation.
- Tests must prove generated users lack SET and general instant-command authority, raw command input is rejected, and the environment gate alone exposes nothing.

## Rejected alternative

A fixed P2 allowlist for beeper toggle and battery self-test while online would offer common maintenance conveniences. It is rejected because command presence and an `OL` token do not prove harmless firmware behavior, adequate battery reserve, or safe device state, and the feature would require retaining write-capable NUT authority.
