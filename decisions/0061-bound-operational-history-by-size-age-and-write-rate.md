# ADR 0061: Bound operational history by size, age, and write rate

- Status: Deferred research - non-authoritative for v0.1
- Date: 2026-08-02

## Context

Operators need enough history to understand outages, policy transitions, and executor results. Persisting every UPS poll or building a time-series database would add write load and product scope, while relying only on firmware syslog would make retention depend on unrelated router settings and rotations.

## Decision

NUTMerlin retains bounded transition-oriented operational history and no persistent per-poll telemetry series.

Default retention budgets are:

- normalized event transitions: 4 MiB or 90 days, whichever limit is reached first
- action and lifecycle audit: 8 MiB or 180 days, whichever limit is reached first
- redacted health and diagnostic history: 4 MiB or 14 days, whichever limit is reached first
- total default operational-history capacity: 16 MiB, separate from the 4 MiB safety-journal reserve

Further rules:

- Current status samples remain in `/tmp`; P0 and P1 do not maintain a historical telemetry graph database.
- Rotation removes the oldest terminal records first and cannot remove or rewrite active or unresolved safety-journal facts.
- Repeated identical health failures persist on first occurrence, recovery, and no more than one aggregate summary every 15 minutes while unchanged.
- Every distinct policy dispatch and result remains individually auditable and is not coalesced as a health repetition.
- Non-safety history may buffer for at most 5 seconds or 10 records, whichever occurs first, before a write; process shutdown attempts a final flush.
- Safety-journal writes retain immediate atomic fsync behavior and do not share the history buffer.
- Operators may lower each retention limit. Raising total operational history above 64 MiB or age above 365 days is outside the ordinary supported profile and requires an explicit expert setting plus free-space validation.
- Rotation failure drops new non-safety diagnostics after an in-memory bounded summary, raises a storage diagnostic, and never consumes reserved journal capacity or blocks read-only monitoring.
- Export and UI rendering apply redaction and record-count limits independently of on-disk retention.

## Consequences

- Useful outage and action history survives reboot without turning routine polling into persistent write traffic.
- The project does not promise historical charts or long-term analytics in P0/P1.
- At most a short buffered tail of non-safety history may be lost on abrupt power failure; committed action recovery remains protected separately.
- Tests must cover every size and age boundary, repeated-condition coalescing, buffer flush, abrupt loss, rotation failure, journal isolation, and retention configuration bounds.

## Rejected alternatives

Firmware syslog alone would minimize addon storage but could not provide consistent history or retention across installations. A local time-series database would enable charts but add write amplification, migration, corruption, and UI scope beyond outage orchestration needs.
