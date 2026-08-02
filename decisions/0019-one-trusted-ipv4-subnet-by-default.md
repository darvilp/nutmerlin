# ADR 0019: Admit one confirmed trusted IPv4 subnet by default

- Status: Accepted
- Date: 2026-08-02

## Context

Read-only NUT access is unauthenticated, so listener and firewall scope are its access-control boundary. Per-client allowlists minimize visibility but are brittle under DHCP and create silent monitoring failures. Automatically trusting every LAN-like interface can admit guest, VPN, or otherwise untrusted networks.

## Decision

The default read-only NUT scope is one explicitly confirmed trusted IPv4 subnet.

- Detect the primary router LAN address and subnet only as a proposed value; require administrator confirmation before admitting it.
- Bind `upsd` to the selected router LAN address rather than a wildcard address.
- Admit TCP port 3493 only from the selected source CIDR by default.
- Deny WAN, guest, VPN-client, and other VLAN or subnet sources unless separately and explicitly enabled.
- Permit advanced configurations to narrow the scope to individual client addresses or add other explicitly trusted subnets.
- Show the effective listener address and source scope in onboarding and diagnostics.
- If the router address or subnet changes ambiguously, remove stale managed rules and fail closed rather than broadening access.
- Do not create an IPv6 listener or IPv6 firewall admission rule by default.
- Permit explicit IPv6 opt-in only when NUTMerlin can identify a specific trusted LAN address and source prefix, enforce denial from WAN and other untrusted interfaces, and obtain administrator confirmation.
- Never use the IPv6 wildcard listener address as a substitute for interface classification.
- Display IPv4 and IPv6 listener and source scopes independently.
- If a delegated prefix changes or the effective IPv6 firewall scope becomes ambiguous, remove stale managed rules and disable IPv6 NUT access rather than broadening it.
- Treat link-local-only onboarding as outside the initial supported configuration.

## Consequences

- DHCP clients on the trusted subnet can use standard NUT access without individual firewall maintenance.
- Every host admitted by that subnet can read the exposed UPS telemetry.
- Interface classification and stale-rule removal require negative-path tests across Merlin firewall implementations.
- Dual-stack clients use IPv4 unless the administrator completes the separate IPv6 opt-in.
- IPv6 support can be added without changing the default network exposure.

## Rejected alternative

Requiring individual client addresses by default would reduce telemetry exposure, but would make DHCP reservations effectively mandatory and increase the chance of unnoticed client disconnection.

Automatically mirroring the trusted IPv4 scope into IPv6 would make dual-stack onboarding more transparent, but delegated prefixes, temporary addresses, and firmware-specific firewall behavior could silently create a broader exposure than the administrator confirmed.
