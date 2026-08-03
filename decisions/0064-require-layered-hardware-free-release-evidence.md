# ADR 0064: Require layered hardware-free release evidence

- Status: Superseded by ADR 0098
- Date: 2026-08-02

## Context

Normal development cannot depend on an ASUS router or physical UPS. Pure x86 host shims do not execute the supported Entware architecture or exact package cohort, while full firmware emulation still cannot establish model-specific kernel, Addons API, firewall, USB, or mount behavior. Treating every layer as equivalent would overstate compatibility; requiring physical hardware for every release would make maintenance brittle.

## Decision

NUTMerlin uses bounded release evidence layers with explicit claims.

Host conformance is required for every change and includes:

- POSIX-shell lint and formatting, unit and golden configuration tests, ownership and lifecycle fault injection, policy state machines, security/input tests, complete CLI and optional WebUI contract tests, executor doubles, and NUT `dummy-ups` integration
- simulation of both supported current Merlin-family capability profiles plus negative and missing-capability profiles
- no router, UPS, direct WSL USB, or live target dependency

Package and ABI evidence is required for every release candidate:

- execute the exact gold-standard current AArch64 Entware package cohort in a reproducible user-mode or rootfs environment
- verify executable architecture and linkage, package versions, required POSIX shell/runtime tools, NUT configuration parsing, `dummy-ups` driver and `upsd` startup, `upsc` queries, and required verifier capabilities
- record the immutable package index and package hashes used by the run

Additional boundaries:

- ARMv7 Entware user-mode results are nonblocking legacy best-effort evidence.
- Neither host shims nor user-mode package execution qualify Addons API behavior, firmware hooks, packet filtering, USB permissions/hotplug, mount ordering, resource limits, or an exact router.
- The first public release requires one complete current-family exact-router qualification report under ADR 0009. Later releases require fresh router evidence only when ADR 0009's risk triggers apply; otherwise the report may carry forward explicitly.
- Publishing the optional WebUI artifact or a platform-specific WebUI claim additionally requires the separate component and exact-platform evidence from ADR 0097. UI failure does not block a qualified core release.
- The first public release also requires one complete harmless physical base-monitoring report for the P0 `usbhid-ups` driver profile under ADR 0065, including stable OL, a controlled short OB/recovery transition, stale or disconnect/reconnect behavior, and exact source identity. The report may use maintainer or community hardware and does not make that UPS model a product prerequisite.
- Later releases require fresh physical UPS evidence only when the NUT package, `usbhid-ups` profile, USB/privilege path, observation semantics, or relevant source behavior changes; otherwise the exact report may carry forward explicitly.
- Exact real-UPS qualification is separate from router qualification and begins read-only. It is not required for ordinary CI and never requires output-off or deep-discharge testing.
- A failure in a mandatory lower evidence layer blocks release even when a hardware report previously passed.
- Every release report states which layers ran, which were carried forward, and which capabilities remain unqualified.

## Consequences

- The supported AArch64 runtime receives real package execution without making a router a routine CI dependency.
- Test reports cannot use QEMU or `dummy-ups` to imply hardware behavior they did not observe.
- AArch64 Entware rootfs work moves from optional research into release infrastructure; ARMv7 remains optional.
- Tests and release tooling need reproducible package snapshots and clear evidence provenance.

## Rejected alternatives

Relying on x86 shims until manual router testing would miss architecture and package failures late. Requiring a physical current router for every release would provide stronger integration evidence but would make maintenance dependent on scarce hardware and still cover only one model.
