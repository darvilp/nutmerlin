# ADR 0059: Gate external NUT access on verified firewall scope

- Status: Accepted
- Date: 2026-08-02

## Context

Binding `upsd` to a selected LAN address prevents wildcard exposure but does not prove that guest, VPN, VLAN, or other routed sources cannot reach that address. Read-only NUT access is intentionally unauthenticated inside the admitted scope, making listener and firewall enforcement a combined boundary.

## Decision

External NUT access is active only while its network exposure gate is satisfied.

- Activation requires the effective `upsd` listener to match the configured specific address and the managed source-filter rules to match every explicitly confirmed source scope.
- NUTMerlin verifies both layers during configuration activation, NUT service restart, LAN address or prefix change, each Merlin firewall-restart hook, and every 300 seconds as drift detection.
- A missing, stale, broadened, conflicting, or unverifiable managed rule immediately fails the gate.
- On gate failure, NUTMerlin removes stale managed rules and disables the external listener, retaining loopback-only local status where the qualified NUT configuration supports it.
- It never substitutes a wildcard listener, trusts a newly detected subnet, or weakens source filtering to preserve availability.
- Restoration may reapply and reactivate the exact previously confirmed scope automatically after verification.
- Router-outbound policy work may continue only when it has no dependency on external NUT client reachability.
- Shutdown-client availability, complete FSD, and any workflow depending on connected NUT clients are explicitly degraded and inhibited while the gate is closed.
- Gate transitions are high-priority local diagnostics but do not themselves authorize a state-changing target action.

## Consequences

- Firewall drift sacrifices NUT client availability rather than exposing telemetry or credentials to an unconfirmed network.
- Listener health must include effective socket and packet-filter inspection, not merely process status.
- Outbound orchestration and inbound NUT access can degrade independently.
- Tests must cover rule deletion, broadening, ordering conflicts, firewall restart races, LAN renumbering, IPv4 and opted-in IPv6 scopes, loopback fallback, and exact-scope restoration.

## Rejected alternative

Keeping a specifically bound LAN listener active with a warning would improve availability, but routed untrusted networks could still reach it when the packet-filter boundary failed.
