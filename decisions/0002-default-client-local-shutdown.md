# ADR 0002: Default to client-local shutdown over NUT

- Status: Accepted
- Date: 2026-08-01
- Updated: 2026-08-02 by ADR 0098

## Decision

The v0.1 shutdown pattern is:

```text
UPS -> NUT server on router -> standard secondary client -> client shuts itself down
```

The administrator may register one independent `upsmon secondary` credential per client. The client owns its local delay, cancellation, thresholds, and shutdown command. NUTMerlin neither executes nor verifies that command and never grants primary, FSD, SET, instant-command, or router-side action authority.

## Consequences

No host-management credential is stored on the router. Client behavior is outside the product claim; v0.1 proves standard authentication and status interoperability, not that a remote host powered off.
