# ADR 0096: Freeze milestones around the safe NUT core

- Status: Accepted
- Date: 2026-08-02

## Context

The initial plan mixes the generally useful NUT server, policy foundations, local scripts, production FSD, alerts, output shedding, and several enterprise protocols. Treating every listed integration as one path to completeness would delay the safe common case and create pressure to weaken executor or hardware gates. Priority labels need capability boundaries, not promises that every router supports every optional adapter.

## Decision

NUTMerlin milestones are frozen around a safe NUT core with independently advertised optional capabilities.

### P0 — public core

P0 is release-blocking for a public community release and includes:

- the supported current Merlin-family, architecture, current-Entware, storage, ownership, installation, update, rollback, disable, detach, uninstall, signature, and first-install contracts
- one active `usbhid-ups` production source through its validated driver profile and loopback-isolated `dummy-ups`
- immutable generated NUT configuration, bounded lifecycle supervision, fresh/unknown status normalization, and no writable UPS administration
- one confirmed trusted IPv4 subnet, exact listener/firewall gating, credential-free read-only NUT status, and explicit per-client `upsmon secondary` onboarding
- monitoring-only core installation, complete local CLI, bounded history, support/export diagnostics, and recovery paths, plus the separately installable curated Merlin status/configuration WebUI component defined by ADR 0097
- policy, target, typed-operation, evidence, journal, dry-run, and simulator foundations needed to prove safety, without enabling a central shutdown policy by default
- the constrained P0 local-script contract only on platform profiles that qualify every privilege, resource, and no-egress boundary; its absence does not remove core platform support
- hardware-free host, `dummy-ups`, current AArch64 package/ABI, simulated Merlin-profile, and security evidence plus the first-public exact-router and harmless physical UPS base reports required by ADR 0064

The P0 user-facing shutdown pattern is client-local NUT. P0 does not wait for SSH, a Windows-specific path, production FSD, or a physical UPS model beyond separately stated qualification evidence.

### P1 — common orchestration

P1 adds, without weakening P0:

- first-class notification-only policies through fixed generic webhook and publish-only MQTT profiles
- restricted SSH bindings using current Entware OpenSSH and typed graceful service/host operations
- explicit immutable target stages, protections, dependencies, conflict analysis, action budgets, qualified runtime/charge thresholds, and graceful host/service load shedding
- event/action audit views and harmless activation evidence for those bindings
- a fully harmless simulated NUT primary/secondary FSD environment for design and compatibility testing, but no production FSD executor

P1 contains no output-cutting operation, abrupt host action, automatic restoration, built-in email/cloud adapter, action-capable generic webhook, inbound MQTT, or automatic update.

### P2 — capability-gated native adapters

P2 may advertise only adapters that independently satisfy their complete release and hardware capability gates:

- constrained HTTPS WinRM `host.graceful_shutdown` if a reproducible qualified router client stack exists
- manually selected, least-privilege, verified-HTTPS Redfish query and `GracefulShutdown` with `Off` verification
- additional validated NUT driver profiles when separately accepted; their presence is not a blanket P2 promise

Failure to qualify WinRM or Redfish leaves that capability absent and does not block a core release. P2 contains no hibernation, ForceOff, reset, power-on, target restoration, direct SNMP/PDU protocol, SNMP SET, or writable UPS command.

### Later — separately governed high-risk or broad scope

`Later` includes:

- complete production FSD with coordinator shutdown, secondary coordination, output/power-down state, restoration, and exact hardware qualification
- UPS/PDU output off, cycle, delay, stay-off, return, outlet control, and abrupt Redfish or other force operations
- target power-on/workload restoration, writable UPS administration, direct SNMP/PDU, root local scripts, hibernation, and broader action-capable webhook protocols
- multiple/redundant UPS sources, source voting/failover, NUT repeater/meta-UPS, calendar scheduling, inbound control protocols, specialized platform/cluster/storage APIs, and built-in email/cloud/mobile services
- AMTM/catalog distribution until its authenticated maintenance model is separately accepted

Release hardening, security, negative testing, documentation, and support evidence are exit gates for every milestone rather than a final cleanup milestone. A capability label never bypasses platform preflight, exact binding qualification, or monitoring-only defaults.

## Consequences

- The first public release can solve the broad NUT-server and client-local problem without storing remote host administrator credentials.
- P1/P2 features are valuable additions rather than hidden prerequisites for a supported core router.
- Several current requirements, plan bullets, and backlog entries move to Later or become capability-gated during reconciliation, especially production FSD, outlet groups, WinRM, Redfish force/restore, SNMP/PDU, writable UPS commands, email, and catalog integration.
- Milestone acceptance must cite behavior and evidence, not code presence or a roadmap heading.
- Tests and support matrices report core platform support separately from optional WebUI, local-script, SSH, WinRM, Redfish, driver-profile, UPS-field, and exact-hardware capabilities.

## Rejected alternative

Making central host orchestration and production FSD part of the first public release would present a broader feature set, but would hold the generally useful NUT server behind remote credential, commitment, executor verification, router shutdown, output control, restoration, and physical-hardware problems that the client-local pattern avoids.
