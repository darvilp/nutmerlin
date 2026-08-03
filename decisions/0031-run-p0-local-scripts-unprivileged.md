# ADR 0031: Run P0 local scripts under an unprivileged identity

- Status: Deferred research - non-authoritative for v0.1
- Date: 2026-08-02

## Context

Merlin lifecycle integration runs with router privilege. Invoking an imported script directly from that context would give a policy or script defect control over routing, firewall state, JFFS, Entware, and other addon secrets. Explicit import establishes administrator intent but does not justify ambient root authority.

Privilege-drop facilities may differ across supported Merlin and Entware combinations.

## Decision

P0 local-script execution requires a qualified dedicated unprivileged runtime identity.

- Installation probes the actual privilege-drop mechanism and execution identity before enabling the executor.
- Execution never silently falls back to root or the privileged lifecycle process identity.
- The runtime identity receives only the filesystem and process access needed for its imported artifact, declared structured input, private transient workspace, and bounded result channel.
- Event and action data are supplied through structured standard input or a protected file rather than shell-expanded arguments.
- The executor scrubs inherited environment variables and never exposes unrelated credentials or router configuration.
- If reliable privilege separation is unavailable, the local-script executor is unavailable on that platform while core NUT server and client-onboarding capability may remain supported.
- Capability and hardware qualification reports state whether unprivileged local-script execution passed.
- Root-script execution is outside P0. Any later design is a distinct expert capability requiring global, imported-script, and policy-level gates rather than an option that weakens this executor.

## Consequences

- Some router/platform combinations may not offer the local-script executor until a safe privilege-drop adapter is qualified.
- Scripts that need router-administration authority require another deliberately designed mechanism.
- Host and router tests must verify effective UID/GID, environment scrubbing, filesystem denial, timeout cleanup, and absence of fallback.

## Rejected alternative

Allowing an explicitly imported script to run as root after a warning would improve compatibility and support router-management tasks, but would create a general root-code execution surface reachable from the policy engine.
