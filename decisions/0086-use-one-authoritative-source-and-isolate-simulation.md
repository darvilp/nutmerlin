# ADR 0086: Use one authoritative source and isolate simulation

- Status: Superseded by ADR 0098
- Date: 2026-08-02

## Context

The P0 design supports one USB UPS and first-class `dummy-ups`, while later backlog mentions multiple UPS devices, redundant sources, and stable matching. Replacing real data with simulation under the same externally visible NUT identity could cause actual secondary clients or policies to react to test events. Multi-source aggregation also requires power-path logic that cannot be inferred from two independent status feeds.

## Decision

P0 through P2 use exactly one active authoritative real source per NUTMerlin installation and isolate simulation from production consumers.

- The normal server exposes one administrator-confirmed logical UPS name, default `ups`, backed by one exact source identity and one qualified NUT driver configuration.
- The logical name is validated as a NUT identifier and becomes a client-facing compatibility value. Renaming it after client registration is an explicit transaction with affected-client preview and revalidation; it is never changed by hardware discovery.
- Additional attached UPS-like USB devices may coexist only when the selected source identity still resolves uniquely under ADR 0058. They are ignored, not aggregated, load-balanced, or treated as standby sources.
- NUTMerlin does not automatically fail over between UPS devices, drivers, real and dummy sources, local and remote NUT data, or cached observations.
- `dummy-ups` is an explicit simulation/maintenance source with a distinct simulation identity and persistent visible marker. On a router it is loopback-only and cannot be published under the production logical UPS name.
- Entering router simulation requires the safe maintenance posture from ADR 0067: active policies and executors are disabled, external NUT access and shutdown-client service are closed, and no production action evidence can be generated.
- Leaving simulation requires explicit selection and harmless validation of the exact real source, two fresh observations, listener/firewall revalidation, and administrator re-enablement of any external or action capability. Simulation never transitions automatically into production authority.
- Hardware replacement may retain the client-facing logical name only through an explicit source-replacement workflow. It invalidates UPS field qualification, binding tests, policy activation evidence, and hardware report identity; retained shutdown-client registrations receive a prominent retest warning.
- Multiple authoritative sources, redundant-power logic, source voting, NUT repeater/meta-UPS behavior, and automatic failover remain `Later` and require their own event, conflict, commitment, and qualification model.

## Consequences

- A common single-UPS household has a stable, simple NUT endpoint, while a second connected UPS does not silently alter event authority.
- Router simulation cannot accidentally broadcast `OB` or `LB` to real shutdown clients.
- Testing a production configuration requires an explicit maintenance transition and later re-enable rather than a transparent driver swap.
- Tests must cover default and renamed identifiers, added USB candidates, exact selected identity, no fallback, production-to-dummy and dummy-to-production gates, loopback and firewall scope, simulated payload marking, attempted production-name reuse, retained-client warnings, and replacement invalidation.

## Rejected alternative

Hot-switching `dummy-ups` or a backup physical source behind the existing public name would simplify demonstrations and failover, but would let simulated or semantically different status inherit production client trust, policy qualification, and telemetry assumptions.
