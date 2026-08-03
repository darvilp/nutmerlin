# ADR 0060: Make the CLI complete and the web UI milestone scoped

- Status: Superseded by ADR 0098
- Date: 2026-08-02

## Context

The Merlin web UI is important for a community addon but is a constrained authenticated adapter with a small shared settings store. Requiring it to expose every advanced policy and executor before the backend capability can ship would couple safe infrastructure work to complex browser authoring. A CLI-only product would undermine approachability and leave common safety state hard to see.

## Decision

The CLI is the complete supported management surface; when the optional WebUI component from ADR 0097 is installed, it is a curated milestone-scoped adapter over the same typed management operations.

- Every supported capability has a CLI path. No supported behavior requires direct editing of managed configuration or state files.
- CLI and UI use the same server-side schemas, validation, preview, authorization, lifecycle transaction, redaction, result vocabulary, and audit records.
- The CLI provides stable exit classes plus versioned machine-readable JSON for status, plans, validation, diagnostics, and results; human-readable output remains the default for interactive use.
- Materially state-changing lifecycle operations show a concrete plan before confirmation. Noninteractive CLI use requires an operation-specific explicit flag and never treats `--yes` alone as authorization for a newly introduced destructive class.
- Secret creation or replacement uses protected standard input, a permission-checked file descriptor, or a one-time authenticated form; secret values are never command arguments.

P0 web scope includes:

- current and stale-marked UPS status, source identity, service health, storage state, network exposure, version/package information, and monitoring-only or inhibition state
- initial source and trusted-LAN onboarding
- read-only client instructions and shutdown-client registration/replacement
- refresh, validate, harmless connection test, NUT service restart, diagnostics, last-known-good rollback, and explicit real/simulated source change
- non-secret configuration import/export and recovery guidance

P1 web scope adds:

- target and binding onboarding for qualified P1 executors
- policy draft, validation, conflict analysis, harmless test, dry-run, explicit activation/deactivation, notification setup, and bounded event/action history

P2 integrations enter the web UI only after their transport, credential, typed-operation, and test contracts are qualified. Complete FSD and all `Later` destructive capabilities are absent from the normal dashboard and require their own future interaction decision.

## Consequences

- CLI recovery and automation remain possible when the Merlin page fails, while common users receive a safe guided interface.
- Backend behavior cannot diverge between browser and shell paths.
- Some advanced features may initially be CLI-only but must still provide structured previews and diagnostics.
- Tests need cross-surface golden results, JSON schema compatibility, fixed service-event verbs, CSRF and encoding, secret argument rejection, noninteractive gates, and direct-file-edit refusal.

## Rejected alternatives

Mandatory feature-for-feature web parity would maximize discoverability but delay advanced capabilities and enlarge browser attack surface. A read-only dashboard with CLI-only configuration would be simpler but would make ordinary community onboarding unnecessarily difficult.
