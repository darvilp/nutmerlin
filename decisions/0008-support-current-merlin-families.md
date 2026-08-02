# ADR 0008: Support both current Merlin firmware families

- Status: Accepted
- Date: 2026-08-01

## Context

Current upstream-supported Asuswrt-Merlin devices span the `3004.388.x` and `3006.102.x` firmware families. Limiting NUTMerlin to the family used by the maintainer's RT-AX86U Pro would reduce initial test cost, but would exclude many current community devices for reasons unrelated to NUTMerlin's intended scope.

## Decision

The intended supported platform contract includes both `3004.388.x` and `3006.102.x` on AArch64.

- `3006.102.x` is the production-reference family because the available RT-AX86U Pro runs it.
- `3004.388.x` receives the same intended support status despite the absence of maintainer-owned hardware in that family.
- Each family must meet the project's qualification criteria before a release advertises it as supported.
- Within each family, only the latest NUTMerlin-qualified upstream stable release is supported.
- A newly published upstream release does not inherit support automatically. The previously qualified release remains supported until the new release qualifies.
- When the new release qualifies, the prior release leaves the support contract without a retirement grace period.
- Earlier releases may remain compatible, but they are compatibility-only platforms and regressions on them do not block a release.
- A shared CPU architecture or Entware feed is not sufficient qualification by itself; Addons API, lifecycle, UI, networking, and recovery behavior also require evidence.

## Consequences

- Platform adapters and tests must account for meaningful differences between both current firmware families.
- Qualification may use reproducible community hardware evidence where maintainer-owned hardware is unavailable.
- A release must identify the one supported firmware release within each family rather than claiming every historical family member implicitly.
- Users of older releases may receive useful compatibility help, but no release or security-maintenance promise.
- Merlin 386/ARMv7 remains legacy best-effort under ADR 0005.

## Rejected alternative

Supporting only `3006.102.x` initially would match the available production-reference router and reduce test scope, but would make personal hardware availability define a community addon's product boundary.
