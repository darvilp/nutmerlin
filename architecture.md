# NUTMerlin architecture

## 1. Architectural intent and authority

NUTMerlin is a safe integration layer around Entware-provided NUT. NUT owns device drivers, UPS communication, upsd, the NUT client protocol, and standard upsmon roles. NUTMerlin owns validated configuration generations, Merlin lifecycle integration, observation normalization, optional WebUI and policy capabilities, and bounded diagnostics.

This document describes the accepted shape. CONTEXT.md defines its vocabulary; accepted ADRs under decisions/ control when this summary is less precise.

The architecture deliberately excludes:

- a new UPS/device protocol stack;
- a general shell or remote-management API;
- automatic source failover or multi-UPS voting through P2;
- production FSD until its full committed lifecycle exists;
- writable UPS/PDU administration, abrupt power, and restoration through P2.

## 2. System context

The default path is standard client-local NUT:

    physical UPS
         |
         v
    qualified NUT driver profile
         |
         v
       upsd  <----- exact listener + firewall gate ----- registered clients
         |                                               |
         |                                               +-- read-only status
         |                                               +-- upsmon secondary
         |
         +--> unprivileged status collector
                    |
                    +--> volatile current status
                    +--> complete local CLI
                    +--> optional exact-version Merlin UI
                    +--> observation normalizer
                              |
                              v
                         policy engine
                              |
                              v
                       immutable action intent
                              |
                              v
                        execution broker
                              |
                              +-- conditional local script (P0)
                              +-- restricted SSH (P1)
                              +-- notification webhook (P1)
                              +-- publish-only MQTT (P1)
                              +-- qualified WinRM (P2)
                              +-- qualified Redfish (P2)

Shutdown-client onboarding is beside, not inside, the executor registry. The client polls NUT and runs its own local shutdown command; NUTMerlin neither dispatches nor verifies that command.

An isolated dummy-ups source has a distinct maintenance identity and loopback-only data path:

    dummy-ups -> isolated upsd -> local health/simulator tests

It never inherits the production source name, external clients, policies, or executor authority.

## 3. Privilege topology

NUTMerlin separates three authorities.

### 3.1 Privileged lifecycle controller

A small router-local controller performs only fixed typed operations for:

- installation and ownership;
- release/configuration selection;
- service lifecycle;
- hook and UI mounting;
- listener/firewall management;
- privilege and filesystem setup;
- disable, rollback, uninstall, and emergency detach.

It exposes no network listener and no general command surface.

### 3.2 Unprivileged status, policy, and UI plane

Unprivileged components:

- query managed NUT status;
- normalize observations;
- evaluate immutable policies;
- render sanitized status;
- prepare management-operation candidates;
- append bounded non-secret history.

They cannot read arbitrary secrets, mutate lifecycle state directly, or dispatch an external command.

### 3.3 Narrow execution broker

The broker accepts one immutable, already authorized action intent. It revalidates:

- policy and operation version;
- target and binding identity;
- safety class and gates;
- credential reference and revocation state;
- freshness, dependencies, budgets, and conflict state;
- durable journal and JFFS anchor readiness.

It exposes only the secret and capability required for that binding, returns structured redacted evidence, and never becomes a general command runner.

Managed upsd and drivers run with the least privilege their qualified profile permits; upsd does not run as root.

## 4. Domain model and ownership

| Concept | Architectural role |
| --- | --- |
| Authoritative UPS source | The one real driver source permitted to govern production status and policy through P2. |
| NUT driver profile | Versioned typed contract for driver options, identity, privilege, rendering, lifecycle, probes, and migration. |
| Fresh observation | One successful, noncontradictory NUT status read with monotonic position inside the freshness deadline. |
| Outage episode | A normalized span of related source state used to deduplicate thresholds, timers, commitments, and recovery. |
| Target | Stable logical destination, independent of transport. |
| Binding | Versioned executor endpoint, credential reference, identity evidence, capability, and verifier for one target. |
| Policy version | Immutable exact snapshot of conditions, stages, targets, actions, operation schemas, dependencies, and gates. |
| Typed operation | Closed versioned structured operation with maximum safety class, retry class, budgets, and evidence contract. |
| Action intent | Durable instance of one policy-version operation against one target/binding during one episode. |
| Activation evidence | Candidate-specific static validation, harmless binding tests, exact dry-run, and resolved warnings. |
| Safety journal | Synchronous durable authority/recovery facts on /opt. |
| JFFS safety anchor | Small independent conservative digest and unresolved-state latch. |
| Operational history | Bounded transition, action, lifecycle, and diagnostic records not used as sole recovery authority. |

Target groups and operation templates are authoring conveniences. Policy activation expands them into exact immutable content. Later changes to a group, template, binding, credential, operation schema, or target do not mutate the active version; they require a new draft and activation.

## 5. Components

### 5.1 Stable JFFS dispatcher and ownership manager

Small managed hook blocks call a stable NUTMerlin dispatcher under /jffs/addons/nutmerlin. Substantial versioned logic remains in complete release slots rather than in firmware hook files.

The ownership manager maintains:

- installation ID;
- ownership manifest;
- release-slot identities;
- exact managed hook blocks, installed component set, and optional UI integration;
- expected /opt storage identity;
- update/configuration transaction linkage.

Foreign or ambiguous NUT deployments are never merged or adopted. Ownership recovery is an explicit conservative operation, not an installer side effect.

### 5.2 Platform adapter

All Merlin-specific behavior stays behind named, testable platform capabilities:

- firmware family, architecture, and Addons API detection;
- NVRAM reads;
- authenticated web-page and service-event integration;
- user-script hook management;
- firewall owner/rule inspection;
- mount and storage identity;
- service/process lifecycle;
- local account and privilege capabilities;
- same-boot identity and positive time-synchronization evidence;
- syslog and resource-limit mechanisms.

Host shims implement the same boundary. Capability probes decide platform eligibility; router model names select report/profile data, not product behavior.

### 5.3 Entware dependency adapter

This adapter validates the preexisting Entware prerequisite and computes a scoped package plan.

The implemented `dependency.plan.v1` operation is read-only. Its release-matched `nutmerlin.entware-cohort.v1` catalog pins the official configured feed URL separately from the HTTPS catalog-provenance URL, package architecture, complete feed-index byte count and digest, exact NUT and `gpgv2` records, package dependency/provider relationships, the complete core transitive closure, required binary/option/environment contracts, and optional capability roots. The initial optional mapping is `ssh` to the three current Entware OpenSSH client packages. The `libnetsnmp-ssl` package is present only as the current feed's provider for `nut-common`'s transitive `libnetsnmp` requirement; it does not enable an SNMP driver or operation.

The native adapter reads the selected Entware root, executable package-manager prerequisite, status database, feed configuration, cached index, verifier, and installed NUT binaries. It hashes the cached index and runs only version/help probes against installed NUT binaries. It never invokes the package manager. Host adapters use private roots, are labeled as simulation or host-native evidence, and cannot return an install-authorizing result.

Plans contain exact per-package candidate provenance, observed versions, and every proposed install or scoped upgrade, with archive bytes as temporary need and the complete installed size of each mutation as the conservative transaction need. The planner adds the 16 MiB post-transaction headroom. Missing, mixed, unsafe, newer, wrong-feed, wrong-architecture, unhealthy, or uncomputable evidence fails closed. An explicit compatibility-only keep also requires binary, option, configuration, and isolated `dummy-ups` probe evidence. Ordinary uninstall produces a retain-all plan for every observed Entware package.

A later lifecycle executor may mutate only the accepted declared plan after the independent storage and policy gates. It never installs Entware, repairs opkg as a platform, changes feeds, formats storage, performs blanket upgrade, selects private NUT binaries, downgrades automatically, or removes packages during ordinary uninstall.

### 5.4 Release lifecycle manager

The lifecycle manager uses:

- current and previous authenticated release slots;
- a bounded durable update journal;
- a stable atomic slot selector;
- safe-window activation;
- one rollback attempt;
- rollback quarantine and exact authority reconciliation.

Candidate code and its compatible configuration generation form one tested activation unit. A rollback cannot independently select incompatible code and configuration.

The core and optional WebUI are separate artifacts under one signed release manifest. Core is always present; WebUI is explicit opt-in. When installed, its artifact and management schema must exactly match the active core slot. Install, removal, update, and rollback journal the selected component set. UI removal changes only owned page registration, assets, and transient nonces; it cannot remove or stop core services or state.

### 5.5 NUT configuration generator

The generator consumes a validated internal model and produces one complete immutable generation containing every managed NUT file, hashes, owner/group/mode metadata, renderer/schema versions, and a unique generation ID.

The flow is:

    validated model
        -> new private generation directory
        -> render every file
        -> validate fields, modes, paths, NUT syntax, and harmless probes
        -> hash and seal
        -> stop affected managed services and close exposure
        -> atomically select generation
        -> resolve one exact ID for the service epoch
        -> set NUT_CONFPATH for drivers, upsdrvctl, upsd, and later NUT components
        -> restart full affected stack
        -> validate source, service, privilege, listener, firewall, journal, and files
        -> reopen permitted exposure after the health gate

Every process in one service epoch uses the same resolved generation. No managed process reads ambient /opt/etc/nut, follows a moving selector, or mixes individual files.

Only active and last-known-good sealed generations remain after staging. A failed candidate receives one complete rollback/health attempt.

### 5.6 Source and NUT runtime manager

P0 profiles are:

- one real usbhid-ups source, named ups to clients by default;
- one isolated loopback-only dummy-ups maintenance source.

The real source binds only when stable identity resolves uniquely. Preferred identity is VID/PID/serial; a no-serial profile must still resolve exactly one candidate with accepted stable attributes. Device nodes and USB bus/port are diagnostic only.

The runtime manager:

- starts/stops the configured driver and upsd;
- queries health and versions;
- verifies exact process privilege and generation;
- verifies source identity continuously where feasible;
- applies the restart circuit breaker;
- never automatically replaces real telemetry with dummy-ups.

### 5.7 Status collector and normalizer

The collector reads NUT through supported NUT interfaces and writes current sanitized state to /tmp.

The normalizer:

- records boot ID and monotonic observation position;
- preserves raw-known status tokens as bounded diagnostics;
- represents missing/malformed/unreliable values as unknown rather than zero;
- marks fields observed, qualified, or known_unreliable;
- applies freshness and two-sample consistency;
- inhibits immediately on the first contradictory or recovery observation;
- never treats numeric fields as authority unless the exact capability is qualified.

Default observation is every five seconds. Freshness expires at NUT stale or max(15 seconds, three intervals). Supported profile intervals are 2–30 seconds.

### 5.8 Policy engine

The policy engine is independent of Merlin lifecycle and NUT process control so host tests can exercise it as a pure state transition system.

It consumes immutable policy versions and fresh normalized observations. It owns:

- outage episode identity;
- reversible versus committed phase;
- monotonic event-relative timers;
- threshold hysteresis and once-per-episode behavior;
- exact target/action snapshots;
- acyclic prerequisites;
- cross-policy conflict analysis and identical-intent coalescing;
- protected coordinator and control-path infrastructure;
- prospective emergency inhibit;
- action budget reservation.

It has no calendar scheduler through P2. It does not dynamically re-expand groups or templates after activation.

### 5.9 Action coordinator and executor registry

The coordinator performs:

    validate -> harmless test -> activate evidence -> prepare intent
             -> journal dispatch intent -> execute -> verify -> record evidence

Every operation declares:

- closed schema/version;
- maximum safety class;
- retry class;
- connection, dispatch, verification, and total budgets;
- target capability and credential requirements;
- accepted evidence and verifier.

Evidence is one of not_dispatched, dispatch_rejected, dispatch_accepted, effect_verified, or outcome_unknown. Only verification can establish effect. A timeout after durable dispatch intent becomes unknown when acceptance cannot be excluded.

Default budgets are five seconds connect, 30 seconds dispatch, and 300 seconds verify. The platform ceilings are 30, 300, and 1800 seconds respectively, with a 3600-second total action ceiling. There is one in-flight action per target, at most two concurrent dispatches, and at most 30 starts per rolling 60 seconds.

### 5.10 Executor adapters

| Adapter | Milestone | Architectural boundary |
| --- | --- | --- |
| Local script | Conditional P0 | Imported immutable POSIX sh artifact, unprivileged, bounded structured I/O, no secrets/arguments/network, and available only on a qualified containment profile. |
| SSH | P1 | Current Entware OpenSSH, one binding key, independently pinned host key, and target-enforced forced command/restricted account. |
| Webhook | P1 | notification.publish only through fixed LAN-anonymous, HTTPS bearer, or HTTPS HMAC profile; 2xx proves delivery acceptance only. |
| MQTT | P1 | Outbound QoS 1 only, ephemeral session, retained current state/availability only, no command subscription or offline replay. |
| Simulated FSD | P1 | Fully harmless isolated primary/secondary design and compatibility environment; no production authority. |
| WinRM | Conditional P2 | Only with a reproducible qualified Entware client stack, verified HTTPS, constrained endpoint, one graceful request, and independent Off evidence. |
| Redfish | Conditional P2 | Exact manually selected ComputerSystem, verified TLS, target-side graceful-only role, one GracefulShutdown, and two-sample Off verification. |

No P0–P2 adapter provides ForceOff, reset, power-on, output control, raw UPS commands, hibernation, direct SNMP/PDU, inbound MQTT, or a general action-capable webhook.

### 5.11 Management-operation controller

The complete CLI and any installed WebUI are adapters over one versioned management-operation controller with common:

- validation;
- candidate preview/hash;
- authorization and confirmation;
- transaction;
- result and exit class;
- audit/redaction.

The local CLI is a required core surface and exposes stable JSON output. The Merlin UI is an optional exact-version component, curated by milestone, and uses only fixed operation IDs and validated fields.

The web path stays inside the authenticated Merlin origin and adds a one-time five-minute nonce bound to installation, operation, candidate hash, and UI schema. The nonce is consumed on first attempted dispatch. Browser validation is advisory; the controller revalidates everything.

There is no standalone web server, REST API, RPC listener, remote CLI wrapper, third-party JavaScript, analytics, or browser credential persistence.

### 5.12 History and support artifacts

Volatile status, safety state, operational history, configuration export, and support bundles are distinct stores/contracts.

Operational history records transitions and results, not every poll. It is never the sole authority for deduplication, commitment, unknown outcome, or recovery.

Configuration export contains non-secret reconstructable definitions and imports them inactive. Public support bundles are allowlisted and pseudonymized; private bundles may preserve more non-secret topology. Neither contains secrets or private keys.

## 6. State models

### 6.1 Source observation state

    UNKNOWN
       |
       +--> ONLINE_CONFIRMED
       |
       +--> ON_BATTERY_CONFIRMED
       |
       +--> COMMUNICATION_LOST
       |
       +--> CONTRADICTORY

Two fresh consistent observations confirm ONLINE or ON_BATTERY. The first sample that contradicts the active condition immediately inhibits new dispatch. Stale, WAIT, malformed, OL+OB, or no recognized line-state token is not action-eligible.

### 6.2 Outage episode state

    IDLE
      |
      +-- confirmed OB --> REVERSIBLE
                              |
                              +-- confirmed OL --> RECOVERED -> IDLE
                              |
                              +-- explicit commit --> COMMITTED
                                                        |
                                                        +--> TERMINAL / RECONCILE

Reversible timers may cancel on confirmed recovery. A committed sequence never becomes reversible because utility returned.

Pending timers retain same-boot monotonic elapsed time while telemetry is stale but cannot dispatch. A router reboot restarts an uncommitted timer from zero. Accepted, committed, or unknown intents never redispatch on restart.

### 6.3 Action evidence state

    NOT_DISPATCHED
          |
          +-- local validation refusal --> DISPATCH_REJECTED
          |
          +-- durable intent + conclusive acceptance --> DISPATCH_ACCEPTED
          |                                               |
          |                                               +-- verifier proof --> EFFECT_VERIFIED
          |
          +-- durable intent + ambiguous outcome --> OUTCOME_UNKNOWN

Unknown is a durable inhibition, not a retryable failure. Rollback, reboot, uninstall, or credential change cannot reinterpret it.

### 6.4 Storage/lifecycle state

Boot-time absent /opt follows the readiness schedule. Unexpected runtime loss, read-only state, changed storage identity, corrupt journal, or anchor mismatch enters a storage fault latch.

The latch closes new policy activation, commitment, dispatch, update/config activation, rollback finalization, and clean uninstall until deterministic reconciliation and explicit clear. Safe local diagnostics and qualified read-only monitoring may remain.

The `storage.preflight.v1` operation inspects native `/opt` and consumes closed mount, composite filesystem/device identity, exact observed mount options, exact-profile, semantic, and sizing evidence. Its transaction and temporary byte counts are explicit operation inputs calculated by the package or release planner, not ambient environment configuration. Identity, mount, profile, journaling, sizing, and space gates run before any disposable semantic probe. Test profiles can prove classification but always refuse mutation; only a positively eligible native exact-qualified profile returns downstream mutation eligibility. `storage.readiness.v1` expresses the bounded late-mount decision and one-start claim without starting services itself; its transient root has a fixed production path, owner, and mode. The owned lifecycle installed by the later deployment ticket supplies hook, timer, validation, and service wiring.

## 7. Policy activation and dispatch flow

Activation is separate from saving a draft:

1. Validate schemas, identifiers, bounds, target expansion, operation classes, conflicts, and protected infrastructure.
2. Resolve exact binding and credential versions.
3. Run current harmless binding tests.
4. Dry-run the exact immutable candidate.
5. Present warnings and exact expanded effects.
6. Require explicit activation.
7. Record candidate-specific evidence, valid for at most 24 hours and invalidated by relevant drift.
8. Store the immutable version and make it eligible for a future episode.

At runtime:

1. Require fresh qualified source evidence.
2. Evaluate the captured version using monotonic time.
3. Revalidate target, binding, credential tombstones, dependencies, conflicts, budgets, storage, and inhibit state.
4. Persist commitment when applicable.
5. Persist and fsync dispatch intent immediately before a nonrepeatable external request.
6. Execute within the operation budget.
7. Verify through the declared read-only verifier.
8. Persist evidence and transition the episode.

Policies may narrow operation budgets but cannot expand retry, safety class, credential privilege, or platform ceilings.

## 8. Lifecycle transactions

### 8.1 First install

1. Administrator stages the release manifest, signature, pinned keyring, installer, and artifacts locally.
2. Independently confirm the full release-root fingerprint.
3. Verify signature, compatibility, sizes, and hashes before executing project code.
4. Validate Merlin, preexisting Entware, storage semantics/identity, opkg health, free space, and foreign ownership.
5. Compute and display the scoped package plan.
6. Create ownership and release state through the journaled transaction.
7. Render and validate an initial complete NUT configuration generation.
8. Start monitoring-only with every external/action surface closed until explicitly configured.

### 8.2 Boot

1. A minimal JFFS dispatcher observes enablement and expected storage identity without blocking router boot.
2. Probe /opt at 5, 15, 30, 60, and 120 seconds, then every 300 seconds while unavailable.
3. Reconcile JFFS anchor, detailed journal, update/config transactions, ownership, boot identity, and unresolved flags.
4. Resolve the exact authenticated release and sealed configuration generation.
5. Start managed NUT services under their qualified privileges.
6. Validate source identity and current health.
7. Open external NUT only after listener/firewall agreement.
8. Start policy authority only when explicitly active and every gate remains valid.

### 8.3 Update/configuration activation

Stage and verify at administrator request. Activate only in a normal confirmed-OL safe window or explicitly disabled maintenance mode. Close external/action surfaces during transition, select the complete candidate atomically, pass 120 continuous healthy seconds plus 24 fresh observations, then finalize or attempt one rollback.

Activation never broadens policy, credential, source, listener, or executor authority.

### 8.4 Disable

Persistently inhibit new automation, close managed external NUT/action surfaces, stop project services as defined by the disable transaction, and retain releases, ownership, configuration, secrets, journals, and history for later enablement/recovery.

### 8.5 Clean uninstall

Refuse when state is in-flight, committed, unknown, unreconciled, ambiguously owned, or unwritable. Otherwise:

1. close actions and network exposure;
2. remove only verified managed hook/UI/firewall/service artifacts;
3. remove all verified NUTMerlin-owned releases, configurations, credentials, journal, history, and data;
4. retain every Entware package and every foreign artifact;
5. retain externally owned revocation instructions as an administrator responsibility.

There is no force-clean mode. Emergency detach removes only independently verified JFFS activation/exposure when /opt is broken and preserves evidence for later cleanup.

## 9. Data placement and durability

The following layout is conceptual; exact leaf names are an implementation detail constrained by ownership manifests and schemas.

    /jffs/addons/nutmerlin/
      stable dispatcher and minimal lifecycle code
      release-slot selector and ownership evidence
      current/previous release slots or their verified references
      two alternating 32 KiB safety-anchor slots
      small managed UI/hook metadata

    /jffs/scripts/
      small NUTMerlin-owned dispatch blocks only

    /opt/.../nutmerlin/
      sealed NUT configuration generations
      binding-scoped secret files
      imported immutable local-script versions
      immutable policy-version store
      4 MiB detailed safety journal reserve
      16 MiB bounded operational history
      update/configuration transaction material

    /tmp/nutmerlin/
      current status
      transient working directories
      locks, sockets, and process state
      web operation nonces
      bounded in-memory diagnostic summaries

Ext4 is the reference profile. Eligibility depends on exact permission, link, rename, fsync, lock, execution, identity, and interruption semantics. JFFS receives no per-poll state or operational history.

Safety facts write detailed /opt state first, then the next atomic JFFS anchor slot before any externally effecting dispatch or selector change. An interruption may leave an extra conservative latch but cannot authorize missing work.

## 10. Network architecture

NUT data and addon management are separate planes.

### NUT data plane

- one exact confirmed IPv4 LAN listener;
- TCP 3493 admitted from one confirmed source subnet;
- credential-free read-only status in that scope;
- independent secondary credentials for registered clients;
- IPv6 off unless one exact trusted address/prefix and independent denial are qualified;
- no WAN, guest, VPN-client, broad private-network, or wildcard exposure.

Listener and firewall scope must agree on activation, restart, firewall hook, and every 300 seconds. Drift closes exposure.

### Management plane

When installed, the only web management path is the authenticated Merlin UI adapter with its one-time nonce. The required complete management path is the local CLI. Native NUT clients have no addon-management authority, and absence or removal of the WebUI does not change core service or CLI authority.

### Executor egress

Each binding validates hostname/address, every resolution result, actual peer, TLS or SSH identity, scope, and redirect policy. Router-owned administration endpoints, unspecified, loopback, link-local, multicast, broadcast, and scope-crossing destinations are rejected as defined by the adapter.

## 11. Time architecture

Monotonic time is authoritative for observations, episodes, delays, action budgets, retries, backoff, rate windows, and same-boot sequencing.

Wall time is a separately trusted state:

- untrusted at every boot;
- trusted only after positive same-boot synchronization evidence;
- revoked after a greater-than-300-second discontinuity versus monotonic projection or a platform unsynchronized/reset signal.

Every record carries boot ID, monotonic position, wall timestamp, and wall_time_trusted. Untrusted wall time blocks new TLS/HMAC/release/key-validity work but does not alter monotonic policy state.

## 12. Failure behavior

| Failure | Architectural response |
| --- | --- |
| Entware absent during boot | Follow readiness schedule; do not create, mount, or repair Entware. |
| /opt lost or read-only at runtime | Latch automation, preserve conservative JFFS state, and require reconciliation/clear. |
| Foreign or ambiguous NUT files | Refuse mutation and expose ownership diagnostics. |
| Invalid or mixed NUT configuration | Keep exposure closed and retain sealed last-known-good generation. |
| USB source missing or ambiguous | Normalize unavailable/unknown; do not bind first match or substitute simulation. |
| Driver or upsd repeatedly fails | Apply 3-in-5-minute breaker, pause 15 minutes, and permit one probe. |
| Stale/contradictory telemetry | Inhibit new ordinary dispatch; never infer LB or zero. |
| Router reboot during reversible timer | Restart uncommitted timer from zero after fresh evidence. |
| Restart after accepted/unknown dispatch | Reconcile; never repeat the external request. |
| One independent target fails | Continue provably independent actions; block exact dependents. |
| Overlapping different intents | Reject unless an explicit relationship resolves the conflict. |
| Network delivery interrupted | Record failed or unknown by dispatch boundary; do not stale-replay after recovery. |
| Safety journal or anchor cannot advance | Block new state-changing authority. |
| Operational history full | Rotate/drop eligible non-safety records without consuming journal reserve. |
| Wall clock untrusted | Block new wall-clock-dependent security sessions; preserve monotonic monitoring. |
| Candidate release/configuration fails | One rollback attempt, then close surfaces and require local CLI recovery. |

## 13. Support and compatibility architecture

Platform support is capability-based within latest-qualified AArch64 3004.388.x and 3006.102.x. Exact model/revision reports are stronger evidence, not a separate promise. Reproducible negative evidence establishes known incompatibility for the affected combination/capability.

The platform report separates support from install disposition. Exact-qualified current platforms are supported; other current-family releases are compatibility-only; Merlin 386/ARMv7 is legacy best-effort; and an unsupported platform with every core safety probe available is experimental. The latter three require explicit acknowledgment before a later monitoring-only install. Unknown, missing, or incompatible core lifecycle evidence refuses installation, while WebUI, wall-clock-security, and local-script probe failures remain scoped to those optional capabilities.

UPS support is not a device-level blanket. The harmless base source contract and each status/numeric capability are qualified separately for exact UPS, firmware where known, driver profile, and NUT version.

Hardware evidence layers remain distinct:

1. host conformance;
2. current Entware package/ABI execution;
3. simulated Merlin integration;
4. exact-router qualification;
5. exact UPS capability qualification.

The RT-AC3100 is an optional legacy profile. The RT-AX86U Pro is a production-reference profile requiring explicit mutation gating. Neither model defines the generic architecture.

## 14. Milestone boundaries

### P0

Safe authenticated lifecycle; healthy Entware prerequisite; one usbhid-ups source; isolated dummy-ups; immutable NUT configuration; fresh normalized status; scoped NUT LAN service; independent secondary onboarding; complete CLI; curated UI; bounded journal/history/export; policy and evidence foundations; conditional contained local scripts.

### P1

First-class notifications, fixed webhook, publish-only MQTT, restricted SSH, qualified thresholds, exact graceful stages, protected infrastructure, event/action views, and harmless FSD simulation.

### P2

Only independently qualified graceful WinRM, graceful-only Redfish, and accepted additional NUT driver profiles.

### Later

Production FSD, output or abrupt power, target restoration, writable UPS administration, direct SNMP/PDU, root scripts, hibernation, multiple sources, scheduling, inbound control, broad platform/cloud services, and AMTM/catalog distribution.
