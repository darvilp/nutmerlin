# NUTMerlin capability and release plan

## 1. Purpose

This document fixes milestone scope and exit gates. It is not an implementation sequence, ticket breakdown, estimate, or release calendar.

Implementation planning begins only after the reconciled design is converted into a separate specification. Accepted ADR 0096 controls milestone membership, and ADR 0097 separates the optional WebUI component from the required core installation.

## 2. Goal

Deliver a safe, maintainable community Asuswrt-Merlin addon that:

- installs and manages Entware-provided NUT without owning Entware;
- exposes one authoritative NUT-compatible source to standard NUT clients on an exact trusted-LAN scope;
- makes client-local shutdown the safe P0 path;
- adds optional graceful orchestration only behind complete capability gates;
- preserves router operation, secrets, durable action evidence, and recoverability under failure.

## 3. Cross-milestone rules

Every milestone:

- starts monitoring-only and requires explicit activation for authority;
- preserves NUT as the device/protocol core;
- uses the latest qualified stable in both intended current AArch64 Merlin families;
- qualifies against the current supported Entware package cohort;
- runs normal tests without a router or physical UPS;
- keeps exact-router and UPS-capability evidence separate;
- uses closed typed operations, least privilege, durable dispatch intent, and explicit evidence grades;
- fails closed on ambiguity;
- protects the coordinator and control-path infrastructure;
- updates requirements, architecture, security, tests, support evidence, and ADRs when semantics change;
- treats security, negative testing, documentation, recovery, and release evidence as exit gates rather than later cleanup.

No milestone label bypasses platform preflight, binding qualification, policy activation evidence, or monitoring-only defaults.

## 4. P0 — public safe NUT core

### 4.1 Included capability

Platform and dependencies:

- supported current AArch64 3004.388.x and 3006.102.x contracts;
- capability-based eligibility and exact-hardware reporting;
- healthy preexisting Entware prerequisite;
- current-feed coherent package policy;
- qualified storage semantics with ext4 reference;
- optional nonblocking Merlin 386/ARMv7 legacy evidence.

Authenticated lifecycle:

- manual authenticated first-install bundle;
- pinned OpenPGP release root and signed manifest/artifacts;
- conservative ownership and foreign-deployment refusal;
- journaled current/previous release slots;
- user-initiated update and safe activation window;
- one rollback attempt and rollback quarantine;
- disable, clean uninstall refusal rules, and emergency detach;
- immutable paired NUT configuration generations.

NUT service:

- one authoritative usbhid-ups source;
- one distinct loopback-only dummy-ups maintenance source;
- stable unique USB source identity;
- bounded driver/upsd lifecycle and restart breaker;
- NUT_CONFPATH-selected complete configuration;
- fresh/unknown state normalization and volatile current status;
- no writable UPS administration.

Network and clients:

- one explicitly confirmed IPv4 trusted subnet and exact listener;
- listener plus firewall exposure gate and periodic drift checks;
- credential-free read-only status in scope;
- IPv6 default-off;
- explicit independent upsmon secondary onboarding;
- once-only credentials, event-driven replacement, two-phase cutover, and durable revocation.

Management and recovery:

- complete local CLI;
- optional exact-version authenticated Merlin WebUI component using a candidate-bound one-time nonce;
- no standalone management listener/API;
- monitoring-only defaults;
- privilege-separated lifecycle, policy/status, optional WebUI, and execution broker;
- dual monotonic/wall-clock trust model;
- 4 MiB safety journal and two-slot 64 KiB JFFS anchor;
- bounded operational history, policy-version retention, configuration export, and support bundles.

Policy foundations:

- normalized fresh observations;
- reversible versus committed phases;
- logical targets and bindings;
- immutable exact policy versions;
- closed typed operations and maximum-effect classes;
- retry classes, action budgets, dependencies, conflicts, evidence grades, and restart reconciliation;
- prospective emergency inhibit;
- event-relative monotonic timing only.

Conditional P0:

- the separately authenticated WebUI artifact, installed only by explicit choice and supported only where its exact Merlin integration qualifies;
- absence of the WebUI does not reduce core platform support or CLI completeness;
- the constrained local-script executor only on platform profiles that prove unprivileged execution, resource/process containment, protected storage, and UID/process-scoped no-egress;
- absence of this executor does not reduce core platform support.

### 4.2 Explicitly excluded

- SSH, webhook, MQTT, and central host actions enabled by default;
- production FSD;
- writable UPS/PDU administration;
- power_abrupt or output_control operations;
- ForceOff, reset, power-on, restoration, or hibernation;
- direct SNMP/PDU;
- multiple/redundant source behavior;
- scheduling and inbound control protocols;
- automatic update;
- built-in cloud/email/mobile services.

### 4.3 Exit gates

P0 exits only when:

1. Host static/unit/security/lifecycle/configuration/policy tests pass without hardware.
2. Isolated dummy-ups integration passes.
3. Exact current AArch64 Entware package/ABI and gpgv2 release evidence passes.
4. Simulated current Merlin-family profiles pass.
5. Both advertised latest stable firmware-family contracts have required evidence.
6. At least one complete exact current-router report passes.
7. At least one harmless physical UPS base report passes.
8. Two independent release-root fingerprint channels and the emergency root-replacement procedure are selected and tested.
9. First install, update, health window, one rollback, rollback failure, disable, clean uninstall, emergency detach, late /opt, runtime storage loss, and restart reconciliation pass.
10. WAN/guest/VPN/other subnet/wildcard/default IPv6 access is closed and scope drift fails closed.
11. Per-client role isolation, once-only delivery, cutover, revocation, and rollback resistance pass.
12. No arbitrary shell/raw NUT config, management API, writable UPS command, production FSD, abrupt/output action, or automatic authority is reachable.

## 5. P1 — common graceful orchestration

### 5.1 Included capability

Notifications:

- first-class notification-only policies;
- fixed normalized notification.publish envelope;
- lan_anonymous, https_bearer, and https_hmac_v1 webhook profiles;
- MQTT v5 ephemeral QoS 1 publication with explicit v3.1.1 compatibility;
- retained current state/availability only;
- no persistent notification outbox or stale replay.

Graceful central operations:

- current Entware OpenSSH;
- one keypair per binding;
- independently pinned host identity;
- target-enforced forced command/restricted account;
- typed graceful service and host operations;
- operation-specific verification.

Policy capability:

- qualified charge/runtime thresholds with hysteresis;
- exact immutable target stages;
- explicit acyclic prerequisites;
- conflict rejection and identical-intent coalescing;
- protected coordinator and network infrastructure;
- bounded concurrency, rate, timeout, and retry;
- event/action history views.

FSD design evidence:

- fully harmless isolated primary/secondary simulation;
- committed-state and latch semantics;
- no production FSD authority.

### 5.2 Explicitly excluded

- action-capable generic webhook;
- inbound MQTT;
- built-in SMTP/SMS/cloud/mobile adapter;
- output/outlet operations;
- abrupt host operation;
- target restoration;
- automatic update;
- production FSD.

### 5.3 Exit gates

P1 exits only when:

- every binding passes current harmless activation evidence and exact dry-run;
- webhook address/peer/TLS/HMAC/redaction/nonrepeatability tests pass;
- MQTT session/retained/no-subscription/no-outbox tests pass;
- SSH forced-command, per-binding key, host-key, privilege, retry, and verifier tests pass;
- dependencies, conflicts, protected targets, thresholds, budgets, and evidence states pass;
- failures do not weaken independent P0 monitoring/client service;
- forbidden inbound, abrupt, output, restoration, and production-FSD operations remain absent.

## 6. P2 — independently qualified native graceful adapters

P2 is capability-gated rather than a blanket promise. A missing adapter does not block a safe core release.

### 6.1 WinRM

May be advertised only when:

- a reproducible supported Entware client cohort exists;
- verified HTTPS works without runtime pip or a homegrown WSMan implementation;
- a dedicated non-admin constrained JEA-equivalent endpoint permits only the typed graceful shutdown;
- dispatch is nonrepeatable;
- an independent verifier can establish Off.

No hibernation, Basic/plaintext, broad TrustedHosts, unrestricted administrator endpoint, or disconnect-as-proof.

### 6.2 Redfish

May be advertised only when:

- one exact ComputerSystem is manually selected and identity-pinned;
- TLS 1.2+ server identity is verified;
- a dedicated target-side role permits read plus GracefulShutdown while denying ForceOff, reset, power-on, and administration;
- one nonrepeatable GracefulShutdown is used;
- Off is verified through two consecutive fresh samples inside the bounded window;
- timeout or ambiguity never escalates.

### 6.3 Additional NUT drivers

An additional driver may enter P2 only through an accepted versioned driver profile with typed options, identity, privilege, rendering, lifecycle, harmless probes, migration, package evidence, and exact hardware capability evidence.

### 6.4 P2 exclusions

- hibernation;
- ForceOff or hard reset;
- power-on/restoration;
- direct SNMP/PDU;
- writable UPS command;
- output control;
- production FSD;
- broad administrator credentials.

## 7. Later — separately governed scope

Later includes:

- complete production FSD with coordinator shutdown, secondary coordination, UPS power-down state, restoration, and exact hardware qualification;
- UPS/PDU output off, cycle, delay, stay-off, return, and outlet control;
- Redfish/other ForceOff, reset, or abrupt power;
- target power-on and workload restoration;
- writable UPS administration including beeper/test/calibration;
- direct SNMP/PDU protocols;
- root local scripts;
- hibernation;
- multiple/redundant UPS sources, voting, failover, repeater, or meta-UPS;
- calendar/cron/timezone/sun scheduling;
- inbound MQTT or other control protocols;
- action-capable webhook protocols;
- specialized hypervisor, cluster, storage, and vendor APIs;
- built-in email, cloud, and mobile services;
- AMTM/catalog distribution until an authenticated maintenance model is accepted.

Every Later item requires a separate trade-off decision, threat model, typed operation contract, qualification strategy, and milestone placement before implementation planning.

## 8. Release support policy

- Advertise only the latest qualified stable in each current Merlin family.
- Keep a previously qualified release supported until the new stable qualifies.
- Move support without a retirement grace period after qualification.
- Treat older firmware/package cohorts as compatibility-only.
- Treat Merlin 386/ARMv7 as legacy best-effort.
- Publish exact-router and UPS-capability reports independently.
- Carry reports forward only across recorded no-risk changes.
- Reproducible negative evidence revokes the affected claim.
- Do not use a 12-month qualification expiry.

## 9. Capability definition of done

A capability is complete only when:

- its accepted requirements and ADRs are satisfied;
- closed schemas and migration/rollback behavior exist;
- least privilege and secret scope are proven;
- safe defaults and absence of broader authority are tested;
- host tests and relevant integration simulators pass;
- exact package/ABI evidence passes when required;
- exact hardware evidence exists for every hardware-dependent claim;
- failures, unknown outcomes, restart, storage loss, update, and rollback fail safely;
- CLI and any installed WebUI diagnostics are accurate and redacted;
- support scope and known incompatibilities are published;
- no lower evidence layer failed or was silently skipped.
