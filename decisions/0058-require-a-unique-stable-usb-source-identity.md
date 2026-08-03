# ADR 0058: Require a unique stable USB source identity

- Status: Accepted
- Date: 2026-08-02
- Updated: 2026-08-02 by ADR 0098

## Decision

- The preferred identity is exact USB VID/PID plus a present stable serial.
- Without a stable serial, v0.1 requires exact VID/PID plus an explicitly qualified stable physical `busport`.
- Logical USB bus and device numbers are diagnostic only.
- Discovery and every activation/reconnect must resolve exactly one device.
- Zero, duplicate, changed, or incomplete matches leave `ups` unavailable.
- `allow_duplicates`, arbitrary regular expressions, and first-compatible-device fallback are unsupported.
- `port=auto` is generated only as NUT protocol syntax and is never source authority.

## Consequences

If the reference UPS exposes no qualifying stable identity, the physical-source claim stops rather than weakening selection.
