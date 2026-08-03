# ADR 0005: Treat Merlin 386/ARMv7 as legacy best-effort

- Status: Deferred research - non-authoritative for v0.1
- Date: 2026-08-01

## Context

The available spare router is an ASUS RT-AC3100 currently running stock Asuswrt. It can provide real Addons API, JFFS, Entware, ARMv7, USB, mount-order, and lifecycle evidence, but its Merlin branch is end-of-life.

Its availability as maintainer-owned hardware does not justify making its platform part of the community support contract.

## Decision

Merlin 386/ARMv7 is a legacy best-effort platform, not a supported release tier.

- Host tests and NUT `dummy-ups` are the normal development path.
- No standard CI, pull-request check, or release gate requires the RT-AC3100.
- The router is an optional test asset and is used only when it provides meaningful compatibility or lifecycle evidence.
- A test may skip it when setup cost, hardware condition, or platform differences make its evidence immaterial.
- Compatibility obtained through portable code and capability detection is welcome, but is not a maintenance or security promise.
- The RT-AX86U Pro remains the manually gated production-reference target.

## Consequences

- Initial development and releases do not depend on locating, flashing, or maintaining the spare router.
- Legacy compatibility regressions do not block a release.
- Users must not infer current-firmware security support from successful operation on Merlin 386.
- The old router may provide useful evidence without defining product scope or architecture.
