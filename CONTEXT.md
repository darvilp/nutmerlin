# NUTMerlin

NUTMerlin is the domain of safely integrating Network UPS Tools with Asuswrt-Merlin routers and optional power-event orchestration.

**Capability milestone**:
A scope and evidence boundary for one product capability; P0 core support is independent from optional P1/P2 adapters, and a milestone label never bypasses qualification.
_Avoid_: Release date, blanket platform feature promise

## Platform support

**Supported platform**:
A router environment included in NUTMerlin's published compatibility contract. Regressions on it may block a release, and it receives maintained lifecycle and security compatibility expectations.
_Avoid_: Compatible platform

**Legacy best-effort platform**:
An upstream-end-of-life router environment that NUTMerlin may test or accommodate when useful, without a release-blocking compatibility or security-support promise.
_Avoid_: Supported legacy platform

**Compatibility-only platform**:
A router environment outside the published support contract on which NUTMerlin may still work, without a promise that compatibility will be tested or maintained.
_Avoid_: Effectively supported, probably supported

**Qualified hardware**:
An exact router model and hardware revision for which the defined NUTMerlin hardware matrix has passed on a supported platform. Qualification is published evidence, not a separate support tier.
_Avoid_: Supported model

**Known-incompatible hardware**:
A router model or hardware revision with reproducible evidence that a mandatory capability cannot operate safely. Its incompatibility overrides general platform eligibility.
_Avoid_: Unknown hardware

**Release evidence layer**:
One explicitly bounded kind of test evidence—host conformance, package/ABI execution, simulated Merlin integration, exact-router qualification, or UPS capability qualification—whose claims do not substitute for another layer.
_Avoid_: Test tier, full compatibility test

**NUT-compatible source**:
A uniquely identified UPS that the packaged NUT driver can monitor and that passes NUTMerlin's mandatory harmless base probes, without implying qualification of every reported field or command.
_Avoid_: Supported UPS, qualified UPS

**Authoritative UPS source**:
The one real, uniquely identified NUT driver source whose fresh observations may govern production status and policies for an installation through P2.
_Avoid_: Available UPS, fallback source, simulated source

**NUT driver profile**:
A versioned NUTMerlin contract for one packaged driver defining its typed options, identity, privilege, rendering, lifecycle, probes, and migration behavior.
_Avoid_: Driver name, raw ups.conf, NUT compatibility

**Isolated simulation source**:
A visibly marked `dummy-ups` maintenance source confined to loopback with external clients, policies, and executors disabled.
_Avoid_: Test mode on production UPS name, automatic fallback

**Direct device protocol**:
A UPS or PDU transport and vendor-data implementation owned by NUTMerlin rather than supplied through the qualified Entware NUT driver layer; direct SNMP/PDU protocols are outside P0 through P2.
_Avoid_: NUT executor, NUT-reported network source

**UPS capability qualification**:
Reproducible evidence that one exact UPS, firmware/revision where known, driver, and NUT-version combination satisfies one named monitoring or telemetry capability contract.
_Avoid_: Device support, NUT compatibility

## Deployment ownership

**NUTMerlin-owned deployment**:
An installation whose managed artifacts are attributable to NUTMerlin through valid project ownership evidence.
_Avoid_: Default NUT installation

**NUT configuration generation**:
An immutable complete, hashed, permissioned set of managed NUT files selected as one unit and supplied to every process in a service epoch through `NUT_CONFPATH`.
_Avoid_: Config backup, individual active file

**Foreign NUT deployment**:
An existing NUT installation or configuration owned manually or by another manager rather than NUTMerlin.
_Avoid_: NUTMerlin installation

**Ambiguous ownership**:
A state in which NUTMerlin cannot establish whether existing NUT artifacts are project-owned or foreign.
_Avoid_: Probably owned

**Ownership manifest**:
The authoritative inventory connecting a NUTMerlin installation to the artifacts it manages.
_Avoid_: File list

**Installation ID**:
A non-secret identifier unique to one NUTMerlin installation and shared by its ownership evidence.
_Avoid_: Credential, instance secret

**Ownership recovery**:
An explicit operation that reconstructs a missing or corrupt ownership manifest only from consistent NUTMerlin ownership evidence.
_Avoid_: Adoption, ownership guessing

## Release lifecycle

**Release slot**:
One complete staged or active NUTMerlin selected-component set retained as a unit for activation or rollback; it always contains the core and may contain its exact-version WebUI.
_Avoid_: File backup

**Core component**:
The required NUTMerlin installation containing router lifecycle integration, NUT management, persistent state, the complete local CLI, and every authority-bearing backend; it remains fully manageable without a web interface.
_Avoid_: CLI-only edition, headless variant

**WebUI component**:
An optional, exact-version-matched Merlin Addons API adapter that depends on the core component and owns only its web assets, registration, and transient browser-operation state.
_Avoid_: Built-in WebUI, standalone web application, management server

**Update journal**:
A bounded record of the durable phases of an install or upgrade transaction, used to resume or roll back safely after interruption.
_Avoid_: Activity log

**Authenticated release**:
A NUTMerlin release whose signed manifest verifies through a previously trusted pinned public key and whose artifacts match the manifest.
_Avoid_: Checksummed release

**Release manifest**:
Signed release metadata identifying the version, artifacts, hashes, sizes, compatibility, and installer requirements of one NUTMerlin release.
_Avoid_: Checksum file

**Release trust root**:
The pinned OpenPGP primary-key fingerprint and verification keyring from which accepted release-signing subkeys and planned rotations derive authority.
_Avoid_: Release key, downloaded public key

**Authenticated first-install bundle**:
The locally staged manifest, signature, verified project keyring, installer, and artifacts whose root fingerprint is independently confirmed before any project code executes.
_Avoid_: Bootstrap script, curl pipe, checksum install

**Safe update window**:
The activation prerequisite that NUTMerlin is either stably online with no active or unresolved automation, or explicitly disabled in maintenance mode and kept disabled after validation.
_Avoid_: Update availability, maintenance period

**Rollback quarantine**:
The monitoring-only state in which a restored previous release must reconcile exact durable state and pass 120 seconds plus 24 fresh observations before any eligible prior authority may return.
_Avoid_: Pointer rollback, immediate downgrade

**Disable**:
A reversible lifecycle operation that makes NUTMerlin inactive and closes its action and network surfaces while retaining its installation and data.
_Avoid_: Uninstall

**Uninstall**:
A destructive lifecycle operation that removes all verified NUTMerlin-owned artifacts and data while preserving foreign artifacts and Entware packages.
_Avoid_: Disable, pause

**Emergency detach**:
An incomplete broken-storage operation that removes only independently verified router activation hooks and exposure while preserving ownership evidence and inaccessible data for later cleanup.
_Avoid_: Force uninstall, clean removal

**Storage fault latch**:
A durable inhibition of policy and executor activation after unexpected loss, read-only remount, or integrity failure of the active Entware storage, cleared only after state reconciliation and explicit administration.
_Avoid_: Offline flag, mount retry

**Safety journal**:
The bounded durable record of policy activation, episode commitment, dispatch intent, unknown outcome, and recovery reconciliation that must remain writable independently of rotating operational history.
_Avoid_: Audit log, event history

**JFFS safety anchor**:
The two-slot 64 KiB conservative identity, generation, transaction, journal-digest, and unresolved-state latch that survives independently of `/opt` without duplicating detailed history.
_Avoid_: Second journal, JFFS event log

**Operational history**:
Bounded persistent transition, action, lifecycle, and redacted diagnostic records retained for operator understanding but not used as the sole authority for action recovery.
_Avoid_: Telemetry database, safety journal

**Configuration export**:
A versioned reconstruction artifact containing supported non-secret configuration whose imported policies and unresolved bindings remain inactive until revalidated.
_Avoid_: Backup, diagnostic bundle

**Public support bundle**:
An allowlisted, pseudonymized diagnostic artifact intended for community sharing and materially more private than an administrator-only configuration or support export.
_Avoid_: Redacted backup, log archive

**Restart reconciliation**:
The startup process that distinguishes same-boot monotonic recovery from a new boot, preserves deduplication, and inhibits action while durable outcome is unresolved.
_Avoid_: Resume timer, startup retry

**Service restart circuit breaker**:
A bounded restart state that suppresses repeated NUT service starts after a defined failure budget and permits only controlled recovery probes.
_Avoid_: Infinite retry, failed service flag

## Dependency management

**Entware prerequisite**:
The preexisting healthy shared package environment NUTMerlin validates before scoped dependency mutation but never bootstraps, repairs as a platform, or owns.
_Avoid_: Bundled Entware, NUTMerlin storage

**Qualified storage profile**:
An exact router, device, filesystem, and mount-option combination proven to enforce the ownership, permission, rename, fsync, locking, execution, and identity semantics NUTMerlin requires; ext4 is the reference.
_Avoid_: Supported filesystem name, healthy USB drive

**Package provenance**:
The record of whether an Entware package predated NUTMerlin or was installed by this NUTMerlin installation.
_Avoid_: Package ownership

**Package cleanup**:
An explicit operation that may remove eligible NUTMerlin-installed Entware packages after a dry-run and safety checks.
_Avoid_: Uninstall

**Gold-standard package set**:
The current Entware packages against which a NUTMerlin release is qualified. NUTMerlin adapts to this set rather than requiring an older package set.
_Avoid_: Pinned package set

**Compatibility-only package cohort**:
An internally consistent older Entware package set permitted to run after mandatory probes, without current qualification or a maintenance promise.
_Avoid_: Supported older packages

## NUT access

**Source identity constraint**:
The exact validated USB attributes that must resolve to one and only one configured UPS before a NUT driver may bind it.
_Avoid_: USB port, first compatible UPS

**Read-only NUT access**:
Unauthenticated NUT protocol access to status and identity data, admitted or denied by the listener and network firewall boundary.
_Avoid_: Read-only credential

**Trusted LAN scope**:
An explicitly confirmed LAN source subnet admitted for native NUT protocol access; read-only status is unauthenticated within it, while shutdown roles require credentials.
_Avoid_: Every local interface, all private networks

**Network exposure gate**:
The requirement that the effective NUT listener and independently verified source-filter rules both match the administrator-confirmed scope before external access is active.
_Avoid_: LAN bind, firewall warning

**Shutdown client**:
A host explicitly registered with the restricted NUT `upsmon secondary` role that owns its own outage policy and local shutdown command.
_Avoid_: Centrally managed host, executor target

**Shutdown-client credential**:
An independently generated NUT credential granting exactly one registered shutdown client the `upsmon secondary` role.
_Avoid_: Shared monitor password, read-only credential

**One-time secret delivery**:
Product-mediated disclosure of a newly generated credential only during creation or replacement, after which normal interfaces cannot reveal the stored value.
_Avoid_: Password recovery, reveal password

**Credential cutover**:
The explicit bounded transition from one current credential to one harmlessly tested pending version, defaulting to 24 hours and never promoting automatically.
_Avoid_: Password rotation, immediate overwrite, dual permanent secrets

**Credential revocation record**:
A durable non-secret version tombstone that prevents a revoked credential from regaining authority through configuration or release rollback.
_Avoid_: Deleted secret, audit message

**Secret store**:
The project-owned collection of independently permissioned credential files referenced by opaque IDs and accessible only to the minimum broker or NUT process that needs them.
_Avoid_: Encrypted vault, settings file

**Privileged lifecycle controller**:
The small router-local authority for fixed installation, ownership, firewall, configuration, and service-lifecycle operations; it exposes no network listener or general command surface.
_Avoid_: NUTMerlin daemon, root policy engine

**Execution broker**:
A narrow local authority that revalidates one immutable action intent and uses only its referenced binding capability and secret without returning raw credential material.
_Avoid_: Secret broker, command runner

**Management operation**:
A typed administrator request with shared validation, preview, authorization, transaction, result, and audit semantics used by the CLI and any web UI adapter.
_Avoid_: CLI command, service-event string

**Web operation nonce**:
A one-time five-minute authorization value bound to one exact web management-operation candidate in addition to Merlin's authenticated form and service-event protections.
_Avoid_: API token, reusable CSRF bypass

**Activation evidence**:
The candidate-specific record of current validation, harmless binding tests, policy dry-run, and resolved warnings required to create an executable immutable policy version.
_Avoid_: Test passed, activation confirmation

## Outage action semantics

**Fresh observation**:
A successful NUT status read within the source freshness deadline, carrying a syntactically valid and noncontradictory status token set plus its local monotonic observation time.
_Avoid_: Latest value, cached status

**Confirmed state**:
An actionable normalized state supported by the required consecutive fresh observations; a first contradictory or recovery observation inhibits dispatch even before the replacement state is confirmed.
_Avoid_: Debounced display value, last-known state

**Qualified telemetry field**:
A NUT variable whose availability and behavior on a specific UPS and driver combination have sufficient recorded evidence for policy use; mere presence makes a value displayable, not action-authoritative.
_Avoid_: Supported variable, valid number

**Telemetry-loss fail-safe**:
An explicitly activated policy path that may take bounded graceful action after prolonged communication loss only when the last confirmed state was on battery.
_Avoid_: Dead UPS means low battery, communication-loss default

**Monitoring-only default**:
The activation posture in which NUTMerlin may collect status and maintain bounded local event history, but has no enabled policy actions, executor dispatch, shutdown-role credentials, or outbound publication.
_Avoid_: Safe default policy, notification-only default

**Prospective automation inhibit**:
A durable emergency gate that stops new episodes and new uncommitted dispatch while preserving already accepted, unknown, or committed meaning and leaving independent NUT clients untouched.
_Avoid_: Stop all, cancel shutdown, process kill

**Notification-only policy**:
An explicitly activated policy containing only `notify`-class publication operations and carrying no authority for service, host, committed, abrupt-power, or output-control action.
_Avoid_: Monitoring-only default, external action protocol

**Coordinator router**:
The Asuswrt-Merlin router hosting a NUTMerlin installation; it is structurally unavailable as an ordinary policy target, and its shutdown belongs only to a complete FSD workflow.
_Avoid_: Router target, local host target

**Protected infrastructure target**:
An external network device excluded from policy actions by default and eligible only in an explicit terminal infrastructure stage when it is not a control-path dependency.
_Avoid_: Critical target, permanently excluded network device

**Control-path dependency**:
A device or service whose continued availability is required to dispatch, observe, or verify work that remains in the current policy episode.
_Avoid_: Important device, same-subnet target

**Reversible outage timer**:
A pending delay that is canceled when its declared recovery event occurs before the policy crosses its commit boundary.
_Avoid_: FSD timer, guaranteed cancelable shutdown

**Commit boundary**:
The durable transition after which a policy action is treated as noncancelable even if utility power or telemetry recovers.
_Avoid_: Action completion

**Committed shutdown**:
A shutdown sequence that continues according to policy after its commit boundary; NUT FSD is one advanced committed mechanism.
_Avoid_: Long timer, reversible FSD

**Complete FSD workflow**:
A production NUT primary/secondary sequence defining router shutdown, secondary synchronization, power-down flag, UPS output behavior, and power-restoration recovery as one committed lifecycle.
_Avoid_: FSD broadcast, signal-only FSD

**Output-cutting operation**:
An UPS or PDU action capable of removing, cycling, or delaying power to one or more connected loads; all such operations are outside P1/P2 and remain `Later`.
_Avoid_: Administrative command, ordinary load shedding

**Writable UPS administration**:
Any NUT variable write or instant command directed at UPS or PDU behavior, including apparently benign beeper or self-test operations; all are outside P0 through P2.
_Avoid_: Harmless UPS command, discovered capability

**Graceful-only Redfish binding**:
A P2 BMC execution path limited to capability discovery, power-state query, `GracefulShutdown`, and bounded verification, with no abrupt power operation.
_Avoid_: Force-off fallback, timeout escalation

**Redfish system identity**:
The verified service identity and exact ComputerSystem resource to which one graceful-only binding is pinned, preventing discovery or redirects from changing the managed host.
_Avoid_: BMC address, first discovered system

**Constrained WinRM binding**:
A Windows remoting path using a dedicated non-administrator identity and JEA-equivalent endpoint limited to NUTMerlin typed operations.
_Avoid_: Administrator PowerShell session, TrustedHosts shortcut

**Qualified WinRM client stack**:
A reproducible, signed-release or current-Entware WS-Man and authentication dependency cohort proven on every supported architecture before the WinRM executor may be advertised.
_Avoid_: Runtime pip install, built-in WinRM support

**Unknown action outcome**:
An execution state in which dispatch may have reached the target but no reliable result or verification establishes what occurred.
_Avoid_: Failure, safe to retry

**Retry classification**:
An action-level capability—`nonrepeatable`, `idempotent`, or `idempotency_keyed`—that limits but cannot be expanded by policy retry settings.
_Avoid_: Executor-wide retry count, policy override

**Action budget**:
The operation-bounded connection, dispatch, verification, retry, concurrency, and rate limits within which one policy action may run.
_Avoid_: Timeout, retry count

**Action prerequisite**:
An action result whose explicitly required evidence must be successful before one or more dependent actions may become eligible.
_Avoid_: Earlier action, previous stage

**Action intent**:
The canonical target, typed operation, parameters, source episode, and commitment semantics used to detect duplicate or conflicting state-changing work across policies.
_Avoid_: Action ID, executor request

**Executor**:
A protocol or local-process adapter that actively attempts a typed action against a target and reports a structured execution outcome.
_Avoid_: Shutdown-client onboarding, expected client behavior

**Target**:
A stable logical destination for policy actions, grouping, exclusions, and target-level safety gates, independent of any one access protocol.
_Avoid_: Hostname, executor endpoint

**Target group**:
An authoring and display label that may help expand a policy draft but grants no authority and is replaced by exact target snapshots before activation.
_Avoid_: Live shutdown tier, implicit policy

**Executor binding**:
A target-owned association to one executor, containing validated endpoint and transport configuration, secret references, and capabilities for that execution path.
_Avoid_: Target, embedded credential

**Policy**:
A versioned rule that maps normalized event conditions and recovery semantics to ordered, target-specific action stages.
_Avoid_: Executor configuration, mutable schedule

**Protected policy version**:
An immutable policy definition that cannot be pruned because active, in-progress, committed, unknown, or unresolved durable state still depends on it.
_Avoid_: Recent policy, retained draft

**Event-relative time**:
Monotonic elapsed duration measured from a normalized event or action fact, used for outage delays, stages, retries, and verification without calendar scheduling.
_Avoid_: Schedule, wall-clock timer

**Trusted wall-clock state**:
Positive post-boot evidence that civil time synchronized successfully and has not since shown a discontinuity greater than 300 seconds relative to monotonic time.
_Avoid_: Plausible date, running NTP process, monotonic clock

**Target restoration**:
An action that powers on a host, starts a shed workload, or otherwise reverses a completed target shutdown after recovery; it is distinct from canceling pending work or restarting NUTMerlin's own supervised services.
_Avoid_: Recovery, online action, inverse shutdown

**Action**:
A policy-owned typed operation against a logical target, with bounded execution and verification settings but no embedded credential value.
_Avoid_: Shared live job, arbitrary command

**Typed operation**:
A versioned, schema-validated action intent whose contract declares safety, retry, binding, dry-run, and verification semantics independently of protocol translation.
_Avoid_: Command string, opaque executor payload

**Operation safety class**:
The closed maximum-effect category assigned to one typed operation version: `observe`, `notify`, `service_graceful`, `host_graceful`, `shutdown_committed`, `power_abrupt`, or `output_control`.
_Avoid_: Safe operation, destructive boolean, executor risk level

**Imported script version**:
An immutable, hash-pinned local-script artifact copied into NUTMerlin ownership through explicit registration and referenced by policy ID and version.
_Avoid_: Allowlisted path, live script

**Unprivileged local-script executor**:
The P0 script adapter running imported script versions under a qualified dedicated identity with no fallback to router root.
_Avoid_: Root script hook, arbitrary local command

**Portable local-script contract**:
The bounded P0 `/bin/sh` interface using immutable code, structured standard input and output, no secret injection, and qualified no-network execution.
_Avoid_: Allowlisted arbitrary executable, shell command template

**Restricted SSH binding**:
An SSH execution path whose target-side account or key authorization enforces the exact typed-operation protocol and exposes no general shell or forwarding capability.
_Avoid_: Dedicated shell account, client-side command allowlist

**Binding-scoped SSH key**:
A unique SSH keypair used by exactly one restricted SSH executor binding, with redisplayable public material and non-exportable private material.
_Avoid_: Deployment key, target-group key

**SSH host-key enrollment**:
The explicit binding transaction that records an exact host key only after its SHA-256 fingerprint is checked through an independent trusted path; candidate scanning is not trust.
_Avoid_: Trust on first use, accept-new

**Credential-free LAN webhook**:
A plaintext HTTP binding limited to `notification.publish`, carrying no authentication secret and resolving only to an explicitly confirmed trusted-LAN destination.
_Avoid_: Trusted HTTP action endpoint, HTTP with HMAC

**Signed webhook envelope**:
The fixed `https_hmac_v1` JSON publication whose exact body bytes, length, timestamp, and stable publication ID are authenticated with a binding-scoped HMAC-SHA-256 key.
_Avoid_: Signed template, arbitrary secret header

**Delivery acceptance**:
Evidence that an executor's destination accepted a message for handling, without evidence that any requested downstream state change completed.
_Avoid_: Action success, verified shutdown

**Action evidence grade**:
The structured statement of what NUTMerlin established about one execution: `not_dispatched`, `dispatch_rejected`, `dispatch_accepted`, `effect_verified`, or `outcome_unknown`.
_Avoid_: Success boolean, exit status, reachability proof

**Delivery gap**:
A bounded local record that one or more outbound publications could not be delivered, reported as a gap or recovery summary rather than replayed as current event transitions.
_Avoid_: Offline queue, delayed event

**Publish-only MQTT binding**:
An outbound broker integration with permission only to publish under a deployment-scoped prefix and no subscribed control surface.
_Avoid_: MQTT control channel, bidirectional executor

**Ephemeral MQTT session**:
A clean MQTT connection with no broker- or client-retained session or outbound queue after disconnect, using stable payload identifiers to tolerate QoS 1 duplicates without replaying missed events.
_Avoid_: Exactly-once publication, persistent MQTT client

**Retained state snapshot**:
An MQTT current-state or availability message kept by the broker for late subscribers, carrying explicit freshness evidence and never representing an event transition or action result.
_Avoid_: Retained outage event, replayable action result
