# ADR 0058: Require a unique stable USB source identity

- Status: Accepted
- Date: 2026-08-02

## Context

For `usbhid-ups`, `port=auto` is required syntax but does not identify a particular libusb device. NUT supports vendor, product, numeric IDs, serial, bus, device, and sometimes physical bus-port selectors. Its documentation identifies serial as the best discriminator, warns that logical bus and device numbers are unstable, and describes duplicate-first matching as nondeterministic.

The P0 product manages exactly one source but must not let that simplify into first-device selection.

## Decision

A real USB source must satisfy one stable identity constraint that resolves to exactly one device.

- The preferred constraint is exact USB vendor ID, product ID, and a present, stable serial number.
- Stable exact vendor and product strings may supplement those identifiers but do not replace numeric IDs where the device exposes them.
- When no stable serial exists, exact VID/PID plus other qualified descriptor evidence is permitted only while discovery produces exactly one candidate.
- A hardware profile may additionally use a demonstrated stable physical `busport` selector, but bus-port support and stability are qualification facts and it is never the sole portable identity.
- Logical USB bus and device numbers are diagnostics only and cannot provide durable source identity.
- NUT's `allow_duplicates` behavior and any first-compatible-device fallback are unsupported.
- The UI accepts discovered literal attributes, not raw regular expressions. Configuration generation escapes and anchors every NUT selector value.
- Installation, activation, reboot, and reconnect require exactly one match. Zero, multiple, changed, or incomplete matches leave the source unavailable and invoke bounded recovery diagnostics rather than rebinding.
- A source identity change requires an explicit source-replacement workflow, fresh telemetry qualification, and policy revalidation.

## Consequences

- A hotplug or reboot cannot silently associate the configured source name with a different UPS.
- Devices without unique serials remain usable in simple one-match installations but become unavailable if ambiguity appears.
- Multiple identical no-serial UPSes require future multi-source identity work rather than unsafe duplicate matching.
- Tests need selector escaping, missing and changing serials, duplicate VID/PID devices, unstable logical enumeration, qualified bus-port behavior, and source replacement.

## Rejected alternative

Binding the first compatible USB device would minimize onboarding for single-UPS households, but the association could change after enumeration, replacement, or adding another similar device without any visible policy change.
