# NUTMerlin research and deferred-capability backlog

## 1. Purpose

This backlog records unresolved research and accepted deferred scope. It is not an implementation ticket list, priority estimate, or permission to begin a capability.

The safe P0/P1/P2 boundaries are settled in ADR 0096 and plan.md; ADR 0097 separates the optional WebUI component from the required core. A backlog item enters implementation planning only after any required decision, threat model, evidence contract, and milestone change are accepted.

## 2. Public-release research blockers

### Release-root publication channels

Select at least two genuinely independent project-controlled channels that publish the full OpenPGP primary-root fingerprint.

The assessment must establish:

- independence of account, hosting, and compromise path;
- exact fingerprint presentation and administrator verification guidance;
- update/rotation behavior;
- archival availability;
- how a compromised channel is reported.

Two pages controlled by the same account or release pipeline do not automatically provide independent trust.

### Emergency signing-root replacement

Document and test:

- detection and publication of suspected primary/subkey compromise;
- release freeze;
- revocation certificate handling;
- channel-specific warning;
- manual bootstrap of a new root;
- behavior of installed versions with the old keyring;
- refusal to accept a new root automatically solely because the suspected old root signed it.

Public release remains blocked until both channel and emergency procedures are accepted and exercised.

## 3. P0 platform and qualification research

### Exact supported stable releases

At each release, identify and qualify the exact latest upstream stable in:

- AArch64 3004.388.x;
- AArch64 3006.102.x.

This is recurring release evidence, not a hard-coded forever version.

### Current Entware cohort

At each release, record:

- supported feed architecture;
- exact coherent NUT package cohort;
- gpgv2;
- required binaries/options;
- optional capability dependencies;
- applicable critical vulnerabilities or safety defects.

NUTMerlin adapts to the current feed; it does not solve incompatibility by requiring an old/private package set.

### Merlin UI authorization integration

Determine, per family on which the optional WebUI will be advertised:

- exact Addons API page-mount behavior;
- authenticated form/session evidence visible to the service-event path;
- safe transient storage for candidate-bound nonces;
- service-event input restrictions;
- failure and recovery when UI mounting or session evidence is unavailable.

The accepted boundary is fixed: no standalone management server/API and no web management when these protections cannot be verified. Failure or absence affects only the optional WebUI claim; the complete core CLI remains authoritative.

### Wall-clock synchronization evidence

Determine, per supported family:

- positive evidence that time synchronization succeeded during the current boot;
- plausible-range validation;
- monotonic projection source;
- detection of a greater-than-300-second discontinuity;
- platform unsynchronized/reset indicators;
- behavior across WAN/NTP loss after trust.

A plausible date or running NTP process is insufficient.

### First exact-router report

Produce one complete current-family model/revision/firmware/storage report covering the entire non-destructive router matrix. This is separate from the physical UPS report.

### First harmless physical UPS report

Produce one exact source report covering stable OL, short OB/recovery, stale or disconnect/reconnect, and unique identity without deep discharge or a writable/output command.

### NUT TLS

Research verified NUT TLS interoperability across the selected Entware NUT build and representative standard clients.

Native trusted-LAN secondary credentials remain the accepted P0 baseline; TLS is an optional profile, not a blocker unless advertised.

## 4. Conditional P0 capability research

### Local-script containment

For each supported platform family, determine whether it can prove:

- dedicated unprivileged identity;
- no root fallback;
- secret/journal/file denial;
- private transient workspace;
- process group and descendant cleanup;
- file/process/CPU/resource bounds;
- no core dump;
- UID- or process-scoped denial of LAN, WAN, and loopback egress.

If any boundary is unavailable or unreliable, local_script remains absent on that platform while the NUT core may still be supported.

### Storage profiles beyond ext4

An exact router/device/filesystem/mount profile may be considered only after passing:

- native UID/GID and 0700/0600/0640;
- case and object/link semantics;
- same-directory atomic rename;
- file and directory fsync;
- exclusive locks;
- executable Entware binaries;
- stable identity;
- controlled interruption/remount recovery.

FAT, VFAT, and exFAT are settled as incompatible and are not research candidates for secret/action-capable use.

### Additional NUT driver profiles

Each proposed driver needs:

- typed options;
- stable identity rules;
- package provenance;
- privilege and lifecycle;
- complete rendering and migration;
- harmless simulator/probe strategy;
- exact source base report;
- independently qualified telemetry fields.

No raw-driver expert path is planned.

## 5. P1 capability questions

### SSH target profiles and verification

For representative Linux/BSD/NAS targets, qualify:

- forced-command wrapper;
- dedicated account and exact permitted operation;
- current Entware OpenSSH interoperability;
- Ed25519 and any needed RSA-SHA2 ≥3072 compatibility;
- operation-specific effect verification.

Targets lacking credible effect verification may report dispatch_accepted but not effect_verified.

### Webhook receiver interoperability

Validate the fixed notification envelope and https_hmac_v1 framing with representative receivers. This cannot add arbitrary payloads, methods, headers, redirects, or action semantics.

### MQTT consumer conventions

Validate stable topic/client naming and current-state/availability behavior with representative local consumers. Home Assistant or Node-RED examples remain consumers of notifications, not privileged built-in integrations.

### Notification presentation

Determine the smallest useful UI/CLI presentation for notification-only policy creation, delivery acceptance, gap summaries, and privacy without creating built-in service-specific adapters.

### Harmless FSD simulator

Define the isolated primary/secondary fixture and expected committed/latch/restart evidence. It must remain structurally unable to reach a real source, external client, router shutdown, or UPS output.

## 6. Conditional P2 capability research

### WinRM client stack

Determine whether a reproducible supported Entware package cohort can provide:

- WSMan/WinRM client behavior;
- verified HTTPS;
- maintainable authentication;
- bounded dependencies and updates;
- constrained-endpoint invocation;
- structured failure evidence.

Current reconnaissance did not establish packaged openwsman, pywinrm, or requests-ntlm. Runtime pip and homegrown WSMan are rejected.

If a stack qualifies, separately validate Windows editions, workgroup/domain behavior, certificate/listener setup, JEA-equivalent endpoint, non-admin rights, firewall, and independent Off verification.

### Redfish least-privilege profiles

For each candidate BMC model/firmware, determine whether a target-side role can:

- read one exact ComputerSystem;
- create/use a constrained session;
- invoke GracefulShutdown;
- deny ForceOff, reset, power-on, account/firmware/console/virtual-media, and unrelated-system access.

Required denial must be proven without attempting a dangerous action. If the narrowest role grants broader power authority, the binding is unavailable for P2.

### Cross-binding Off verification

For SSH or WinRM targets without native authoritative Off evidence, evaluate a separately qualified read-only binding that maps to the same logical target and exact system identity.

Disconnect, timeout, and ping failure remain insufficient.

## 7. Later high-risk capability decisions

Each item below requires a new ADR before implementation planning.

### Complete production FSD

Resolve:

- primary/coordinator behavior;
- secondary coordination and timeouts;
- durable commit and restart;
- router shutdown order;
- UPS power-down state;
- network/storage dependencies;
- return-power and restoration;
- exact hardware qualification;
- physical confirmation and recovery.

Signal-only FSD remains rejected.

### UPS/PDU output control

Resolve separately for:

- off;
- cycle;
- delay;
- stay-off;
- return;
- outlet/group control.

The design must cover physical topology, device-specific capability, credentials, target and policy gates, nonrepeatability, unknown outcome, onsite confirmation, recovery, and testing that never automates a live output-off command.

### Abrupt host and BMC power

ForceOff, hard reset, and equivalent actions require a separate maximum-effect contract, target-side privilege, recovery model, and hardware evidence. They are not a fallback for failed graceful shutdown.

### Target restoration

Power-on and workload restart require return-power stability, dependency order, surge/load limits, partial recovery, anti-flap behavior, and repeated-outage semantics.

### Writable UPS administration

Beeper, test, calibration, upsrw, and other writes require device-specific typed contracts and credentials. There will be no raw upscmd/upsrw pass-through.

### Direct SNMP/PDU

Determine whether owning a direct protocol/device stack provides enough value beyond accepted NUT driver profiles. Any design needs MIB/version/authentication, typed read/write capabilities, outlet identity, verification, and output-control separation.

### Action-capable webhook

Define a real typed action protocol with receiver authorization, idempotency key, effect verification, replay protection, and operation schemas. Generic HTTP 2xx cannot provide this.

### Multiple and redundant UPS sources

Resolve power-domain identity, target dependency, voting, split-brain, stale-source behavior, failover, meta-UPS/repeater semantics, and policy migration. No automatic source failover exists through P2.

### Calendar scheduling

Resolve civil-time trust, time zones, daylight-saving changes, missed/duplicate runs, reboot, and separation from outage-event policy. Through P2 all timing remains event-relative monotonic.

### Hibernation

Define its target semantics, residual load, restart/resume behavior, verification, and interaction with update/storage. It is not equivalent to graceful shutdown.

### Specialized platforms and built-in services

Potential future domains include:

- hypervisors and clusters;
- storage arrays/NAS-specific APIs;
- Kubernetes/drain;
- email/SMS/mobile/cloud notification;
- vendor-specific orchestration.

Each requires a concrete community use case and independent trust/dependency/failure analysis.

### AMTM or catalog distribution

Assess installer ownership, authenticated artifacts, pinned-key behavior, update initiation, rollback, release-root rotation, catalog maintainer trust, and emergency response before requesting inclusion.

### Policy-store expansion

If protected policy versions exhaust the ordinary 8 MiB store, define an explicit expansion workflow with free-space, quota, endurance, rollback, UI/CLI, and recovery semantics. Until then, new activation is refused.

## 8. Nonblocking research

- Partial firmware rehosting for narrow firmware behavior questions.
- Optional ARMv7 Entware user-mode execution.
- Community hardware report tooling and privacy ergonomics.
- New exact router/storage/UPS reports beyond the first-public minimum.
- Client-neutral Windows NUT-client interoperability tracking.
- Additional harmless support-bundle redaction tests.

None replaces a required evidence layer or broadens the support contract.

## 9. Settled items that are not backlog

Do not reopen these as ordinary feature suggestions:

- repository exists at darvilp/nutmerlin;
- GPL-3.0-or-later, GitHub Actions, protected main, and feature/draft-PR workflow;
- latest-qualified 3004.388.x and 3006.102.x support;
- Merlin 386/ARMv7 legacy best-effort;
- client-local NUT secondary as the P0 shutdown path;
- no age-based secondary credential expiry;
- one confirmed IPv4 trusted subnet and IPv6 default-off;
- current Entware feed as gold standard;
- all Entware packages retained on normal uninstall;
- user-initiated signed updates;
- monitoring-only defaults;
- one authoritative source and isolated dummy-ups;
- no production FSD, output control, ForceOff, restoration, direct SNMP/PDU, writable UPS administration, hibernation, scheduling, or inbound control through P2.

Changing one of these requires revisiting its accepted ADR, not adding an implementation backlog item.
