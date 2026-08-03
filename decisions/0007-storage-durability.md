# ADR 0007: Treat Entware storage as fallible and minimize writes

- Status: Accepted
- Date: 2026-08-01
- Updated: 2026-08-02 by ADR 0098

## Decision

- Prefer reliable always-on storage but do not make media certification part of the product.
- Keep code needed for diagnosis and safe shutdown under `/jffs/addons/nutmerlin`.
- Keep owned NUT configuration and credentials under `/opt/etc/nutmerlin`.
- Keep PID, socket, lock, retry, status, and log data under `/tmp/nutmerlin`.
- Persist only installation identity, enabled state, source/LAN/client settings, and current/last-known-good configuration.
- Detect missing, late, read-only, replaced, or ownership-mismatched `/opt` and close service/network surfaces safely.
- Require only the filesystem behavior used by v0.1: ownership/modes, safe file types, writeability, free space, and same-filesystem atomic rename.

## Consequences

There is no per-poll persistent write, storage qualification authority, audit/event store, configuration export, or generalized durability transaction in v0.1.
