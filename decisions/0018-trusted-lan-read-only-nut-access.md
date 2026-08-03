# ADR 0018: Expose native read-only NUT access to trusted LAN clients

- Status: Superseded by ADR 0098
- Date: 2026-08-02

## Context

NUT clients such as `upsc` do not currently require credentials for read-only `GET` and `LIST` access. The `upsd.users` file governs administrative commands and `upsmon` roles, so presenting a read-only username and password would create a false authentication boundary. Client-local shutdown remains the default NUTMerlin deployment pattern.

## Decision

NUTMerlin permits native unauthenticated read-only NUT access within explicitly trusted LAN scope.

- Listener binding and firewall admission are the protection boundary for read-only status.
- Client onboarding states plainly that admitted hosts can read exposed UPS status and identity without credentials.
- The basic server configuration does not create an administrative or `upsmon` user unless an explicitly enabled feature requires one.
- `upsmon` primary or secondary roles, FSD, variable writes, and instant commands use separate credentials and least-privilege capabilities.
- Status descriptions and exported telemetry contain no secrets and avoid unnecessary device serial numbers.
- The CLI and any installed WebUI show the effective listener address and firewall scope.
- Trusted-LAN admission uses the one confirmed IPv4 subnet and listener/firewall contract in ADRs 0019 and 0059.

## Consequences

- Standard NUT clients work without a NUTMerlin-specific proxy or credential fiction.
- Any host admitted by the network boundary can read UPS telemetry.
- Firewall and listener correctness become release-blocking security behavior.
- Requirements that imply a credential for ordinary read access must be corrected during reconciliation.

## Rejected alternative

Localhost-only access with a VPN, SSH tunnel, or authenticated proxy would conceal telemetry from other LAN hosts, but would complicate standard NUT interoperability and client-local shutdown onboarding.
