# NUTMerlin design interview decision ledger

Status: interview closeout; root packet reconciled 2026-08-02
Date: 2026-08-02
Authority: accepted ADRs 0001 through 0097

This ledger closes the design-grilling phase. It indexes every settled decision, records the principal rejected alternative, gathers numerical defaults in one place, and records the documentation changes applied by the subsequent reconciliation pass.

The individual ADRs remain authoritative when this summary is less precise. The root packet has now been reconciled against this ledger; the change lists below remain as an audit map. No product code, GitHub issue, ticket set, or implementation sequence was created by the interview or reconciliation.

## Settled decisions and rejected alternatives

### Identity, platform, lifecycle, and dependencies

| ADR | Settled decision | Principal rejected alternative and why |
| --- | --- | --- |
| [0001](decisions/0001-name-and-scope.md) | Use NUTMerlin, nutmerlin, and /jffs/addons/nutmerlin. NUT remains the device and network-protocol core; optional integrations consume NUT-derived events. | A generic UPS orchestration product or new device stack would obscure the NUT ecosystem boundary and duplicate mature driver/protocol work. |
| [0002](decisions/0002-default-client-local-shutdown.md) | The P0 host-shutdown pattern is a registered NUT upsmon secondary that owns its local policy and shutdown command. Fresh installs create no shutdown credential. | Central SSH push as the default would put host credentials and platform-specific shutdown responsibility on the router. |
| [0003](decisions/0003-reversible-vs-committed.md) | Model reversible outage handling separately from committed shutdown. Recovery may cancel only reversible work; NUT FSD is committed-only. | Using FSD as a cancelable outage timer is unsafe because FSD is a latched coordinated-shutdown commitment. |
| [0004](decisions/0004-testing-without-full-firmware-emulator.md) | Use host shims, dummy-ups, current AArch64 package/ABI evidence, simulated Merlin integration, optional real routers, and separately gated real-UPS tests. | Requiring full firmware rehosting would be costly, model-specific, and still poor evidence for hardware, NVRAM, USB, and closed components. |
| [0005](decisions/0005-optional-legacy-router.md) | Merlin 386/ARMv7 and the RT-AC3100 are legacy best-effort only; use the spare router when its evidence is meaningful. | Promising legacy support because the maintainer owns one spare router would create a release and security obligation unsupported by upstream lifecycle. |
| [0006](decisions/0006-repository-defaults.md) | Use public darvilp/nutmerlin, GPL-3.0-or-later, GitHub Actions, protected main, feature branches, and draft PRs; hardware jobs are manual. | A stale repository owner or private/ad hoc baseline would misdirect release tooling and undermine the intended community project. |
| [0007](decisions/0007-storage-durability.md) | Treat Entware media as fallible, prefer SSD, require no swap, keep high-frequency state in RAM, and bound persistent writes. | Trusting media quality, logging every poll, or requiring swap would increase wear without providing a recovery guarantee. |
| [0008](decisions/0008-support-current-merlin-families.md) | Support AArch64 3004.388.x and 3006.102.x, but only the latest NUTMerlin-qualified upstream stable in each family. The new stable must qualify before support moves; the old one then becomes compatibility-only without a grace period. | Supporting only the maintainer-owned family would be too narrow; promising older firmware indefinitely would multiply an untested security surface. |
| [0009](decisions/0009-capability-based-router-support.md) | Determine platform eligibility with mandatory capability probes, publish exact model/revision qualification separately, accept one complete reproducible report, carry it forward only across no-risk changes, and revoke on reproducible negative evidence. | A model allowlist would exclude capable hardware; permanent qualification or a calendar-only expiry would ignore the changes that actually affect compatibility. |
| [0010](decisions/0010-refuse-foreign-nut-deployments.md) | Refuse installation or mutation when an existing NUT deployment is foreign or ownership is ambiguous. | Automatically adopting, merging, or overwriting a manual deployment risks service loss, secret exposure, and destructive uninstall. |
| [0011](decisions/0011-conservative-ownership-recovery.md) | Recover ownership only through an explicit operation and only when independent NUTMerlin evidence is complete and consistent. | Guessing ownership from familiar paths or file contents could convert foreign files into project-owned deletion targets. |
| [0012](decisions/0012-journaled-two-slot-updates.md) | Install and update through journaled staging with current and previous complete release slots, an atomic selector, candidate health checks, and one automatic rollback attempt. | In-place replacement has no deterministic crash recovery and can mix code, data, hooks, and configuration from different releases. |
| [0013](decisions/0013-retain-entware-packages-on-uninstall.md) | Normal uninstall removes no Entware package, including packages NUTMerlin originally installed. | Automatic package removal cannot safely prove that other Entware software or administrators do not rely on the package. |
| [0014](decisions/0014-minimal-current-entware-dependencies.md) | Qualify against the current supported Entware feed, mutate only the required coherent cohort, and install optional packages only with their capability. Interactive install defaults to upgrading a compatible older cohort but permits an explicit compatibility-only keep; unattended mutation requires an explicit dependency policy. | Blanket opkg upgrade, automatic downgrade/pinning, private NUT builds, and silent old-package preservation create shared-system risk or a maintenance burden NUTMerlin cannot own. |
| [0015](decisions/0015-remove-all-owned-data-on-uninstall.md) | A clean uninstall removes all verified NUTMerlin-owned releases, configuration, secrets, journals, history, hooks, and managed exposure while preserving foreign artifacts and Entware packages. | Retaining hidden state by default would make uninstall incomplete and could leave credentials or stale authority behind; reversible retention belongs to disable. |
| [0016](decisions/0016-user-initiated-addon-updates.md) | Update checks, download, staging, and activation are administrator-initiated; NUTMerlin never silently installs an update. | Automatic updates could change an outage-control system during an unsafe state and make rollback authority ambiguous. |
| [0017](decisions/0017-require-pinned-release-signatures.md) | Authenticate every installable release with a signed manifest rooted in a previously pinned key, then verify every artifact size and SHA-256 digest. | HTTPS transport and unsigned checksum files establish integrity in transit at best, not publisher authenticity. |

### NUT exposure and shutdown-client credentials

| ADR | Settled decision | Principal rejected alternative and why |
| --- | --- | --- |
| [0018](decisions/0018-trusted-lan-read-only-nut-access.md) | Permit credential-free, read-only NUT status only inside the separately confirmed trusted-LAN listener and firewall scope. | WAN exposure, wildcard LAN exposure, or a nominal read-only password would either broaden access or add no meaningful boundary. |
| [0019](decisions/0019-one-trusted-ipv4-subnet-by-default.md) | Default to one administrator-confirmed IPv4 source subnet, one exact router listener address, and TCP 3493 admission only from that scope. IPv6 is off unless an exact safe scope is explicitly enabled. | Treating all private, VPN, guest, VLAN, or wildcard addresses as trusted would turn address class into an authorization policy. |
| [0020](decisions/0020-use-independent-shutdown-client-credentials.md) | Give every registered shutdown client a unique restricted upsmon secondary credential. | A shared monitor password increases blast radius and prevents independent revocation and audit. |
| [0021](decisions/0021-permit-native-nut-credentials-on-trusted-lan.md) | Permit native non-TLS NUT secondary credentials only on the confirmed trusted LAN; offer verified TLS as an optional profile and never downgrade automatically. | Requiring TLS before basic P0 interoperability would exclude common NUT clients, while allowing plaintext outside the trusted scope would expose reusable credentials. |
| [0022](decisions/0022-deliver-shutdown-client-secrets-once.md) | Generate secrets inside the product, disclose them once at creation or replacement, and make loss a replacement event. | Password reveal or recovery surfaces would require broader long-term secret access and make routine UI compromise more damaging. |
| [0023](decisions/0023-do-not-expire-shutdown-client-credentials-by-age.md) | Do not expire or rotate shutdown-client credentials merely because of age; replace on compromise, trust change, client retirement, ownership transfer, or explicit administration. | Calendar rotation without an out-of-band delivery agent would silently break clients and provide false assurance. |

### Domain contracts, dispatch, and executor boundaries

| ADR | Settled decision | Principal rejected alternative and why |
| --- | --- | --- |
| [0024](decisions/0024-commit-before-nonrepeatable-action-dispatch.md) | Persist and fsync a dispatch intent immediately before any nonrepeatable external request; an ambiguous post-intent result is outcome_unknown. | Recording only after success or assuming a timeout means failure can duplicate a shutdown after restart. |
| [0025](decisions/0025-gate-retries-by-action-capability.md) | Every typed operation declares nonrepeatable, idempotent, or idempotency_keyed retry semantics; a policy may only narrow them. | A common retry toggle cannot distinguish safe connection retries from duplicate state-changing dispatch. |
| [0026](decisions/0026-model-shutdown-clients-outside-the-executor-registry.md) | Model a NUT shutdown client as an onboarding/resource contract, not an executor. | A synthetic nut_client executor would imply the router dispatched or verified a client-local shutdown that it did not control. |
| [0027](decisions/0027-model-targets-as-logical-destinations.md) | A target is a stable logical destination with one or more separately qualified bindings. | Equating a target with an IP address or protocol binding makes identity, conflict detection, credential rotation, and verification incoherent. |
| [0028](decisions/0028-own-actions-by-immutable-policy-version.md) | Actions and exact expanded targets are captured by an immutable policy version; templates are copied, never live-linked. | Mutable shared actions or groups could change an active policy without a new review and activation boundary. |
| [0029](decisions/0029-use-versioned-typed-operations.md) | Use closed, versioned operation schemas with structured inputs, declared effects, retry class, verification contract, and safety class. | Opaque command strings and executor-specific free-form payloads defeat validation, least privilege, migration, and simulation. |
| [0030](decisions/0030-import-local-scripts-as-owned-versions.md) | Import administrator-selected scripts as immutable, hash-pinned, NUTMerlin-owned versions under protected /opt storage. | Executing a mutable live path lets unrelated edits silently alter an already activated action. |
| [0031](decisions/0031-run-p0-local-scripts-unprivileged.md) | Make local-script execution available only through a dedicated unprivileged identity on a qualified platform; never fall back to root. | Root scripts convert the addon into a general privileged command runner and erase a critical containment boundary. |
| [0032](decisions/0032-require-target-enforced-ssh-restrictions.md) | Require a target-side forced command or equivalently restricted wrapper for every SSH binding. | A normal shell account would let a stolen router key perform operations beyond the typed contract. |
| [0033](decisions/0033-scope-ssh-keypairs-to-one-binding.md) | Generate a unique SSH keypair for each binding and rotate/revoke it independently. | Reusing one automation key across targets makes compromise and retirement installation-wide. |
| [0034](decisions/0034-limit-http-webhooks-to-credential-free-lan-notifications.md) | Plain HTTP is allowed only for credential-free notification.publish to a confirmed trusted-LAN destination; secrets, non-LAN delivery, and action-bearing protocols require verified security profiles. | Plain HTTP secrets or action requests are observable and mutable by any on-path LAN participant. |
| [0035](decisions/0035-treat-generic-webhook-success-as-delivery-only.md) | Treat HTTP 2xx only as receiver acceptance of a notification; it is never proof that another system changed state. | Mapping a generic response body or 2xx to target-state success would invent an unverifiable action protocol. |
| [0036](decisions/0036-make-mqtt-publish-only.md) | P1 MQTT only publishes normalized notification/state messages and never subscribes for commands. | Inbound MQTT would create a remote control plane, authorization model, replay surface, and availability dependency. |
| [0037](decisions/0037-retain-only-mqtt-state-and-availability.md) | Permit retained MQTT only for current state and availability; events and action results are always non-retained. | Retaining event-like messages causes reconnecting consumers to misinterpret old work as new. |
| [0038](decisions/0038-require-a-complete-production-fsd-workflow.md) | Production FSD remains unavailable until NUTMerlin has a complete primary/router/output/restoration workflow; P1 may exercise only a harmless isolated simulation. | Signal-only FSD would commit secondaries while leaving the coordinator and UPS power-down lifecycle undefined. |
| [0039](decisions/0039-defer-output-cutting-operations-to-later.md) | Keep load.off, shutdown.*, outlet off/cycle/delay, and every equivalent UPS/PDU output operation outside P1 and P2. | Adding a confirmation checkbox or environment gate does not provide the state machine, hardware proof, recovery, and physical safeguards these operations need. |
| [0040](decisions/0040-defer-redfish-forceoff-to-later.md) | P2 Redfish is limited to query plus constrained GracefulShutdown and bounded Off verification; ForceOff, reset, and power-on are Later. | ForceOff as a fallback can corrupt hosts and bypasses the promised graceful-operation contract. |
| [0041](decisions/0041-require-constrained-winrm-endpoints.md) | WinRM may call only a dedicated constrained JEA-equivalent endpoint through verified HTTPS with a non-admin identity. | Administrator endpoints, Basic/CredSSP shortcuts, unrestricted PowerShell, and broad TrustedHosts entries expose excessive authority. |
| [0042](decisions/0042-default-to-monitoring-only.md) | Fresh installs and upgrades are monitoring-only: no enabled policy, executor, shutdown credential, webhook, MQTT, or newly broadened authority. | Helpful automation defaults can shut down community hardware before topology, timing, and recovery have been reviewed. |
| [0043](decisions/0043-exclude-the-coordinator-router-from-ordinary-policies.md) | Structurally exclude the NUTMerlin router from ordinary target policies; only a future complete committed FSD workflow may shut it down. | Treating the coordinator like any host can remove observation, dispatch, and recovery authority mid-sequence. |
| [0044](decisions/0044-protect-external-network-infrastructure-by-default.md) | Mark network infrastructure protected by default and permit it only as an explicit terminal-stage target when it is no longer a control-path dependency. | Early load shedding of switches, APs, DNS, storage, or gateways can strand pending actions and verification. |
| [0045](decisions/0045-use-conservative-observation-freshness-and-debounce.md) | Normalize NUT state with bounded freshness, contradictions as unknown, and two consistent observations before action eligibility; the first contradictory/recovery sample inhibits immediately. | Acting on one poll, cached display values, WAIT, or contradictory OL/OB tokens makes transient or malformed telemetry destructive. |
| [0046](decisions/0046-require-qualified-numeric-telemetry-for-threshold-actions.md) | Runtime and charge can authorize actions only when that exact source/driver capability is qualified, fresh, on battery, debounced, and hysteretic. No numeric threshold is prefilled. | Assuming every UPS reports trustworthy runtime or charge turns vendor estimates and sentinel values into shutdown authority. |
| [0047](decisions/0047-inhibit-ordinary-dispatch-during-telemetry-loss.md) | Stale telemetry inhibits new ordinary state-changing dispatch. An explicit fail-safe is possible only after last-confirmed OB plus a longer loss window and only for graceful/notification effects. | Treating communication loss as low battery, replaying cached conditions, or enabling fail-safe by default confuses uncertainty with evidence. |
| [0048](decisions/0048-use-common-bounded-action-budgets.md) | Apply common timeout, retry, concurrency, rate, and total-duration ceilings to every operation, with stricter per-operation contracts allowed. | Executor-specific unbounded waiting and retries can outlive an outage stage, overload a router, or duplicate actions. |

### Policy evaluation, recovery, storage, and release evidence

| ADR | Settled decision | Principal rejected alternative and why |
| --- | --- | --- |
| [0049](decisions/0049-continue-independent-actions-and-fail-closed-on-dependencies.md) | Continue actions that are provably independent, but require explicit acyclic prerequisites and block a dependent action unless its exact evidence requirement is satisfied. | One global continue-on-error flag either stops unrelated safe work or lets dependent work run after an unsafe prerequisite result. |
| [0050](decisions/0050-reject-ambiguous-cross-policy-action-conflicts.md) | Coalesce identical concurrent intents and reject different overlapping intents unless an explicit relationship makes them unambiguous; do not resolve by numeric priority. | Last-writer-wins or policy priority hides conflicts and can make a lower-level action undo a safety assumption. |
| [0051](decisions/0051-distinguish-late-mount-from-runtime-storage-failure.md) | Treat expected boot-time /opt delay as bounded retry, but latch automation after unexpected runtime loss, read-only remount, or identity/integrity failure until reconciliation and explicit clear. | One retry-forever state cannot distinguish normal boot order from loss of durable authority during active operation. |
| [0052](decisions/0052-bound-nut-and-usb-recovery-with-a-circuit-breaker.md) | Bound driver/service restart attempts with a circuit breaker and a controlled later probe; never switch a real source to dummy-ups automatically. | Infinite restart loops wear storage and hide faults; simulation fallback could drive policy from fabricated state. |
| [0053](decisions/0053-recover-current-state-without-replaying-network-work.md) | After network recovery publish current state and optional gap summaries, but do not replay stale webhook/MQTT work or treat reconnection as verification. | A persistent notification outbox can deliver obsolete outage events after recovery and still cannot prove remote effects. |
| [0054](decisions/0054-separate-the-safety-journal-from-operational-history.md) | Reserve a small synchronous safety journal for authority and recovery facts, separate from bounded buffered operational history and volatile status. Journal unavailability blocks new state change. | Using rotating logs as the recovery authority or fsyncing every observation either loses safety facts or destroys write endurance. |
| [0055](decisions/0055-use-permissioned-secret-files-without-a-secret-backup.md) | Store each secret in a protected project-owned file with narrow process access; do not place it in settings, UI, logs, argv, exports, backups, or support bundles, and do not claim secure erasure. | Application-encrypted blobs still need an on-router decryption key and add recovery complexity without improving the router trust boundary. |
| [0056](decisions/0056-split-privileged-lifecycle-from-policy-and-status.md) | Split a small privileged lifecycle controller and narrow execution broker from unprivileged status, policy, and UI processes; no root network listener or root monolith. | A single root daemon makes parsers, network input, policy bugs, and web integration part of the full privileged attack surface. |
| [0057](decisions/0057-distinguish-same-boot-restart-from-router-reboot.md) | Resume an uncommitted monotonic timer only after same-boot reconciliation; on router reboot restart it from zero. Never repeat committed or unknown intent. | Reconstructing elapsed outage time from wall clock across reboot is vulnerable to clock error and can dispatch immediately on startup. |
| [0058](decisions/0058-require-a-unique-stable-usb-source-identity.md) | Bind a USB UPS only when validated VID/PID/serial identity, or a narrowly qualified no-serial identity, resolves to exactly one device; bus/port is supplemental. | First compatible device, device node, or physical port selection can silently bind the wrong UPS after reboot or replacement. |
| [0059](decisions/0059-gate-external-nut-access-on-verified-firewall-scope.md) | Open external NUT only when the exact listener and independently verified source-filter rules match the confirmed scope; recheck activation, restart, firewall hooks, and periodically. | A correct bind alone does not prevent firmware/firewall changes from admitting untrusted sources. |
| [0060](decisions/0060-make-the-cli-complete-and-the-web-ui-milestone-scoped.md) | Give the local CLI complete management parity and stable JSON/exit classes; expose only curated milestone-appropriate operations in the Merlin UI through shared schemas. | UI-only management, direct file editing, or an arbitrary web command surface makes recovery and validation inconsistent. |
| [0061](decisions/0061-bound-operational-history-by-size-age-and-write-rate.md) | Retain transition-oriented event, action/lifecycle, and redacted diagnostic history under separate size/age limits; keep poll samples volatile and rate-limit repeated health writes. | An unbounded telemetry database would consume shared storage and flash endurance; no history would make safety diagnosis impractical. |
| [0062](decisions/0062-separate-configuration-export-from-support-bundles.md) | Make non-secret reconstruction export, public pseudonymized support bundle, and private administrator support bundle separate contracts; imports remain inactive. | One generic backup/log archive would either leak topology and secrets or omit the information needed for reconstruction and support. |
| [0063](decisions/0063-require-current-harmless-evidence-before-policy-activation.md) | Require static validation, current harmless binding tests, exact policy dry-run, warning resolution, and explicit activation; evidence expires or invalidates on drift. | Saving a policy, checking a box, or relying on an old successful test is not proof that its present bindings and credentials are safe. |
| [0064](decisions/0064-require-layered-hardware-free-release-evidence.md) | Require host tests on every change and current AArch64 Entware package/ABI evidence for every release; require exact current-router and harmless physical-UPS base reports for the first public release, then refresh hardware evidence on risk triggers. ARMv7 remains nonblocking. | Treating CI as hardware proof or making all releases wait on every physical rig either overclaims evidence or makes community delivery brittle. |
| [0065](decisions/0065-qualify-ups-capabilities-independently.md) | Qualify the harmless base source contract and each numeric/status capability separately for the exact UPS, driver profile, NUT version, and evidence set; reproducible negative evidence revokes only the affected claim. | A blanket supported-UPS label turns driver recognition into an unjustified promise about runtime, charge, status, identity, or writable commands. |
| [0066](decisions/0066-use-a-pinned-openpgp-root-and-offline-release-signing.md) | Use an offline OpenPGP Ed25519 primary trust root, a bounded release-signing subkey, detached signed manifests, Entware gpgv2 verification, deliberate root transition, and manual compromise recovery. | An online CI root, first-seen key, or automatic transition signed only by a suspected old key creates a single compromise path to router code execution. |
| [0067](decisions/0067-activate-updates-only-in-a-safe-window.md) | Stage in an explicit update session, but activate only when stably online with no active/unresolved authority or while explicitly disabled in maintenance; require continuous candidate health and rollback representation. | Hot activation during an outage or automatically re-enabling after maintenance can mix executable state across a safety boundary. |
| [0068](decisions/0068-limit-policies-to-event-relative-time.md) | Through P2, policy timing is event-relative monotonic duration only; exclude calendar, cron, timezone, sunrise/sunset, and recurring scheduling. | Civil-time scheduling adds clock trust, daylight-saving, missed-run, duplicate-run, and unrelated automation semantics to a power-safety core. |

### Messaging, effect classification, and native adapters

| ADR | Settled decision | Principal rejected alternative and why |
| --- | --- | --- |
| [0069](decisions/0069-use-ephemeral-qos1-mqtt-publication.md) | Default MQTT to v5 with an ephemeral session and QoS 1; permit explicitly selected v3.1.1 compatibility without automatic downgrade. Persist no offline queue and apply exact TLS/address scope. | Persistent sessions and automatic protocol/security fallback can replay stale events, retain subscriptions, or silently weaken transport. |
| [0070](decisions/0070-classify-operations-by-maximum-effect.md) | Classify every typed operation by its maximum credible effect: observe, notify, service_graceful, host_graceful, shutdown_committed, power_abrupt, or output_control. Gates follow the maximum, not the normal case. | Executor names or administrator-selected labels can understate a command that is capable of a more destructive effect. |
| [0071](decisions/0071-defer-target-restoration-actions-to-later.md) | Do not power on hosts, restart workloads, or perform target restoration through P2; recovery cancels pending work and reports state only. | Automatic recovery after a fixed OL interval can flap equipment, overload returning power, or start services before dependencies recover. |
| [0072](decisions/0072-make-notification-only-policies-first-class.md) | Support notification-only policies with one normalized notification.publish envelope over webhook or MQTT; the receiver may act independently, but NUTMerlin records delivery only. | Built-in per-service email/SMS/cloud adapters or action-shaped generic notifications multiply secret, retry, and verification semantics outside the core. |
| [0073](decisions/0073-keep-snmp-and-pdu-protocols-outside-p2.md) | Keep direct SNMP/PDU implementation outside P0–P2. A network UPS/PDU may be observed only through a separately validated NUT driver profile. | Owning SNMP polling/SET, MIBs, and PDU sessions would create another device stack and prematurely expose output control. |
| [0074](decisions/0074-defer-all-writable-ups-administration.md) | Expose no raw upscmd, upsrw, beeper, test, calibration, outlet, or other writable UPS/PDU administration through P2; hold no general admin credential. | A command allowlist or environment gate alone cannot make arbitrary device writes safe, portable, or reversible. |
| [0075](decisions/0075-constrain-and-verify-redfish-graceful-shutdown.md) | P2 Redfish selects one exact ComputerSystem, verifies TLS and least privilege, prefers session auth, dispatches GracefulShutdown once, and verifies two consecutive Off observations. | ForceOff fallback, broad BMC credentials, auto-discovered systems, or probing dangerous commands can affect the wrong host or grant latent abrupt power authority. |
| [0076](decisions/0076-gate-winrm-on-a-qualified-client-stack.md) | Advertise P2 WinRM only if a reproducible Entware-compatible client stack qualifies; use verified HTTPS and a constrained endpoint for one nonrepeatable graceful shutdown, with separate Off evidence. | Runtime pip installation, a homegrown WSMan client, or broad administrator remoting is hard to reproduce, update, constrain, and audit on a router. |
| [0077](decisions/0077-pin-ssh-identity-with-current-entware-openssh.md) | Use the current Entware OpenSSH cohort, Ed25519 keys by default, narrowly allowed RSA-SHA2 compatibility, and an independently verified SHA-256 host fingerprint in a binding-owned configuration. | Firmware-client fallback, TOFU, shared known_hosts, DSA, or SHA-1 silently broadens and weakens the authenticated path. |
| [0078](decisions/0078-use-explicit-action-evidence-grades.md) | Record not_dispatched, dispatch_rejected, dispatch_accepted, effect_verified, or outcome_unknown; execute may establish acceptance, but only the operation verifier may establish effect. | A binary success flag or loss of ping/session cannot distinguish refusal, accepted shutdown, verified Off, and ambiguity. |
| [0079](decisions/0079-constrain-p0-local-scripts-to-a-portable-contract.md) | Limit P0 scripts to imported POSIX sh text, structured bounded input/output, no secrets/arguments/network, hard timeouts, and a qualified unprivileged/no-egress profile; otherwise mark the capability unavailable. | Arbitrary binaries, root fallback, or claiming a generic shell sandbox would create a privileged extensibility escape hatch. |
| [0080](decisions/0080-use-fixed-authenticated-webhook-profiles.md) | Use fixed lan_anonymous, https_bearer, and https_hmac_v1 POST profiles, a fixed JSON envelope, no redirects, per-resolution SSRF checks, and delivery-only 2xx semantics. | Arbitrary methods, headers, templates, query secrets, redirects, or response parsing turn the webhook into a programmable exfiltration and command surface. |

### Time, management, source, rollback, and final scope

| ADR | Settled decision | Principal rejected alternative and why |
| --- | --- | --- |
| [0081](decisions/0081-separate-monotonic-time-from-trusted-wall-clock.md) | Use monotonic time for safety transitions and maintain a separate per-boot wall-clock trust state for TLS, signed webhooks, release/key validity, and audit timestamps. | Assuming firmware time is trustworthy at boot, or using wall time for outage timers, permits jumps and unsynchronized clocks to authorize work. |
| [0082](decisions/0082-keep-management-local-to-merlin-and-the-router.md) | Provide no standalone network API or management server. The Merlin UI uses its authenticated form/service-event path plus a one-time candidate-bound nonce; the local CLI reaches the same controller. | A custom root/web API would add session, authorization, CSRF, exposure, and upgrade responsibilities unrelated to NUT integration. |
| [0083](decisions/0083-require-a-preexisting-healthy-entware-installation.md) | Require an existing healthy Entware installation and validated /opt before mutation; NUTMerlin never bootstraps Entware, selects/formats storage, repairs the feed as a whole, or owns opkg. | Bundling or repairing Entware would make NUTMerlin responsible for shared storage and package-manager state beyond its dependency cohort. |
| [0084](decisions/0084-require-manual-authentication-of-first-install.md) | First install is a locally staged authenticated bundle; the administrator independently confirms the full root fingerprint before verifying manifest, artifacts, installer, and then executing locally. | curl-pipe execution, a first-seen adjacent key, or an unsigned bootstrap makes the initial trust decision attacker-controlled. |
| [0085](decisions/0085-snapshot-explicit-targets-into-policy-stages.md) | Treat target groups as authoring/display labels only; activation snapshots the exact target/action expansion. Group edits do not change an active version, and no built-in criticality labels carry behavior. | Dynamic group membership or magic noncritical/important/critical semantics can alter live sequencing without a policy revision. |
| [0086](decisions/0086-use-one-authoritative-source-and-isolate-simulation.md) | Through P2, allow one authoritative real UPS source, named ups to clients by default. Keep dummy-ups under a distinct loopback-only maintenance identity with policies, clients, and external access disabled. | Automatic real-to-dummy fallback, multiple active sources, or source voting can drive production work from simulation or conflicting power domains. |
| [0087](decisions/0087-require-versioned-nut-driver-profiles.md) | P0 supports versioned usbhid-ups and isolated dummy-ups profiles with typed options, identity, privilege, rendering, probes, and migrations; additional drivers require new profiles. | Raw driver names, free-form ups.conf, and an expert bypass make configuration injection and capability claims unreviewable. |
| [0088](decisions/0088-quarantine-and-revalidate-rollback.md) | Roll back only to the authenticated previous paired slot, initially monitoring-only, reconcile exact safety/configuration state, and pass the full health window before narrowly restoring unchanged prior authority. Manual rollback stays inactive. | Immediate pointer reversal can reintroduce revoked credentials, old policy, unsafe schemas, or duplicate an unknown action. |
| [0089](decisions/0089-refuse-clean-uninstall-with-unresolved-actions.md) | Refuse clean uninstall while work is in flight, committed, unknown, unreconciled, ambiguously owned, or unwritable. Emergency detach removes only independently verified JFFS activation/exposure and preserves evidence. | Force uninstall could erase the only recovery record, repeat or abandon a shutdown, or delete foreign/shared state. |
| [0090](decisions/0090-activate-immutable-nut-configuration-generations.md) | Render complete immutable NUT configuration generations outside ambient /opt/etc/nut, select one atomically through NUT_CONFPATH for a whole service epoch, validate health, retain active and last-known-good, and roll back once. | Editing individual live files or following a moving symlink can mix epochs and overwrite a foreign deployment. |
| [0091](decisions/0091-anchor-safety-state-sparingly-on-jffs.md) | Pair the detailed /opt journal with two alternating 32 KiB JFFS anchor slots holding only conservative identity, generation, transaction, digest, and unresolved-state facts; write only at safety boundaries. | A second full journal would wear JFFS and duplicate authority; no independent anchor would let a missing/replaced /opt erase unresolved intent. |
| [0092](decisions/0092-make-emergency-inhibition-prospective.md) | Emergency automation inhibit blocks new episodes/dispatch and cancels only undispatched reversible work; it never recalls accepted, unknown, or committed work and persists until explicit clear. | Treating inhibit as a universal cancel or clearing old uncertainty when it is removed would falsely promise reversal of external effects. |
| [0093](decisions/0093-use-explicit-two-phase-credential-cutover.md) | Allow at most current plus pending credential, deliver pending once, harmlessly test it, and require explicit promotion. Expiry removes only pending; emergency revocation is immediate and leaves a durable tombstone that rollback cannot undo. | Immediate overwrite, automatic promotion, permanent dual secrets, or rollback resurrection can break working clients or restore compromised authority. |
| [0094](decisions/0094-bound-immutable-policy-version-retention.md) | Bound ordinary immutable-policy storage and inactive history, but never prune a version needed by active, committed, unknown, in-progress, rollback, or journal state. Reusing an old version creates a new draft and full validation. | Unlimited versions consume shared storage; age-only pruning can destroy the exact contract needed to reconcile an external effect. |
| [0095](decisions/0095-qualify-storage-semantics-with-ext4-as-reference.md) | Recommend ext4, but publish support only for exact storage profiles that prove Unix permissions, link behavior, atomic rename, fsync, locking, execution, identity, and interruption recovery. FAT/VFAT/exFAT are incompatible. | Filesystem-name assumptions or permission emulation weaken secret isolation and journal/config durability exactly where fail-closed behavior depends on them. |
| [0096](decisions/0096-freeze-milestones-around-the-safe-nut-core.md) | Freeze P0 around safe NUT service/client-local operation, P1 around notifications/restricted SSH/graceful stages and simulated FSD, P2 around independently qualified graceful WinRM/Redfish and added driver profiles, and place high-risk/broad integrations in Later. | Pulling every appealing integration into MVP would make release safety depend on unqualified protocols, destructive effects, and unavailable hardware. |
| [0097](decisions/0097-make-the-webui-an-optional-version-matched-component.md) | Make the complete CLI-based core the required, default installation and the Merlin WebUI an explicit opt-in component authenticated by the same release manifest and locked to the exact core version/schema. UI removal and failure preserve all core services, state, and CLI recovery. | Bundling every install couples core support to optional firmware integration; an independently versioned UI product would create trust, ownership, schema-skew, and support splits. |

## Explicit defaults and numerical thresholds

Absence is itself a default where shown: a fresh installation has no WebUI component, active policy, central executor, shutdown-client credential, webhook, MQTT binding, outage timer, runtime threshold, charge threshold, telemetry-loss fail-safe, IPv6 listener, production FSD, or writable device operation.

### Support, qualification, packages, and release lifecycle

| Subject | Settled default or threshold | Source |
| --- | --- | --- |
| Supported firmware families | AArch64 3004.388.x and 3006.102.x. Support attaches to the latest NUTMerlin-qualified upstream stable in each family, not automatically to a newly published stable. There is no prior-version grace period. | ADR 0008 |
| Legacy platform | Merlin 386/ARMv7 is legacy best-effort and non-release-blocking; the RT-AC3100 is optional. | ADR 0005 |
| Exact router qualification | One complete, reproducible, waiver-free hardware report qualifies one exact model/revision combination. Carry-forward is risk-triggered, not calendar-based; there is no 12-month expiry. Reproducible negative evidence revokes the affected qualification. | ADR 0009 |
| First public physical evidence | At least one exact current-family router report and one harmless physical UPS base report, in addition to host, dummy-ups, simulated platform, and current AArch64 package/ABI evidence. Later refresh is risk-triggered. | ADR 0064 |
| Package baseline | Current coherent cohort in the supported Entware feed. Interactive install defaults to scoped upgrade; the administrator may keep a proven coherent older cohort as compatibility-only. Unattended mutation requires an explicit dependency policy. | ADR 0014 |
| Entware free space | Calculated transaction and package-manager temporary needs, plus at least 16 MiB of post-transaction safety headroom. An uncomputable requirement is refused. | ADR 0083 |
| Release slots | At most two complete slots: current and previous. Candidate activation gets one automatic rollback attempt. | ADR 0012 |
| Installed components | Core is required and is the first-install default. WebUI is explicit opt-in, uses a separately authenticated artifact under the same release, and must exactly match the active core version and management schema. | ADR 0097 |
| NUT configuration generations | At most two sealed complete generations after staging: active and last-known-good. Candidate failure gets one selector rollback and full health attempt. | ADR 0090 |
| Activation health | 120 continuous healthy seconds and at least 24 consecutive fresh observations at the default 5-second interval. The same floor applies to update candidates, configuration generation activation, and rollback quarantine. | ADRs 0067, 0088, 0090 |
| Release signing | Offline OpenPGP Ed25519 primary root; release-signing subkey validity no more than 12 months. Planned root transition publishes both roots for at least 90 days and two public releases, whichever is longer. | ADR 0066 |
| First-install trust | Manual local bundle and independent confirmation of the full root fingerprint before any project code executes. Public release requires at least two independent project-controlled fingerprint channels and a tested emergency replacement procedure. | ADRs 0066, 0084 |
| Updates | Administrator-initiated only. Activation requires confirmed OL and no active, pending state-changing, committed, unknown, storage-latched, or unreconciled state, or an explicitly disabled maintenance flow that remains disabled. | ADRs 0016, 0067 |
| Default client-facing source | One authoritative real source through P2, named ups by default. Isolated dummy-ups uses a distinct maintenance identity and loopback only. | ADR 0086 |
| P0 drivers | Versioned usbhid-ups production profile and isolated dummy-ups profile. Every additional driver needs its own accepted profile and evidence. | ADR 0087 |

### Observation, outage, and recovery timing

| Subject | Settled default or threshold | Source |
| --- | --- | --- |
| Status observation | 5-second default interval. Qualified source profiles may use 2–30 seconds. | ADR 0045 |
| Freshness | Stale immediately when NUT reports stale, otherwise after max(15 seconds, 3 times the observation interval). The default therefore expires at 15 seconds. | ADR 0045 |
| Debounce | Two consecutive fresh, mutually consistent observations separated by at least one interval are required for an action-eligible state. The first contradictory or recovery observation immediately inhibits new dispatch. | ADR 0045 |
| Contradictions | OL plus OB, no recognized line-state token, WAIT, malformed tokens, or profile-defined contradiction normalize to unknown and are never action-eligible. | ADR 0045 |
| Outage delay | None is enabled or prefilled. A 180-second workstation delay may appear only as a clearly labeled example requiring explicit configuration and harmless validation. | ADR 0003 |
| Numeric thresholds | No charge or runtime threshold is enabled or prefilled. Trip requires two fresh qualified samples during confirmed OB and fires at most once per outage episode. | ADR 0046 |
| Charge hysteresis | Default clear point is trip threshold plus 2 percentage points. | ADR 0046 |
| Runtime hysteresis | Default clear point is trip threshold plus max(60 seconds, 10 percent of the trip threshold). | ADR 0046 |
| Telemetry-loss fail-safe | Disabled by default. If explicitly configured, last state must be confirmed OB and continuous loss must last at least max(30 seconds, 2 times the source freshness deadline). Only notification, graceful service stop, and graceful host shutdown are eligible. | ADR 0047 |
| Boot-time /opt readiness | Probe at 5, 15, 30, 60, and 120 seconds, then every 300 seconds while enabled and still unavailable. Runtime loss is not handled by this retry schedule; it latches automation. | ADR 0051 |
| NUT/USB restart breaker | No more than three start attempts in five minutes, delayed 5, 15, then 60 seconds. Pause for 15 minutes, permit one recovery probe, and reset the breaker only after five continuous healthy minutes. | ADR 0052 |
| External NUT drift check | Verify exact listener and firewall scope on activation, service restart, relevant firewall hook, and at least every 300 seconds while externally exposed. | ADR 0059 |
| Same-boot versus reboot | Same-boot uncommitted timers may resume from durable monotonic evidence; router reboot restarts an uncommitted timer from zero. Committed or unknown intent is never repeated. | ADR 0057 |
| Emergency inhibit | Persistent and prospective. It cancels only undispatched reversible work, does not recall accepted/unknown/committed effects, and explicit clear merely arms future new episodes. | ADR 0092 |

### Action budgets and adapter-specific bounds

| Subject | Settled default or threshold | Source |
| --- | --- | --- |
| Connection timeout | 5-second default; configurable hard range 1–30 seconds. | ADR 0048 |
| Dispatch timeout | 30-second default; configurable hard range 1–300 seconds. | ADR 0048 |
| Verification timeout | 300-second default; configurable hard range 0–1800 seconds. Zero is valid only when the operation contract declares no verification. | ADR 0048 |
| Total action lifetime | Hard ceiling of 3600 seconds unless a later specialized workflow defines its own bounded lifecycle. | ADR 0048 |
| Nonrepeatable dispatch | One dispatch attempt and no automatic post-dispatch retry. A provably pre-dispatch connection failure may retry within budget without consuming the one dispatch. | ADRs 0024, 0025, 0048 |
| Idempotent/keyed dispatch | At most three total dispatch attempts with default delays of 2 seconds and 5 seconds. | ADR 0048 |
| Concurrency | One in-flight action per logical target and at most two concurrent executor dispatches per installation. | ADR 0048 |
| Rate | At most 30 dispatch starts in any rolling 60-second interval. | ADR 0048 |
| Evidence grades | Closed set: not_dispatched, dispatch_rejected, dispatch_accepted, effect_verified, and outcome_unknown. | ADR 0078 |
| Safety classes | Closed ascending maximum-effect set: observe, notify, service_graceful, host_graceful, shutdown_committed, power_abrupt, and output_control. P0–P2 contain no power_abrupt or output_control operation. | ADR 0070 |
| Redfish | TLS 1.2 or newer; exact selected ComputerSystem; one nonrepeatable GracefulShutdown; 300-second verification; 5-second poll; two consecutive fresh Off observations. No escalation. | ADR 0075 |
| SSH | Current Entware OpenSSH cohort; Ed25519 default. RSA compatibility, where qualified, is at least 3072 bits and must use RSA-SHA2. Exact SHA-256 host fingerprint; no TOFU. | ADR 0077 |
| Local script artifact/input | POSIX /bin/sh text no larger than 256 KiB and containing no NUL; input is one versioned JSON document on stdin no larger than 32 KiB. | ADR 0079 |
| Local script output | One JSON result on stdout no larger than 16 KiB; diagnostic stderr no larger than 8 KiB. On timeout send TERM, wait 2 seconds, then kill the remaining process group. | ADR 0079 |
| Local script availability | No root fallback. The executor is absent unless the exact platform qualifies privilege drop, process cleanup, resource bounds, filesystem denial, and UID/process-scoped no-egress enforcement. | ADRs 0031, 0079 |
| Webhook profiles | Closed set: lan_anonymous, https_bearer, and https_hmac_v1. POST application/json only, fixed normalized body, no redirects, and any 2xx means delivery acceptance only. | ADR 0080 |
| HMAC webhook | HMAC-SHA-256 over the exact versioned framing in ADR 0080. Receiver guidance defaults to 300 seconds maximum timestamp skew plus publication-ID deduplication. | ADR 0080 |
| MQTT | MQTT v5 default with Clean Start 1 and Session Expiry 0; v3.1.1 compatibility requires Clean Session 1. QoS 1, no persistent offline queue, no automatic version downgrade. | ADR 0069 |

### Network, secrets, UI, and clock trust

| Subject | Settled default or threshold | Source |
| --- | --- | --- |
| NUT LAN exposure | One explicitly confirmed IPv4 subnet, one exact router LAN listener, TCP 3493 only from the selected source scope. WAN, guest, VPN-client, other VLAN/subnet, and wildcard listeners are denied. | ADRs 0018, 0019 |
| IPv6 | Disabled by default. Explicit opt-in requires one specific trusted address/prefix, independent WAN/untrusted denial, and administrator confirmation; ambiguity disables IPv6 access. | ADR 0019 |
| Shutdown credentials | No credential on fresh install. One independently generated upsmon secondary credential per registered client; no primary, FSD, SET, or instant-command authority. | ADRs 0002, 0020 |
| Native NUT transport | Non-TLS credential use is limited to the confirmed trusted LAN. Verified TLS is optional where qualified; there is no automatic downgrade. | ADR 0021 |
| Secret disclosure | Show a generated secret exactly once at creation or replacement. Loss requires replacement, not reveal. | ADR 0022 |
| Age rotation | None. Credentials remain current until an event or explicit administrator action requires replacement/revocation. | ADR 0023 |
| Credential cutover | At most one current and one pending version. Pending window defaults to 24 hours and is configurable from 1–168 hours. Expiry deletes pending only; promotion requires a fresh harmless test and explicit confirmation. | ADR 0093 |
| Secret file modes | Secret directory 0700; ordinary secret files 0600; NUT-readable generated secret material 0640 with the narrow required group. An incompatible filesystem disables secret-bearing features. | ADR 0055 |
| TLS floor | TLS 1.2 or newer with verified server identity for secret-bearing/non-LAN webhook, MQTT, WinRM, and Redfish profiles. No trust-all or plaintext downgrade. | ADRs 0034, 0069, 0075, 0076, 0080 |
| Web UI operation nonce | One exact candidate-bound nonce, valid for five minutes and consumed on the first attempted dispatch regardless of result. | ADR 0082 |
| Management network surface | None through P2: no standalone REST, RPC, web server, or remotely callable CLI. The complete local CLI is always present; an installed exact-version Merlin WebUI shares its typed management operations. | ADRs 0082, 0097 |
| Wall-clock trust | Every boot begins untrusted. Trust requires positive same-boot synchronization evidence; a discontinuity greater than 300 seconds versus monotonic projection revokes trust. | ADR 0081 |
| Untrusted-clock effects | Block new TLS validity decisions, HMAC webhook publication, authenticated release staging/activation, and key/certificate validity decisions. Monotonic local monitoring and otherwise qualified non-wall-clock work may continue. | ADR 0081 |

### Persistent storage, retention, and diagnostic artifacts

| Subject | Settled default or threshold | Source |
| --- | --- | --- |
| Reference filesystem | Journaled ext4 with execution and native Unix ownership/modes. noatime is recommended but not a correctness gate. FAT, VFAT, and exFAT are incompatible. | ADR 0095 |
| Required filesystem semantics | Persistent UID/GID and 0700/0600/0640 modes, case-sensitive stable names, correct regular/symlink/hard-link distinctions, same-directory atomic rename, file and directory fsync, exclusive locking, executable Entware binaries, stable identity, and interruption recovery. | ADR 0095 |
| Safety journal | Reserve 4 MiB on /opt. It is synchronous at authority boundaries and separate from history; inability to append required state blocks new state change. | ADR 0054 |
| JFFS anchor | Two alternating 32 KiB slots, 64 KiB total. No poll writes, credentials, policy payloads, telemetry series, or operational history. Journal/anchor disagreement selects the more restrictive state. | ADR 0091 |
| Event transition history | 4 MiB or 90 days, whichever limit is reached first. | ADR 0061 |
| Action/lifecycle history | 8 MiB or 180 days, whichever limit is reached first. | ADR 0061 |
| Health/diagnostic history | 4 MiB or 14 days, whichever limit is reached first. | ADR 0061 |
| Total operational history | 16 MiB by default, separate from the 4 MiB journal. Ordinary supported maximum is 64 MiB or 365 days; exceeding either requires an expert setting and free-space validation. | ADR 0061 |
| Repeated health writes | Persist first occurrence, recovery, and no more than one aggregate summary every 15 minutes while unchanged. | ADR 0061 |
| History buffering | Flush after at most 5 seconds or 10 records, whichever occurs first. Safety-journal facts are not buffered this way. | ADR 0061 |
| Public support bundle | At most the latest 24 hours or 1,000 history records, whichever is reached first; allowlisted and pseudonymized with a bundle-local salt. | ADR 0062 |
| Bundle temporary file | Mode 0600, automatically expires after 10 minutes, and is deleted after confirmed handoff where possible. Never uploaded automatically. | ADR 0062 |
| Policy version size | At most 256 KiB serialized, excluding credential values. | ADR 0094 |
| Policy store | 8 MiB ordinary full-version capacity on /opt. Retain the newest 10 inactive terminal versions per policy plus full versions referenced by retained action history, normally 180 days. | ADR 0094 |
| Protected policy versions | No age limit and no pruning while active, in progress, committed, outcome-unknown, unreconciled, rollback-referenced, or journal-referenced. Exhaustion blocks new activation rather than deleting safety evidence. | ADR 0094 |

## Unresolved research questions

These questions do not weaken the accepted defaults. Where evidence is missing, the affected capability remains unavailable or compatibility-only.

| Research question | Why it remains open and its disposition |
| --- | --- |
| Which two independent project-controlled channels will publish the full OpenPGP root fingerprint, and what exact emergency root-replacement procedure will be tested? | This is the one explicit public-release trust blocker in ADR 0066. A GitHub release and content served through the same account/control plane do not automatically count as independent. |
| What exact Merlin mechanisms prove same-boot NTP synchronization and detect a later wall-clock discontinuity on both current firmware families? | ADR 0081 fixes the semantic contract; platform adapters and qualification must find positive evidence rather than infer trust from a plausible date or running daemon. |
| Which Merlin Addons API, authenticated-form, service-event, and transient-storage mechanisms satisfy the UI nonce contract on each supported family? | ADR 0082 fixes the UI boundary, but exact firmware integration must be researched and qualified before the optional WebUI is published for that family; it does not block a core release. |
| Can both current Merlin families enforce an unprivileged local-script identity, reliable process-group cleanup, bounded resources, filesystem denial, and UID/process-scoped no-egress? | The local-script capability is conditional P0. If any boundary cannot be proved, the executor is absent on that platform without blocking core NUT support. |
| Is there a reproducible supported Entware WinRM/WSMan client cohort with a maintainable authentication stack? | Current feed reconnaissance did not establish an openwsman, pywinrm, or requests-ntlm package path. WinRM remains a conditional P2 capability; no runtime pip install or homegrown WSMan fallback is allowed. |
| Which BMC implementations permit a dedicated role that can read one ComputerSystem and request GracefulShutdown while denying ForceOff, reset, power-on, and administration? | This is both vendor- and firmware-dependent. A P2 Redfish binding is unavailable when the restriction cannot be proved harmlessly. |
| What qualified independent evidence can verify Off after SSH or WinRM graceful shutdown on targets without Redfish or another read-only management plane? | Disconnect and failed ping are explicitly insufficient. Each operation/target profile needs a credible verifier or must stop at dispatch_accepted. |
| Which NUT TLS server/client combinations are interoperable in the selected Entware build and common client ecosystem? | Native trusted-LAN NUT remains permitted without TLS. Verified NUT TLS is an optional profile that needs package, certificate, and cross-client evidence. |
| Which additional NUT drivers deserve versioned profiles after usbhid-ups and dummy-ups? | Driver recognition alone is insufficient. Each profile needs typed options, identity rules, privilege, lifecycle, harmless probes, migration, and hardware evidence. |
| Which non-ext4 storage profiles can satisfy the exact permission, fsync, rename, locking, execution, identity, and interruption matrix? | Filesystem names do not confer support. Each exact router/device/filesystem/mount combination needs qualification under ADR 0095. |
| What is the complete production FSD lifecycle, including router-primary behavior, secondary coordination, durable commitment, UPS power-down state, restoration, and exact hardware gates? | Production FSD is Later and unavailable until one coherent decision and test matrix covers the full lifecycle; P1 simulation does not answer it. |
| What future safety and physical-control model could admit UPS/PDU output control or abrupt power actions? | It must define device-specific capabilities, multi-layer authorization, onsite confirmation, nonrepeatability, power-path dependencies, recovery, and qualification. A generic NUT command gate is explicitly insufficient. |
| What recovery model, dependency graph, and anti-flap criteria could admit target power-on or workload restoration? | Automatic restoration is Later. The design must address return-power stability, surge/load order, partial dependency recovery, and repeated outages. |
| Is an action-capable webhook protocol worthwhile, and what idempotency, authentication, typed operation, verification, and peer authorization contract would it require? | Generic P1 webhooks remain notification-only. A future action protocol cannot infer effect from arbitrary HTTP 2xx responses. |
| Should direct SNMP/PDU, multiple UPS sources, voting/failover, calendar scheduling, hibernation, specialized cluster/storage APIs, or built-in cloud/email/mobile services ever enter product scope? | Each is Later and requires its own user case, trust model, failure semantics, dependency footprint, and ADR. None is implied by the executor framework. |
| Can AMTM or another catalog provide an authenticated maintenance channel compatible with pinned release trust and user-initiated updates? | Catalog distribution remains Later until its key, artifact, update, rollback, and maintainer-ownership model is accepted. |
| How should an administrator expand the ordinary 8 MiB policy-version store when protected versions exhaust it? | New activation currently fails closed. Any expansion mechanism needs free-space, endurance, quota, rollback, and UI/CLI semantics in a future decision. |

## Hardware-dependent questions

These are qualification questions, not reasons to hard-code a model allowlist.

- Which exact latest stable 3004.388.x and 3006.102.x releases pass the full platform matrix at each NUTMerlin release?
- Which exact router models and hardware revisions have complete community-reproducible reports? The RT-AX86U Pro is the production reference and requires NUTMERLIN_ALLOW_PRODUCTION_ROUTER=1 for modification; the RT-AC3100 is optional legacy evidence only.
- Does the selected router expose the required Addons API, hook, firewall, process-identity, mount, fsync, locking, and clock-synchronization capabilities without exceptions?
- Does the exact UPS expose a unique serial? If not, do its VID/PID and profile-specific immutable attributes resolve to exactly one device without relying on first match or bus/port alone?
- For each UPS/firmware/driver/NUT combination, which of OL, OB, recovery, LB, charge, runtime, voltage, load, stale indication, and disconnect behavior are qualified, observed-only, known-unreliable, or absent?
- Can the first-public physical report demonstrate harmless OL, short OB/recovery, stale or disconnect/reconnect, and stable identity without deep discharge or any writable/output command?
- Which exact storage device, filesystem, and mount-option combinations preserve modes, identities, atomic rename, file/directory fsync, locks, and data across reboot, reconnect, controlled interruption, and read-only recovery?
- For Redfish, which endpoint, service identity, selected ComputerSystem, TLS chain/pin, account role, session behavior, GracefulShutdown task behavior, and Off reporting are qualified?
- For WinRM, which Windows editions, HTTPS listener/certificate configuration, workgroup/domain mode, JEA endpoint, account rights, firewall rule, and independent Off verifier are qualified?
- For SSH, which target operating systems and forced-command wrappers implement the typed graceful operation and return verifiable evidence without granting a general shell?
- Which switches, APs, storage systems, DNS services, gateways, and BMC networks are actual control-path dependencies in a given installation and therefore protected from ordinary load shedding?
- If Later work considers FSD or output control, what exact UPS transfer/output behavior, outlet topology, load, router power path, and restoration behavior has been physically qualified? No automated test may answer this by issuing output-off.

## Documentation reconciliation audit map

### requirements.md

The reconciliation applied these requirements changes:

- replace the stale repository owner with darvilp/nutmerlin and make the dual current-family/latest-qualified support contract explicit;
- separate supported platform, compatibility-only platform, legacy best-effort platform, qualified hardware, and independently qualified UPS capability;
- state that healthy preexisting Entware is a prerequisite; package mutation is scoped, current-feed-first, and never removed by ordinary uninstall;
- replace generic idempotent lifecycle wording with foreign-deployment refusal, conservative ownership recovery, journaled two-slot activation, rollback quarantine, clean-uninstall refusal, and emergency detach;
- require authenticated first install, pinned signed manifests, offline root custody, safe update windows, and user-initiated updates;
- make one authoritative usbhid-ups source and isolated dummy-ups the P0 source contract, with immutable complete configuration generations selected through NUT_CONFPATH;
- make client-local NUT secondary onboarding the P0 shutdown requirement and remove any implication that the router verifies a client's local shutdown;
- replace raw action/executor fields with logical targets, qualified bindings, immutable policy versions, typed operations, safety classes, explicit evidence grades, retry classes, dependencies, and conflict analysis;
- encode monitoring-only defaults, coordinator/network protections, freshness/debounce, qualified numeric fields, telemetry-loss inhibition, bounded action budgets, restart/storage latches, and prospective emergency inhibit;
- constrain webhook, MQTT, SSH, local script, Redfish, and WinRM to their accepted contracts;
- move production FSD, ForceOff, output control, restoration, direct SNMP/PDU, writable UPS administration, hibernation, multiple UPS, scheduling, and broad platform/cloud integrations to Later;
- replace vague force/output dual opt-in requirements with absence from P0–P2 and a requirement for future class-specific ADRs and qualification;
- add the exact history, support-bundle, policy-retention, credential-cutover, JFFS-anchor, filesystem, and clock-trust requirements from the numerical tables above.
- make the complete CLI core the default installation and define the WebUI as an explicit, exact-version optional component whose removal or failure preserves all core state and service.

### architecture.md

The reconciliation applied these architecture changes:

- redraw the runtime around an unprivileged status/policy/UI plane, a small privileged lifecycle controller, and a narrow execution broker rather than a root monolith;
- separate NUT shutdown-client onboarding from the executor registry and remove nut_client as an executor;
- model Authoritative UPS source → normalized fresh observation → immutable policy version → exact target/action snapshot → binding/typed operation → durable intent → execution evidence → verifier;
- distinguish reversible episode state, durable commitment, dispatch intent, outcome_unknown, recovery reconciliation, and prospective inhibit;
- replace mutable target groups, generic priority, and global continue_on_error with authoring-only groups, explicit target snapshots, acyclic prerequisites, independent-action continuation, coalescing, and conflict rejection;
- replace ambient /opt/etc/nut editing with sealed complete configuration generations, one service-epoch NUT_CONFPATH, active/LKG retention, and paired code/config rollback;
- show separate volatile status, bounded operational history, 4 MiB safety journal, and two-slot 64 KiB JFFS anchor;
- add late-mount versus runtime-storage-fault states, NUT/USB restart breaker, dual-clock trust, listener/firewall exposure gate, and rollback quarantine;
- remove architecture paths that present production FSD in P1, SNMP/PDU in P2, Redfish ForceOff/restoration, raw writable NUT commands, or automatic simulated-source failover;
- describe the optional WebUI as a separately authenticated, exact-version Merlin adapter with a candidate-bound one-time nonce and the required CLI core as the complete local surface, with no standalone management API.

### security.md

The reconciliation promoted these accepted invariants:

- foreign or ambiguous ownership is never adopted or overwritten;
- fresh installation and every capability expansion are monitoring-only until explicitly validated and activated;
- no NUT or addon control surface is exposed to WAN by default; listener and firewall scope must agree continuously;
- no untrusted value is interpolated into a shell command, service-event name, path, header, query, or arbitrary payload;
- secrets are binding-scoped, shown once, file-permissioned, redacted, absent from argv/settings/browser/log/export/bundle, and never resurrected after revocation;
- no transport automatically downgrades; TLS identity, SSH host key, DNS resolution, peer address, redirect, and wall-clock gates fail closed;
- target-side least privilege is mandatory for SSH, WinRM, and Redfish; client-side command omission is not least privilege;
- a durable commit precedes nonrepeatable dispatch, timeout can become outcome_unknown, and rollback/uninstall cannot erase or repeat it;
- the coordinator and active control-path infrastructure are protected from ordinary policies;
- production FSD, abrupt power, output control, writable UPS administration, restoration, inbound MQTT, and a remote management API are absent through their stated milestones;
- safety-journal or JFFS-anchor failure, mismatch, read-only storage, source ambiguity, stale telemetry, or policy conflict inhibits new state-changing authority;
- no generic environment variable, checkbox, or dry-run result can register or authorize a higher safety class.
- the optional WebUI has no independent authority, version, listener, state model, or ability to block a qualified core-only installation.

### testing.md

The reconciliation organized tests by evidence claim rather than by available hardware:

- host tests on every change for POSIX sh portability, parsers, typed schemas, generated configurations, policy transitions, monotonic timers, conflicts, dependencies, retry/evidence state, redaction, ownership, and transaction recovery;
- golden and negative tests for every NUT driver profile and complete immutable configuration generation, including malicious values, symlinks, modes, hashes, NUT_CONFPATH consistency, mixed-epoch refusal, and one rollback;
- dummy-ups integration for OL/OB/recovery, contradictions, stale data, thresholds/hysteresis, telemetry loss, same-boot restart, reboot reset, breaker behavior, isolated simulation identity, and harmless simulated FSD;
- lifecycle fault injection at every install/update/config/rollback/uninstall journal boundary, with missing/read-only/replaced /opt, torn JFFS anchor slots, digest mismatch, insufficient space, and foreign/ambiguous ownership;
- network tests for one-subnet TCP 3493 scope, WAN/guest/VPN/VLAN denial, IPv6 default-off and fail-closed drift, restart/firewall-hook revalidation, DNS rebinding, peer mismatch, redirect refusal, and no management listener;
- credential tests for per-client isolation, once-only display, two-phase cutover at 1/24/168-hour boundaries, pending expiry, emergency revocation, tombstones, rollback resistance, file modes, and bundle/export exclusion;
- executor contract tests for dry-run, harmless activation evidence, timeout ceilings, concurrency/rate limits, nonrepeatable ambiguity, evidence grades, and verifier independence;
- protocol-specific simulators for fixed webhooks/HMAC framing, ephemeral QoS 1 MQTT and retained-state rules, forced-command SSH/host-key pinning, conditional local-script limits/no-egress, conditional JEA WinRM, and graceful-only Redfish with two-sample Off verification;
- security tests that prove no arbitrary shell, raw NUT command, writable UPS/PDU action, ForceOff, restoration, inbound MQTT, secret-bearing plaintext fallback, UI replay, or privilege fallback exists;
- current AArch64 Entware package/ABI execution for every release, exact-router report on the stated risk triggers, harmless physical-UPS base qualification, and independently gated field capabilities;
- destructive test gates for host shutdown and production-router mutation, while keeping every automated UPS output-off test prohibited.

The prior Redfish test case for optional ForceOff-enabled behavior was removed from P2 tests rather than merely disabled by default.

### hardware.md and development.md

The reconciliation applied these hardware and development changes:

- present the RT-AX86U Pro as a manually gated production-reference target, not proof of the entire 3006 family;
- keep the RT-AC3100 optional legacy best-effort and remove wording that makes its setup or ARMv7 feed part of the critical path;
- define the exact structured router, UPS capability, and storage qualification report fields and negative-report revocation behavior;
- recommend ext4/SSD while making eligibility capability-based and explicitly rejecting FAT/VFAT/exFAT;
- keep WSL2, direct USB passthrough, WinNUT, and the maintainer's CyberPower UPS as useful test arrangements rather than runtime dependencies or product scope;
- correct clone and repository examples to darvilp/nutmerlin;
- document the production-router, host-shutdown, and UPS-command test gates without implying that NUTMERLIN_ALLOW_UPS_COMMANDS authorizes output control.

### plan.md

The reconciliation replaced the feature-sequence plan with the capability freeze in ADR 0096 and the component boundary in ADR 0097:

- P0 core: safe signed lifecycle, current supported platform/package/storage contracts, one usbhid-ups source plus isolated dummy-ups, immutable NUT configuration, scoped LAN NUT service, independent secondary-client onboarding, complete CLI, bounded records/recovery, policy safety foundations, and conditional constrained local scripts; the curated WebUI is a separately qualified opt-in P0 component;
- P1: notification-only webhook/MQTT, restricted SSH, explicit graceful load-shedding stages, and harmless simulated FSD only;
- P2: only independently qualified graceful WinRM/Redfish and accepted additional NUT driver profiles;
- Later: production FSD, output/force/restoration, writable device administration, direct SNMP/PDU, root scripts, hibernation, multiple UPS, scheduling, inbound protocols, broad specialized adapters, cloud services, and AMTM distribution.

Release hardening, threat tests, documentation, and support evidence became exit criteria for every milestone rather than a final cleanup phase. Turning these bounds into implementation tasks was deliberately deferred beyond documentation reconciliation.

### backlog.md

The reconciliation applied these backlog changes:

- remove the already-created repository task and correct all stale owner references;
- split platform qualification, exact-router qualification, UPS capability qualification, storage qualification, and optional ARMv7 evidence into separate backlog concepts;
- add the release-blocking trust-channel/emergency-key research, the core platform research for clock trust, and separate nonblocking qualification research for optional-WebUI nonce integration;
- make local-script work conditional on qualified unprivileged/no-egress enforcement;
- narrow P1 webhook/MQTT/SSH items to the accepted profiles and move production FSD out of P1;
- narrow P2 WinRM and Redfish to capability-gated graceful-only adapters and move ForceOff, restoration, and direct SNMP/PDU out of P2;
- replace fixed noncritical/important/critical group semantics with label-only target groups and immutable exact stage snapshots;
- add future research items for driver profiles, NUT TLS, non-ext4 storage, full FSD, output control, restoration, action-capable webhook, multi-UPS, scheduling, AMTM trust, and policy-store expansion;
- remove any task whose acceptance test would automate a UPS output-off command.

### ADRs and terminology

- Keep root [CONTEXT.md](CONTEXT.md) as the only ubiquitous-language file and [decisions](decisions/) as the only ADR hierarchy.
- ADRs 0001–0097 are Accepted. Reconciled requirements and tests link to them rather than creating a new decision tree.
- Create a new ADR only when one of the research questions is genuinely answered or an accepted boundary is intentionally changed. Likely future ADR subjects are release fingerprint channels, platform-specific script containment, qualified WinRM stack, a new driver profile, a non-ext4 storage profile, production FSD, output control, restoration, action-capable webhook, direct SNMP/PDU, multi-UPS, calendar scheduling, AMTM distribution, and policy-store expansion.
- Do not create docs/adr or another project-document hierarchy.

## Reconciled stale or contradictory packet text

The reconciliation removed these settled contradictions:

| Prior packet text or shape | Accepted replacement |
| --- | --- |
| danielarvilpayne/nutmerlin in requirements, development, plan, and backlog | darvilp/nutmerlin |
| nut_client listed as an executor | Shutdown-client onboarding resource outside the executor registry |
| Production FSD as a P1 executor | Harmless isolated simulation in P1; complete production lifecycle in Later |
| Redfish optional ForceOff and restoration in P2 | Query plus GracefulShutdown and bounded Off verification only; force/restoration Later |
| SNMP SET or managed-PDU actions in P2 | Direct SNMP/PDU outside P0–P2; read-only device data only through an accepted NUT driver profile |
| Ordered noncritical/important/critical groups as built-in policy semantics | Groups are labels; an immutable policy version snapshots exact targets/actions and dependencies |
| Ambient generated files under /opt/etc/nut | Complete sealed NUTMerlin-owned generations selected for one service epoch through NUT_CONFPATH |
| Generic executor continue-on-error or priority | Independent action continuation, exact prerequisites, conflict rejection, and identical-intent coalescing |
| Force/output actions protected by dual opt-in | No such operations in P0–P2; future support needs a class-specific ADR, registry contract, credentials, qualification, and independent gates |
| Tests for ForceOff disabled/enabled behavior | No automated or P2 ForceOff test; graceful-only simulator tests and proof that ForceOff is absent |
| Curated WebUI bundled into every P0 core install | Complete CLI core is the default; WebUI is an explicit same-release, exact-version optional component with independent qualification |

## Primary external references consulted

Repository evidence and accepted ADRs are the source of product decisions. These primary sources were used to check protocol/package semantics and should be refreshed during implementation or release qualification:

- [NUT upsmon.conf manual](https://networkupstools.org/docs/man/upsmon.conf.html) for polling, dead-time, primary/secondary, and FSD-related semantics.
- [NUT upsd.conf manual](https://networkupstools.org/docs/man/upsd.conf.html) and [upsd manual](https://networkupstools.org/docs/man/upsd.html) for listener/configuration behavior and NUT_CONFPATH.
- [NUT upsdrvctl manual](https://networkupstools.org/docs/man/upsdrvctl.html) and [usbhid-ups manual](https://networkupstools.org/docs/man/usbhid-ups.html) for managed configuration and driver scope.
- [OASIS MQTT 5.0](https://docs.oasis-open.org/mqtt/mqtt/v5.0/mqtt-v5.0.html) and [MQTT 3.1.1](https://docs.oasis-open.org/mqtt/mqtt/v3.1.1/mqtt-v3.1.1.html) for clean-session, expiry, QoS, and retained-message semantics.
- [Current Entware AArch64 package index](https://bin.entware.net/aarch64-k3.10/Packages.html) and [ARMv7 feed index](https://bin.entware.net/armv7sf-k3.2/) for dependency reconnaissance; exact packages must be rechecked per release.
- [DMTF Redfish data model](https://redfish.dmtf.org/schemas/v1/DSP0268_2025.3.html) for ComputerSystem Reset and GracefulShutdown vocabulary.
- [Microsoft JEA role capabilities](https://learn.microsoft.com/en-us/powershell/scripting/security/remoting/jea/role-capabilities?view=powershell-7.6), [JEA security considerations](https://learn.microsoft.com/en-us/powershell/scripting/security/remoting/jea/security-considerations?view=powershell-7.6), and [PowerShell remoting troubleshooting](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_remote_troubleshooting?view=powershell-7.5) for constrained WinRM and workgroup HTTPS boundaries.
- [OpenSSH ssh_config](https://man.openbsd.org/OpenBSD-7.4/ssh_config.5) and [ssh-keygen](https://man.openbsd.org/OpenBSD-7.3/ssh-keygen.1) for strict host-key and key-algorithm contracts.
- [Merlin/amtm WebUI packaging survey](research/merlin-webui-packaging.md) for primary-source evidence of both separate companion UIs and bundled counterexamples.

## Closeout

The design interview and follow-up correction settled 97 ADRs and the terminology needed to discuss them. The root documentation reconciliation is complete. Product implementation, issue creation, ticket generation, and formal implementation planning remained outside both phases.
