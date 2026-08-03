# ADR 0059: Gate external NUT access on verified firewall scope

- Status: Accepted
- Date: 2026-08-02
- Updated: 2026-08-02 by ADR 0098

## Decision

- External NUT is disabled by default and never available for dummy.
- Require one administrator-entered router LAN IPv4 address and one administrator-entered source IPv4 CIDR.
- Reject wildcard, `/0`, loopback, multicast, broadcast, WAN-equal, invalid, and default IPv6 exposure.
- Bind `upsd` only to loopback plus the selected address.
- Create one attributable allow-then-deny firewall chain and verify both the effective listener and exact rules before reporting exposure healthy.
- Revalidate at configuration activation, service restart, firewall hook, LAN change, and the five-minute reconciler.
- Missing, stale, broadened, conflicting, or unverifiable rules close external admission and preserve only loopback where safe.

## Consequences

Availability is sacrificed rather than widening access. No policy, FSD, IPv6, guest, VPN, or WAN behavior is implied.
