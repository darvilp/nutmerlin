# ADR 0004: Do not require a full Asuswrt-Merlin emulator

- Status: Accepted
- Date: 2026-08-01

## Context

Only one real UPS is available. There is a primary RT-AX86U Pro and an optional ASUS RT-AC3100 currently running stock Asuswrt. Full Merlin firmware emulation under QEMU is difficult because of model-specific hardware, NVRAM, initialization, USB, networking, and closed binaries.

## Decision

Use layered testing:

1. host tests with Merlin command/filesystem shims
2. NUT integration tests with `dummy-ups`
3. required current AArch64/Entware package and ABI release evidence under ADR 0064
4. optional RT-AC3100 as the legacy Merlin 386/ARMv7 lifecycle rig
5. primary router and real UPS for manually gated integration

ARMv7 user-mode execution and full firmware rehosting remain optional research or legacy evidence.

## Consequences

- Most tests run quickly without hardware.
- When used, the spare router provides more relevant addon coverage than an incomplete firmware boot.
- Real UPS battery cycling is minimized.
- Platform adapter boundaries become a mandatory design constraint.
