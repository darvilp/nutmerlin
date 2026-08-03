# ADR 0009: Base router support on capabilities, not model allowlists

- Status: Deferred research - non-authoritative for v0.1
- Date: 2026-08-01

## Context

The supported Merlin firmware families span more router models than the maintainer can own or test directly. Restricting installation and support to an exact-model allowlist would make available hardware define the scope of a general community addon. Treating every model as identical would ignore meaningful differences in Addons API behavior, storage, USB, networking, and lifecycle hooks.

## Decision

Router support is capability-based within the firmware-family and architecture contract established by ADR 0008.

- Mandatory preflight probes, not a hard-coded model allowlist, determine platform eligibility.
- An eligible but untested router model remains within the supported platform contract.
- Exact model and hardware-revision combinations that pass the hardware matrix are reported as qualified hardware.
- Qualification supplies stronger evidence about a combination but is not a separate support tier.
- Known-incompatible hardware overrides general platform eligibility and must fail closed for the affected capability or installation.
- Diagnostics and release reports distinguish platform eligibility, exact-hardware qualification, and known incompatibilities.

One complete, reproducible hardware report is sufficient to qualify an exact router model and hardware revision.

- The report may be produced by the maintainer or a community member; evidence requirements are identical.
- It identifies the router model, hardware revision, exact firmware, architecture, Entware feed and NUT packages, addon version, and storage filesystem.
- It contains project-generated structured results and redacted diagnostics.
- It passes every mandatory non-destructive core router lifecycle check without waivers or skipped checks, including installation, repeat installation or repair, simulation, NUT service and query behavior, complete CLI, network isolation, reboot, late and failed `/opt`, rollback, upgrade, disable and enable, preservation of unrelated state, and uninstall.
- The optional WebUI component from ADR 0097 has a separate qualification result for the same exact platform. Missing or negative UI evidence removes only the WebUI claim and does not revoke otherwise complete core qualification.
- Router qualification uses `dummy-ups` and does not require a physical UPS; UPS-model qualification is separate evidence.
- An anecdotal or incomplete success report may be published as community experience but does not confer qualification.

Qualification uses risk-triggered carry-forward rather than expiring after a fixed calendar interval.

- A completed report remains immutable historical evidence for its recorded combination.
- Qualification may carry forward when a release records that no relevant router-facing behavior or dependency changed.
- A supported Merlin firmware change, hardware revision change, Entware architecture or feed change, NUT major or minor version change, relevant NUTMerlin platform change, security advisory, or reproduced compatibility fault triggers fresh current-release evidence.
- Relevant NUTMerlin platform changes include installation, ownership, upgrade, rollback, uninstall, hooks, mount handling, firewall behavior, generated NUT configuration, and service lifecycle. Addons API integration is a separate trigger for the optional WebUI claim.
- A trigger does not erase the earlier positive report; it prevents that report from being represented as a test of the changed combination.
- There is no separate 12-month expiry because supported Merlin releases are expected to trigger reassessment more frequently.
- Reproducible negative evidence revokes qualification for the affected combination and may establish a known incompatibility until the fault is resolved and retested.

## Consequences

- New upstream-supported models can be eligible without waiting for an allowlist update.
- Capability probes and diagnostics become safety-critical interfaces with negative-path tests.
- Published compatibility reports must identify model, hardware revision, firmware, architecture, Entware feed, and test scope.
- A single high-quality community report can grow the qualified-hardware matrix without requiring duplicate physical devices.
- Some model-specific faults will be discovered only after community deployment; reproduced faults must become explicit incompatibility data rather than hidden conditionals.

## Rejected alternative

An exact-model allowlist would make every untested model compatibility-only until individually approved. It provides narrower claims but scales poorly and ties community availability to the maintainer's hardware inventory.
