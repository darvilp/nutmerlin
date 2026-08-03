# ADR 0014: Manage Entware dependencies minimally and target current packages

- Status: Superseded by ADR 0098
- Date: 2026-08-01

## Context

Entware is shared infrastructure with a current package feed. Synchronizing or downgrading its packages for NUTMerlin would risk unrelated addons and make NUTMerlin responsible for maintaining old package archives. Ignoring missing or incompatible dependencies would make installation unreliable.

## Decision

NUTMerlin uses minimal, scoped dependency management and treats the current supported Entware feed as its gold standard.

- Never run a blanket `opkg upgrade`.
- Inspect installed versions before proposing mutation.
- Leave compatible required packages unchanged.
- Present an explicit package plan before installing missing packages or upgrading incompatible required packages.
- When NUT components must change together, mutate only the required NUT package cohort.
- Never downgrade or pin packages automatically.
- Install executor-specific optional dependencies only when that executor is enabled.
- Refresh feed metadata only during an explicit install, repair, or dependency action.
- Offline operation and repair remain available when compatible dependencies are already installed.
- Record package versions and provenance before and after mutation.
- In this project, the latest NUT package set means the current package cohort available from the supported Entware feed, not the newest upstream NUT source release.
- Qualify NUTMerlin against that current Entware package cohort.
- Do not require, fetch, or preserve an older package set as the solution to incompatibility with the current feed; update NUTMerlin instead.
- Do not build, vendor, or retrieve alternate NUT binaries when the Entware feed lags upstream.
- Report a newer upstream NUT release as informational feed lag.
- If the current Entware cohort has a critical unresolved vulnerability or safety defect, warn or refuse affected operation and pursue an upstream or Entware resolution rather than silently substituting a private build.

An already-installed older NUT package cohort may run as compatibility-only when all of these conditions hold:

- Core NUT packages report a coherent upstream version rather than a mixed cohort.
- Required binaries, options, and configuration behavior are present.
- Configuration validation and a harmless `dummy-ups` smoke test pass.
- No applicable critical vulnerability or known safety defect requires refusal.

Interactive installation presents a package plan and defaults to upgrading such a cohort to the current Entware versions. The administrator may explicitly keep the older compatible cohort. Keeping it produces a persistent compatibility-only diagnostic and makes the combination ineligible for current hardware qualification. Mixed, incomplete, or known-unsafe cohorts require scoped repair and cannot start managed services.

Unattended installation requires an explicit dependency policy whenever package mutation is needed.

- Automation must choose either the current Entware cohort or preservation of a coherent compatibility-only cohort while installing only missing requirements.
- Without a declared policy, NUTMerlin emits the proposed package plan and exits without mutation.
- If no package mutation is needed, unattended installation may continue normally.
- No policy can authorize a mixed, incomplete, or known-unsafe cohort.

## Consequences

- Fresh installations normally receive the feed's current packages without affecting unrelated Entware software.
- A breaking current-feed change is a NUTMerlin compatibility issue rather than a reason to downgrade users.
- Entware remains the single runtime package supply chain for NUT.
- Release reports and tests must record the exact gold-standard package set.
- Optional executors do not inflate the core dependency footprint.
- Existing coherent installations are not mutated unnecessarily when the administrator explicitly accepts compatibility-only status.

## Rejected alternative

Synchronizing every installation to an exact archived package set would improve reproducibility but require package pinning, downgrades, archive maintenance, and broader mutation of shared Entware state.
