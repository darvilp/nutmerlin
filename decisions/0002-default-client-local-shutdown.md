# ADR 0002: Default to client-local shutdown over NUT

- Status: Accepted
- Date: 2026-08-01

## Context

A router can either expose UPS state for clients to monitor and act on locally or centrally push shutdown commands. A community addon must support heterogeneous clients without making any one operating system, client package, or remote-management protocol a runtime dependency.

## Decision

The default pattern is:

```text
UPS -> NUT server on router -> client polls NUT -> client shuts itself down
```

NUTMerlin will provide connection information and guidance, but each target host owns its shutdown privilege and local action.

P0 includes explicit onboarding for standard NUT shutdown clients:

- A fresh installation exposes only the separately defined read-only NUT access and creates no shutdown-role credential.
- An administrator may explicitly register a shutdown client, causing NUTMerlin to provision credentials with only the NUT `upsmon secondary` role and to provide client-neutral configuration guidance.
- The client owns its delay, cancellation behavior, thresholds, and local shutdown command. NUTMerlin does not execute or verify that local command from the router.
- Shutdown-client onboarding never grants `upsmon primary`, FSD, `SET`, or instant-command authority.
- Credentials are allocated independently per shutdown client; generation and rotation are governed by separate credential-lifecycle decisions.
- Optional WinNUT guidance must not make WinNUT or Windows part of the runtime contract.
- Shutdown-client onboarding is not an executor and does not create router-side action results.

Milestone 1's exclusion of host shutdown orchestration means router-initiated execution and sequencing are out of scope; it does not exclude standard secondary-client onboarding.

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
- P0 must generate and test restricted `upsmon secondary` configuration and onboarding without claiming that a remote host actually powers off.
- Central sequencing requires later policy/executor features.

## Rejected default

Central SSH push is not the default because it requires remote services, credentials, and target-specific privilege configuration.
