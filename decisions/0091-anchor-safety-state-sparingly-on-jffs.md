# ADR 0091: Anchor safety state sparingly on JFFS

- Status: Accepted
- Date: 2026-08-02

## Context

The detailed safety journal lives on Entware storage so it can retain bounded recovery facts without wearing JFFS. If `/opt` disappears or is replaced, however, the router still needs durable evidence that the expected volume, selected code/configuration, or an unresolved commitment existed. A full second journal would duplicate recovery logic and add avoidable firmware-flash writes.

## Decision

NUTMerlin pairs the `/opt` safety journal with a small conservative JFFS safety anchor.

- The authoritative detailed journal remains the reserved 4 MiB `/opt` journal from ADR 0054. Operational history also remains off JFFS.
- JFFS reserves two alternating 32 KiB anchor slots, for a 64 KiB total bound. Startup selects the highest valid sequence whose checksum, schema, installation identity, and internal links are consistent; a torn or conflicting pair fails closed.
- The anchor stores only installation and expected-storage identity, active release and NUT-config generation IDs, lifecycle transaction type/phase, detailed-journal sequence and digest, storage-fault state, and conservative flags that an active episode, commit, dispatch intent, or unresolved outcome exists.
- The anchor contains no credential, private material, raw policy, target endpoint, telemetry sample, event history, diagnostic text, or per-poll timestamp.
- A new policy commitment, nonrepeatable dispatch, update/config activation, rollback, uninstall phase, or resolution that would clear an inhibition first appends and fsyncs its detailed `/opt` fact, then atomically writes and fsyncs the next JFFS anchor slot before any externally effecting request or selector change.
- Interruption between the two writes may create an extra conservative latch but can never authorize missing work. Journal/anchor sequence or digest disagreement inhibits actions and requires deterministic reconciliation; the more restrictive state wins.
- Clearing an active, committed, or unknown flag follows the same order. Failure to update JFFS leaves the old inhibition in force rather than losing the detailed resolution.
- Ordinary fresh observations, timer ticks, retries already covered by an unchanged dispatch intent, repeated health failures, status rendering, and operational log records never write the anchor.
- Missing, full, read-only, corrupt, future-schema, or identity-mismatched JFFS anchor state permits only read-only monitoring after ownership checks and blocks new policy activation, commitment, update, configuration activation, rollback finalization, and clean uninstall until explicit conservative recovery.
- A replacement `/opt` volume cannot clear the anchor merely by presenting a new empty journal. Expected-storage mismatch follows ADR 0051 and ownership recovery.

## Consequences

- Loss of Entware storage cannot make the router forget that unresolved safety state existed.
- Each rare effecting lifecycle transition adds one bounded JFFS atomic write; polling and routine diagnostics add none.
- A crash may produce a false-positive inhibition requiring reconciliation, which is preferred to replaying or forgetting an effect.
- Tests must interrupt before and after both fsyncs, corrupt and reorder each anchor slot, exhaust JFFS space, replace `/opt`, present empty and replayed journals, exercise every allowed and forbidden write class, and measure that sustained polling produces zero anchor writes.

## Rejected alternative

Keeping all durable action state only on `/opt` would minimize JFFS use, but removal or failure of that volume could erase the router's only evidence that it must not trust a replacement journal or repeat an unresolved operation. Mirroring the full journal on JFFS would solve that at excessive write and complexity cost.
