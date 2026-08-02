# NUTMerlin

NUTMerlin is a planned community Asuswrt-Merlin addon that safely integrates Entware-provided Network UPS Tools with the router lifecycle, standard NUT clients, and optional power-event orchestration.

NUT remains the UPS device and network-protocol engine. NUTMerlin does not implement a replacement UPS protocol stack.

## Product shape

The milestone boundaries are deliberately narrow:

1. **P0 — safe NUT core.** One qualified usbhid-ups source, an isolated dummy-ups source, signed install/update/rollback, exact trusted-LAN NUT exposure, per-client upsmon secondary onboarding, monitoring-only defaults, complete local CLI, durable recovery, hardware-free testing, and an optional exact-version curated Merlin WebUI component.
2. **P1 — common graceful orchestration.** Notification-only webhook and MQTT profiles, restricted SSH, qualified thresholds, protected target stages, graceful load shedding, and harmless simulated FSD.
3. **P2 — qualified native adapters.** Graceful-only WinRM and Redfish when their complete dependency, least-privilege, transport, target, and verification contracts pass.
4. **Later.** Production FSD, UPS/PDU output control, abrupt power, restoration, writable UPS administration, direct SNMP/PDU, hibernation, multiple UPS sources, scheduling, inbound protocols, and broad platform/cloud integrations.

The normal shutdown path is client-local:

    UPS -> NUT server on Merlin router -> registered NUT secondary -> local host shutdown

The client owns its delay, cancellation, and local command. NUTMerlin creates no shutdown credential until an administrator registers a client and does not claim to verify the client’s local shutdown.

The core installs and operates without a WebUI. An administrator may explicitly add or remove the version-matched WebUI component without changing NUT services, configuration, credentials, policies, history, or CLI recovery. Both artifacts are authenticated by the same release manifest and never run at mismatched versions.

## Safety defaults

- Fresh installs and upgrades are monitoring-only.
- External NUT status is credential-free and read-only within one explicitly confirmed IPv4 trusted subnet.
- WAN, guest, VPN-client, other subnet, wildcard, and IPv6 access are closed by default.
- No outage timer, runtime/charge threshold, telemetry-loss fail-safe, central executor, or shutdown credential is prefilled.
- Reversible outage handling is distinct from committed shutdown; FSD is never a cancelable timer.
- No raw NUT configuration, arbitrary shell command, writable UPS command, ForceOff, output control, or automatic restoration exists through P2.
- Secrets are binding-scoped, shown once, stored in protected files, and excluded from logs, browser state, exports, and support bundles.
- Storage, telemetry, identity, policy, transport, or action ambiguity fails closed for new state-changing work.

## Support model

The intended supported platform contract covers the latest NUTMerlin-qualified stable release in each current AArch64 Merlin family:

- 3004.388.x
- 3006.102.x

Eligibility is capability-based rather than a router-model allowlist. An exact model/revision becomes qualified hardware through one complete reproducible report; qualification is carried forward only when relevant platform behavior did not change, and reproducible negative evidence revokes the affected claim.

Merlin 386/ARMv7 and the available RT-AC3100 are legacy best-effort only. The RT-AX86U Pro is a manually gated production-reference target, not proof of an entire firmware family.

UPS capabilities are qualified separately for an exact UPS, driver profile, and NUT version. The maintainer’s CyberPower CP1500PFCLCD is reference hardware, not a product dependency or blanket support promise.

## Dependencies and storage

NUTMerlin requires a preexisting healthy Entware installation and qualifies against the current supported Entware package cohort. It never bootstraps Entware, runs a blanket opkg upgrade, substitutes private NUT binaries, or removes Entware packages during ordinary uninstall.

Ext4 on a USB-attached SSD is the reference always-on storage profile. Other exact storage profiles must prove the required Unix permissions, atomic rename, fsync, locking, execution, identity, and interruption-recovery semantics. FAT, VFAT, and exFAT are incompatible.

## Development and evidence

Normal development runs from a Linux filesystem using host shims and NUT dummy-ups, without an ASUS router or physical UPS. Every release also requires current AArch64 Entware package/ABI evidence. Exact-router and physical-UPS reports are separately gated and make only the claims they exercise.

No automated test may issue UPS output-off. Production-router mutation requires NUTMERLIN_ALLOW_PRODUCTION_ROUTER=1, and an actual host-shutdown test requires NUTMERLIN_ALLOW_HOST_SHUTDOWN=1 plus documented safeguards.

The initial host-safe core slice is available without hardware:

    make bootstrap
    make test
    bin/nutmerlin self-check --json

The self-check runs through the versioned local management-operation path using
disposable isolated roots. It reports monitoring-only health and does not call
router, firewall, service, package, NUT, WebUI, or hardware controls.

## Project documents

- [CONTEXT.md](CONTEXT.md) — canonical domain terminology.
- [decision-ledger.md](decision-ledger.md) — complete design-interview closeout and reconciliation map.
- [decisions/](decisions/) — the sole ADR hierarchy.
- [requirements.md](requirements.md) — normative capability and acceptance requirements.
- [architecture.md](architecture.md) — component, state, data, and lifecycle boundaries.
- [security.md](security.md) — threats, invariants, privilege, transport, and supply-chain controls.
- [testing.md](testing.md) — evidence layers, simulation, negative tests, and hardware qualification.
- [hardware.md](hardware.md) — reference equipment, support tiers, bench safety, and report contracts.
- [development.md](development.md) — safe WSL/Linux workflow, commands, profiles, and gates.
- [plan.md](plan.md) — capability milestones and exit gates, not implementation tickets.
- [backlog.md](backlog.md) — unresolved research and deferred capability inventory.
- [references.md](references.md) — primary external implementation references.
- [AGENTS.md](AGENTS.md) — contributor and agent guardrails.

## Status

Design reconciliation is complete and implementation has begun with the
host-safe core self-check. The accepted decisions are ADRs 0001–0097 under
decisions/. The remaining public-release research blocker is selection of two
independent release-root fingerprint publication channels and a tested
emergency root-replacement procedure.

The repository is public at darvilp/nutmerlin under GPL-3.0-or-later. Versions, package availability, firmware behavior, and hardware claims must be requalified rather than assumed from this planning packet.
