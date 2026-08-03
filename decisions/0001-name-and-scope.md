# ADR 0001: Use the name NUTMerlin and retain NUT as the core

- Status: Accepted
- Date: 2026-08-01
- Updated: 2026-08-02 by ADR 0098

## Decision

Use display name **NUTMerlin**, repository/package slug `nutmerlin`, CLI `nutmerlin`, and addon root `/jffs/addons/nutmerlin`.

Network UPS Tools remains the only UPS protocol, driver, status, and standard-client engine. v0.1 is an integration layer for a conventional NUT server and contains no orchestration or executor runtime.

## Consequences

The product stays compatible with standard NUT clients, avoids duplicating driver/protocol work, and remains client-neutral. Future centralized orchestration requires a separate architecture review.
