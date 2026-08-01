# ADR 0005: Keep the RT-AC3100 optional

- Status: Accepted
- Date: 2026-08-01

## Context

The available spare router is an ASUS RT-AC3100 currently running stock Asuswrt. It can provide real Addons API, JFFS, Entware, ARMv7, USB, mount-order, and lifecycle coverage, but its Merlin branch is end-of-life and setting it up adds friction.

The project must be easy to develop through Codex in WSL2 without requiring old hardware to be continuously available.

## Decision

The RT-AC3100 is an optional, manually invoked legacy integration profile.

- Host tests and NUT `dummy-ups` are the normal development path.
- No standard CI or pull-request check requires the RT-AC3100.
- The router is used for selected 386/ARMv7 compatibility and lifecycle tests.
- The RT-AX86U Pro remains the manually gated production-reference target.
- Community hardware reports may satisfy cross-model release coverage.

## Consequences

- Initial development can begin without locating a drive or flashing the spare router.
- Hardware-specific regressions may be discovered later than host-level defects.
- Platform adapters and capability detection remain mandatory.
- The old router provides valuable legacy coverage without defining the whole project architecture.
