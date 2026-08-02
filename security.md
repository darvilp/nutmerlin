# NUTMerlin security model

## 1. Objectives and controlling invariants

NUTMerlin is security-sensitive because it combines a privileged router lifecycle, reusable credentials, power telemetry, and actions that may stop services or hosts.

The controlling invariants are:

1. NUTMerlin never weakens the router’s network perimeter by default.
2. A fresh install or upgrade is monitoring-only.
3. Foreign or ambiguous NUT state is never adopted or overwritten.
4. No untrusted value becomes shell code, a service-event name, an executable path, a header name, or an arbitrary payload.
5. Secrets are binding-scoped, shown once, minimally readable, redacted, and never restored after revocation.
6. A durable intent precedes every nonrepeatable external dispatch.
7. Unknown outcome is preserved and inhibits repetition.
8. Stale, contradictory, ambiguous, or unqualified UPS evidence cannot authorize ordinary state-changing work.
9. The coordinator router and active control-path infrastructure are protected from ordinary policies.
10. No production FSD, abrupt power, UPS/PDU output control, writable UPS administration, restoration, or remote addon-management API exists through P2.
11. No transport silently downgrades identity, encryption, protocol version, or address scope.
12. Storage/journal/anchor inconsistency fails closed for new authority.
13. The optional WebUI has no independent authority, state model, listener, release version, or ability to impair a healthy core-only installation.

Accepted ADRs under decisions/ control details and exceptions.

## 2. Trust boundaries

| Boundary | Trust assumption |
| --- | --- |
| WAN/internet | Untrusted. No NUT or addon management admission by default. |
| Guest Wi-Fi, VPN clients, other VLANs/subnets | Untrusted until a specific scope is deliberately qualified; not part of the default trusted LAN. |
| Confirmed trusted LAN subnet | Limited network trust for read-only NUT and explicitly registered native secondary credentials; not a trust boundary for arbitrary management. |
| Merlin web administrator | Privileged human session, still subject to server-side validation, exact confirmation, nonce, lifecycle, and safety gates. |
| Local router administrator/CLI | Privileged local management principal; no ability to bypass operation registration or unresolved safety state. |
| NUT read-only client | Can observe admitted NUT data only. |
| Registered NUT secondary | Holds one restricted per-client credential and owns its local shutdown behavior. |
| Executor target | Separate trust domain with independently pinned identity, credential, least privilege, and verifier. |
| Entware/opkg | Shared prerequisite outside NUTMerlin ownership. |
| /opt storage | Persistent but removable/fallible; must prove exact filesystem semantics and identity. |
| JFFS | Firmware-persistent and write-sensitive; stores only minimal code/metadata and a bounded conservative safety anchor. |
| UPS/NUT telemetry | Hardware/protocol input that may be stale, contradictory, absent, or inaccurate. |
| Release distribution | Untrusted until the pinned OpenPGP root validates the signed manifest and every artifact. |
| Imported local script | Administrator-trusted logic constrained by a qualified runtime; not hostile-code containment. |

## 3. Principal threats

| Threat | Example | Required response |
| --- | --- | --- |
| Network exposure | upsd listens on WAN, guest, wildcard, or stale LAN address | Listener plus firewall agreement; close on drift. |
| Management exposure | Custom root REST/RPC server becomes a remote execution surface | No standalone management listener through P2. |
| Credential theft | Key, password, bearer token, or HMAC value appears in UI/log/argv/export | File-permissioned secret store, once-only delivery, redaction, no reveal. |
| Command/config injection | Hostname, path, script, method, header, or NUT option escapes validation | Closed schemas, fixed operations, typed driver profiles, no arbitrary shell/raw config. |
| CSRF/replay | Authenticated browser is induced to submit an old dangerous candidate | Merlin authentication plus candidate-bound one-time five-minute nonce and server-side revalidation. |
| Supply-chain compromise | Installer, archive, key, or manifest is replaced | Independent pinned fingerprint, signed manifest, artifact size/hash verification, offline root. |
| Ownership takeover | Manual NUT deployment is mistaken for project-owned state | Refuse foreign/ambiguous state; explicit conservative recovery only. |
| Duplicate external effect | Timeout or reboot repeats a graceful shutdown | Fsync dispatch intent first; outcome_unknown; no post-intent retry for nonrepeatable work. |
| Telemetry fault/spoof | False LB or invalid runtime triggers shutdown | Freshness, contradictions as unknown, exact capability qualification, debounce, hysteresis. |
| Privilege amplification | Router compromise yields general shell/admin/BMC authority | Split privilege, target-enforced restriction, one key/credential per binding, no dormant higher authority. |
| SSRF/DNS rebinding | Webhook or Redfish reaches router admin or changes address class | Validate every resolution and connected peer; reject unsafe ranges and redirects. |
| Storage loss/replacement | Empty replacement /opt appears to clear old committed state | JFFS anchor links expected storage and detailed journal; restrictive mismatch wins. |
| Clock manipulation | Bad boot time bypasses TLS/key/HMAC validity or fires timer | Monotonic policy time; explicit wall-clock trust state. |
| Resource denial | Poll/retry/log/process storm exhausts router | Fixed freshness, breaker, budget, concurrency, rate, history, and process limits. |
| Destructive capability creep | A generic UPS command or ForceOff is hidden behind a checkbox | Operation classes are closed; abrupt/output classes absent through P2. |

## 4. Ownership and installation security

### 4.1 Entware boundary

NUTMerlin validates but never owns Entware, /opt, feed configuration, or the opkg database.

It shall not:

- download or invoke an Entware installer;
- partition, format, select, or remount Entware storage;
- run blanket opkg upgrade;
- repair the shared database/feed as a platform;
- fetch a private or older NUT binary to evade current-feed compatibility;
- remove an Entware package during ordinary uninstall.

Package mutation is limited to the declared coherent cohort after an exact plan, free-space check, provenance record, and explicit dependency policy where unattended.

### 4.2 Foreign deployment boundary

An existing NUT configuration is project-owned only when the ownership manifest, installation ID, managed artifacts, and independent evidence agree.

NUTMerlin shall not:

- infer ownership from path/name/content alone;
- import or merge a manual deployment during install;
- stop a foreign NUT process as part of its own lifecycle;
- delete a file or rule whose ownership is unproven.

Ownership recovery is an explicit fail-closed procedure. Inconsistency remains ambiguous.

### 4.3 Authenticated first install

The first-install bundle contains the release manifest, detached signature, pinned project keyring, installer, and artifacts.

Before executing project code:

1. obtain the full release-root fingerprint through an independent project-controlled channel;
2. confirm the full fingerprint;
3. verify the manifest signature with the pinned keyring;
4. verify every declared artifact name, byte size, and SHA-256 hash;
5. inspect the candidate version/compatibility and execute locally.

No curl-pipe or first-seen adjacent key is accepted.

An unsupported-platform acknowledgment is not a safety bypass. Experimental, compatibility-only, or legacy installation remains monitoring-only and is eligible only after every core ownership, hook, firewall, identity, mount, and boot probe succeeds. Unknown or incompatible core evidence refuses mutation; optional capability failures grant no fallback authority.

Public release is blocked until two independent project-controlled fingerprint channels and a tested emergency root-replacement procedure are selected. This is unresolved release research, not permission to weaken bootstrap.

### 4.4 Release signing and rotation

- Dedicated offline Ed25519 primary certification key.
- Primary private key never in CI, routers, or ordinary workstations.
- Dedicated release-signing subkey, maximum validity 12 months.
- Canonical completed manifest signed only after required evidence passes.
- Entware gpgv2 verifier and provenance included in package/ABI evidence.
- Planned subkey rotation certified before expiry.
- Planned root transition dual-signed and published for at least 90 days and two releases, whichever is longer.
- Suspected compromise stops publication/update guidance.
- A possibly compromised old root cannot automatically authorize its replacement.
- Primary-key revocation certificate created at root generation and stored independently offline.

### 4.5 Update, configuration, and rollback activation

Staging may occur only in an explicit administrator update session. Activation requires the safe update window or explicit maintenance disablement.

During activation:

- action and external NUT surfaces close;
- the candidate release/configuration pair is selected atomically through its journaled transaction;
- health runs for 120 continuous seconds and at least 24 fresh observations;
- no new policy, credential, listener, or executor authority is enabled;
- candidate failure receives one rollback attempt.

Rollback begins monitoring-only, revalidates exact state, and cannot restore a revocation, unknown outcome, retry budget, or unsafe previous authority. Manual rollback always requires explicit reactivation.

The core and optional WebUI artifacts are authenticated by the same release manifest and may never run at different release or management-schema versions. If the matching UI cannot accompany an update, the administrator must explicitly postpone the core update or approve UI removal. Removing the UI invalidates outstanding nonces and preserves all core configuration, credentials, journals, history, services, and CLI access.

## 5. Network and management security

### 5.1 NUT listener/firewall gate

Default external NUT access is:

- one administrator-confirmed IPv4 trusted source subnet;
- one exact router LAN listener;
- TCP 3493 only;
- credential-free read-only status;
- registered secondary credentials only when explicitly created.

Default denial includes WAN, guest, VPN-client, other VLAN/subnet, wildcard listeners, and IPv6.

IPv6 opt-in requires an exact trusted LAN address/prefix, independent denial from untrusted interfaces, and administrator confirmation. Prefix/scope ambiguity removes stale rules and closes IPv6.

The listener and firewall must agree on:

- activation;
- every managed service restart;
- relevant firewall hook;
- at least every 300 seconds.

Any mismatch closes the exposure. A broad listener has no expert override.

### 5.2 Shutdown-client roles

Fresh install creates no shutdown credential. Each registered client receives a unique randomly generated credential with only the upsmon secondary role.

Client onboarding never grants:

- upsmon primary;
- FSD;
- SET;
- instant commands;
- addon management;
- a shared credential.

Native non-TLS credentials are permitted only within the exact trusted LAN. Verified NUT TLS is optional when independently qualified; there is no downgrade.

### 5.3 Local management only

NUTMerlin exposes no custom management web server, REST API, RPC listener, remotely callable CLI, or reusable web API token through P2.

When the optional WebUI component is installed, the web adapter:

- runs inside the authenticated Merlin origin;
- uses documented form/service-event protections;
- accepts only fixed versioned management-operation IDs and validated fields;
- requires a nonce bound to installation, operation, candidate hash, and UI schema;
- expires the nonce after five minutes;
- consumes it on first attempted dispatch;
- revalidates authentication context, nonce, candidate, current state, confirmation, and authorization server-side;
- serves only sanitized bounded status artifacts;
- uses no third-party scripts, remote fonts, analytics, or browser credential persistence.

The complete CLI calls the same local controller without HTTP. State-changing CLI operations require appropriate local router-administrator authority and operation-specific confirmation.

### 5.4 Input and shell safety

- Target POSIX /bin/sh where shell is required; never assume Bash.
- Never use eval with external or stored input.
- No untrusted interpolation into shell, sh -c, command substitution, environment assignment, redirection, pipeline, service-event name, or executable path.
- Validate every identifier, hostname, address, CIDR, port, path, duration, threshold, operation value, and document against a closed schema and bounds.
- Normalize project paths and reject traversal, unexpected symlinks, ownership drift, or filesystem object-type changes.
- Use fixed argument vectors and -- where supported.
- Create temporary objects with restrictive mode and unpredictable project-scoped names.
- Driver profiles and webhook profiles are closed; raw NUT configuration, arbitrary methods/headers/payloads, and arbitrary command fields do not exist.

## 6. Privilege and credential security

### 6.1 Process privilege

The privileged lifecycle controller and execution broker are narrow local authorities. Status, policy, and any installed WebUI code are unprivileged. There is no root network listener or root monolith.

Each executor credential is provisioned for the least powerful enabled operation set. Enabling host_graceful does not pre-provision shutdown_committed, power_abrupt, output_control, or administrative authority.

### 6.2 Secret storage

Secrets use independent files referenced by opaque IDs:

- directory mode 0700;
- ordinary secret mode 0600;
- NUT-readable generated material mode 0640 with only the necessary group.

Secrets never appear in:

- Merlin custom_settings.txt;
- JavaScript, HTML, status JSON, URLs, or browser persistence;
- source control;
- logs, diagnostics, or response bodies;
- configuration export or support bundle;
- command-line arguments where avoidable;
- general backup artifacts.

NUTMerlin does not claim application encryption improves a router that must hold the decrypting key, and it does not claim secure erase on flash. A filesystem that ignores required UID/GID/modes makes secret-bearing features unavailable.

### 6.3 Once-only delivery and cutover

A new secret is shown once. Loss requires replacement.

A binding/client has at most one current and one pending credential. Pending defaults to 24 hours and may be 1–168 hours. Expiry deletes pending only; it never disables current.

Promotion requires:

- current harmless authentication/capability evidence using pending;
- explicit administrator confirmation;
- a new validated configuration/binding generation;
- invalidation and regeneration of affected activation evidence.

Emergency revocation immediately inhibits the binding and creates a durable non-secret tombstone. Rollback and last-known-good configuration may not restore the revoked version. For externally owned credentials, NUTMerlin reports the target-side revocation work and does not claim completion without evidence or explicit administrator confirmation.

Age alone never rotates or expires a secondary-client credential.

## 7. Policy and action security

### 7.1 Observation gate

Default polling is five seconds. The source is stale when NUT reports stale or after max(15 seconds, three observation intervals).

Two consistent fresh observations are required for action eligibility. The first contradictory/recovery sample inhibits immediately. OL+OB, WAIT, malformed tokens, absent recognized line state, and profile-defined contradiction are unknown.

Numeric charge/runtime values can authorize work only when the exact capability is qualified and the source is confirmed OB. They never override stale or contradictory categorical state.

### 7.2 Monitoring-only and activation evidence

Saving a target, binding, or policy does not grant authority.

Activation requires:

- static closed-schema and conflict validation;
- current harmless binding tests;
- exact expanded policy dry-run;
- displayed warnings and effects;
- explicit administrator confirmation;
- candidate-specific evidence no older than 24 hours.

Relevant configuration, identity, credential, version, network, privilege, or capability drift invalidates evidence.

### 7.3 Reversible versus committed

A reversible timer may cancel after confirmed recovery. A committed sequence continues according to its captured policy version.

FSD is not a reversible timer. Production FSD is absent until the complete lifecycle is accepted and qualified.

Communication loss is not LB or FSD. The optional fail-safe is absent by default and, when explicitly enabled, can only notify or request qualified graceful service/host action after last-confirmed OB and at least max(30 seconds, twice freshness) continuous loss.

### 7.4 Target protection and conflicts

- The active coordinator router cannot appear in an ordinary policy.
- Network/control-path infrastructure is protected by default.
- Target groups have no built-in noncritical/important/critical authority.
- Active policies contain exact target/action snapshots.
- Dependencies are explicit and acyclic.
- Identical intent may coalesce.
- Different overlapping intent is rejected unless explicitly related.
- Numeric priority and global continue-on-error do not resolve safety conflicts.

### 7.5 Dispatch and retry

Immediately before a nonrepeatable external request, append/fsync dispatch intent to the detailed journal, then update the JFFS safety anchor before effecting the request.

Operation retry classes are registry-controlled:

- nonrepeatable: one dispatch, no post-dispatch retry;
- idempotent or idempotency_keyed: at most three attempts with 2- then 5-second delays.

Timeouts and resource limits follow ADR 0048. An unknown result is durable. Reboot, update, rollback, credential rotation, disable, inhibit, or uninstall cannot convert unknown into not_dispatched.

### 7.6 Safety classes

Every operation declares its maximum credible class:

1. observe;
2. notify;
3. service_graceful;
4. host_graceful;
5. shutdown_committed;
6. power_abrupt;
7. output_control.

The highest possible effect controls. User parameters, scripts, executors, or policies cannot lower the class. power_abrupt and output_control are absent from P0–P2 registries.

NUTMERLIN_ALLOW_UPS_COMMANDS cannot register, authorize, or test an output_control operation.

## 8. Executor security

### 8.1 Local script

The P0 local-script capability is available only when the exact platform qualifies:

- dedicated unprivileged identity;
- no root fallback;
- inaccessible secret store/journal;
- immutable read-only imported artifact;
- private transient working directory and restrictive umask;
- bounded file/process/CPU resources and no core dump where supported;
- reliable process-group cleanup;
- UID/process-scoped denial of LAN, WAN, loopback control endpoints, and other network egress.

The script is POSIX sh text up to 256 KiB with no NUL. Input is one JSON document on stdin up to 32 KiB; stdout is one JSON result up to 16 KiB; stderr is diagnostic-only up to 8 KiB. No policy-controlled argv, interpreter, path, environment, redirection, pipeline, or secret exists.

These controls constrain administrator-trusted code; they are not presented as a hostile-code sandbox.

### 8.2 SSH

- Current qualified Entware OpenSSH only; no firmware-client fallback.
- Unique keypair per binding.
- Ed25519 default; qualified RSA is at least 3072 bits and RSA-SHA2.
- Exact independently verified SHA-256 host fingerprint; no TOFU.
- Binding-owned SSH configuration/known-host state.
- Target-enforced forced command or equivalent restricted wrapper.
- Dedicated low-privilege target account.
- No general shell, PTY, agent forwarding, port forwarding, DSA, or SHA-1.
- Verification remains operation-specific; disconnect is not Off proof.

### 8.3 Webhook

P1 has three closed profiles:

- lan_anonymous: credential-free HTTP/HTTPS notification to the confirmed trusted LAN;
- https_bearer: verified HTTPS plus one binding bearer token;
- https_hmac_v1: verified HTTPS plus one binding HMAC-SHA-256 key and exact signed framing.

All use fixed POST application/json and the normalized notification envelope. Redirects are always disabled. Every resolved address and connected peer is checked; router-owned, unspecified, loopback, link-local, multicast, broadcast, or scope-crossing destinations are rejected.

Any HTTP 2xx proves delivery acceptance only. Generic webhook is nonrepeatable after body dispatch. HMAC publication requires trusted wall time; receiver guidance defaults to 300-second skew plus publication-ID deduplication.

### 8.4 MQTT

- Publish only; no subscriptions or commands.
- MQTT v5 default: Clean Start 1, Session Expiry 0.
- Explicit v3.1.1 compatibility: Clean Session 1.
- QoS 1 and no persistent offline queue.
- Retained messages only for current state and availability.
- Events/results never retained or stale-replayed.
- Stable scoped client/topic identity.
- TLS 1.2+ with verified identity for credentials or non-LAN destinations.
- Anonymous plaintext only for non-sensitive publication inside the confirmed trusted LAN.
- No automatic protocol or transport downgrade.

### 8.5 WinRM

WinRM is unavailable unless a reproducible supported Entware client stack qualifies.

When available:

- verified HTTPS;
- dedicated non-admin identity;
- constrained JEA-equivalent endpoint;
- exact graceful-shutdown operation only;
- one nonrepeatable dispatch;
- independent Off verifier.

No runtime pip, homegrown WSMan, Basic/plaintext, CredSSP shortcut, unrestricted administrator endpoint, broad TrustedHosts, hibernate, or disconnect-as-proof.

### 8.6 Redfish

Redfish is manually bound to one exact selected ComputerSystem:

- TLS 1.2+ and verified service identity;
- no LAN-wide discovery or redirects;
- dedicated per-binding account and session auth when qualified;
- target-side role permitting read and GracefulShutdown while denying ForceOff, reset, power-on, account/firmware/console/virtual-media/unrelated-system authority;
- denial proven only through non-actuating evidence, never a dangerous probe;
- one nonrepeatable ResetType GracefulShutdown request;
- 300-second default verification, five-second poll, two consecutive fresh Off observations;
- no escalation on timeout or ambiguity.

A BMC whose narrowest available role necessarily grants broader power authority is not a P2-qualified binding.

### 8.7 Prohibited early adapters

Through P2 there is no:

- direct SNMP/PDU implementation;
- raw upscmd/upsrw;
- beeper/test/calibration or other writable UPS administration;
- ForceOff, hard reset, power-on, outlet, output-off/cycle/delay;
- inbound MQTT;
- action-capable generic webhook;
- root local script;
- target restoration;
- production FSD.

Read-only network UPS/PDU data may enter only through an accepted NUT driver profile.

## 9. Storage, journal, and clock security

### 9.1 Qualified storage

Ext4 is the reference. Exact storage qualification must prove native UID/GID and modes, case semantics, object/link distinctions, same-directory atomic rename, file and directory fsync, exclusive locking, executable Entware binaries, stable identity, and controlled interruption recovery.

FAT, VFAT, and exFAT are incompatible. noexec, permission emulation, ignored modes, unstable identity, or inadequate durability closes secret/action capability.

### 9.2 Safety journal and JFFS anchor

The /opt safety journal has a reserved 4 MiB capacity. It holds policy activation, commitment, dispatch intent, unknown outcome, lifecycle/config transactions, and recovery facts.

JFFS holds two alternating 32 KiB anchor slots. The anchor contains only conservative identity, generation, transaction, journal digest/sequence, storage fault, and unresolved-state flags.

For a safety transition:

1. append and fsync the detailed /opt fact;
2. write and fsync the next JFFS anchor slot;
3. only then issue an external effect or selector change.

Mismatch, corruption, future schema, missing/read-only JFFS, or expected-storage mismatch selects the more restrictive state and blocks new authority. Per-poll status and operational history never write the anchor.

### 9.3 Wall-clock trust

Policy time is monotonic. Wall clock begins untrusted every boot and becomes trusted only after positive same-boot synchronization evidence.

Trust is revoked by:

- a greater-than-300-second discontinuity versus monotonic projection;
- a platform-reported unsynchronized/reset state;
- an implausible value.

While untrusted, block new TLS sessions/validity decisions, HMAC publication, authenticated release staging/activation, and key/certificate validity decisions. Do not shorten, lengthen, fire, cancel, or reorder monotonic policy work.

## 10. Logging, export, and privacy

Operational history is bounded and separate from the safety journal:

- transitions: 4 MiB or 90 days;
- actions/lifecycle: 8 MiB or 180 days;
- health/diagnostics: 4 MiB or 14 days;
- total: 16 MiB.

Repeated identical health failure persists on first occurrence, recovery, and no more than one aggregate every 15 minutes. Non-safety history may buffer for at most five seconds or 10 records.

Logs may include:

- boot/event/policy/target/binding/operation IDs;
- safety class and evidence grade;
- monotonic and wall timestamps with trust marker;
- dry-run, attempts, start/finish, bounded redacted diagnostic;
- lifecycle/configuration/source/network/storage health identifiers.

Logs, exports, and bundles must omit:

- passwords, tokens, private keys, HMAC keys, authorization headers;
- raw secret references that reveal a value;
- sensitive command/payload output;
- unnecessary serial numbers/usernames;
- raw policy or topology detail from the public bundle.

Public bundles pseudonymize identifiers with a bundle-local non-reusable salt and include at most 24 hours or 1,000 records. Temporary bundles are mode 0600 and expire after 10 minutes. There is no automatic upload.

## 11. Required security tests

At minimum:

- WAN, guest, VPN-client, other-subnet, wildcard, and default IPv6 cannot reach TCP 3493.
- Listener/firewall drift closes exposure on activation, restart, hook, and periodic check.
- Native secondary credentials cannot authenticate outside the admitted trusted scope.
- Per-client revocation does not affect another client and rollback cannot restore a revoked version.
- Once-shown secrets never appear in UI source, status, argv, logs, exports, bundles, or backups.
- Malicious hostname, address, path, identifier, driver option, JSON field, webhook input, or script metadata cannot inject shell/config/path behavior.
- Symlink/object-type/ownership changes invalidate generations and owned artifacts.
- Web nonces expire, consume on first attempt, reject replay, and cannot authorize a changed candidate.
- No management listener or remote CLI wrapper exists.
- Release verification rejects first-seen keys, bad signatures, unlisted files, hash/size changes, expired/revoked signing authority, untrusted clock, and unsafe root transition.
- Foreign and ambiguous deployments remain untouched; ownership recovery rejects partial/inconsistent evidence.
- Every lifecycle/configuration journal interruption recovers conservatively.
- Torn/conflicting JFFS anchors and replaced /opt cannot clear unresolved state.
- Stale, contradictory, flapping, or unqualified numeric telemetry cannot dispatch ordinary state-changing work.
- Retry, timeout, restart, rollback, and inhibit cannot duplicate a nonrepeatable unknown action.
- Target conflict and unmet dependency fail closed while independent actions may continue.
- Local script is unavailable when any privilege/no-egress/resource boundary cannot be proven.
- SSH rejects host-key drift and cannot obtain a general shell.
- Webhook rejects redirects, invalid TLS, unsafe resolutions/peers, arbitrary payload/header changes, and post-body retry.
- MQTT never subscribes, persists a session/outbox, or retains event/action results.
- WinRM remains absent without the qualified stack/endpoint/verifier.
- Redfish cannot select an ambiguous system, use a broad role, attempt ForceOff/reset/on, or escalate on timeout.
- The installed P0–P2 registry contains no production FSD, power_abrupt, output_control, writable UPS, restoration, direct SNMP/PDU, or inbound-control operation.
- No automated test issues UPS output-off.
