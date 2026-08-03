# ADR 0055: Use permissioned secret files without a secret backup

- Status: Accepted
- Date: 2026-08-02
- Updated: 2026-08-02 by ADR 0098

## Decision

- Store each client secret under `/opt/etc/nutmerlin` in a private `0700` directory and `0600` file, or the narrow `0640` ownership/mode required by the qualified NUT identity.
- Store no secret in JFFS metadata, shared Merlin settings, environment exports, command arguments where avoidable, logs, diagnostics, packages, or documentation.
- Return a new secret once to the invoking administrator. Provide no reveal, recovery, or export operation.
- Current NUT configuration necessarily contains active credential values. Last-known-good may contain only credentials that remain valid; revocation invalidates any fallback containing the revoked value.
- Do not claim encryption at rest or secure erasure from flash media.

## Consequences

Loss requires new provisioning and revocation. Root or storage compromise may disclose active secrets; independent credentials limit blast radius.
