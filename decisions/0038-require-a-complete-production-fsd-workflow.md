# ADR 0038: Require a complete production FSD workflow

- Status: Deferred research - non-authoritative for v0.1
- Date: 2026-08-02

## Context

Upstream NUT FSD is a committed primary/secondary shutdown mechanism. A primary `upsmon` sets FSD, waits for secondaries, invokes its local `SHUTDOWNCMD`, and normally participates in the late UPS power-cycle sequence. The data server latches FSD until restart.

Using a harmless router `SHUTDOWNCMD` and restarting `upsd` after signaling clients would keep network infrastructure running, but would create a partial nonstandard sequence whose safe latch-clear point is ambiguous.

## Decision

NUTMerlin does not offer a production signal-only FSD mode.

- Production FSD is unavailable until a complete primary workflow is explicitly designed, implemented, and qualified.
- That workflow must define primary-role credentials, the router's terminal behavior, secondary synchronization, `HOSTSYNC`, `FINALDELAY`, `POWERDOWNFLAG`, output-control behavior, and recovery when utility power returns.
- FSD enablement is separate from ordinary shutdown-client onboarding and cannot be inferred from registered secondary clients.
- NUTMerlin never substitutes a no-op primary shutdown command merely to broadcast FSD while keeping the data server operational.
- NUTMerlin never clears a production FSD latch automatically for service convenience while sequence outcome is uncertain.
- P1 may provide a fully simulated primary/secondary environment with harmless marker shutdown commands and explicit reset instructions.
- Reversible timers and other executors remain independent of FSD availability.
- Production FSD sequencing follows the later output-control safety decisions and qualification gates.

## Consequences

- Production FSD moves behind router shutdown, output control, power restoration, and hardware qualification work rather than shipping as an isolated P1 executor.
- Users who want the router and network to remain powered use client-local or explicit central executors instead of FSD.
- Simulation tests can establish semantics without implying production readiness.

## Rejected alternative

A labeled router-preserving profile could set FSD with a harmless primary shutdown command, wait for clients, and restart `upsd` to clear the latch, but would diverge from the complete NUT power-cycle model and could clear committed state while client outcome remained uncertain.
