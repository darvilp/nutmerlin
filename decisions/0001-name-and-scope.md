# ADR 0001: Use the name NUTMerlin and retain NUT as the core

- Status: Accepted
- Date: 2026-08-01

## Context

The addon may eventually support SSH, webhooks, MQTT, WinRM, Redfish, SNMP/PDU control, alerts, and load shedding. A generic UPS name could imply that the project owns device protocols and all orchestration.

## Decision

Use:

- display name: **NUTMerlin**
- repository/package slug: `nutmerlin`
- CLI: `nutmerlin`
- addon directory: `/jffs/addons/nutmerlin`

NUT remains the UPS device and network protocol engine. Other mechanisms are executors consuming NUT-derived events.

## Consequences

### Positive

- Immediately communicates compatibility with the NUT ecosystem.
- Avoids duplicating NUT drivers.
- Keeps the project client-neutral.
- Makes the additional integrations understandable as optional extensions.

### Negative

- Some users may assume the addon only exposes NUT and does no orchestration.
- Documentation must explain that SSH/webhook/MQTT/etc. are supported executors.

## Revisit when

Reconsider only if the project stops using NUT as its primary event/device layer.
