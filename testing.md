# NUTMerlin test strategy

## 1. Emulator conclusion

Do not make full Asuswrt-Merlin emulation a project requirement.

Generic QEMU/FirmAE-style firmware rehosting can run parts of router firmware, but Merlin builds depend on model-specific ARM/MIPS platforms, Broadcom hardware, NVRAM, init behavior, networking devices, USB, and some closed binaries. Reconstructing enough of that environment may be useful for firmware security research, but it is fragile and disproportionate for an addon whose main code should be portable shell, configuration generation, and NUT integration.

Use a layered replacement:

1. **Host test harness** for addon logic and mocked Merlin commands.
2. **NUT `dummy-ups`** for UPS state simulation.
3. **Optional AArch64 user-mode/QEMU container** for Entware binary smoke tests.
4. **Optional RT-AC3100** for full Merlin 386/ARMv7 lifecycle integration.
5. **Primary RT-AX86U Pro and real CP1500PFCLCD** only for controlled final integration.

This yields better coverage than a partially booted firmware image.

## 2. Available hardware

Known:

- Primary router: ASUS RT-AX86U Pro running Merlin.
- One real CyberPower CP1500PFCLCD UPS.
- Optional ASUS RT-AC3100 in storage, currently running stock Asuswrt.
- Windows PC target.
- ONT, ISP gateway, and ASUS router are intended to remain powered after the Windows PC shuts down.

### RT-AC3100 role and qualification

The RT-AC3100 is optional. No normal CI job, pull request, or early Codex task may require it.

When hardware integration is useful, qualify it by verifying:

- final correct RT-AC3100 Asuswrt-Merlin 386 image is available
- Addons API is present
- Entware ARMv7 feed is usable
- JFFS custom scripts/configs work
- USB storage mounts reliably
- AP mode provides stable LAN management
- SSH is LAN-only
- a recovery path is documented

Use it for legacy integration only. It must not be exposed as an internet-facing router. The production RT-AX86U Pro remains the final hardware reference target.

## 3. Test layers

## Layer 0 — Static checks

Runs on every commit.

Checks:

- ShellCheck
- shfmt
- JSON/YAML validation if used
- Markdown link/lint checks
- no secrets in repository
- no disallowed destructive commands in default paths
- executable mode checks
- generated hook block delimiters
- package manifest consistency

Suggested default command:

```sh
./test/run static
```

## Layer 1 — Host unit tests with Merlin shims

Run in a normal Linux container or VM.

Provide fake implementations for:

- `nvram`
- `service`
- `logger`
- `cru`
- `iptables`/`ip6tables` or the chosen firewall adapter
- mount/umount
- `opkg`
- Merlin helper functions
- `/jffs`, `/opt`, `/tmp`, and `/www/user` through a configurable root

Recommended environment:

```text
NUTMERLIN_TEST_ROOT=/tmp/nutmerlin-test-root
NUTMERLIN_PLATFORM=mock
PATH=test/shims:$PATH
```

Test:

- platform detection
- path handling
- hook insertion/removal
- idempotency
- settings validation
- config rendering
- atomic activation/rollback
- ownership tracking
- migration
- redaction
- policy state transitions
- executor validation
- command-injection resistance

The production code should call platform-adapter functions rather than scattered direct router commands.

## Layer 2 — NUT integration with `dummy-ups`

Run NUT in a Linux container/VM or directly on the spare router.

Use two modes:

### Static device + controlled variable writes

Start with a `.dev` file containing all variables that tests may modify. Change status through NUT test interfaces. This is the most deterministic approach.

### Sequence replay

Use `.seq` files with `TIMER` lines for demonstrations, long-running scenarios, and recording/replay of real behavior.

NUT supports generating a real-device dump with:

```sh
upsc ups@localhost > captured-device.dev
```

A recorder can capture changing values during an actual outage for later replay. Do this only after the real UPS connection is stable.

### Required simulated scenarios

| ID | Scenario | Expected result |
|---|---|---|
| SIM-001 | Stable `OL` | No outage action |
| SIM-002 | `OB` for less than delay, then `OL` | Timer canceled; no shutdown action |
| SIM-003 | `OB` beyond delay | Configured reversible action fires once |
| SIM-004 | `OB LB` | Critical policy fires according to explicit configuration |
| SIM-005 | Runtime crosses threshold | Only runtime policies fire |
| SIM-006 | Charge crosses threshold | Only charge policies fire |
| SIM-007 | Missing runtime/charge | Dependent policies do not fire |
| SIM-008 | `COMMBAD` then recovery | Diagnostic event; no default shutdown |
| SIM-009 | Rapid `OL`/`OB` flapping | Debounced; no duplicate action |
| SIM-010 | Service restart during pending timer | Documented safe reconstruction |
| SIM-011 | Service restart after action | No duplicate non-repeatable action |
| SIM-012 | Power returns after commit/FSD | Committed sequence continues |
| SIM-013 | Two policies target same host | Deterministic ordering/deduplication |
| SIM-014 | Executor timeout | Bounded retry and correct policy behavior |
| SIM-015 | One target fails, another succeeds | Continue/stop semantics honored |
| SIM-016 | Stale contradictory data | No destructive action |
| SIM-017 | Router clock changes | Delay uses monotonic behavior |
| SIM-018 | Simulation loops | No accumulating duplicate timers |

Starter fixtures are under `test/scenarios/`.

## Layer 3 — Optional Entware ABI smoke tests

Purpose: execute the same Entware packages or architecture binaries without a router where practical.

Possible approach:

- AArch64 and ARMv7 Linux container/rootfs profiles.
- QEMU user-mode (`qemu-aarch64-static` or `qemu-arm-static`) on an x86 development machine.
- Mount or install an Entware test root.
- Run `opkg`, NUT binary version checks, configuration parsing, `dummy-ups`, `upsd`, and `upsc`.

Limitations:

- not a Merlin boot
- not model-specific kernel behavior
- no real Broadcom switch/NVRAM
- USB permissions and hotplug differ
- Entware init scripts may need harness adaptation

Treat this as useful package/ABI coverage, not firmware emulation.

## Layer 4 — Optional RT-AC3100 integration rig

This is the closest practical legacy Merlin integration environment, but it is not required for ordinary development.

### Bench topology

```text
Windows/WSL2 development PC --Ethernet--> primary LAN
                                      |
                                      +--> RT-AC3100 in AP mode
                                             |
                                             +--> USB storage with Entware
```

Leave its WAN port unused. Initial firmware and Entware setup may temporarily use LAN egress through the primary router; block the device's internet access afterward.

### Use `dummy-ups` first

The spare router does not need the physical UPS for most tests. Install the Entware dummy driver and exercise:

- installer
- Addons API detection
- UI mount
- service-event actions
- boot/reboot
- post-mount timing
- firewall-start
- LAN binding
- package repair
- storage removal/reinsert
- settings persistence
- upgrade/migration
- uninstall
- recovery after broken generated config
- resource use

### Spare-router destructive test policy

- No UPS load commands exist because `dummy-ups` is used.
- Host executor targets are test VMs or marker scripts.
- Keep a recovery path:
  - configuration backup
  - direct Ethernet
  - reset procedure
  - ASUS rescue-mode instructions
- Never use the spare router as the sole route to needed documentation during recovery.

## Layer 5 — Gated RT-AX86U Pro with real CP1500PFCLCD

Run only after Layers 0–4 pass.

### Stage 5A: Read-only USB test

1. Disable CyberPower PowerPanel or any other process that may claim the UPS USB device.
2. Connect CP1500PFCLCD USB to the RT-AX86U Pro.
3. Start only `usbhid-ups` and `upsd`.
4. Verify identity and status through `upsc`.
5. Compare UPS LCD, NUT, and known model quirks.
6. Confirm router CPU/memory/log behavior.
7. Do not configure administrative NUT credentials.
8. Do not run `upscmd`.

Pass criteria:

- stable polling
- correct OL/OB transitions
- no routing disruption
- no log flood
- reconnect works after USB cable removal/reinsert

### Stage 5B: Short physical outage

1. Keep the UPS output connected to low-risk loads.
2. Unplug the UPS input from the wall; do not unplug the loads.
3. Confirm `OB`.
4. Restore wall power before the configured delay.
5. Confirm `OL`, timer cancellation, and zero host shutdown actions.

Repeat several times with reasonable spacing; do not abuse the battery.

### Stage 5C: Long outage with harmless executor

Use a policy whose action creates an audit marker or calls a test webhook rather than shutting down Windows.

Expected:

- action fires once after the delay
- network remains up
- returning power records recovery
- no output-control command is sent

### Stage 5D: Windows client in a disposable environment

Preferred targets:

- Windows VM with snapshot/checkpoint
- spare Windows machine
- test account/service on the actual PC with the final shutdown command replaced by a harmless marker, if the client supports it

Test:

- connection and authentication
- startup with Windows
- reconnect after network interruption
- short-outage cancellation
- long-outage action
- shutdown/hibernate choice
- behavior when the router reboots
- behavior when NUT data becomes stale

Because WinNUT is a third-party client whose implementation may evolve, preserve client-neutral acceptance tests using the NUT protocol.

### Stage 5E: Real Windows shutdown

Require:

```text
NUTMERLIN_ALLOW_HOST_SHUTDOWN=1
```

Procedure:

1. Save work and stop sensitive workloads.
2. Temporarily use a short but nonzero delay.
3. Trigger wall-power loss.
4. Observe Windows graceful shutdown.
5. Verify ONT/router/network remain powered.
6. Restore utility input.
7. Confirm the PC does not auto-start unless its actual AC input was cycled.
8. Restore production delay.

### Stage 5F: Hibernation comparison

Optional. Test hibernation separately from shutdown and document:

- resume reliability
- storage/driver behavior
- unattended service behavior
- update interactions
- actual residual power draw

Do not make hibernate the default unless repeat testing supports it.

## 4. Real UPS conservation

With only one UPS:

- Use simulation for nearly all state-machine testing.
- Capture one or two representative real outage sequences and replay them.
- Avoid deep discharge.
- Recharge fully between meaningful runtime tests.
- Do not use repeated output cycling as a routine test.
- Keep real-UPS tests short unless validating runtime behavior.
- Do not test low-battery behavior physically until other coverage is complete.
- Never test output-off commands while network infrastructure or important storage is attached.
- Record battery age and starting charge for runtime comparisons.

## 5. Client test doubles

Create test endpoints for each executor:

### Local script

Writes an event record to a temporary file.

### SSH

A container/VM account with a forced command that logs invocation and exits.

### Webhook

A local HTTP server that records headers/body and can return configurable status codes or delays.

### MQTT

A local broker with a test subscriber.

### FSD

A fully simulated NUT primary/secondary pair; never the production UPS during initial development.

### WinRM

Backlog test VM with a least-privilege endpoint.

### Redfish

Backlog mock Redfish service plus, later, real BMC hardware. Simulate:

- `On`
- graceful shutdown accepted
- delayed transition to `Off`
- graceful shutdown timeout
- optional `ForceOff` escalation disabled/enabled
- authentication failure
- certificate failure

## 6. Release matrix

Capture for every hardware test:

```text
Router model:
Merlin version/branch:
CPU architecture:
Entware feed:
NUT version:
Addon version:
USB storage filesystem:
UPS manufacturer/model:
USB vendor/product IDs:
NUT driver:
Exposed status variables:
Exposed administrative commands:
Client OS/client version:
Result:
Known quirks:
```

Minimum community beta matrix:

- RT-AX86U Pro plus the CP1500PFCLCD.
- One additional compatible ASUS router from local hardware or a reproducible community report; the RT-AC3100 is optional.
- One simulated non-CyberPower UPS profile.
- Linux NUT client.
- Windows NUT client.
- SSH test target.
- Webhook test target.

## 7. WSL2/Codex test environment

The repository lives in the WSL Linux filesystem and is opened by Codex IDE beta through WSL integration.

Required host checks:

- `make lint`
- `make test`
- `make test-nut`
- `make test-security`
- `make package`

Default WSL2 NAT networking is sufficient for outbound SSH and NUT queries to LAN devices. Mirrored networking is optional for tests that require a router or container to initiate connections into WSL.

Direct USB attachment through `usbipd-win` is optional and not part of the default test path.

## 8. Entware storage qualification

Before installing Entware on a test device:

1. Identify and record the media model and serial when available.
2. Run a complete F3 write/read verification on empty media.
3. Run `fsck.ext4 -f` after qualification.
4. Check `dmesg` for USB resets, disconnects, and I/O errors.
5. Query SMART when the media/USB bridge supports it.
6. Reject media with corruption, read-only remounts, unstable identity, or unexplained errors.

Passing these checks does not prove remaining flash endurance. A qualified USB stick is acceptable for the intermittently powered RT-AC3100 rig; use a USB-attached SSD for an always-on production installation.

Storage-failure scenarios:

| ID | Scenario | Expected result |
|---|---|---|
| STOR-001 | `/opt` absent at boot | Services wait/retry without corrupting JFFS |
| STOR-002 | `/opt` mounts late | Services start exactly once |
| STOR-003 | `/opt` becomes read-only | Degraded state; no destructive action |
| STOR-004 | Drive removed after safe stop | Clear offline diagnostics |
| STOR-005 | Unexpected disconnect | No retry/log storm; safe recovery after remount |
| STOR-006 | Log limit reached | Rotation/retention enforced |
| STOR-007 | Replacement drive/reinstall | Exported configuration restores supported settings |

## 9. CI structure

Suggested jobs:

```text
lint
unit-platform-mock
unit-policy
unit-config
integration-nut-dummy
integration-webhook
integration-ssh
security-input-validation
package-artifact
```

Hardware tests remain manually triggered and publish structured reports.

## 10. Firmware-emulation research backlog

Optional, non-blocking research:

- FirmAE/Firmadyne extraction of a Merlin image.
- QEMU boot of generic ARM environment.
- User-mode execution of selected ASUS binaries with an NVRAM shim.
- UI response emulation.

Do not delay MVP work for this. A partial firmware emulator would still not replace USB, hotplug, firewall, mount-order, and real Addons API testing on hardware.
