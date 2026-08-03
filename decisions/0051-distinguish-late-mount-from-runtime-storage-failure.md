# ADR 0051: Distinguish late mount from runtime storage failure

- Status: Superseded by ADR 0098
- Date: 2026-08-02

## Context

Asuswrt-Merlin may expose `/opt` after early boot hooks run, so temporary boot-time absence is expected. Loss, read-only remount, or I/O failure after NUTMerlin has been active is materially different: policy state, secrets, generated NUT configuration, imported scripts, logs, and durable dispatch evidence may have become unavailable or uncertain.

## Decision

NUTMerlin treats expected late mount and unexpected runtime storage failure as different lifecycle states.

For boot-time late mount:

- A minimal JFFS-resident coordinator does not block router boot or repeatedly spawn service processes.
- It checks after 5, 15, 30, 60, and 120 seconds, then every 300 seconds while the addon remains enabled and storage unavailable.
- A Merlin `post-mount` event triggers an immediate serialized check without creating a second startup path.
- Services start exactly once only after validating the expected storage identity, NUTMerlin ownership evidence, configuration integrity, required writeability, Entware package cohort, and required executables.
- A different, foreign, or ambiguously owned volume mounted at `/opt` is refused rather than adopted.

For unexpected removal, read-only remount, or I/O/integrity failure:

- New uncommitted policy dispatch is inhibited immediately.
- NUT and executor services dependent on the failed storage are stopped when safely possible, and their managed listener/firewall exposure is closed.
- No executable, imported script, configuration, or secret is read from storage that failed integrity checks.
- The incident sets a durable storage fault latch outside the failed volume.
- If the expected volume returns and fully validates, read-only monitoring may resume automatically to restore status service.
- Policy and executor activation remain inhibited until durable episode and dispatch state is reconciled and an administrator explicitly clears the latch.
- Planned removal uses the normal disable/safe-stop lifecycle and does not set a fault latch when completion is verified.

## Consequences

- Ordinary late mount recovers without manual intervention while an unexpected disappearance cannot silently resume automation.
- A small, non-secret coordinator state must survive independently of `/opt` without turning JFFS into a high-frequency journal.
- Client NUT status can recover sooner than router-driven automation after a storage incident.
- Tests must cover every retry boundary, duplicate hooks, wrong media, read-only transitions, I/O errors, validated reinsertion, latch persistence, monitoring-only recovery, and planned removal.

## Rejected alternatives

Automatically resuming all services after the filesystem becomes available would maximize availability but cannot prove that durable action state remained coherent. Requiring manual intervention for every late boot mount would be safe but conflict with normal Merlin/Entware startup ordering.
