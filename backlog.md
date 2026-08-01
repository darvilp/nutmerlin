# NUTMerlin prioritized backlog

## P0 — Core release

### Platform and packaging

- [ ] Create public `danielarvilpayne/nutmerlin` repository from WSL2; GPL-3.0-or-later decision is accepted.
- [ ] Merlin/Addons API detection.
- [ ] Entware detection and package manifest.
- [ ] Idempotent install/repair/update/uninstall.
- [ ] Managed user-script hook insertion/removal.
- [ ] Late `/opt` mount handling.
- [ ] Last-known-good rollback.
- [ ] CLI recovery mode.
- [ ] Existing manual NUT deployment detection/adoption.
- [ ] Named mock, RT-AC3100, and RT-AX86U Pro hardware profiles.
- [ ] Production-router deployment gate.
- [ ] Optional RT-AC3100 386/ARMv7 compatibility workflow.
- [ ] Storage-media diagnostics and missing/read-only `/opt` handling.
- [ ] Write-minimized state and bounded log design.

### NUT server

- [ ] One local `usbhid-ups` source.
- [ ] First-class `dummy-ups` source.
- [ ] Validated NUT config generation.
- [ ] Driver and `upsd` lifecycle.
- [ ] LAN-only listener/firewall.
- [ ] Read-only client onboarding.
- [ ] Status and health query.
- [ ] Missing/stale telemetry handling.
- [ ] Real/simulated source switch.
- [ ] Capture/replay helper for `.dev`/`.seq`.

### UI and diagnostics

- [ ] Merlin dashboard.
- [ ] CLI status.
- [ ] Validation and restart actions.
- [ ] Client connection instructions.
- [ ] Redacted logs/diagnostics.
- [ ] Settings export/import without secrets.
- [ ] Package/version/architecture display.

### Policy foundation

- [ ] Normalized event model.
- [ ] Delay and recovery cancellation.
- [ ] Idempotent event episodes.
- [ ] Dry run.
- [ ] Local allowlisted script executor.
- [ ] Restart-safe state semantics.
- [ ] WSL2/Codex bootstrap, test harness, and router shims.
- [ ] `dummy-ups` CI scenarios.

## P1 — Common general-use patterns

### SSH executor

- [ ] Key generation/import.
- [ ] Host-key pinning.
- [ ] Restricted-command onboarding.
- [ ] Linux/BSD/NAS templates.
- [ ] Optional Windows OpenSSH template.
- [ ] Timeout/retry.
- [ ] Verification strategies.
- [ ] Target group ordering.

### HTTP webhook executor

- [ ] JSON payload schema.
- [ ] HTTPS verification.
- [ ] Secret headers.
- [ ] HMAC signature.
- [ ] Timeout/retry.
- [ ] Response policy.
- [ ] SSRF protections.

### MQTT executor

- [ ] Normalized event topics.
- [ ] Action-result topics.
- [ ] TLS.
- [ ] Credentials.
- [ ] Retained-message controls.
- [ ] Home Assistant/Node-RED examples.

### NUT FSD and coordinated shutdown

- [ ] Advanced primary/secondary setup.
- [ ] Explicit committed-state UI.
- [ ] FSD test environment.
- [ ] Client disconnect/timeout tracking.
- [ ] No kill-power default.
- [ ] Recovery/restart documentation.

### Alerts and load shedding

- [ ] Webhook alerts.
- [ ] MQTT alerts.
- [ ] Optional local notification adapters.
- [ ] Runtime and charge thresholds.
- [ ] Ordered noncritical/important/critical groups.
- [ ] Target exclusions.
- [ ] Event/audit history.
- [ ] Capability-gated outlet groups where supported.

## P2 — Backlog executors

### WinRM / PowerShell Remoting

- [ ] HTTPS transport.
- [ ] Least-privilege/JEA guidance.
- [ ] Windows shutdown and hibernate.
- [ ] Connection test.
- [ ] Execution and verification.
- [ ] Credential/certificate storage.
- [ ] Windows firewall setup documentation.

### Redfish

- [ ] Service discovery/manual endpoint setup.
- [ ] Dedicated BMC account guidance.
- [ ] TLS trust configuration.
- [ ] Power-state query.
- [ ] `GracefulShutdown`.
- [ ] Poll/verify transition to `Off`.
- [ ] Explicit configurable timeout.
- [ ] Optional `ForceOff` escalation behind dual opt-in.
- [ ] Optional `On`/restore action.
- [ ] Rate limiting.
- [ ] Mock Redfish test server.
- [ ] Real BMC compatibility reports.

### SNMP / managed PDU

- [ ] SNMPv3 preferred.
- [ ] MIB/capability model.
- [ ] Read-only discovery.
- [ ] SET action allowlist.
- [ ] Outlet mapping.
- [ ] Verification.
- [ ] Dual opt-in for power-off.

### UPS administrative commands

- [ ] Capability discovery.
- [ ] Beeper control.
- [ ] Battery self-test.
- [ ] Delayed output actions.
- [ ] `shutdown.return`/`shutdown.stayoff` safety design.
- [ ] Device-specific compatibility records.
- [ ] Separate administrative credential.
- [ ] No default exposure.

## Later — Specialized platforms

- [ ] VMware vCenter/ESXi.
- [ ] Hyper-V/SCVMM.
- [ ] Proxmox API.
- [ ] Nutanix.
- [ ] TrueNAS/Synology/QNAP native adapters where NUT/SSH is insufficient.
- [ ] Kubernetes/cluster drain workflows.
- [ ] Storage-array shutdown.
- [ ] Cloud notification integrations.
- [ ] Multi-UPS and redundant power-source logic.
- [ ] NUT repeater/meta-UPS support.
- [ ] Multiple USB devices and stable matching.
- [ ] UPS compatibility report submission workflow.
- [ ] Localization.
- [ ] AMTM catalog inclusion.
- [ ] Signed release/update channel.
- [ ] Optional mobile-friendly status page.

## Research / non-blocking

- [ ] Full or partial Asuswrt-Merlin firmware rehosting under QEMU/FirmAE.
- [ ] AArch64 and ARMv7 Entware user-mode test images.
- [ ] Generic ASUS web API emulator for UI-independent testing.
- [ ] Official/current Windows NUT client alternatives.
- [ ] WinNUT successor/Coco.Nut status.
- [ ] NUT TLS support in the selected Entware build and client ecosystem.
- [ ] Hardware-triggered USB hotplug behavior across router models.
