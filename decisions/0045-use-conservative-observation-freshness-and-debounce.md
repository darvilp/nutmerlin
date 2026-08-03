# ADR 0045: Use conservative observation freshness and debounce

- Status: Deferred research - non-authoritative for v0.1
- Date: 2026-08-02

## Context

NUT normally polls frequently and marks missing driver data stale. Its `upsmon` client is designed to protect its own host and may deliberately infer a critical condition when communication is lost after a known on-battery state. NUTMerlin can dispatch actions to many independent targets, so a cached or single contradictory sample must not become action authority.

The repository requires stale and contradictory telemetry to fail closed but does not define freshness or debounce numerically.

## Decision

NUTMerlin applies its own conservative observation contract on top of NUT.

- The default status-observation interval is 5 seconds.
- A source is stale immediately when NUT reports stale data, or after 15 seconds without a successful fresh observation under the default interval.
- If a qualified source profile changes the observation interval, the NUTMerlin freshness deadline is `max(15 seconds, 3 * observation interval)`.
- Supported source-profile intervals are 2 through 30 seconds; values outside that range require a later compatibility decision rather than unchecked configuration.
- An action-eligible normalized state requires two consecutive fresh, mutually consistent observations separated by at least one observation interval.
- The first fresh observation contradicting the active condition or indicating recovery immediately inhibits new dispatch. Two consecutive consistent observations are still required to confirm the replacement state and close or transition the episode.
- An `ups.status` set containing both `OL` and `OB`, no recognized line-state token, `WAIT`, malformed tokens, or another defined contradiction is unknown and never action-eligible.
- Displayed last-known values remain clearly marked stale and cannot satisfy a policy prerequisite.
- Freshness uses monotonic elapsed time. Wall-clock timestamps remain audit metadata only.
- Source-specific exceptions must be part of a qualified hardware/driver profile and visible in diagnostics; silent adaptive widening is not allowed.

## Consequences

- Default behavior aligns with NUT's common 5-second poll and 15-second stale timing without inheriting its local-host shutdown inference.
- A genuine transition normally becomes action-eligible about one poll interval after first observation, while a possible recovery blocks dispatch immediately.
- Profiles for unusually slow drivers need explicit qualification.
- Tests require boundary coverage at 2, 5, 15, and 30 seconds; consecutive-sample, contradictory-token, stale-cache, wall-clock-jump, and recovery-inhibition cases.

## Rejected alternative

Delegating all state timing to `upsmon`, including its last-known-on-battery communication-loss behavior, would reuse mature NUT semantics but could initiate broad router-dispatched actions from missing rather than current evidence.
