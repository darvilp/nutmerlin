# ADR 0012: Use journaled two-slot install and upgrade activation

- Status: Superseded by ADR 0098
- Date: 2026-08-01

## Context

NUTMerlin spans JFFS-resident addon integration and Entware-backed configuration on `/opt`. The two filesystems cannot be committed atomically, and either a reboot or loss of `/opt` can interrupt installation or upgrade. Updating active files in place would expose mixed-version states and weaken recovery.

## Decision

Install and upgrade use a journaled two-slot activation model.

- Retain at most two complete selected-component release slots: current and previous. Each slot always contains the core and contains the exact matching optional WebUI only when selected under ADR 0097.
- Stage and verify a new release without modifying the active slot.
- Managed firmware hooks invoke a stable dispatcher rather than version-specific code.
- A small persistent update journal records the durable transaction phase needed for deterministic resume or rollback.
- NUT configuration is staged separately on `/opt` with its own last-known-good set.
- Activation atomically switches a small current-release pointer or equivalent dispatcher selection on JFFS.
- The previous release and configuration remain intact until restart and health checks succeed.
- An activation failure receives one automatic rollback attempt.
- If rollback fails, NUTMerlin-dependent services are disabled, both slots and diagnostics are preserved, and explicit CLI recovery is required. Core router services remain untouched.
- Preflight refuses mutation unless enough space exists for the selected component set and all rollback material.
- Loss or read-only transition of `/opt` stops transaction progress and enters conservative recovery rather than advancing partial state.

The journal coordinates recoverable phases; it does not claim cross-filesystem atomicity.

## Consequences

- Update interruption at every durable phase must be testable.
- JFFS space accounting must include two complete addon releases plus bounded metadata.
- Cleanup of the previous slot occurs only after successful finalization and never removes the active recovery path.
- Repair can distinguish a staged, activated, health-checking, rolling-back, or failed transaction.

## Rejected alternative

In-place updates with per-file backups use less space but can expose a partially updated tree and require more complex reconstruction after interruption.
