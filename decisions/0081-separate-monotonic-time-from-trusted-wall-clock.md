# ADR 0081: Separate monotonic time from trusted wall clock

- Status: Deferred research - non-authoritative for v0.1
- Date: 2026-08-02

## Context

Routers can boot with an implausible wall clock and synchronize only after networking becomes available. Policy delays, freshness, retries, and cancellation must remain safe across NTP corrections, while TLS certificate validity, signed webhook replay windows, release-key validity, and human timestamps require credible civil time. Treating one clock as authoritative for both creates either premature actions or weakened authentication.

## Decision

NUTMerlin maintains separate monotonic policy time and explicitly trusted wall-clock state.

- Observation freshness, outage duration, cancellation, debounce, action budgets, backoff, circuit breakers, rate windows, and same-boot sequencing use monotonic time only.
- Every event and result records boot ID and monotonic position. It also records wall time plus a `wall_time_trusted` indicator; an untrusted timestamp is displayed as provisional and never silently presented as exact civil time.
- Each router boot begins with wall clock untrusted, regardless of a plausible persisted value.
- Wall clock becomes trusted only after the qualified platform adapter obtains positive evidence of a successful time synchronization during that boot and validates a plausible result. Merely running an NTP process, resolving a server, or seeing a plausible year is insufficient.
- After trust, loss of WAN or NTP reachability does not by itself revoke trust during the same continuous boot. A wall-clock discontinuity greater than 300 seconds relative to monotonic projection, a platform-reported unsynchronized reset, or an implausible value revokes trust until another positive synchronization.
- Wall-clock changes never shorten, lengthen, fire, cancel, reorder, or recommit monotonic policy work.
- Verified-TLS session establishment, HMAC webhook publication, authenticated release staging or activation, key/certificate validity decisions, and any future freshness signature requiring civil time are inhibited while wall clock is untrusted. No certificate pin, warning acknowledgement, or plaintext fallback bypasses that gate.
- SSH host-key authentication, local read-only NUT monitoring, monotonic policies using otherwise qualified non-wall-clock transports, and local diagnostics may continue when their own gates permit.
- If wall clock becomes untrusted during an established security session, NUTMerlin closes or declines new wall-clock-dependent dispatch according to that protocol's safe boundary; it does not reinterpret an already committed unknown outcome as not dispatched.
- Cross-boot ordering uses durable sequence and boot identifiers, not wall timestamps. Router reboot follows ADR 0057 and never reconstructs elapsed outage time from civil-time difference.

## Consequences

- A router that boots without time synchronization can still monitor a UPS but cannot prematurely use TLS or signed freshness mechanisms.
- Local outage actions over pinned SSH may remain available when WAN/NTP is down, while HTTPS, MQTT TLS, WinRM, Redfish, signed webhooks, and updates clearly report a clock-health gate.
- History can show uncertain timestamps without losing deterministic event ordering.
- Tests must cover pre-sync boot, false-positive NTP process state, exact 300-second discontinuity boundary, forward and backward jumps, WAN loss after sync, restart, TLS and signing inhibition, monotonic timer invariance, open-session interruption, and provisional timestamp rendering.

## Rejected alternative

Accepting pinned certificates or release keys while the wall clock is unknown would preserve more functionality immediately after boot, but would bypass validity intervals and still could not provide trustworthy signed-message timestamps. Using wall time for policy delays would make NTP corrections action-authoritative.
