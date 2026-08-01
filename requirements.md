# NUTMerlin requirements

## 1. Product scope

NUTMerlin shall provide a supported, user-friendly method to run Network UPS Tools on Asuswrt-Merlin using Entware and to expose normalized UPS events to standard clients and optional orchestration executors.

Confirmed reference hardware includes a CyberPower `CP1500PFCLCD`, an RT-AX86U Pro production router, and an optional RT-AC3100 legacy integration router. The product remains device-neutral and shall not hard-code this hardware.

NUTMerlin is not:

- a replacement for NUT drivers or protocol handling
- a cloud monitoring service
- a generic remote-command platform
- a guarantee that every UPS reports correct telemetry
- a substitute for device-specific shutdown testing

Priority labels:

- **P0** — MVP/release blocker
- **P1** — common follow-on capability
- **P2** — backlog capability
- **Later** — specialized or enterprise integration

## 2. Supported deployment patterns

### REQ-PATTERN-001 — Network UPS server (P0)

The router shall run the UPS driver and NUT data server. Independent clients shall be able to monitor status and apply their own shutdown policy.

### REQ-PATTERN-002 — Coordinated NUT shutdown (P1)

The addon shall support an advanced committed primary/secondary NUT shutdown workflow, including FSD, without presenting it as a cancelable outage timer.

### REQ-PATTERN-003 — Agentless push (P1)

The addon shall support centrally initiated actions through pluggable executors, beginning with SSH.

### REQ-PATTERN-004 — Platform-native and out-of-band actions (P2)

The executor model shall allow later WinRM, Redfish, SNMP/PDU, and platform-specific actions.

### REQ-PATTERN-005 — Alerts only (P1)

A user shall be able to publish events without enabling shutdown actions.

### REQ-PATTERN-006 — Load shedding (P1)

A user shall be able to stage actions by priority and threshold while preserving excluded infrastructure.

## 3. Platform and installation

### REQ-PLAT-001 — Merlin detection (P0)

The installer shall verify that the device runs Asuswrt-Merlin and exposes the Addons API before installing the UI.

### REQ-PLAT-002 — Entware detection (P0)

The installer shall detect Entware, its mount path, package architecture, package manager availability, and writeability.

### REQ-PLAT-003 — Dependency management (P0)

The installer shall install only required Entware packages and shall record which packages it installed.

### REQ-PLAT-004 — Existing NUT deployment protection (P0)

If a preexisting NUT configuration is detected and ownership is ambiguous, the installer shall stop or enter an explicit import/adopt workflow. It shall not silently overwrite manual configuration.

### REQ-PLAT-005 — Idempotency (P0)

Install, repair, upgrade, and uninstall operations shall be safe to repeat.

### REQ-PLAT-006 — Late `/opt` mount (P0)

Service startup shall tolerate Entware storage being absent or mounted after base router services.

### REQ-PLAT-007 — Clean uninstall (P0)

Uninstall shall remove only project-owned files, hook blocks, firewall rules, and optionally project-installed packages after confirming they are unused.

### REQ-PLAT-008 — Recovery (P0)

A documented CLI recovery path shall work when the web page fails to mount.


### REQ-PLAT-009 — Hardware-optional development (P0)

The repository's normal lint, unit, NUT simulation, security, and packaging checks shall run without an ASUS router or physical UPS.

### REQ-PLAT-010 — Explicit router profiles (P0)

Hardware deployment shall use named profiles. A production profile shall require an explicit override, while the RT-AC3100 profile shall be classified as optional legacy test hardware.

### REQ-PLAT-011 — Legacy capability detection (P0)

The addon shall detect architecture, firmware capabilities, Addons API support, Entware feed, available commands, firewall implementation, and USB behavior rather than assuming parity between Merlin 386 and current branches.

### REQ-PLAT-012 — Development environment neutrality (P0)

WSL2 is the primary maintainer environment, but runtime and host tests shall remain compatible with a normal Linux environment.

## 4. UPS and NUT management

### REQ-NUT-001 — USB HID MVP (P0)

The MVP shall support one locally attached UPS through `usbhid-ups`, subject to NUT device compatibility.

### REQ-NUT-002 — Simulation (P0)

The addon shall support `dummy-ups` as a first-class source for development, demonstrations, and troubleshooting.

### REQ-NUT-003 — Configuration generation (P0)

The addon shall generate valid `ups.conf`, `upsd.conf`, and `upsd.users` content from validated settings.

### REQ-NUT-004 — Atomic activation (P0)

Generated configuration shall be validated and activated atomically with a last-known-good rollback.

### REQ-NUT-005 — Service lifecycle (P0)

The addon shall start, stop, restart, and report health for the configured driver and `upsd`.

### REQ-NUT-006 — Status query (P0)

The addon shall use NUT interfaces such as `upsc` rather than parsing USB HID data itself.

### REQ-NUT-007 — Unknown telemetry (P0)

Missing, stale, malformed, or known-unreliable telemetry shall be represented as unknown. It shall not be coerced to zero.

### REQ-NUT-008 — Administrative command separation (P0)

Read-only monitoring and administrative NUT commands shall use separate capabilities and credentials.

### REQ-NUT-009 — No default load control (P0)

UPS output-off, delayed load-off, `shutdown.return`, `shutdown.stayoff`, and equivalent commands shall be disabled by default and absent from the primary UI.

### REQ-NUT-010 — Multi-UPS extensibility (Later)

The internal model shall not prevent later multi-UPS support, but the MVP may support exactly one source.

## 5. Persistent storage and durability

### REQ-STOR-001 — Persistent Entware storage (P0)

A real-router installation shall require a supported persistent `/opt` storage device. Merlin firmware installation itself shall not require external storage.

### REQ-STOR-002 — No swap requirement (P0)

The MVP shall not require or automatically create swap.

### REQ-STOR-003 — Write minimization (P0)

The addon shall not persist a record on every UPS poll. High-frequency status shall remain in volatile storage; persistent writes shall be limited to configuration, migrations, event transitions, and bounded audit records.

### REQ-STOR-004 — Bounded logs (P0)

Persistent logs shall have explicit size/age limits and rotation. Logs shall not be written frequently to JFFS.

### REQ-STOR-005 — Storage failure handling (P0)

Missing, read-only, unexpectedly unmounted, or failed `/opt` storage shall produce a clear degraded state and shall not trigger destructive policy actions.

### REQ-STOR-006 — Reproducibility and backup (P0)

A user shall be able to export non-secret configuration and reproduce the installation on replacement media.

### REQ-STOR-007 — Media diagnostics (P1)

Diagnostics shall report filesystem, mount options, free space, read-only state, recent storage-related errors where available, and whether SMART passthrough is available. The addon shall not claim to determine remaining USB-flash endurance when the device exposes no reliable health data.

## 6. Networking

### REQ-NET-001 — LAN-only default (P0)

`upsd` shall bind only to explicitly selected trusted LAN addresses by default.

### REQ-NET-002 — WAN prohibition (P0)

The installer shall not create WAN exposure. It shall warn or refuse when a selected listener appears WAN-facing.

### REQ-NET-003 — Guest isolation (P0)

Guest and untrusted VLAN access shall be denied unless explicitly enabled.

### REQ-NET-004 — Firewall lifecycle (P0)

Firewall rules shall be reapplied through Merlin hooks and removed on disable/uninstall.

### REQ-NET-005 — Address changes (P0)

The addon shall detect or recover from LAN address changes without leaving stale broad listeners or firewall rules.

### REQ-NET-006 — Client onboarding (P0)

The UI and CLI shall display:

- server address
- port
- UPS name
- authentication requirements
- client-neutral setup notes
- optional WinNUT guidance

## 7. User interface and diagnostics

### REQ-UI-001 — Merlin integration (P0)

The addon shall use the Merlin Addons API and service-event mechanism rather than modifying firmware source.

### REQ-UI-002 — Status dashboard (P0)

The dashboard shall show available values for:

- UPS state
- battery charge
- estimated runtime
- load
- input voltage
- model
- driver
- service health
- listener address
- simulation/real source

### REQ-UI-003 — Safe actions (P0)

The UI shall provide validation, connection test, restart, refresh, and diagnostics actions.

### REQ-UI-004 — Destructive action isolation (P0)

The normal dashboard shall not provide one-click UPS output-off or forced host shutdown.

### REQ-UI-005 — Redaction (P0)

The UI and diagnostics exports shall redact credentials, tokens, private keys, sensitive headers, and command content as appropriate.

### REQ-UI-006 — Bounded settings store (P0)

Only compact settings shall use Merlin's shared addon settings storage. Complex policies, targets, and secrets shall use project-owned files.

### REQ-UI-007 — Accessible CLI parity (P0)

Core install, status, validate, repair, logs, enable, disable, and uninstall operations shall be available through CLI.

## 8. Event and policy model

### REQ-POL-001 — Normalized events (P0)

The policy engine shall normalize at least:

- `online`
- `on_battery`
- `low_battery`
- `runtime_below`
- `charge_below`
- `communication_lost`
- `communication_restored`
- `overload`
- `replace_battery`
- `forced_shutdown`

### REQ-POL-002 — Delayed reversible action (P0)

A policy shall be able to start a timer on an event and cancel it when a specified recovery event occurs.

### REQ-POL-003 — Threshold actions (P1)

Policies shall support runtime and battery-charge thresholds only when those values are available and valid.

### REQ-POL-004 — Ordered groups (P1)

Policies shall support ordered target groups and per-stage delays.

### REQ-POL-005 — Retry and timeout (P1)

Actions shall support bounded retries and timeouts.

### REQ-POL-006 — Error behavior (P1)

Policies shall define continue-on-error or stop-on-error behavior.

### REQ-POL-007 — Idempotency (P0)

A single event episode shall not execute the same non-repeatable action more than once unless retry policy allows it.

### REQ-POL-008 — Restart semantics (P0)

Policy state after router or service restart shall be deterministic and documented.

### REQ-POL-009 — Commit boundary (P1)

Policies shall explicitly distinguish cancelable pending actions from committed shutdown sequences.

### REQ-POL-010 — FSD semantics (P1)

FSD shall be labeled noncancelable/latched and shall not be used by default for a short-outage grace period.

### REQ-POL-011 — Dry run (P0)

Every policy and executor shall support dry-run or harmless test behavior.

## 9. Executors

### REQ-EXEC-001 — Executor interface (P0)

Executors shall expose validation, test, execution, verification, and capability description.

### REQ-EXEC-002 — Local script (P0)

The addon shall support administrator-created scripts from an allowlisted directory without allowing arbitrary shell text from the UI.

### REQ-EXEC-003 — NUT client onboarding (P0)

The addon shall support the standard pattern where clients poll NUT and shut themselves down.

### REQ-EXEC-004 — SSH (P1)

SSH shall support key authentication, host-key verification, restricted commands, timeout, retry, and target-specific templates.

### REQ-EXEC-005 — HTTP webhook (P1)

Webhooks shall support HTTPS verification, bounded timeouts, response policy, redacted headers, and optional signing.

### REQ-EXEC-006 — MQTT (P1)

MQTT shall publish normalized events and results with explicit retained-message behavior and optional TLS.

### REQ-EXEC-007 — NUT FSD (P1)

Advanced FSD orchestration shall require explicit enablement and shall not imply UPS output shutdown unless separately configured.

### REQ-EXEC-008 — WinRM (P2)

The architecture shall allow Windows-native remote shutdown through WinRM/PowerShell Remoting.

### REQ-EXEC-009 — Redfish (P2)

The architecture shall allow Redfish power-state queries, graceful shutdown, optional verified escalation, and optional restoration actions.

### REQ-EXEC-010 — SNMP/PDU (P2)

The architecture shall allow capability-scoped SNMP SET or managed PDU actions.

### REQ-EXEC-011 — Specialized platforms (Later)

VMware, Hyper-V, Nutanix, storage, and cluster integrations may be added through executors or external webhooks.

## 10. Security

### REQ-SEC-001 — Least privilege (P0)

Each service, credential, and executor shall receive only the permissions required.

### REQ-SEC-002 — Secret storage (P0)

Secrets shall be stored in project-owned files with restrictive permissions and excluded from settings exports.

### REQ-SEC-003 — Input safety (P0)

All user input shall be validated and safely encoded. No untrusted input shall be evaluated as shell code.

### REQ-SEC-004 — Host-key and TLS verification (P1)

SSH host keys and HTTPS certificates shall be verified by default.

### REQ-SEC-005 — Audit trail (P1)

The addon shall record redacted event, policy, target, executor, result, and timestamp data.

### REQ-SEC-006 — Update integrity (P1)

The release process shall publish hashes or signatures and support rollback.

### REQ-SEC-007 — CSRF/UI safety (P0)

State-changing UI operations shall use the established Merlin form/action mechanism and require authenticated router access.

### REQ-SEC-008 — Destructive dual opt-in (P2)

Force-off and UPS/PDU output actions shall require both global feature enablement and target/action enablement.

## 11. Development and repository

### REQ-DEV-001 — WSL filesystem workflow (P0)

Maintainer documentation shall place Linux-tooling working trees in the WSL/Linux filesystem rather than under `/mnt/c` by default.

### REQ-DEV-002 — Stable command surface (P0)

The repository shall expose stable `make` targets for bootstrap, lint, tests, NUT integration, security checks, packaging, and optional hardware deployment.

### REQ-DEV-003 — Hardware gates (P0)

No default command shall deploy to a router, shut down a host, issue an administrative UPS command, or require hardware. Destructive and production-target actions shall require explicit environment gates.

### REQ-DEV-004 — Public repository defaults (P0)

The project shall use the public `danielarvilpayne/nutmerlin` GitHub repository, GPL-3.0-or-later licensing, GitHub Actions, and feature-branch pull requests.

### REQ-DEV-005 — Hardware tests outside PR gates (P0)

Hardware workflows shall be manually triggered and shall not be required for ordinary pull requests.

## 12. Reliability and performance

### REQ-REL-001 — Router availability (P0)

Failure of NUTMerlin shall not intentionally interrupt routing, DNS, Wi-Fi, or WAN services.

### REQ-REL-002 — Resource bounds (P0)

Polling, logging, and retries shall be bounded for router CPU, memory, storage, and process count.

### REQ-REL-003 — Dependency failure (P0)

Missing `/opt`, failed USB attachment, stale UPS data, or crashed NUT processes shall produce diagnostics and safe degraded behavior.

### REQ-REL-004 — No action on ambiguity (P0)

When event state is contradictory or insufficient, destructive actions shall not be executed.

### REQ-REL-005 — Time correctness (P1)

Policies shall use monotonic time for delays where available so wall-clock corrections do not incorrectly fire or cancel actions.

## 13. Testability

### REQ-TEST-001 — No full firmware emulator dependency (P0)

Normal development and CI shall not depend on full Asuswrt-Merlin firmware emulation.

### REQ-TEST-002 — Router shims (P0)

Platform-specific commands and filesystem roots shall be abstractable for host tests.

### REQ-TEST-003 — NUT simulation (P0)

Integration tests shall use `dummy-ups` with static and dynamic scenarios.

### REQ-TEST-004 — Optional legacy router rig (P0)

When available, the RT-AC3100 or another spare router shall provide manually invoked Merlin lifecycle, UI, firewall, mount, reboot, upgrade, and uninstall coverage. Its absence shall not block ordinary development or pull requests.

### REQ-TEST-005 — Real UPS gate (P0)

Real UPS testing shall be a separate, manually gated stage and begin read-only.

### REQ-TEST-006 — Destructive test gates (P0)

Host shutdown, FSD, force-off, and output control tests shall require explicit opt-in.

## 14. MVP acceptance criteria

The MVP is acceptable when:

1. It installs on the RT-AX86U Pro without disrupting routing.
2. It can switch between `dummy-ups` and one real USB HID UPS.
3. A remote standard NUT client can query the selected source.
4. Default firewall/listener behavior is trusted-LAN only.
5. Services recover after reboot and late Entware mount.
6. UI and CLI report status and actionable diagnostics.
7. Install, upgrade, repair, and uninstall are idempotent.
8. No destructive UPS command is enabled.
9. CI tests run without router or UPS hardware.
10. The isolated router test matrix passes on at least one spare router, if compatible hardware is available.
