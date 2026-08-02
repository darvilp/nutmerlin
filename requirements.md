# NUTMerlin requirements

## 1. Authority, scope, and milestones

NUTMerlin shall be a community Asuswrt-Merlin integration layer around Entware-provided Network UPS Tools. NUT owns UPS device communication and the NUT network protocol. NUTMerlin owns safe installation, validated configuration, lifecycle integration, status normalization, client onboarding, optional policy evaluation, and qualified executor dispatch.

The controlling design records are:

- root CONTEXT.md for terminology;
- accepted ADRs under decisions/ for architectural decisions;
- decision-ledger.md as the interview closeout index.

When a summary in this file is less precise than an ADR, the ADR controls. The milestones are capability and evidence boundaries, not dates:

- P0: public safe NUT core and client-local shutdown onboarding;
- optional P0 component: version-matched curated Merlin WebUI;
- P1: common notification and graceful orchestration;
- P2: independently qualified native graceful adapters;
- Later: separately governed high-risk or broad-scope capabilities.

NUTMerlin is not:

- a replacement UPS protocol or driver implementation;
- a cloud monitoring service;
- a general remote-command or router-management platform;
- a guarantee that every NUT variable is reliable;
- a promise of support for every router model, UPS, filesystem, or old package;
- a path to UPS/PDU output control, abrupt host power, or automatic restoration through P2.

### REQ-SCOPE-001 — Client neutrality (P0)

The addon shall remain client-neutral. A standard NUT upsmon secondary is the P0 shutdown pattern; Windows, WinNUT, WSL2, and the maintainer’s own PC are examples rather than runtime dependencies.

### REQ-SCOPE-002 — Monitoring-only default (P0)

A fresh install and an upgrade shall enable no policy, central executor, shutdown-client credential, webhook, MQTT binding, outage timer, telemetry-loss fail-safe, production FSD workflow, or writable device operation.

### REQ-SCOPE-003 — No dangerous early registry entries (P0–P2)

The installed operation registry through P2 shall contain no power_abrupt or output_control operation. A generic checkbox, confirmation, environment variable, dry-run, or credential shall not create such authority.

## 2. Supported deployment patterns

### REQ-PATTERN-001 — Network UPS server and client-local shutdown (P0)

The router shall run one qualified NUT driver source and upsd. Independent clients may read status and, after explicit registration, authenticate as restricted upsmon secondaries that own their local delay, cancellation, threshold, and shutdown command.

NUTMerlin shall not claim that it dispatched or verified a client-local shutdown.

### REQ-PATTERN-002 — Notification-only policy (P1)

A policy may publish a normalized notification through a fixed webhook or publish-only MQTT profile without enabling a target-state action. Delivery acceptance shall not be represented as target-state verification.

### REQ-PATTERN-003 — Graceful central orchestration (P1)

Restricted SSH and qualified local-script bindings may perform typed, explicitly activated graceful service or host operations. Policies may sequence exact target/action snapshots with prerequisites and protected infrastructure.

### REQ-PATTERN-004 — Native graceful adapters (P2)

WinRM host.graceful_shutdown and Redfish GracefulShutdown may be advertised only when each complete adapter, transport, target privilege, and verifier contract is independently qualified.

### REQ-PATTERN-005 — Production FSD (Later)

Production NUT FSD shall remain unavailable until a complete primary/router, secondary-client, durable commitment, UPS power-down, restoration, and exact-hardware workflow is accepted and qualified. P1 may provide only a harmless isolated FSD simulation.

### REQ-PATTERN-006 — Deferred broad and destructive scope (Later)

UPS/PDU output off, cycle, delay, stay-off, return, writable UPS administration, Redfish ForceOff/reset/power-on, target restoration, direct SNMP/PDU, hibernation, multiple or redundant sources, calendar scheduling, inbound control protocols, specialized platform APIs, and built-in cloud/email/mobile services require later decisions.

## 3. Platform support and qualification

### REQ-SUP-001 — Current Merlin families (P0)

The intended support contract shall cover AArch64 3004.388.x and 3006.102.x. Within each family, only the latest NUTMerlin-qualified upstream stable release is supported.

A newly published stable release shall not inherit qualification. The previously qualified release remains supported until the new release qualifies; qualification then moves without a retirement grace period. Earlier releases are compatibility-only.

### REQ-SUP-002 — Capability-based platform eligibility (P0)

Mandatory preflight probes shall determine whether a router environment satisfies the supported platform contract. A hard-coded model allowlist shall not be the eligibility authority.

Known-incompatible evidence shall override general eligibility and fail closed for the affected capability or installation.

### REQ-SUP-003 — Exact hardware qualification (P0)

Exact router model and hardware revision qualification shall require one complete, reproducible, waiver-free hardware report. The report shall identify the exact router, firmware, architecture, Entware feed and packages, addon, storage profile, and structured non-destructive results.

Qualification may carry forward only when a release records that no relevant platform-facing behavior or dependency changed. It has no calendar expiry. A supported firmware change, hardware revision, feed/ABI change, NUT major/minor change, relevant addon platform change, security advisory, or reproducible fault triggers fresh evidence. Reproducible negative evidence revokes the affected qualification until fixed and retested.

### REQ-SUP-004 — Legacy best-effort (P0)

Merlin 386/ARMv7 and the RT-AC3100 shall be legacy best-effort only. No normal CI, pull request, release, or core capability shall wait for that hardware.

### REQ-SUP-005 — Development environment neutrality (P0)

The maintainer workflow may use Codex IDE beta and WSL2, but host tests shall run on a normal Linux environment. The working tree should reside on a Linux filesystem rather than /mnt/c for Linux-tool workflows.

### REQ-SUP-006 — Layered release evidence (P0)

Host conformance tests shall run for every change. Every release shall execute the exact current AArch64 Entware package/ABI cohort used by supported platforms.

The first public release shall also have:

- at least one complete exact current-family router report; and
- at least one harmless physical UPS base report covering OL, short OB/recovery, stale or disconnect/reconnect, and stable identity.

Later hardware evidence shall refresh on the risk triggers in REQ-SUP-003. ARMv7 evidence is nonblocking.

## 4. Entware, ownership, and lifecycle

### REQ-PLAT-001 — Preexisting healthy Entware prerequisite (P0)

NUTMerlin shall require a preexisting, mounted, writable, supported-architecture Entware installation with a healthy opkg database and feed configuration.

NUTMerlin shall not install Entware, choose or format storage, change feed configuration, repair the shared package database, or claim ownership of /opt.

### REQ-PLAT-002 — Scoped current-feed dependency management (P0)

The supported Entware feed’s current coherent package cohort shall be the gold standard.

NUTMerlin shall:

- inspect versions before mutation;
- never run a blanket opkg upgrade;
- leave compatible required packages unchanged;
- present an exact package plan;
- mutate only required packages and coherent NUT components;
- install optional dependencies only when their capability is enabled;
- never silently downgrade, pin, vendor, or fetch a private NUT build;
- record package versions and provenance.

An interactive install shall default to upgrading a coherent older compatible cohort, while permitting explicit compatibility-only preservation after required probes. Unattended mutation shall require an explicit dependency policy. Mixed, incomplete, vulnerable, or known-unsafe cohorts shall be refused or repaired within the declared cohort.

### REQ-PLAT-003 — Transaction headroom (P0)

Package and release mutation shall require conservatively calculated transaction and temporary space plus at least 16 MiB of post-transaction safety headroom. Mutation shall be refused when the requirement cannot be calculated safely.

### REQ-PLAT-004 — Foreign deployment refusal (P0)

NUTMerlin shall not adopt, merge, overwrite, stop, or uninstall a foreign NUT deployment. Missing or inconsistent ownership evidence shall be treated as ambiguous ownership and refused.

### REQ-PLAT-005 — Conservative ownership recovery (P0)

Ownership recovery shall be a separate explicit operation. It may reconstruct an ownership manifest only from complete, mutually consistent NUTMerlin evidence and shall never infer ownership merely from familiar paths or contents.

### REQ-PLAT-006 — Authenticated first install (P0)

First install shall use a locally staged authenticated bundle. Before project code executes, the administrator shall independently confirm the full OpenPGP root fingerprint, verify the signed manifest, and verify every installer and artifact size/hash.

Streaming network content into a shell and trusting a key first encountered beside the candidate shall be prohibited.

### REQ-PLAT-007 — Journaled two-slot lifecycle (P0)

Install and update shall stage the complete selected component set separately from the active slot, record durable phases in a bounded update journal, atomically select the candidate, retain current and previous slots only, and permit one automatic rollback attempt. Every slot contains the core and contains the WebUI only when explicitly selected.

A failed rollback shall close NUTMerlin action and network surfaces, preserve both slots and diagnostics, and require local CLI recovery without disrupting core router services.

### REQ-PLAT-008 — User-initiated updates (P0)

Update discovery, download, staging, and activation shall require an explicit administrator session. NUTMerlin shall never install an update silently.

### REQ-PLAT-009 — Safe update window (P0)

Normal activation shall require confirmed OL, healthy writable storage and journal, correct network/privilege gates, and no active episode, pending state-changing action, committed sequence, unknown outcome, storage fault latch, or unresolved reconciliation.

Maintenance activation may use isolated dummy-ups only after explicit disablement. Policies, executors, shutdown-client service, and external NUT access shall remain closed after validation until the real source is resolved and the administrator explicitly enables the addon.

Candidate health shall require at least 120 continuous healthy seconds and 24 consecutive fresh observations at the default interval. Every migration shall retain a validated representation usable by the previous release.

### REQ-PLAT-010 — Rollback quarantine (P0)

Rollback shall restore only the authenticated previous release paired with its compatible last-known-good configuration and shall begin monitoring-only.

The restored slot shall reconcile exact ownership, journals, credentials, source, configuration, network scope, and policy hashes, then pass the same 120-second/24-observation gate. One automatic rollback may restore exact unchanged previous authority only when no active, committed, unknown, or unreconciled state exists. Manual rollback shall require explicit reactivation.

Rollback shall never restore a revoked credential, erase an unknown outcome, reopen a retry budget, or oscillate versions automatically.

### REQ-PLAT-011 — Disable, uninstall, and emergency detach (P0)

Disable shall close actions and managed network surfaces while retaining installation and data.

Clean uninstall shall remove all verified NUTMerlin-owned code, configuration, secrets, journals, history, hooks, and firewall state, but shall retain all Entware packages and every foreign artifact.

Clean uninstall shall refuse while work is in flight, committed, unknown, unreconciled, ambiguously owned, or unwritable. It shall have no force mode. When /opt is broken, emergency detach may remove only independently verified JFFS activation hooks and exposure while preserving ownership evidence and inaccessible data for later cleanup; it shall not claim clean removal.

### REQ-PLAT-012 — Late mount versus runtime storage loss (P0)

Boot readiness shall check /opt after 5, 15, 30, 60, and 120 seconds, then every 300 seconds while enabled and unavailable.

Unexpected runtime loss, replacement, read-only transition, or integrity failure of the active storage shall latch state-changing automation until deterministic reconciliation and explicit administrator clear. Read-only monitoring may resume automatically only when its own authority is intact.

### REQ-PLAT-013 — Optional version-matched WebUI component (P0)

The required core component shall contain all runtime services, persistent state, lifecycle and recovery behavior, management authority, and the complete local CLI. A core-only installation shall be fully supported and shall be the first-install default.

The WebUI shall be a separately authenticated optional artifact in the same signed release and version as the core. It shall require a healthy exact-version core, shall not install or operate standalone, and shall add no independent listener, controller, state model, or update channel.

WebUI install and removal shall be explicit ownership-checked lifecycle operations. Removal shall invalidate outstanding web nonces and remove only verified UI registration, assets, and transient UI state while preserving core services, configuration, credentials, policies, journals, history, and CLI access. Full core uninstall shall remove any installed WebUI under the clean-uninstall contract.

Updates shall preserve the selected component set and shall never serve a WebUI whose release or management schema differs from the active core. If a matching WebUI cannot be staged, the administrator shall explicitly postpone the core update or approve UI removal; unattended removal requires an operation-specific authorization. Rollback shall restore only an authenticated matching UI or leave it absent.

## 5. UPS sources and NUT configuration

### REQ-NUT-001 — One authoritative source (P0)

Through P2, an installation shall have exactly one authoritative real UPS source. Its default client-facing NUT name shall be ups.

NUTMerlin shall not aggregate, vote, or automatically fail over between real sources.

### REQ-NUT-002 — Isolated simulation (P0)

dummy-ups shall use a visibly distinct maintenance identity and loopback-only listener. External clients, policies, and executors shall be disabled for the simulated source. NUTMerlin shall never switch a failed real source to simulation automatically.

### REQ-NUT-003 — Versioned driver profiles (P0)

P0 shall define closed, versioned profiles for usbhid-ups and isolated dummy-ups. A profile shall own typed options, identity constraints, privilege, rendering, lifecycle, harmless probes, and migrations.

The CLI and any installed WebUI shall not accept an arbitrary driver name, raw ups.conf content, or an expert bypass. Additional drivers require separately accepted profiles.

### REQ-NUT-004 — Unique stable USB identity (P0)

A USB source shall bind only when validated VID/PID/serial identity resolves to exactly one device. A qualified no-serial profile may use exact stable attributes only when exactly one candidate exists. Bus and port are supplemental diagnostics, never sole or first-match authority.

### REQ-NUT-005 — Immutable complete configuration generations (P0)

NUTMerlin shall render complete, immutable, hashed, permissioned NUT configuration generations outside ambient /opt/etc/nut.

Every managed process in a service epoch shall resolve one validated generation ID and use NUT_CONFPATH. Candidate activation shall close exposure, change one atomic selector, restart the full affected stack, and reopen access only after validation.

At most active and last-known-good generations shall be retained after staging. Generation activation shall require 120 continuous healthy seconds and at least 24 fresh observations and shall receive one rollback attempt.

NUTMerlin shall refuse missing, modified, unsealed, symlinked, ownership-inconsistent, or future-schema generations rather than adopt them.

### REQ-NUT-006 — NUT lifecycle and bounded recovery (P0)

NUTMerlin shall manage and report health for the configured driver and upsd without permanently replacing firmware files.

Driver/service recovery shall permit no more than three starts in five minutes, delayed 5, 15, and 60 seconds, then pause for 15 minutes and permit one probe. The breaker shall reset only after five continuous healthy minutes.

### REQ-NUT-007 — NUT interfaces, not USB parsing (P0)

Status collection shall use NUT interfaces such as upsc and shall not implement USB HID parsing or vendor UPS protocols.

### REQ-NUT-008 — No writable administration (P0–P2)

NUTMerlin shall expose no raw upscmd, upsrw, beeper, battery test, calibration, outlet, shutdown.*, load.off, or other writable UPS/PDU operation through P2 and shall hold no general UPS administrative credential.

## 6. NUT networking and shutdown clients

### REQ-NET-001 — Exact trusted-LAN scope (P0)

The default external NUT scope shall be one administrator-confirmed IPv4 source subnet and one exact router LAN listener address. TCP port 3493 shall be admitted only from that scope.

WAN, guest, VPN-client, other VLAN/subnet, wildcard, and router-administration exposure shall be denied by default.

### REQ-NET-002 — IPv6 default-off (P0)

No IPv6 NUT listener or admission rule shall exist by default. Explicit opt-in shall require a specific trusted LAN address and source prefix, verified denial from untrusted interfaces, and administrator confirmation. Prefix or scope ambiguity shall remove stale rules and disable IPv6 access.

### REQ-NET-003 — Network exposure gate (P0)

External NUT access shall open only when the effective listener and independently verified firewall source scope agree exactly.

The gate shall be checked at activation, service restart, relevant firewall hook, and at least every 300 seconds. Drift shall close exposure rather than broaden it.

### REQ-NET-004 — Read-only status access (P0)

Credential-free read-only NUT status may be available inside the confirmed trusted-LAN scope. It shall convey no addon management, shutdown, FSD, SET, or instant-command authority.

### REQ-NET-005 — Independent secondary-client onboarding (P0)

Fresh installation shall create no shutdown credential. Explicit registration shall create one independently generated credential granting exactly one client only the upsmon secondary role and shall show client-neutral connection/configuration guidance.

NUTMerlin shall never grant upsmon primary, FSD, SET, or instant-command authority through this flow.

### REQ-NET-006 — Native credential transport (P0)

Native non-TLS NUT secondary credentials may be used only within the confirmed trusted LAN. Verified NUT TLS may be offered as a separately qualified optional profile. There shall be no automatic transport downgrade.

### REQ-NET-007 — Credential lifecycle (P0)

A generated secret shall be shown only once at creation or replacement. Loss shall require replacement rather than reveal. Credentials shall not expire automatically by age.

Replacement shall allow at most current and pending versions. The pending window shall default to 24 hours and permit 1–168 hours. Expiry shall remove only the pending credential. Promotion shall require a current harmless test and explicit confirmation.

Emergency revocation shall immediately inhibit the binding, remove locally held authority when safe, and write a durable non-secret revocation record that update, configuration, and rollback cannot reverse.

## 7. Observation and policy semantics

### REQ-OBS-001 — Fresh observations (P0)

The default observation interval shall be five seconds. Qualified profiles may use 2–30 seconds.

A source shall be stale immediately when NUT says it is stale or after max(15 seconds, 3 times the observation interval) without a fresh successful observation.

An action-eligible state shall require two consecutive fresh, mutually consistent observations separated by at least one interval. The first contradictory or recovery observation shall inhibit new dispatch immediately.

OL plus OB, no recognized line-state token, WAIT, malformed tokens, or a profile-defined contradiction shall normalize to unknown.

### REQ-OBS-002 — Qualified numeric telemetry (P1)

Charge or runtime shall authorize a threshold action only when the exact UPS/driver/profile/NUT capability is qualified, the source is confirmed OB, and two fresh values meet the threshold.

No charge or runtime threshold shall be enabled or prefilled. Charge clear shall default to trip plus 2 percentage points. Runtime clear shall default to trip plus max(60 seconds, 10 percent of trip). A threshold shall fire at most once per outage episode unless a distinct later stage defines another threshold.

### REQ-OBS-003 — Telemetry-loss behavior (P0/P1)

Stale or unavailable telemetry shall inhibit new ordinary state-changing dispatch. Pending reversible timers may retain same-boot monotonic elapsed time but shall not dispatch until all evidence is fresh and revalidated.

A telemetry-loss fail-safe shall be absent by default. If explicitly activated, it shall require last-confirmed OB and continuous loss for at least max(30 seconds, 2 times the freshness deadline). It may only notify, stop a service gracefully, or request a qualified graceful host shutdown. It shall never invoke FSD, coordinator action, abrupt power, or output control.

### REQ-POL-001 — Reversible and committed phases (P0)

The policy model shall distinguish reversible work from committed shutdown. Recovery may cancel only reversible work. FSD shall never be used as a cancelable outage timer.

No outage duration shall be enabled or prefilled. A 180-second workstation delay may appear only as an explicitly configured, clearly labeled example with harmless validation.

### REQ-POL-002 — Immutable policy versions (P0)

An active policy shall be an immutable version containing exact target/action snapshots, operation/schema versions, dependencies, gates, and non-secret credential references.

Templates and target groups shall be authoring aids only. Changing a group or template shall not alter an active policy. Selecting an old version shall create a new draft and require current validation.

### REQ-POL-003 — Logical targets and bindings (P0)

A target shall represent one logical destination. Protocol endpoints and credentials shall live in separately versioned and qualified bindings.

The active NUTMerlin coordinator shall be structurally excluded from ordinary policies. Network infrastructure shall be protected by default and may appear only in an explicit terminal stage when it is no longer a control-path dependency.

### REQ-POL-004 — Typed operations and safety classes (P0)

Operations shall use closed, versioned structured schemas and declare their maximum credible class:

- observe;
- notify;
- service_graceful;
- host_graceful;
- shutdown_committed;
- power_abrupt;
- output_control.

Runtime parameters, executors, scripts, or policies shall not lower the registered class. Enabling one class shall not pre-provision credentials for a higher class.

### REQ-POL-005 — Dependencies and conflicts (P1)

Independent actions shall continue when another independent action fails. Dependencies shall be explicit and acyclic, and a dependent action shall run only when its exact evidence prerequisite is met.

Identical simultaneous intents may coalesce. Different overlapping intents shall be rejected unless their relationship is explicit. Numeric priority and a global continue-on-error flag shall not resolve ambiguity.

### REQ-POL-006 — Event-relative time (P0–P2)

Observation freshness, delay, debounce, cancellation, retry, action budget, backoff, rate, and breaker timing shall use monotonic time.

Through P2, policies shall have no calendar, cron, timezone, sunrise/sunset, or recurring schedule semantics.

### REQ-POL-007 — Restart reconciliation (P0)

Every event/result shall carry a boot identity and monotonic position. Same-boot uncommitted timing may resume only from consistent durable state. A router reboot shall restart an uncommitted timer from zero.

Committed, accepted, or outcome-unknown work shall never be re-dispatched merely because a process or router restarted.

### REQ-POL-008 — Prospective emergency inhibit (P0)

An administrator inhibit shall persistently block new episodes, commitments, and dispatch and shall cancel only undispatched reversible work.

It shall not recall accepted, unknown, or committed effects. Clearing it shall arm only future new episodes and shall not clear existing unresolved state.

## 8. Action and executor contracts

### REQ-ACT-001 — Executor interface (P0)

Every executor shall conceptually implement:

- validate(target, action);
- test(target, action);
- execute(target, action, event);
- verify(target, action, execution_result);
- describe_capabilities().

Every result shall include executor, target, policy/version, event, start/finish timestamps, dry-run state, retry count, evidence grade, status, and a bounded redacted diagnostic.

### REQ-ACT-002 — Durable dispatch intent and evidence (P0)

Immediately before a nonrepeatable external request, NUTMerlin shall append and fsync a durable dispatch intent. Ambiguity after intent shall produce outcome_unknown and shall not retry automatically.

Evidence grades shall be:

- not_dispatched;
- dispatch_rejected;
- dispatch_accepted;
- effect_verified;
- outcome_unknown.

An execute response may prove acceptance only. Only the typed verifier may prove effect. Disconnect, failed ping, or session loss shall not prove a host is Off.

### REQ-ACT-003 — Retry classes and budgets (P0)

Every operation shall declare nonrepeatable, idempotent, or idempotency_keyed semantics.

Default budgets shall be:

- connection timeout: 5 seconds, configurable 1–30;
- dispatch timeout: 30 seconds, configurable 1–300;
- verification timeout: 300 seconds, configurable 0–1800;
- total action ceiling: 3600 seconds;
- nonrepeatable: one dispatch attempt and no post-dispatch automatic retry;
- idempotent/keyed: at most three total attempts with 2-second then 5-second delays;
- one in-flight action per logical target;
- at most two concurrent executor dispatches per installation;
- at most 30 dispatch starts per rolling 60 seconds.

A policy may narrow but not exceed an operation or qualified platform ceiling.

### REQ-EXEC-001 — NUT client onboarding is not an executor (P0)

The standard secondary-client flow shall be modeled separately from the executor registry and shall create no router-side action result.

### REQ-EXEC-002 — Constrained local scripts (conditional P0)

The local-script executor shall be unavailable unless the platform qualifies unprivileged execution, process cleanup, resource limits, protected filesystem access, and UID/process-scoped no-egress without root fallback.

An imported script shall be an immutable hash-pinned POSIX /bin/sh text artifact no larger than 256 KiB and contain no NUL. It shall receive one versioned JSON document on stdin no larger than 32 KiB, return one JSON result on stdout no larger than 16 KiB, and have stderr capped at 8 KiB.

Policy input shall control no interpreter, path, argument, environment assignment, redirection, pipeline, or secret. On timeout, terminate the process group, wait two seconds, then kill the remainder.

### REQ-EXEC-003 — Restricted SSH (P1)

SSH shall use the current qualified Entware OpenSSH cohort, a dedicated target-side restricted account/forced-command wrapper, and one keypair per binding.

Ed25519 shall be the default. Qualified RSA compatibility shall use at least 3072 bits with RSA-SHA2. The exact SHA-256 host fingerprint shall be verified independently; TOFU, firmware-client fallback, DSA, SHA-1, general shells, forwarding, and PTY shall be prohibited.

### REQ-EXEC-004 — Fixed notification webhook (P1)

Generic webhook shall publish only notification.publish using one closed profile:

- lan_anonymous: credential-free HTTP or HTTPS to the confirmed trusted LAN;
- https_bearer: verified HTTPS with one binding-scoped bearer token;
- https_hmac_v1: verified HTTPS with one binding-scoped HMAC-SHA-256 key and the exact ADR 0080 framing.

The method shall be POST, content type application/json, and body the versioned normalized envelope. Policies shall not select methods, headers, query secrets, body templates, or arbitrary fragments.

Redirects shall be disabled. DNS results and the connected peer shall be scope-checked for every connection. Any 2xx shall mean delivery acceptance only. Generic webhook shall not retry after body dispatch because no receiver deduplication contract exists.

HMAC publication shall require trusted wall time. Receiver guidance shall default to 300 seconds maximum skew plus publication-ID deduplication.

### REQ-EXEC-005 — Publish-only MQTT (P1)

MQTT shall publish only normalized notification, current state, and availability messages. It shall not subscribe for commands.

MQTT v5 shall be the default with Clean Start 1 and Session Expiry 0. Explicit v3.1.1 compatibility shall use Clean Session 1. All publications shall use QoS 1. No persistent offline queue or automatic version/security downgrade shall exist.

Only current state and availability may be retained. Events and action results shall never be retained.

### REQ-EXEC-006 — Qualified WinRM (conditional P2)

WinRM shall remain absent unless a reproducible supported Entware client stack exists.

An available binding shall use verified HTTPS, a dedicated non-admin constrained JEA-equivalent endpoint, one nonrepeatable graceful shutdown request, and independent Off verification. Runtime pip installation, homegrown WSMan, Basic/plaintext, CredSSP shortcuts, unrestricted administrator endpoints, broad TrustedHosts, and hibernation shall be prohibited.

### REQ-EXEC-007 — Graceful-only Redfish (conditional P2)

Redfish shall bind manually to one exact service identity and selected ComputerSystem over TLS 1.2 or newer with verified identity and a dedicated least-privilege account.

The target-side role shall permit read plus GracefulShutdown while denying ForceOff, reset, power-on, account administration, firmware, virtual media, console, and unrelated systems. NUTMerlin shall never test dangerous denial by attempting a dangerous command.

host.graceful_shutdown shall send exactly one ResetType GracefulShutdown request. Verification shall default to 300 seconds with five-second polling and shall require two consecutive fresh Off observations. Timeout or ambiguity shall never escalate.

### REQ-EXEC-008 — Notification-only integrations (P1)

P1 shall provide no built-in SMTP, SMS, mobile, cloud, inbound MQTT, or action-capable generic webhook adapter. External systems may consume notifications and act independently outside NUTMerlin’s verification contract.

## 9. Privilege, secrets, management, and release trust

### REQ-SEC-001 — Privilege separation (P0)

A small privileged lifecycle controller shall perform fixed ownership, install, configuration, firewall, and service operations. Status, policy, and any installed WebUI processing shall be unprivileged. A narrow execution broker shall revalidate one immutable intent and expose neither a general command interface nor raw secret material.

No root network listener or root policy/UI monolith shall exist. Managed upsd shall not run as root.

### REQ-SEC-002 — Secret store (P0)

Secrets shall be stored in independently permissioned project-owned files referenced by opaque IDs.

Required modes shall be:

- secret directory: 0700;
- ordinary secret: 0600;
- NUT-readable generated material: 0640 with only the necessary group.

Secrets shall not appear in custom_settings.txt, JavaScript, status pages, logs, command-line arguments where avoidable, configuration export, support bundles, or backups. NUTMerlin shall not claim secure erasure. A filesystem that cannot preserve the required boundary shall disable secret-bearing features.

### REQ-SEC-003 — Input and path safety (P0)

Every hostname, address, username, identifier, path, duration, threshold, payload field, and operation parameter shall be validated against a closed schema. Untrusted input shall never become shell code, a command fragment, a service-event name, a header name, a query secret, or an executable path.

### REQ-SEC-004 — Transport and peer verification (P1/P2)

Secret-bearing or non-LAN webhook, MQTT, WinRM, and Redfish shall require TLS 1.2 or newer and verified server identity. Trust-all, plaintext fallback, automatic downgrade, redirects, ambiguous resolution, and peer-address drift shall fail closed.

### REQ-SEC-005 — Local management surfaces only (P0)

NUTMerlin shall expose no standalone management web server, REST API, RPC listener, remote CLI wrapper, or third-party browser asset through P2.

When the optional WebUI component is installed, the Merlin web adapter shall use the authenticated firmware origin/form/service-event path plus a one-time nonce bound to installation, management operation, candidate hash, and UI schema. The nonce shall expire after five minutes and be consumed on first attempted dispatch.

The complete local CLI and any installed curated milestone-scoped WebUI shall call the same versioned management-operation controller. CLI JSON shall be a local result format, not a network protocol. Secrets shall enter through one-time form fields, stdin, or a protected file descriptor rather than argv.

### REQ-SEC-006 — Wall-clock trust (P0)

Each boot shall begin with wall time untrusted. Trust shall require positive same-boot synchronization evidence and a plausible result. A discontinuity greater than 300 seconds against monotonic projection or a platform unsynchronized/reset indication shall revoke trust.

Untrusted wall time shall inhibit new TLS validity decisions, HMAC publication, authenticated release staging/activation, and key/certificate validity decisions. It shall never alter monotonic policy timing.

### REQ-SEC-007 — Signed release root (P0)

Every installable release shall have a detached OpenPGP signature over a canonical manifest listing version, artifacts, byte sizes, SHA-256 hashes, compatibility metadata, and installer requirement.

The release trust root shall be an offline Ed25519 primary key identified by its full pinned fingerprint. The release-signing subkey shall have at most 12 months’ validity and shall remain outside CI. Entware gpgv2 and its provenance shall be part of the release verifier gate.

Planned root transition shall be signed by old and new roots and publish both for at least 90 days and two public releases, whichever is longer. Suspected compromise shall stop publication and require manual trust bootstrap; a possibly compromised old signature shall not authorize automatic replacement.

Public release shall wait until two independent project-controlled fingerprint publication channels and an emergency replacement procedure are documented and tested.

## 10. Storage, journal, history, and export

### REQ-STOR-001 — Qualified storage semantics (P0)

Ext4 shall be the reference and recommended /opt filesystem. Another exact router/device/filesystem/mount profile shall be eligible only after proving persistent UID/GID and modes, case-sensitive names, regular/symlink/hard-link distinctions, same-directory atomic rename, file and directory fsync, reliable exclusive locking, executable Entware binaries, stable identity, and controlled interruption recovery.

FAT, VFAT, and exFAT shall be incompatible. noexec, ownership emulation, ignored chmod/chown, unstable identity, or inadequate durable rename/fsync shall be refused. noatime is recommended but not a correctness gate. SSD is recommended for always-on use.

### REQ-STOR-002 — Volatile status and bounded writes (P0)

Current poll/status data shall remain in /tmp. No persistent write shall occur for every UPS poll. Swap shall not be required or created.

### REQ-STOR-003 — Safety journal (P0)

NUTMerlin shall reserve 4 MiB on /opt for a synchronous safety journal containing only authority and reconciliation facts. A required append/fsync failure shall block new state change while permitting safe read-only diagnostics where possible.

### REQ-STOR-004 — JFFS safety anchor (P0)

Two alternating 32 KiB JFFS slots, 64 KiB total, shall conservatively anchor installation/storage identity, selected generations, lifecycle phase, journal sequence/digest, and unresolved-state flags.

The anchor shall contain no credential, private material, raw policy, target endpoint, telemetry series, operational history, or diagnostic text and shall not be written for ordinary polls or repeated health failures. Journal/anchor disagreement shall select the more restrictive state and inhibit new authority.

### REQ-STOR-005 — Operational history (P0/P1)

Default persistent history shall be:

- normalized transitions: 4 MiB or 90 days;
- action and lifecycle audit: 8 MiB or 180 days;
- redacted health/diagnostics: 4 MiB or 14 days;
- total: 16 MiB, separate from the journal.

Identical health failures shall persist on first occurrence, recovery, and at most one summary every 15 minutes. Non-safety history may buffer for at most five seconds or 10 records.

Operators may lower limits. Raising total history over 64 MiB or retention over 365 days shall require an expert setting and free-space validation.

### REQ-STOR-006 — Policy-version retention (P0)

One immutable serialized policy version shall be at most 256 KiB. The ordinary full policy store shall default to 8 MiB.

The newest 10 inactive terminal versions per policy plus versions referenced by retained 180-day action history shall be retained. Active, in-progress, committed, outcome-unknown, unreconciled, rollback, and journal-referenced versions shall never be pruned regardless of age. Exhaustion shall refuse new activation rather than delete protected evidence.

### REQ-STOR-007 — Export and support bundles (P0)

Configuration export shall contain supported non-secret reconstruction data only. Imported secrets shall become unresolved bindings and imported policies shall remain inactive pending current validation.

A public support bundle shall be allowlisted, pseudonymized with a bundle-local salt, and contain at most 24 hours or 1,000 operational records. A private bundle may retain more non-secret topology but shall still exclude every secret and private key.

Temporary bundle files shall be mode 0600, expire after 10 minutes, and be deleted after confirmed handoff where possible. NUTMerlin shall never upload a bundle automatically.

## 11. Reliability and failure behavior

### REQ-REL-001 — Preserve router service (P0)

Failure of NUTMerlin shall not intentionally interrupt routing, DNS, Wi-Fi, WAN, or other core firmware services. NUTMerlin shall use Merlin Addons API and user-script hooks and shall not permanently patch firmware files.

### REQ-REL-002 — Fail closed on ambiguity (P0)

Unknown source state, source identity ambiguity, policy conflict, unresolved action outcome, storage/journal/anchor inconsistency, foreign ownership, invalid configuration, untrusted transport, insufficient privilege, or failed activation evidence shall inhibit the affected state-changing authority.

### REQ-REL-003 — Current-state network recovery (P1)

After network recovery, notification transports shall publish current state and may publish a bounded gap summary. They shall not persist or replay stale webhook/MQTT events, and reconnection shall not verify prior effects.

### REQ-REL-004 — Bounded resources (P0)

Polling, logging, retries, queues, subprocesses, history, policy storage, and recovery loops shall remain within the fixed or qualified bounds in this document and the accepted ADRs.

## 12. Repository and development safety

### REQ-DEV-001 — Repository defaults (P0)

The project shall use public darvilp/nutmerlin, GPL-3.0-or-later, GitHub Actions, protected main, feature branches, and draft pull requests. Hardware workflows shall be manually triggered and shall not gate ordinary pull requests.

### REQ-DEV-002 — Stable local command surface (P0)

The repository shall expose stable local entry points for bootstrap, lint, unit tests, NUT integration, security checks, documentation checks, packaging, and explicitly gated hardware operations.

### REQ-DEV-003 — Hardware and destructive gates (P0)

No default command shall deploy to a router, modify the production RT-AX86U Pro, shut down a host, or require physical hardware.

Production-router mutation shall require NUTMERLIN_ALLOW_PRODUCTION_ROUTER=1. A test capable of host shutdown shall require NUTMERLIN_ALLOW_HOST_SHUTDOWN=1 plus its documented physical safeguards.

NUTMERLIN_ALLOW_UPS_COMMANDS shall not authorize any output-control operation through P2. No automated test shall issue UPS output-off.

## 13. Testability and release acceptance

### REQ-TEST-001 — Hardware-free normal tests (P0)

Normal development and CI shall use POSIX shell/static checks, platform shims, isolated filesystem roots, and NUT dummy-ups and shall require neither full firmware emulation nor physical hardware.

### REQ-TEST-002 — Complete claim layers (P0)

Host tests, package/ABI execution, simulated Merlin integration, exact-router qualification, and UPS capability qualification shall be reported as separate evidence layers. One layer shall not substitute for another.

### REQ-TEST-003 — Safety defaults (P0)

Executors shall default to dry-run in test environments. Simulators shall use harmless marker operations. Real UPS work shall begin read-only. Hardware tests shall tolerate missing/read-only /opt without state-changing action.

### REQ-TEST-004 — Required negative coverage (P0)

Tests shall cover input injection, symlink/path attacks, network-scope drift, secret redaction, untrusted clock, foreign/ambiguous ownership, every lifecycle journal boundary, torn JFFS anchors, stale/contradictory telemetry, source identity ambiguity, retry/evidence transitions, privilege fallback refusal, rollback/revocation interaction, and absence of forbidden operation classes.

## 14. P0 public-release acceptance criteria

P0 is acceptable only when:

1. Both intended current Merlin families have current qualification evidence for the exact stable releases being advertised.
2. Host tests, dummy-ups integration, current AArch64 Entware package/ABI execution, and simulated Merlin-profile tests pass.
3. At least one complete exact current-router report and one harmless physical UPS base report satisfy ADR 0064.
4. First install and every update authenticate a pinned signed manifest and artifacts; two independent fingerprint channels and the emergency replacement procedure are tested.
5. Install, repair, update, one rollback, disable, recovery, clean uninstall, and emergency detach satisfy their ownership and journal contracts.
6. One usbhid-ups source and isolated dummy-ups use immutable configuration generations and bounded service recovery.
7. One confirmed IPv4 trusted subnet can query read-only NUT status; WAN, guest, VPN, other subnet, wildcard, and default IPv6 access fail closed.
8. Each registered secondary client receives an independent once-shown restricted credential; loss, cutover, revocation, and rollback are safe.
9. A core-only install is fully operable through the complete local CLI. When the optional exact-version WebUI is installed, it shares validated management operations and exposes no management listener, arbitrary shell, raw NUT configuration, secret, or dangerous command.
10. Storage/journal/anchor failure, stale or contradictory telemetry, unknown outcomes, and conflicts inhibit new state-changing authority without disrupting router services.
11. Persistent history, support bundles, and policy versions meet their size, age, privacy, and write-endurance bounds.
12. No production FSD, writable UPS/PDU administration, ForceOff, output control, restoration, direct SNMP/PDU, hibernation, or automatic update exists.
