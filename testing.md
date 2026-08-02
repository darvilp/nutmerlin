# NUTMerlin test and qualification strategy

## 1. Evidence model

NUTMerlin does not treat one successful run as proof of every layer. Reports must identify which claim they establish:

1. **Host conformance** — parsers, validation, policy, transactions, rendering, security, and platform-shim behavior on ordinary Linux.
2. **Entware package/ABI execution** — the exact current package cohort and architecture binaries used by the release.
3. **Simulated Merlin integration** — Addons API, hooks, firewall, mount, UI/service-event, and lifecycle behavior through a controlled platform profile.
4. **Exact-router qualification** — one model/revision/firmware/storage combination completing the full non-destructive hardware matrix.
5. **UPS capability qualification** — one exact UPS/driver/profile/NUT combination proving the harmless base source contract and each separately claimed telemetry capability.

Evidence from one layer never substitutes for another. A full Asuswrt-Merlin emulator is not required; it remains optional research because incomplete rehosting does not prove model-specific hardware, NVRAM, USB, firewall, mount ordering, Addons API, or closed firmware behavior.

## 2. Common safety rules

- All normal tests run without an ASUS router or physical UPS.
- dummy-ups is the default state source.
- Test executors default to dry-run and harmless markers.
- Real-router tests use dummy-ups unless a test explicitly requires the physical source.
- Real-UPS work begins read-only.
- No automated test issues load.off, shutdown.*, outlet off/cycle/delay, Redfish ForceOff/reset/on, or any equivalent output/power operation.
- No P0–P2 test assumes those operations exist behind a gate; absence is the expected result.
- A test capable of actual host shutdown requires NUTMERLIN_ALLOW_HOST_SHUTDOWN=1 plus documented physical confirmation and recovery.
- Deployment or mutation of the RT-AX86U Pro requires NUTMERLIN_ALLOW_PRODUCTION_ROUTER=1.
- NUTMERLIN_ALLOW_UPS_COMMANDS does not authorize output control.
- Failed or ambiguous policy, source, binding, storage, network, or action evidence fails closed.
- Hardware reports are redacted and contain no reusable production credential.

## 3. Layer 0 — documentation and static conformance

Run for every change.

Required checks:

- POSIX /bin/sh parse and portability;
- ShellCheck;
- shfmt diff;
- JSON/YAML/schema validation where used;
- Markdown links and ADR references;
- executable modes and package manifest;
- generated hook ownership delimiters;
- no committed secret or local endpoint;
- no forbidden destructive operation in P0–P2 registries/default paths;
- no arbitrary driver, NUT configuration, shell, webhook method/header/body, or management-listener surface;
- source files do not permanently patch firmware or replace non-owned files;
- architecture/requirements/security/tests remain consistent with accepted ADRs.

Static scans are guardrails, not proof that a dangerous command is unreachable. Unit and integration tests must establish the semantic absence.

## 4. Layer 1 — host conformance with Merlin shims

Run on normal Linux with isolated roots for /jffs, /opt, /tmp, and web assets. Shim every platform capability rather than scattering direct router calls.

The harness supplies controlled behavior for:

- NVRAM;
- firmware and Addons API capabilities;
- service-event and web mounting;
- user-script hook insertion/removal;
- firewall and listener inspection;
- mount/storage identity and read-only transitions;
- opkg/package metadata;
- service/process lifecycle;
- user/group/privilege operations;
- boot identity and time synchronization;
- syslog and resource limits.

### 4.1 Validation and injection

Exercise valid, invalid, edge, and adversarial:

- identifiers, target labels, hostnames, addresses, CIDRs, ports, usernames;
- source/driver options and USB identity;
- paths, symlinks, hard links, traversal, object-type swaps, modes, owner/group;
- durations, thresholds, action budgets, policy sizes, retry classes;
- webhook URLs/resolution/peer, headers, HMAC framing, JSON sizes;
- MQTT client/topic/profile values;
- SSH fingerprints and key algorithms;
- Redfish service/system identity;
- CLI JSON and web form fields;
- imported script metadata and structured I/O.

No input may become shell code, a service-event name, executable path, environment assignment, redirect, pipeline, arbitrary NUT text, or arbitrary network payload.

### 4.2 Ownership and lifecycle transactions

Test:

- clean new installation;
- repeat install and repair;
- foreign NUT files/processes;
- ambiguous/missing/corrupt ownership manifest;
- complete conservative ownership recovery;
- partial or conflicting recovery evidence;
- current/previous release slots;
- interruption before and after every update-journal phase;
- insufficient transaction space and 16 MiB headroom;
- safe update window refusal during active, pending, committed, unknown, storage-latched, or unreconciled state;
- disabled maintenance activation remaining disabled;
- 120-second/24-observation candidate gate;
- one automatic rollback;
- rollback failure closing surfaces;
- exact unchanged automatic authority restoration;
- manual rollback remaining inactive;
- unsafe-previous-release diagnostic-only rollback;
- disable/enable;
- clean uninstall precondition refusal;
- full removal of owned state with all Entware packages retained;
- broken-/opt emergency detach preserving evidence.

Every fault-injection point must have deterministic restart behavior.

### 4.3 Configuration generations

Golden and negative tests cover:

- complete generation rendering;
- exact manifest/hashes;
- owner/group/modes;
- closed driver-profile options;
- NUT syntax and harmless isolated smoke probes;
- atomic selector;
- one resolved NUT_CONFPATH per service epoch;
- rejection of missing, edited, unsealed, symlinked, ownership-drifted, mixed-schema, or future-schema generation;
- exposure closed during transition;
- active and last-known-good retention only;
- 120-second/24-observation health gate;
- one selector rollback;
- release/configuration compatibility pairing.

No managed test process may read ambient /opt/etc/nut.

### 4.4 Policy model

Unit tests cover:

- immutable policy versions and exact target/action expansion;
- authoring group/template changes not mutating active versions;
- logical targets with independently versioned bindings;
- maximum-effect safety classes;
- retry classes and narrowing-only policy budgets;
- activation evidence creation, 24-hour expiry, and invalidation on drift;
- reversible versus committed state;
- same-boot monotonic resume and router-reboot reset;
- no calendar/timezone/cron semantics;
- once-per-episode threshold actions;
- exact acyclic prerequisites;
- independent-action continuation;
- unmet/ambiguous dependency refusal;
- identical-intent coalescing;
- different-intent conflict rejection;
- coordinator exclusion and network-infrastructure protection;
- prospective inhibit before and after dispatch/commit;
- policy-version pruning protection and 8 MiB exhaustion.

### 4.5 Action evidence and budgets

Boundary tests cover:

- not_dispatched;
- dispatch_rejected;
- dispatch_accepted;
- effect_verified;
- outcome_unknown;
- fsynced intent immediately before nonrepeatable dispatch;
- conclusive pre-dispatch connection failure;
- lost response after bytes may have been accepted;
- no post-dispatch nonrepeatable retry;
- idempotent/keyed attempts at one, two, and three with 2-/5-second delays;
- 1/5/30-second connection range/default/ceiling;
- 1/30/300-second dispatch range/default/ceiling;
- 0/300/1800-second verification range/default/ceiling;
- 3600-second total action ceiling;
- one in-flight action per target;
- two concurrent dispatches;
- 30 starts in rolling 60 seconds;
- verifier polling never issuing a state-changing command;
- reboot/update/rollback/revocation/inhibit/uninstall preserving unknown outcome.

## 5. Layer 2 — NUT integration with isolated dummy-ups

Run driver, upsd, and upsc in a container/VM or controlled Entware profile using sealed generated configurations.

Use:

- static .dev fixtures with controlled supported variable writes;
- .seq replay for demonstrations and timed traces;
- only the distinct loopback simulation identity;
- no external clients, policies, or executors attached to the production source name.

Starter fixtures live under test/scenarios/. A real-device dump may inform a synthetic fixture after redaction, but a fixture is not physical hardware evidence.

### 5.1 Observation scenarios

| ID | Scenario | Expected result |
| --- | --- | --- |
| OBS-001 | Stable OL | Confirm online after two fresh samples; no outage episode. |
| OBS-002 | Stable OB | Confirm on battery after two fresh samples and open one episode. |
| OBS-003 | First OL after confirmed OB | Immediately inhibit new dispatch; confirm recovery after second consistent OL. |
| OBS-004 | OL and OB together | Unknown; never action-eligible. |
| OBS-005 | WAIT, malformed, or no line token | Unknown; never action-eligible. |
| OBS-006 | NUT reports stale | Immediately stale. |
| OBS-007 | No fresh sample for 15 seconds at 5-second interval | Stale at the default deadline. |
| OBS-008 | Qualified intervals 2 and 30 seconds | Deadline is max(15 seconds, three intervals). |
| OBS-009 | Requested interval outside 2–30 seconds | Refused without a new profile decision. |
| OBS-010 | Rapid OL/OB flap | Immediate inhibition plus two-sample confirmation; no duplicate work. |
| OBS-011 | Unqualified runtime/charge present | Display observed, never authorize threshold. |
| OBS-012 | Known-unreliable numeric field | Display-only with confidence marker. |

### 5.2 Reversible, threshold, and telemetry-loss scenarios

| ID | Scenario | Expected result |
| --- | --- | --- |
| POL-001 | OB shorter than configured delay, then OL | Reversible timer cancels; no action. |
| POL-002 | OB beyond delay with fresh evidence | Exact configured reversible action fires once. |
| POL-003 | Service restart during uncommitted timer, same boot | Resume only from consistent monotonic durable state. |
| POL-004 | Router reboot during uncommitted timer | Restart timer from zero after fresh OB confirmation. |
| POL-005 | Recovery after durable commitment | Committed workflow continues; no reversal. |
| POL-006 | Charge trip twice during confirmed OB | Fire once; clear only at trip plus at least 2 points. |
| POL-007 | Runtime trip twice during confirmed OB | Fire once; clear only at trip plus max(60 seconds, 10 percent). |
| POL-008 | Low values while OL, stale, charging, or contradictory | No threshold trip. |
| POL-009 | Telemetry lost with no fail-safe | Inhibit new state-changing dispatch. |
| POL-010 | Explicit fail-safe before minimum loss | No dispatch. |
| POL-011 | Explicit fail-safe after last OB and required loss | Only qualified notification/service_graceful/host_graceful action eligible. |
| POL-012 | Fresh sample returns during fail-safe evaluation | Immediately inhibit until state is confirmed. |
| POL-013 | Fail-safe attempts FSD/coordinator/abrupt/output | Schema/activation refusal. |
| POL-014 | Inhibit before dispatch | Cancel only undispatched reversible work. |
| POL-015 | Inhibit after acceptance or commit | Preserve accepted/unknown/committed state; do not claim cancellation. |

### 5.3 Service recovery scenarios

| ID | Scenario | Expected result |
| --- | --- | --- |
| NUT-001 | One transient driver failure | Restart after five seconds. |
| NUT-002 | Repeated failures | Attempts delayed 5, 15, 60 seconds; maximum three starts in five minutes. |
| NUT-003 | Breaker opens | Pause 15 minutes, then one probe. |
| NUT-004 | Probe remains healthy | Reset only after five continuous healthy minutes. |
| NUT-005 | Real source unavailable | Never start or substitute dummy-ups under production identity. |
| NUT-006 | USB identity matches two devices | Refuse binding. |
| NUT-007 | Device node/bus port changes but stable identity remains unique | Rebind only under the accepted profile identity rules. |

### 5.4 Harmless FSD simulation

P1 may run a fully isolated dummy primary/secondary pair to test:

- role generation and authentication;
- FSD latch semantics;
- committed-state display;
- process/restart behavior;
- failure diagnostics.

It shall have no physical UPS, external client credential, router shutdown command, output command, or production policy authority. Simulation cannot qualify production FSD.

## 6. Layer 3 — current Entware package and ABI evidence

Every release must execute the exact supported current AArch64 feed cohort rather than merely parse package metadata.

Evidence includes:

- feed architecture and package provenance;
- gpgv2 version and release-manifest verification;
- NUT binary versions/options;
- usbhid-ups and dummy-ups profile-required options;
- upsdrvctl, driver, upsd, and upsc with NUT_CONFPATH;
- configuration validation and isolated dummy-ups smoke;
- current Entware OpenSSH when P1 SSH is advertised;
- current MQTT/webhook dependency cohort when advertised;
- filesystem/process/privilege assumptions that package execution exposes.

A coherent older cohort may pass compatibility probes but is labeled compatibility-only and cannot qualify current hardware.

ARMv7 user-mode or exact-feed execution is optional legacy evidence. Full firmware emulation is not a release gate.

## 7. Layer 4 — simulated Merlin platform profiles

The simulator combines host roots and platform shims into named 3004.388.x and 3006.102.x capability profiles.

Required scenarios:

- supported and unsupported firmware-family detection;
- newly published but not-yet-qualified stable represented as unqualified;
- explicit support versus install-disposition results for compatibility-only,
  legacy best-effort, and probe-safe experimental platforms;
- refusal on missing, unknown, or incompatible core evidence while Addons API,
  clock, and resource-limit failures disable only their scoped capabilities;
- Addons API absent or partial;
- exact hook insertion/removal and unrelated content preservation;
- web-page mounting and failure;
- service-event fixed operation dispatch;
- one-time nonce creation, expiry at five minutes, first-attempt consumption, replay/change refusal;
- IPv4 listener and firewall agreement;
- IPv6 default-off and opt-in drift;
- firewall restart/hook and 300-second periodic revalidation;
- boot identity and positive NTP synchronization evidence;
- greater-than-300-second wall-clock jump revoking trust;
- late /opt schedule;
- runtime storage loss and identity change;
- account/privilege availability;
- local-script capability absent when any containment probe fails;
- resource ceilings lower than generic defaults where a profile requires it.

Simulator results are platform-integration evidence, not exact-router qualification.

## 8. Layer 5 — exact-router qualification

One complete report is sufficient for an exact router model/hardware revision/firmware/storage combination. It may come from a maintainer or community member; the evidence contract is identical.

The report records:

- router model and hardware revision;
- exact Merlin firmware and family;
- CPU architecture;
- Entware feed and exact relevant packages;
- addon/release/renderer/schema versions;
- storage device identity, filesystem, and mount options;
- structured test runner and redacted diagnostics;
- all skipped/waived checks, which make the report non-qualifying.

The mandatory non-destructive matrix includes:

- install;
- repeat install/repair;
- foreign/ambiguous deployment refusal;
- isolated simulation;
- managed NUT service/query;
- complete CLI and management-listener absence;
- network listener/firewall isolation and drift recovery;
- reboot;
- late /opt;
- unexpected missing/read-only/replaced /opt;
- update, health window, rollback, and rollback failure;
- disable/enable;
- unrelated hook/firewall/file preservation;
- clean uninstall and blocked-uninstall cases;
- emergency detach;
- storage/journal/JFFS anchor reconciliation;
- process privilege and resource bounds.

Router qualification uses dummy-ups and needs no physical UPS.

Optional WebUI qualification adds core-only install, explicit UI add/remove/re-add, exact core/UI version and schema matching, installed-set preservation across update and rollback, explicit UI removal when a candidate lacks a valid matching artifact, mount-slot exhaustion, authenticated service-event dispatch, nonce behavior, and proof that every UI failure leaves core services, state, and CLI operation unchanged. A failed or skipped UI matrix removes only the WebUI claim.

Qualification carry-forward is risk-triggered. A firmware, hardware revision, Entware feed/architecture, NUT major/minor, relevant lifecycle/network/configuration/platform change, security advisory, or reproduced fault requires current evidence. A reproducible negative report revokes the affected qualification; no 12-month timer applies.

### 8.1 RT-AX86U Pro

This is the production-reference target and requires NUTMERLIN_ALLOW_PRODUCTION_ROUTER=1 for deployment or modification. Use dummy-ups for the router lifecycle matrix unless a separately approved physical-UPS test requires otherwise.

### 8.2 RT-AC3100

This is optional legacy Merlin 386/ARMv7 evidence. Its absence, setup cost, or immaterial results do not block work or release. A successful run is legacy compatibility evidence, not current support or security support.

## 9. Layer 6 — physical UPS qualification

UPS claims are independent of router qualification.

### 9.1 Harmless base source report

The first public release requires at least one exact physical report with:

- UPS manufacturer/model and revision/firmware where known;
- USB VID/PID/serial or accepted no-serial identity evidence;
- exact NUT, driver, driver-profile, router, and addon versions;
- stable OL observation;
- short OB and recovery;
- stale report or USB disconnect/reconnect;
- unique stable source identity;
- no routing disruption, process/log storm, or wrong-device binding.

The report shall not deep-discharge the battery or issue any writable/output command.

### 9.2 Independent capability reports

Qualify separately:

- LB behavior;
- battery.charge;
- battery.runtime;
- input/output voltage;
- load;
- overload;
- replace-battery;
- any other displayed or policy-relevant field.

For numeric authority, capture behavior during known OL/OB/recovery, range/sentinel behavior, updates, and known limitations. A field may be observed, qualified, known_unreliable, or absent.

Driver recognition or an NUT device-list entry does not qualify every field.

### 9.3 Real UPS conservation

- Prefer captured/synthetic replay for state-machine work.
- Keep physical outages short.
- Avoid deep discharge and repeated battery cycling.
- Recharge between meaningful runtime observations.
- Begin read-only and create no administrative credential.
- Never run upscmd/upsrw or output-control commands.
- Keep control-path network/storage loads protected.
- Record battery age and starting charge only when relevant to a qualified numeric report.

## 10. Executor and transport test doubles

### 10.1 Local script

Use imported immutable marker scripts and test:

- 256 KiB artifact boundary and NUL rejection;
- 32 KiB input, 16 KiB stdout, and 8 KiB stderr boundaries;
- malformed/multiple/extra result refusal;
- no argv/secret/environment inheritance;
- private working directory and read-only artifact;
- unprivileged UID;
- file/process/CPU limits;
- no LAN/WAN/loopback egress;
- TERM, two-second grace, and process-group kill;
- executor absence, not root fallback, when any containment probe fails.

### 10.2 SSH

Use a disposable container/VM with a forced-command wrapper. Test:

- unique binding key;
- Ed25519 and qualified RSA-SHA2 ≥3072;
- independent exact SHA-256 host fingerprint;
- changed host key and TOFU refusal;
- no shell, PTY, agent/port forwarding;
- conclusive pre-dispatch refusal versus ambiguous post-dispatch loss;
- operation-specific verifier and no disconnect-as-Off.

### 10.3 Webhook

A controlled server/DNS/peer harness tests:

- lan_anonymous limited to credential-free trusted-LAN notification;
- verified HTTPS bearer and HMAC;
- exact HMAC v1 byte framing and 300-second receiver guidance;
- trusted-clock requirement;
- fixed POST/content type/envelope;
- no arbitrary method/header/query/body;
- every DNS result and actual peer;
- unsafe ranges/router endpoints;
- DNS rebinding and scope drift;
- redirect refusal;
- 2xx delivery acceptance only;
- bounded/redacted response diagnostics;
- no retry after body dispatch or unknown acceptance.

### 10.4 MQTT

A local broker and packet/session inspection test:

- MQTT v5 default with Clean Start 1/Session Expiry 0;
- explicit v3.1.1 Clean Session 1;
- QoS 1;
- no subscription, command topic, persistent session, or offline outbox;
- retained current state/availability only;
- non-retained event/result;
- stable scoped identity/topic;
- TLS 1.2+ and server identity for credentials/non-LAN;
- no automatic downgrade;
- reconnect publishes current state only, not stale events.

### 10.5 WinRM

WinRM tests do not begin until a reproducible Entware client cohort exists. Then use a disposable Windows VM to prove:

- HTTPS identity;
- dedicated non-admin credential;
- constrained JEA-equivalent endpoint;
- only the typed graceful shutdown operation;
- one dispatch/no post-dispatch retry;
- independent Off evidence;
- refusal of Basic/plaintext, CredSSP shortcut, broad TrustedHosts, unrestricted endpoint, hibernate, and runtime-installed dependency.

A test stack that cannot meet every condition leaves the adapter unavailable rather than weakening the contract.

### 10.6 Redfish

A mock service and later qualified BMC test:

- manual endpoint and exact ComputerSystem selection;
- service/system identity drift;
- TLS 1.2+ validation and explicit private CA/pin;
- session lifecycle;
- target role evidence allowing read/GracefulShutdown while denying broader power/admin authority;
- no dangerous denial probe;
- already-Off result;
- one ResetType GracefulShutdown;
- asynchronous task acceptance versus effect;
- 300-second verification with five-second polls;
- two consecutive fresh Off observations;
- timeout/task failure/lost response as failed or unknown;
- no ForceOff, reset, power-on, or escalation request.

### 10.7 Notification-only and FSD boundaries

Tests prove:

- webhook/MQTT notifications do not become central action evidence;
- no built-in SMTP/SMS/cloud/mobile adapter exists through P2;
- no inbound MQTT exists;
- production FSD operation is absent;
- simulated FSD cannot bind a real source, external client, router command, or output action.

## 11. Storage, journal, and retention qualification

### 11.1 Exact storage semantics

Using disposable data, test the exact router/device/filesystem/mount profile for:

- persistent UID/GID and modes 0700, 0600, 0640;
- case-sensitive stable names;
- regular/symlink/hard-link distinction;
- same-directory atomic rename;
- file and containing-directory fsync;
- exclusive locking;
- executable Entware binaries;
- stable device/mount identity across reboot/reconnect;
- controlled interruption/remount without mixed or silently lost journal/config generation.

Ext4 is the reference. FAT/VFAT/exFAT and permission emulation are expected refusal. Other filesystems require the same exact matrix.

Host tests drive `storage.preflight.v1` with disposable exact-profile evidence and explicit transaction/temporary byte inputs; the result is explicitly simulation-only and cannot authorize installation. An isolated native-adapter fixture proves the CLI retains the selected Entware root, records exact mount options, and changes its composite identity when the device serial changes beneath a constant filesystem UUID. Injection, missing-size, invalid-size, and pre-probe refusal cases must prove zero external mutation. Readiness tests cover concurrent claims and symlinked, weakly permissioned, or malformed transient state without starting a service.

### 11.2 Late mount and runtime faults

| ID | Scenario | Expected result |
| --- | --- | --- |
| STOR-001 | /opt absent at boot | Probe 5/15/30/60/120 seconds, then every 300; no duplicate service starts. |
| STOR-002 | /opt appears with expected identity | Reconcile and start exactly once. |
| STOR-003 | /opt becomes read-only | Latch new state-changing authority. |
| STOR-004 | Unexpected disconnect | Conservative anchor remains; no retry/log storm. |
| STOR-005 | Different replacement storage appears | Refuse empty-journal reset and require ownership recovery/reconciliation. |
| STOR-006 | Detailed journal append/fsync fails | Block commitment/dispatch/activation; safe monitoring where possible. |
| STOR-007 | One JFFS anchor slot tears | Select highest valid consistent slot and retain conservative latch. |
| STOR-008 | Journal/anchor digest conflicts | More restrictive state wins. |
| STOR-009 | Both anchors corrupt/read-only | Read-only monitoring only after ownership checks; block new authority and clean uninstall. |
| STOR-010 | Operational history full | Drop/rotate eligible non-safety records without consuming 4 MiB journal reserve. |

### 11.3 Write-rate and retention boundaries

Test:

- no persistent poll write;
- transition 4 MiB/90-day rotation;
- action/lifecycle 8 MiB/180-day rotation;
- health 4 MiB/14-day rotation;
- 16 MiB total and separate 4 MiB journal;
- repeated health summary no more than every 15 minutes;
- history flush at five seconds or 10 records;
- expert requirement above 64 MiB or 365 days;
- public bundle limit of 24 hours or 1,000 records;
- 0600 bundle and 10-minute expiry;
- 256 KiB policy-version limit;
- 8 MiB policy store;
- newest 10 inactive versions plus history references;
- protected-version exhaustion refusing new activation.

## 12. Credential, UI, and privacy tests

### 12.1 Shutdown-client credentials

Test:

- no credential on fresh install;
- unique upsmon secondary per client;
- no primary/FSD/SET/instant-command permission;
- once-only display;
- loss requires replacement;
- no age expiry;
- native non-TLS admission only from confirmed trusted LAN;
- current plus pending maximum;
- 1-, 24-, and 168-hour cutover bounds;
- pending expiry leaves current working;
- harmless test plus explicit promotion;
- emergency revocation;
- externally owned revocation remains an explicit target task;
- revocation tombstone blocks config/release rollback.

### 12.2 Secret handling

Test modes, minimum process access, and absence from:

- shared addon settings;
- HTML/JavaScript/status;
- browser persistence;
- argv/process listings where avoidable;
- logs and error paths;
- configuration export;
- public/private support bundles;
- last-known-good backup semantics.

An incompatible filesystem must disable the secret-bearing capability.

### 12.3 CLI and optional WebUI parity

For every management operation exposed in both surfaces, use common fixtures to prove identical:

- validation;
- preview/candidate hash;
- authorization/confirmation;
- transaction;
- result/exit class;
- redaction/audit.

WebUI component lifecycle tests cover explicit opt-in, exact release/schema matching, ownership, add/remove/re-add, update/rollback component preservation, outstanding-nonce invalidation on removal, and core survival when mounting or validation fails.

Web-only interaction tests cover Merlin authentication context, fixed service-event operation, five-minute nonce, first-attempt consumption, replay/change refusal, output encoding, strict bounds, no third-party assets, and status allowlist.

CLI-only tests cover stable JSON, stable exit classes, local privilege, recovery without UI, and secret input through stdin/file descriptor rather than argv.

## 13. Windows and standard-client testing

The server contract remains client-neutral.

Test standard NUT protocol behavior independently of any one client package:

- credential-free read-only query;
- one registered secondary authentication;
- reconnect after network interruption;
- server restart;
- per-client revocation;
- no claim that disconnect means shutdown.

A native Windows client or service may be tested in a disposable VM. Progress from read-only connection to harmless local marker. An actual Windows shutdown is optional and separately gated; it validates that client configuration only, not a router executor.

WSL2 is not the Windows shutdown agent. Hibernation is Later and is not a P0–P2 acceptance case.

## 14. Release evidence and blocking rules

Every release records:

- exact advertised Merlin stable release per family;
- architecture and current Entware feed/cohort;
- NUT and verifier versions;
- host/static/integration results;
- package/ABI results;
- simulated platform-profile results;
- risk-trigger assessment for existing router/UPS reports;
- capability availability and absent conditional adapters;
- installed component set and separately qualified WebUI availability;
- known incompatibilities and negative reports;
- signed manifest/artifact evidence.

Lower-layer failure blocks a claim even if higher-layer hardware happened to work.

The first public core release additionally blocks on:

- one complete current exact-router report;
- one harmless physical UPS base report;
- two independent release-root fingerprint channels;
- tested emergency signing-root replacement;
- P0 security/negative/ownership/lifecycle/storage/network acceptance.

Publishing the optional WebUI artifact additionally requires its host/static, simulated-Merlin, component-lifecycle, and exact-platform interaction evidence. Failure removes or withholds the WebUI artifact or platform claim and does not block an otherwise qualified core release.

WinRM or Redfish qualification failure removes that P2 capability and does not block the safe core release. RT-AC3100/ARMv7 failure is nonblocking legacy information.

## 15. Optional firmware-emulation research

FirmAE/Firmadyne/QEMU boot or user-mode experiments may investigate firmware commands or web behavior, but:

- they are not required;
- they do not replace current Entware package/ABI execution;
- they do not qualify Addons API, firewall, mount, USB, storage durability, or exact hardware;
- they must not delay the P0 safe-core evidence path.
