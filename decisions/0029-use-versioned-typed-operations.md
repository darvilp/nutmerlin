# ADR 0029: Use versioned typed operations for actions

- Status: Accepted
- Date: 2026-08-02

## Context

The planned executors span local processes, SSH, webhooks, MQTT, NUT, WinRM, Redfish, and device-control protocols. Allowing each policy action to carry an opaque executor payload would maximize integration freedom, but would prevent the policy engine from consistently validating destructive intent, retry behavior, binding eligibility, verification, and dry-run semantics.

## Decision

Every action selects a versioned typed operation and supplies parameters validated against that operation's structured schema.

- An operation contract declares its stable ID and version, parameter schema, destructive class, retry classification, eligible binding capabilities, dry-run behavior, and supported verification strategies.
- Common intent may use executor-neutral operations such as `host.graceful_shutdown`; specialized operations use executor-namespaced IDs.
- An executor translates an eligible operation into fixed protocol or process behavior and cannot reinterpret an unknown operation as pass-through input.
- Policies contain no raw shell or PowerShell text, credentials, arbitrary HTTP methods, unvalidated payload fragments, or device command strings.
- SSH operations select vetted target-side command templates rather than policy-provided command text.
- Local-script operations select an allowlisted script manifest and provide only arguments declared by that manifest's schema.
- Endpoint, transport, topic, and credential configuration belongs to the target's executor binding unless an operation schema explicitly permits a narrowly validated per-action value.
- Operation-version changes require explicit migration or a new policy version; unknown or unsupported versions fail validation.
- `describe_capabilities()` reports supported operation versions and their safety metadata.

## Consequences

- The policy engine and UI can apply uniform gates without understanding every wire protocol.
- Novel integrations may require a new operation contract instead of accepting an arbitrary payload.
- Operation schemas and migrations become part of compatibility and executor qualification.

## Rejected alternative

Executor-specific validated but opaque action objects would be easier for unusual integrations, but would weaken cross-executor selection, shared UI behavior, centralized safety classification, and deterministic migration.
