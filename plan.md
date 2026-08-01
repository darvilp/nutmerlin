# NUTMerlin implementation plan

## Goal

Deliver a safe, maintainable Asuswrt-Merlin addon that installs and configures Entware NUT, exposes UPS status to the LAN, supports standard NUT clients, and later adds pluggable orchestration methods.

## Hardware and development policy

- WSL2/container tests and NUT `dummy-ups` are the main path.
- The RT-AC3100 is an optional, manually invoked 386/ARMv7 integration profile.
- No normal pull request or Codex task may require the RT-AC3100.
- The RT-AX86U Pro and real CP1500PFCLCD are manually gated final hardware targets.
- Hardware availability must not block implementation of platform-neutral logic.

## Guiding order

The implementation order follows the agreed priority:

1. NUT server/client interoperability.
2. Local command/script extension point.
3. SSH, HTTP webhook, MQTT, and advanced NUT FSD support.
4. WinRM, Redfish, SNMP/PDU control, and specialized platform integrations.
5. Enterprise/vendor-specific orchestration only after the core is stable.

## Phase 0 — Research and scaffold

### Deliverables

- Create the public `danielarvilpayne/nutmerlin` repository from WSL2 when the local starter packet is ready.
- Apply the GPL-3.0-or-later license and GitHub Actions defaults.
- Establish the WSL2/Codex development scaffold and stable `make` entry points.
- Confirm current Merlin and Entware targets for AArch64 and legacy ARMv7.
- Record the confirmed CyberPower CP1500PFCLCD profile and NUT compatibility reference.
- Define the RT-AC3100 as an optional legacy integration profile, not a dependency.
- Implement CI linting and host-side test harness skeleton.
- Implement router command shims for:
  - `nvram`
  - `service`
  - `logger`
  - `cru`
  - mount operations
  - firewall operations
  - Entware package operations

### Exit criteria

- Host CI runs without router hardware.
- A test can generate NUT configuration into a temporary root.
- The test harness cannot alter the developer's real `/jffs` or `/opt`.
- `make test` and `make test-nut` complete without router hardware.
- Hardware profiles are opt-in and cannot select the RT-AX86U Pro without an explicit override.
- Repository, license, WSL2, and CI conventions are documented.

## Milestone 1 — Core NUT server MVP (P0)

### Scope

- Detect Merlin Addons API support.
- Detect Entware availability and architecture.
- Install required NUT packages.
- Discover or configure one USB UPS.
- Generate minimal NUT server configuration.
- Start, stop, restart, and query the NUT driver and `upsd`.
- Bind `upsd` to a selected trusted LAN interface.
- Create a read-only client credential or documented unauthenticated read mode, according to verified NUT behavior.
- Show copyable client connection information.
- Support `dummy-ups` as a first-class simulation source.
- Provide CLI status and diagnostics.
- Provide clean uninstall without removing unrelated Entware or manual configuration.

### Out of scope

- Host shutdown orchestration.
- FSD.
- UPS output control.
- SSH, MQTT, webhooks, WinRM, or Redfish.
- Multi-UPS.

### Exit criteria

- A Linux NUT client and a Windows NUT client can read simulated state from the test NUT server.
- At least one manually gated Merlin router test confirms real Addons API and Entware behavior before a public MVP release.
- A reboot and Entware remount restore the service.
- WAN and guest networks cannot connect under default settings.
- Installation, reinstall, upgrade, and uninstall are repeatable.
- No real UPS administrative command is required.

## Milestone 2 — Merlin UI and operational hardening (P0)

### Scope

- Add a Merlin web page.
- Display:
  - online/on-battery/low-battery state
  - battery charge
  - estimated runtime
  - UPS load
  - input voltage
  - device/driver identity
  - driver and server health
  - configured listeners
  - recent redacted diagnostics
- Provide actions:
  - refresh
  - validate configuration
  - test NUT connection
  - restart services
  - switch between real and simulated source with explicit confirmation
- Add last-known-good rollback.
- Add log rotation or bounded logging.
- Add package/version diagnostics.
- Add safe settings import/export with secrets excluded.

### Exit criteria

- UI actions route through Merlin's service-event mechanism.
- Invalid settings cannot produce active malformed config.
- All output is encoded and input is validated.
- The UI never exposes arbitrary shell execution or destructive UPS commands.
- Upgrade across at least two addon versions preserves supported settings.

## Milestone 3 — Policy engine and local executor (P0)

### Scope

Implement a client-neutral event and policy layer.

Events:

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

Policy capabilities:

- delay
- cancellation condition
- threshold
- target group
- ordered action stages
- retry
- timeout
- continue-on-error
- dry-run
- committed/noncancelable boundary

Executors:

- `nut_client` documentation/onboarding target
- `local_script` allowlisted executor

### Exit criteria

- Short outage is canceled when `online` returns.
- Long outage fires once after the configured delay.
- Repeated or flapping NUT states do not duplicate actions.
- Policy state survives or safely resets after process restart according to documented semantics.
- Local scripts are allowlisted, argument-safe, time-limited, and dry-run capable.
- All tests pass with `dummy-ups`.

## Milestone 4 — Common orchestration executors (P1)

### 4A: SSH

- Key-based authentication.
- Host-key pinning.
- Restricted-command setup guidance.
- Linux/BSD/NAS command templates.
- Optional Windows OpenSSH template, clearly secondary to a local NUT client.
- Test, execute, timeout, retry, and verification stages.

### 4B: HTTP webhook

- HTTP(S) POST.
- Header and bearer-secret support.
- Optional HMAC signing.
- Response-code policy.
- TLS verification enabled by default.

### 4C: MQTT

- Publish normalized events and policy results.
- Optional command/result topics.
- TLS and credentials.
- Retained-message behavior explicitly controlled.

### 4D: NUT FSD advanced mode

- Clearly labeled committed shutdown mode.
- Separate from reversible outage timers.
- Require explicit primary/secondary configuration.
- Default to no UPS kill-power.
- Explain that FSD remains latched until `upsd` restart and is normally part of a complete shutdown sequence.

### Exit criteria

- Each executor has validation, connection test, dry-run, execution, and redacted audit results.
- A failure in one target follows policy continue/stop semantics.
- FSD cannot be enabled accidentally through the default client onboarding path.
- Credentials never appear in UI source, logs, process listings where avoidable, or settings exports.

## Milestone 5 — Alerts and load shedding (P1)

### Scope

- Event notifications through webhook and MQTT.
- Optional email integration only if a lightweight, secure delivery path is identified.
- Ordered target groups:
  - noncritical
  - important
  - critical
- Runtime/charge-based staged actions.
- Optional supported UPS outlet-group actions behind capability checks and strong safety gates.
- Event history and action audit view.

### Exit criteria

- Unsupported or unreliable UPS variables are handled as unknown, not zero.
- Load-shedding actions are simulated before activation.
- Outlet controls require an explicit allowlist and per-device capability discovery.
- Network infrastructure can be excluded from all shutdown stages.

## Milestone 6 — P2 executors

### Scope

- WinRM/PowerShell Remoting.
- Redfish:
  - graceful shutdown
  - power-state query
  - optional escalation to force-off only after explicit policy and timeout
  - optional power-on after restoration
- SNMP SET and managed PDU actions.
- Optional UPS administrative commands where safely supported.

### Exit criteria

- Each executor has a documented threat model and least-privilege setup.
- Redfish graceful shutdown is distinct from `ForceOff`.
- Out-of-band force actions are never the default.
- All destructive actions require explicit global and target-level enablement.

## Milestone 7 — Community release hardening

### Scope

- Test matrix across representative Merlin generations and architectures, with community reports allowed to supplement unavailable local hardware.
- Hardware compatibility reporting workflow.
- Installer/update rollback.
- Release checksums or signatures.
- Migration handling.
- User documentation and troubleshooting.
- SNBForums beta.
- AMTM inclusion request only after adoption, maintenance commitment, and compatibility evidence.

### Exit criteria

- At least two router models and two UPS families have completed the release matrix.
- No known critical security issue.
- Uninstall restores all modified hooks and firewall state.
- Recovery procedure is documented and tested.
- A maintainer can reproduce release artifacts.

## Definition of done

A feature is done only when:

- requirements and acceptance criteria are updated
- threat model is considered
- unit and integration tests exist
- real-router behavior is tested when applicable
- failure and rollback behavior are documented
- user-facing diagnostics are present
- no secrets are leaked
- unsafe commands are opt-in
