# ADR 0055: Use permissioned secret files without a secret backup

- Status: Accepted
- Date: 2026-08-02

## Context

NUTMerlin must retain NUT passwords, SSH private keys, webhook or MQTT credentials, and later protocol credentials on a consumer router. Encrypting them with an automatically available key on the same device can protect a detached Entware drive, but only if generated configurations, rollback copies, temporary plaintext, and recovery behavior are all included in an audited design. The supported router platform provides no assumed hardware-backed keystore or interactive boot unlock.

## Decision

P0 through P2 use independently permissioned secret files and do not claim application-level encryption at rest.

- The secret-store directory is owned by the required privileged identity and mode `0700`.
- Each ordinary secret file is mode `0600` and has one opaque secret ID; secrets are not combined into a broad settings document.
- A NUT configuration file that the qualified NUT runtime must read may be owned by the required administrative identity and NUT group with mode `0640`; no unrelated service joins that group.
- Installation verifies ownership, effective permissions, mount options, symlink absence, and atomic-create behavior before enabling any secret-bearing capability.
- A filesystem that cannot enforce the required semantics is incompatible with secret-bearing NUT roles and executors, though credential-free read-only monitoring may remain eligible if its own storage requirements pass.
- Policy, UI, diagnostics, local scripts, and ordinary status processes receive opaque references rather than secret values. Only the minimum broker or NUT process needed for the operation may read the applicable file.
- Secrets are not placed in Merlin's shared settings, JFFS metadata, environment exports, command arguments where avoidable, logs, diagnostics, browser content, release slots, or non-secret configuration exports.
- NUTMerlin provides no secret backup or recovery export. Replacement media or a lost secret requires target-side revocation and fresh provisioning.
- Loss or theft of active storage is treated as possible disclosure of every secret stored there, and diagnostics identify the affected binding IDs without revealing values.
- Deletion removes project-owned files and references, but the UI and documentation do not claim secure erasure from flash media.
- A later encrypted design requires a separately qualified authenticated-encryption implementation, key custody and recovery contract, complete plaintext-artifact inventory, migration path, and ADR.

## Consequences

- The security claim is limited and testable: least privilege and file isolation, not protection from router root or physical media acquisition.
- Independent binding credentials and constrained target accounts remain essential blast-radius controls.
- Users must reprovision credentials after media replacement and rotate them after loss.
- Tests must verify exact modes and ownership, umask, symlink and hard-link attacks, backup and export exclusion, process visibility, deletion behavior, and unsupported filesystem refusal.

## Rejected alternative

A JFFS-held master key with authenticated encrypted secrets and tmpfs-only plaintext could protect a detached `/opt` volume, but would add a cryptographic runtime and complex plaintext lifecycle without protecting against whole-router or root compromise. It remains a later hardening candidate rather than a partial P0 claim.
