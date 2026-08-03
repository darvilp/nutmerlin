# ADR 0087: Require versioned NUT driver profiles

- Status: Superseded by ADR 0098
- Date: 2026-08-02

## Context

NUT provides many drivers and driver-specific options. Accepting an arbitrary driver name and raw `ups.conf` keys would extend hardware reach, but would bypass the validated internal model, make secret and path placement driver-dependent, and prevent deterministic generation, lifecycle, identity, and negative testing. NUT compatibility alone does not establish that NUTMerlin knows how to manage a driver's configuration safely.

## Decision

NUTMerlin manages a source only through an installed, versioned NUT driver profile.

- P0 production ships one `usbhid-ups` profile and one isolated `dummy-ups` simulation profile. No other production driver is a P0 promise.
- A driver profile declares the exact packaged driver and supported versions, typed option schema, defaults and bounds, secret and path handling, source-identity rules, privilege and device requirements, generated configuration mapping, lifecycle probes, harmless tests, status expectations, and migration behavior.
- Configuration accepts only profile-declared fields. Unknown keys, raw `ups.conf` fragments, arbitrary driver names, free-form regexes, include directives, and user-selected driver command paths are rejected.
- The `usbhid-ups` profile treats identity values as literal validated attributes and generates any required anchored matching form itself under ADR 0058. `port=auto` is generated protocol syntax, not a source selector.
- The `dummy-ups` profile accepts only owned or release-provided bounded simulation fixtures and remains subject to ADR 0086's loopback and inactive-policy isolation.
- Adding a profile for another Entware NUT driver is a scoped feature with its own config golden files, package dependency evidence, privilege and lifecycle tests, simulator or driver double, support claim, and source/hardware qualification path. No raw expert mode substitutes for that work.
- A source using a packaged NUT driver without an installed matching NUTMerlin profile may be NUT-compatible in the ecosystem but is not a manageable NUTMerlin source. A preexisting manual configuration remains foreign under ADR 0010.
- UPS capability qualification under ADR 0065 is layered on top of driver-profile eligibility. A qualified profile does not qualify every device or telemetry field, and a qualified UPS report does not authorize undeclared driver options.
- Profile version changes follow config migration, last-known-good, activation evidence, and source-replacement rules; an update cannot silently reinterpret an active option.

## Consequences

- P0 configuration generation and support claims remain exhaustive and testable.
- Users of less common NUT drivers need a community-contributed profile instead of pasting their existing `ups.conf`.
- Future NUT network/SNMP drivers can be added without creating a direct NUTMerlin device-protocol stack, but are not implied by the core release.
- Tests must cover every profile field and unknown field, literal-to-generated matching, driver/path substitution, secret placement, profile/version mismatch, migrations, golden configuration, unsupported packaged drivers, foreign config refusal, and separation of profile from UPS capability qualification.

## Rejected alternative

An expert driver form accepting arbitrary NUT driver names and key/value options would make more NUT-supported devices work immediately, but would turn configuration validation into a syntax check and make ownership, secrets, paths, source identity, privilege, and upgrades depend on unmodeled driver behavior.
