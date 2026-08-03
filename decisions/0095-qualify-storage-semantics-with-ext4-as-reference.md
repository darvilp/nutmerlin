# ADR 0095: Qualify storage semantics with ext4 as reference

- Status: Deferred research - non-authoritative for v0.1
- Date: 2026-08-02

## Context

Entware, immutable configuration, secrets, ownership, atomic journals, and imported scripts depend on filesystem behavior, while removable media and router filesystem drivers vary. A filesystem label alone cannot prove mount options, permission enforcement, rename/fsync behavior, or stability on an exact router. An ext4-only product claim would be clear but broader than the actual semantic requirement.

## Decision

Ext4 is the reference and recommended `/opt` storage profile; support eligibility is determined by qualified filesystem semantics on the exact platform.

- Install preflight records the block/storage identity, filesystem type, mount source and target, relevant mount options, free space, and available health evidence without claiming remaining endurance.
- The reference profile is a journaled ext4 filesystem with execution enabled and ordinary Unix ownership and mode semantics. `noatime` is recommended for endurance but is not a correctness gate.
- Another filesystem is eligible only when the router/storage qualification proves persistent UID/GID and modes including `0700`, `0600`, and `0640`; case-sensitive stable names; regular/symlink/hard-link distinction; same-directory atomic rename; file and containing-directory fsync behavior; reliable exclusive locking; executable Entware binaries; and stable mount/device identity across reboot and reconnect.
- The qualification includes controlled interruption/remount recovery using disposable data and confirms that a reported successful fsync/rename does not yield a mixed or silently lost journal/config generation in the exercised cases. It is evidence, not a guarantee against all media failure.
- FAT, VFAT, and exFAT are incompatible with supported Entware/NUTMerlin installation because they do not provide the required native ownership and mode boundary. Permission-emulation options are not accepted for secret-bearing or action-capable use.
- NTFS, F2FS, ext3, or another router-supported filesystem receives no implied support from its name; it must pass the same exact capability and interruption matrix before publication as a qualified profile.
- `noexec`, unexpected read-only, unstable mount source, ownership emulation, ignored chmod/chown, missing durable rename/fsync, or inconsistent link behavior makes the storage profile ineligible. NUTMerlin does not weaken secret modes or journal semantics to continue.
- SMART or wear telemetry is optional diagnostic evidence. Its absence does not by itself fail support, and its presence does not replace filesystem or interruption tests.
- Storage-media brand, type, and capacity do not grant qualification. SSD is recommended for always-on production use; temporary flash media may qualify a test run but does not gain an endurance promise.
- Runtime drift from the qualified mount and filesystem state follows ADRs 0051, 0054, and 0091 and closes action authority.

## Consequences

- Most users receive a simple ext4 recommendation, while genuinely equivalent filesystems are not forbidden by policy.
- Filesystems that appear writable but cannot enforce secrets or durability fail before credentials or automation are enabled.
- Exact router/storage reports become the evidence source for non-reference filesystems.
- Tests must cover ignored chmod/chown, umask, links, case collisions, rename and fsync interruption, lock contention, noexec/read-only/remount, device replacement, mount-option drift, missing SMART, low space, and reference/non-reference support labeling.

## Rejected alternative

Supporting only ext4 would reduce the qualification matrix and simplify documentation, but would confuse one proven reference implementation with the actual required semantics and unnecessarily exclude another filesystem that demonstrates the same behavior on a supported router.
