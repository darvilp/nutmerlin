# ADR 0073: Keep direct SNMP and PDU protocols outside P2

- Status: Deferred research - non-authoritative for v0.1
- Date: 2026-08-02

## Context

The original P2 registry includes an `snmp_pdu` executor with MIB discovery, read-only queries, SET allowlists, outlet mapping, and verification. That would make NUTMerlin maintain another device protocol and model alongside NUT, despite the project's mission to use Entware-provided NUT as the UPS protocol layer. Output control is already deferred beyond P2 by ADR 0039.

## Decision

P0 through P2 contain no direct SNMP or managed-PDU protocol executor.

- UPS or PDU telemetry available through a current Entware NUT driver may be consumed as ordinary NUT source data, subject to source identity, field qualification, freshness, and capability ADRs.
- NUTMerlin does not ship MIBs, implement SNMP discovery or polling, map vendor outlet OIDs, hold SNMP credentials, or issue SNMP SET in P0 through P2.
- Read-only CLI and, when installed, WebUI status may display qualified values reported by NUT; this does not imply direct SNMP support or output-control capability.
- A device for which no suitable NUT driver exists is not made compatible by adding an ad hoc protocol adapter to the core addon.
- External systems may consume NUTMerlin webhook or MQTT publications and perform independently authorized PDU or SNMP automation, but their effects are outside NUTMerlin execution and verification claims.
- Future direct PDU or SNMP integration is `Later` and requires a separate scope ADR, protocol security model, constrained operation registry, exact device/MIB qualification, simulator, harmless discovery path, and the output-control gates required by ADRs 0039 and 0070.

## Consequences

- P2 remains focused on constrained WinRM and graceful-only Redfish rather than a vendor-MIB ecosystem.
- NUT-supported network UPS devices can still participate without NUTMerlin duplicating their protocol driver.
- Hardware reports identify the NUT driver and qualified variables, not merely the underlying transport.
- Requirements, architecture, plan, and backlog references that promise a P2 `snmp_pdu` executor or SNMP SET move to `Later` during reconciliation.
- Tests need NUT-driver doubles and representative NUT-exposed network-source data, but no project-owned SNMP stack in P0 through P2.

## Rejected alternative

A P2 read-only SNMP adapter with all SET operations absent would reduce immediate physical risk and support devices outside NUT, but would still create a parallel discovery, credential, MIB, data-normalization, and hardware-qualification surface that does not deepen the NUT integration.
