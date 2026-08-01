# NUTMerlin architecture

## 1. Architectural intent

NUTMerlin is an integration and policy layer. NUT owns UPS device communication and the network protocol. NUTMerlin owns installation, validated configuration, Merlin lifecycle integration, safe presentation, normalized policy, and optional executors.

```text
UPS or simulator
      |
      v
NUT driver (usbhid-ups / dummy-ups / future driver)
      |
      v
upsd data server  <---------- standard NUT clients
      |
      +--> NUTMerlin status collector
      |        |
      |        +--> Merlin UI / CLI
      |        |
      |        +--> event normalizer
      |                 |
      |                 v
      |             policy engine
      |                 |
      |                 +--> local script
      |                 +--> SSH
      |                 +--> webhook
      |                 +--> MQTT
      |                 +--> NUT FSD
      |                 +--> WinRM (backlog)
      |                 +--> Redfish (backlog)
      |                 +--> SNMP/PDU (backlog)
      |
      +--> audit and diagnostics
```

## 2. Development and hardware boundaries

```text
Codex IDE -> WSL2 repository -> host tests / Merlin shims / dummy-ups
                                      |
                                      +-> optional RT-AC3100 legacy profile
                                      +-> gated RT-AX86U Pro + real UPS profile
```

The platform-neutral policy, validation, configuration, and executor logic must run without router hardware. Hardware adapters are invoked only through named profiles. The RT-AC3100 is optional and tests the final Merlin 386/ARMv7 environment; it is not the reference architecture.

## 3. Deployment patterns

### 3.1 Network UPS server — default

```text
UPS --USB--> ASUS router/NUT server --TCP 3493--> host NUT clients
                                                   |
                                                   +--> local shutdown
```

The router exposes status. Each host decides its delay, threshold, and shutdown type. This is the default because it avoids storing host credentials on the router.

### 3.2 Coordinated NUT shutdown — advanced

```text
UPS --> NUT primary policy --> FSD --> NUT secondary clients
```

This is a committed workflow. FSD is not a reversible warning. The UI must state that it normally continues through host shutdown and possibly UPS output cycling.

### 3.3 Agentless central push

```text
UPS --> NUTMerlin policy
          +--> SSH
          +--> webhook
          +--> MQTT
          +--> WinRM
          +--> Redfish
          +--> SNMP/PDU
```

This is appropriate for targets without a NUT client or when centralized ordering is required.

### 3.4 Alerts only

Events are published without shutdown actions. This mode can coexist with any other pattern.

### 3.5 Load shedding

Policies act on groups in order. Example:

```text
On battery 3 minutes  -> stop desktop group
Runtime below 30 min  -> stop noncritical server group
Low battery           -> committed critical shutdown group
Network infrastructure -> excluded
```

## 4. Components

### 4.1 Installer/updater

Responsibilities:

- platform detection
- Entware dependency installation
- ownership detection
- hook installation
- UI mounting
- initial configuration
- migration
- rollback
- clean uninstall

It must not assume `/opt` is mounted during early boot.

### 4.2 Platform adapter

All Merlin-specific operations should be behind functions, including:

- NVRAM reads
- Addons API support detection
- service-event dispatch
- user-script hook management
- firewall integration
- web UI mount
- syslog
- Entware mount readiness

This allows host tests with shims.

### 4.3 Configuration model and generator

Use a validated internal representation rather than editing arbitrary NUT text in the UI.

Conceptual model:

```yaml
source:
  id: ups
  type: usbhid-ups
  driver_options:
    port: auto

server:
  listeners:
    - address: 192.168.1.1
      port: 3493
  trusted_networks:
    - 192.168.1.0/24

clients:
  read_only:
    enabled: true

policies: []
targets: []
```

Generation flow:

```text
load settings -> validate -> render temp files -> syntax/smoke check
-> backup current -> atomic rename -> restart -> health check
-> rollback on failure
```

### 4.4 NUT runtime manager

Responsibilities:

- driver start/stop/restart
- `upsd` start/stop/restart
- health checks
- stale data detection
- status queries
- package and version reporting
- simulation/real-source switching

### 4.5 Status collector and event normalizer

The collector reads NUT variables and produces a stable internal event model. It must preserve unknown values and source timestamps.

Example normalized snapshot:

```json
{
  "source_id": "ups",
  "observed_at": "2026-08-01T19:00:00-04:00",
  "status_tokens": ["OB", "DISCHRG"],
  "online": false,
  "on_battery": true,
  "low_battery": false,
  "battery_charge_percent": 96,
  "battery_runtime_seconds": 4200,
  "load_percent": 8,
  "stale": false
}
```

Do not infer reliability merely because a field exists.

### 4.6 Policy engine

The policy engine should be independent from Merlin shell hooks and NUT process startup.

Conceptual policy:

```yaml
id: stop-workstations
trigger:
  event: on_battery
delay_seconds: 180
cancel_when:
  event: online
commit: false
targets:
  - windows-desktop
actions:
  - executor: nut_client
```

Policy requirements:

- deterministic event episode ID
- monotonic timers
- idempotency
- bounded retries
- explicit cancellation
- explicit commit boundary
- persisted state only where necessary
- safe restart behavior

### 4.7 Executor registry

Executors are plugins selected by name and target type.

Conceptual contract:

```text
validate(target, action) -> validation result
test(target, action) -> harmless connectivity/capability result
execute(target, action, event) -> execution result
verify(target, action, execution result) -> verification result
describe_capabilities() -> metadata
```

Initial registry:

| Executor | Priority | Notes |
|---|---:|---|
| `nut_client` | P0 | Onboarding/documentation; client executes locally |
| `local_script` | P0 | Allowlisted scripts only |
| `ssh` | P1 | Primary agentless executor |
| `webhook` | P1 | External orchestrators/Home Assistant/Node-RED |
| `mqtt` | P1 | Event bus and automation |
| `nut_fsd` | P1 | Committed coordinated shutdown |
| `winrm` | P2 | Windows-native push |
| `redfish` | P2 | Out-of-band server control |
| `snmp_pdu` | P2 | Managed PDU/outlet control |

### 4.8 UI adapter

The UI reads safe status files/endpoints and submits validated settings through Merlin's established form and service-event mechanism.

The UI must not:

- read private keys
- render secrets
- execute raw commands
- expose force-off controls by default
- assume a field is supported on every UPS

### 4.9 Audit log

Record:

- normalized event
- policy transition
- target
- executor
- dry-run state
- attempt count
- result
- redacted diagnostics

Use bounded storage and avoid frequent JFFS writes.

## 5. State model

Recommended state machine:

```text
UNKNOWN
  |
  +--> ONLINE
  |      |
  |      +--> ON_BATTERY_PENDING
  |                |
  |                +-- online before timer --> ONLINE
  |                |
  |                +-- timer/threshold --> ON_BATTERY_ACTIVE
  |                                      |
  |                                      +-- online --> RECOVERY --> ONLINE
  |                                      |
  |                                      +-- low battery/commit policy
  |                                              --> COMMITTED_SHUTDOWN
  |
  +--> COMMUNICATION_LOST
          |
          +--> restored --> prior/derived state
          +--> fail-safe policy only when explicitly configured
```

### Reversible states

- `ON_BATTERY_PENDING`
- `ON_BATTERY_ACTIVE` before commit
- `RECOVERY`

Actions may be canceled when `online` returns.

### Committed state

- `COMMITTED_SHUTDOWN`

Once entered, the configured sequence proceeds. NUT FSD belongs here.

## 6. Filesystem layout

Proposed layout:

```text
/jffs/addons/nutmerlin/
  nutmerlin
  lib/
  web/
  migrations/
  defaults/
  config/
    addon.conf
    policies/
    targets/
  state/
    ownership.json
    last-known-good/
  VERSION

/jffs/scripts/
  services-start          # small managed dispatch block
  service-event           # small managed dispatch block
  firewall-start          # small managed dispatch block
  post-mount              # small managed dispatch block
  unmount                 # optional managed dispatch block

/opt/etc/nut/
  nut.conf
  ups.conf
  upsd.conf
  upsd.users
  upsmon.conf              # only if used
  upssched.conf            # only if used

/opt/etc/nutmerlin/
  secrets/
  generated/
  scripts/

/opt/var/log/nutmerlin/
  events.log
  audit.log

/tmp/nutmerlin/
  status.json
  runtime state
  locks
  sockets
```

Exact Entware paths must be discovered during Phase 0.

## 7. Data storage

### Merlin addon settings

Use only for compact values such as:

- enabled state
- UI version
- selected LAN address
- selected source ID
- display preferences

### Project-owned configuration

Use dedicated files for:

- policies
- target lists
- credentials
- key material
- complex templates
- migrations
- ownership records

### Runtime state

Use `/tmp` for frequently updated status and transient timers. Persist only state needed for deterministic recovery.

### Durability rules

- `/jffs` contains small addon code, metadata, and managed hook dispatchers.
- `/opt` contains Entware packages, generated NUT configuration, optional secrets, and bounded persistent logs.
- `/tmp` contains current status, locks, PID files, transient policy timers/state, and generated UI data.
- No component writes a status sample to persistent storage on every poll.
- Missing or read-only `/opt` is a degraded condition. The addon shall stop dependent services, expose diagnostics, and avoid destructive actions.
- The installation must be reproducible from the repository/release archive plus exported non-secret configuration.

## 8. Lifecycle

### Boot

1. `services-start` mounts UI and schedules readiness checks.
2. `post-mount` detects the Entware volume.
3. Validate configuration and dependencies.
4. Start configured NUT driver.
5. Start `upsd`.
6. Apply LAN firewall rules.
7. Start policy/event services if enabled.
8. Publish status.

### Apply settings

1. UI submits settings.
2. `service-event` invokes NUTMerlin dispatcher.
3. Validate and generate.
4. Activate atomically.
5. Restart only affected services.
6. Health check.
7. Roll back on failure.
8. Report result to UI and audit log.

### Uninstall

1. Disable policies and executors.
2. Stop project services.
3. Remove project firewall rules.
4. Unmount/remove UI integration.
5. Remove managed hook blocks.
6. Restore or leave user-owned NUT configuration according to ownership record.
7. Remove project files.
8. Offer removal of packages installed solely by NUTMerlin.

## 9. Failure behavior

| Failure | Expected behavior |
|---|---|
| Entware drive missing | Router continues normally; addon reports unavailable |
| UPS unplugged from USB | Mark communication lost; no destructive action unless explicitly configured |
| `upsd` fails | Attempt bounded restart; retain diagnostics; no push action from stale state |
| Invalid config | Refuse activation; retain last known good |
| Router reboots during outage | Reconstruct state conservatively; avoid duplicate non-repeatable actions |
| Target unreachable | Retry according to policy; record failure; follow continue/stop semantics |
| Power returns during pending timer | Cancel pending reversible action |
| Power returns after committed FSD | Continue committed sequence; document latched behavior |
| Telemetry missing | Ignore dependent threshold; do not interpret as zero |
| Audit storage full | Rotate/drop oldest bounded records; do not block core monitoring |

## 10. Compatibility strategy

- Detect capabilities at runtime.
- Maintain a compatibility report rather than hard-coding broad vendor claims.
- Prefer NUT driver compatibility data.
- Record router model, firmware branch, CPU architecture, Entware feed, NUT version, UPS model, USB IDs, and exposed variables/commands in test reports.
- Keep device-specific quirks as data/diagnostics, not scattered shell conditionals.

## 11. Non-goals for early releases

- Full Asuswrt firmware emulation.
- Firmware compilation or binary patching.
- Automatic WAN/cloud access.
- Universal Windows client installation.
- Arbitrary remote shell management.
- Automatic UPS output cycling.
- Native VMware/Nutanix/storage orchestration.


## 12. Hardware profiles

### `mock`

Host filesystem and Merlin-command shims with no router.

### `ac3100`

Optional Asuswrt-Merlin 386/ARMv7 integration profile. Expected AP-mode bench device, no WAN-port use, internet egress normally blocked after setup.

### `ax86u-pro`

Production-reference AArch64 router profile. Requires an explicit production-router gate for deployment or modification.

### `cp1500pfclcd`

Real UPS reference profile using `usbhid-ups`. Administrative commands discovered from the device remain disabled unless a later explicitly gated feature enables them.
