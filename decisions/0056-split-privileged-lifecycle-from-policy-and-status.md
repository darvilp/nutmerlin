# ADR 0056: Split privileged lifecycle from policy and status

- Status: Accepted
- Date: 2026-08-02

## Context

Merlin hooks, firewall rules, service control, ownership repair, and protected configuration require router privilege. Status parsing, policy evaluation, UI rendering, and most orchestration logic do not. A single long-lived root process would make every parser and executor part of the router's administrative trust boundary.

Creating a separate operating-system identity and daemon for every target would maximize isolation but may exceed the account and supervision facilities reliably available across supported Merlin and Entware environments.

## Decision

NUTMerlin uses a split privilege architecture.

- A small privileged lifecycle controller implements only fixed install, ownership, atomic configuration, firewall, service-supervision, recovery, and uninstall operations.
- The lifecycle controller has no network listener, accepts no arbitrary command or path, and revalidates every request against current ownership and lifecycle state.
- Status collection, normalization, policy evaluation, scheduling, and safe UI-data generation run under a dedicated unprivileged NUTMerlin identity with no write access to JFFS hooks, active configuration, the secret store, or router network settings.
- A narrow local execution broker receives a fully validated immutable action intent, revalidates policy version, target, operation, feature gates, action budget, and binding capability, and uses only the referenced binding secret.
- The broker never returns raw secret values to the policy engine, web UI, local script, log pipeline, or diagnostics.
- Local broker communication uses a qualified protected local IPC mechanism with peer identity checks and no LAN exposure.
- When installed, the optional WebUI consumes sanitized status and submits fixed Merlin service-event verbs; it cannot invoke the broker or read privileged files directly.
- NUT drivers and `upsd` use the qualified Entware/NUT privilege-drop identities and USB permissions. A network-facing `upsd` cannot remain running as root.
- If required user, group, privilege-drop, or protected-local-IPC capabilities are unavailable, credential-free read-only monitoring may remain eligible, but policy executors and privileged NUT roles are unavailable rather than silently running as root.
- Capability and hardware reports record each privilege boundary independently.

## Consequences

- Most complex and input-facing logic is outside the router-root boundary.
- Executor compromise is still serious but does not automatically expose every binding secret or router administration surface.
- Supported-platform probes must establish real effective identities, file access, IPC peer checks, and absence of fallback.
- Tests need confused-deputy, forged-action, stale-policy, cross-binding secret, UI-to-broker, filesystem denial, and effective-UID scenarios.

## Rejected alternatives

One root daemon with internal modules would be simpler to supervise but would provide no meaningful boundary after parser or executor compromise. One operating-system account per binding would isolate more strongly but would add account lifecycle and platform assumptions disproportionate to the initial target scale.
