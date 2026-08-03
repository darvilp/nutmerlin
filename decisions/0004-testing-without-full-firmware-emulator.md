# ADR 0004: Do not require a full Asuswrt-Merlin emulator

- Status: Accepted
- Date: 2026-08-01
- Updated: 2026-08-02 by ADR 0098

## Decision

Use separate evidence layers:

1. POSIX/static checks.
2. Host unit and golden tests through public seams.
3. Real host `dummy-ups -> upsd -> upsc` integration.
4. Simulated Merlin lifecycle through isolated platform shims.
5. Manually gated exact RT-AX86U Pro evidence.
6. Separately gated CP1500PFCLCD evidence.

A full firmware emulator, ARMv7 execution, and the RT-AC3100 are optional later research. Ordinary pull requests require only layers 1–4.

## Consequences

Normal development is repeatable and hardware-free. No evidence layer may claim behavior belonging to another layer.
