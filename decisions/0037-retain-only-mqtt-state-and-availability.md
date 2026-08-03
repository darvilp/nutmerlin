# ADR 0037: Retain only MQTT state and availability

- Status: Deferred research - non-authoritative for v0.1
- Date: 2026-08-02

## Context

Retained MQTT messages are delivered to subscribers that were not present when the message was published. That behavior is useful for a current dashboard snapshot but can replay an old outage transition or action result as though a new event occurred.

## Decision

Only current-state and availability topics may use MQTT retained messages.

- A retained current-state payload includes schema version, source ID, observation timestamp, publication timestamp, and explicit stale or unknown indicators.
- A retained availability topic distinguishes online and offline publisher state, and the binding configures a retained last-will message for unclean disconnect.
- Event-transition topics are never retained.
- Action-result and audit topics are never retained.
- Documentation requires consumers to check current availability and freshness fields before using retained state.
- Graceful disable and uninstall attempt to publish offline and clear retained state before deleting credentials or binding data.
- If the broker is unreachable during cleanup, NUTMerlin reports that remote retained data could not be guaranteed removed; local uninstall still follows its ownership transaction.

## Consequences

- Newly connected dashboards can render state immediately without replaying events as new triggers.
- The broker may retain an obsolete snapshot when cleanup cannot connect, so timestamps and availability remain mandatory consumer inputs.
- MQTT tests need late-subscriber, last-will, stale-state, and cleanup-failure scenarios.

## Rejected alternative

Retaining nothing would eliminate stale broker state but would make new subscribers wait for another publication and reduce usefulness for dashboards and home-automation discovery.
