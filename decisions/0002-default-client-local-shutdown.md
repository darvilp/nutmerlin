# ADR 0002: Default to client-local shutdown over NUT

- Status: Accepted
- Date: 2026-08-01

## Context

A router can either expose UPS state for clients to monitor or centrally push shutdown commands. The initial personal use case is a Windows PC that should shut down after a short outage while the router and ONT remain powered.

## Decision

The default pattern is:

```text
UPS -> NUT server on router -> client polls NUT -> client shuts itself down
```

NUTMerlin will provide connection information and guidance, but each target host owns its shutdown privilege and local action.

SSH is the first optional agentless executor. Webhook, MQTT, FSD, WinRM, Redfish, and SNMP/PDU follow according to the backlog.

## Rationale

- No privileged host credentials on the router.
- Standard NUT interoperability.
- Per-host policy and shutdown type.
- Works across Windows, Linux, NAS, and other clients.
- Router compromise has a smaller blast radius.
- Returning power can cancel a client-local pending shutdown.

## Consequences

- Each host needs a client and local configuration.
- Client behavior and quality vary.
- Central sequencing requires later policy/executor features.

## Rejected default

Central SSH push is not the default because it requires remote services, credentials, and target-specific privilege configuration.
