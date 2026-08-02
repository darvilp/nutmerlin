# ADR 0015: Remove all NUTMerlin-owned data on uninstall

- Status: Accepted
- Date: 2026-08-02

## Context

Preserving configuration after uninstall can simplify reinstallation, but it also leaves privileged credentials, target details, policies, and operational history on removable router storage after the administrator believes the addon is gone. NUTMerlin already provides a reversible disable operation and a non-secret export path.

## Decision

Normal uninstall removes all verified NUTMerlin-owned artifacts and data.

- Disable is the reversible operation: it stops policies and services, closes managed listener and firewall access, and retains the installation and data.
- Uninstall first displays the verified ownership inventory and requires explicit confirmation.
- Uninstall removes project-owned code, release slots, hooks, UI integration, generated NUT configuration, policies, targets, secrets, logs, audit history, runtime and recovery state, and ownership metadata.
- Foreign artifacts remain untouched.
- All Entware packages remain installed under ADR 0013.
- Uninstall does not silently create or retain any backup, especially one containing secrets.
- The administrator may explicitly export supported non-secret configuration before uninstall; credentials must be re-entered after reinstall.
- Unattended uninstall requires explicit authorization for irreversible data removal.
- Uninstall uses the lifecycle journal so interruption converges toward a clean final state and leaves actionable recovery diagnostics.

## Consequences

- Reinstallation after uninstall requires restoring non-secret settings and provisioning credentials again.
- Users who may return to the addon should disable it rather than uninstall it.
- Post-uninstall verification must prove that project credentials, history, hooks, listeners, and firewall rules are gone while foreign state and Entware packages remain.

## Rejected alternative

Preserving configuration and secrets by default would make reinstallation easier, but would leave sensitive remote-control material behind and weaken the meaning of a clean uninstall.
