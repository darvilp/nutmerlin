# ADR 0022: Deliver shutdown-client secrets only once

- Status: Superseded by ADR 0098
- Date: 2026-08-02

## Context

The NUT server must retain each shutdown-client password in protected configuration, so a privileged product interface could technically reveal it later. Persistent redisplay would simplify client reinstallation, but would also create a standing secret-extraction path through the normal router UI or CLI.

Independent per-client credentials make replacement local to one client when its value is lost.

## Decision

NUTMerlin delivers a shutdown-client secret only once, when the credential is created or explicitly replaced.

- Normal UI, CLI, and status interfaces subsequently report only that the credential exists; they provide no reveal operation.
- Loss of the delivered value requires explicit credential replacement rather than recovery of the stored value.
- The one-time delivery is excluded from URLs, logs, audit details, diagnostics, settings, exports, command arguments, and persistent browser storage.
- Product responses carrying the secret must not be cacheable or retained in generated status pages.
- Credential creation and replacement are audited without recording the secret value.
- A failed or abandoned delivery never causes NUTMerlin to copy the value into a more persistent or broadly readable location for convenience.
- Direct inspection by a router root administrator remains outside the product-interface guarantee; NUTMerlin does not add a command that performs that inspection.

## Consequences

- Reinstalling a client whose credential was not retained requires replacement and client reconfiguration.
- CLI and, when installed, WebUI tests must prove that a second read cannot retrieve the value and that surrounding output paths do not retain it.
- Automated provisioning needs an explicit protected one-time output mechanism rather than a general secret-query API.

## Rejected alternative

Allowing redisplay through a local root-only CLI would not grant more filesystem authority than root already has, but would create an easy, scriptable exfiltration path and weaken the product's redaction model.
