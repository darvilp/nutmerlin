# NUTMerlin v0.1 requirements

## 1. Product outcome

NUTMerlin v0.1 shall install and operate Entware NUT as a standards-compatible monitoring-only server on one exact Asuswrt-Merlin reference router. A standard NUT secondary client shall authenticate with an independent restricted credential and own its local shutdown behavior.

The first complete tracer shall prove installation, dummy NUT operation, lifecycle recovery, local CLI status, exact trusted-LAN exposure, secondary-client onboarding, a uniquely identified physical UPS, reboot and reconnect recovery, owned repair/removal, and exact hardware evidence.

## 2. Runtime and platform

- Runtime code shall be POSIX `/bin/sh` compatible.
- NUT shall own UPS protocols, drivers, `upsd`, `upsc`, and standard client semantics.
- Substantial code shall live under `/jffs/addons/nutmerlin`; firmware hook files receive only small delimited dispatch blocks.
- The runtime shall contain no NUTMerlin daemon, policy engine, broker, worker queue, database, or persistent journal.
- Normal development and CI shall require neither an ASUS router nor a physical UPS.
- Production-reference deployment or modification shall require `NUTMERLIN_ALLOW_PRODUCTION_ROUTER=1`.

## 3. Entware and ownership

- Installation shall require a preexisting healthy Entware installation.
- NUTMerlin shall check required package and binary compatibility without installing, upgrading, repairing, or removing Entware packages.
- Missing dependencies shall produce exact administrator guidance.
- Foreign or ambiguously owned NUT files, configuration, processes, listeners, hooks, or ownership evidence shall cause read-only refusal before mutation.
- An installation ID and owned-file metadata shall cover every NUTMerlin code root, hook block, configuration root, scheduled job, and firewall object.
- Repair and uninstall shall modify only attributable artifacts. Normal uninstall shall remove no Entware package.

## 4. Storage and configuration

- `/opt` shall be treated as fallible, late, read-only, replaceable storage.
- High-frequency status, retry, PID, lock, and log data shall remain under `/tmp`.
- Persistent state shall be limited to installation identity, enabled state, source settings, LAN scope, client credentials, and current/last-known-good configuration.
- Configuration values shall be parsed as typed data without `eval` or sourcing administrator-writable shell text.
- NUTMerlin shall render a complete private `ups.conf`, `upsd.conf`, and `upsd.users` set, validate it, set ownership/modes, hash it, and atomically select it.
- Every managed NUT process in one service epoch shall use the same resolved `NUT_CONFPATH`.
- Only current, last-known-good, and an active candidate set may exist.
- A failed activation may restore the prior set once. Rollback shall never restore a revoked credential, wider LAN scope, enabled service, or dummy source under real-source authority.

## 5. Source profiles

- v0.1 shall provide one closed release-owned `dummy-ups` profile named `dummy`.
- Dummy shall be loopback-only, visibly simulated, and never selected automatically after physical-source failure.
- v0.1 shall provide one closed `usbhid-ups` profile named `ups`.
- Physical selection shall require exact VID/PID plus a stable serial or accepted stable physical `busport` and shall resolve exactly one device.
- Logical bus/device numbers and first-match selection shall never authorize a source.
- Missing, changed, or duplicate identity shall keep the physical driver unavailable.
- No profile shall expose arbitrary driver options, writable variables, instant commands, FSD, shutdown commands, or output control.

## 6. Service lifecycle

- The local CLI shall start, stop, and restart the owned driver and `upsd`.
- Merlin `services-start`, `services-stop`, `post-mount`, `unmount`, and `firewall-start` hooks shall invoke one idempotent lifecycle path.
- One named `cru` job may reconcile health periodically without persistent per-check writes.
- Duplicate hook invocations shall not create duplicate jobs or processes.
- Missing/read-only `/opt`, invalid configuration, source ambiguity, or ownership mismatch shall leave external access closed.
- Recovery attempts shall be bounded and shall not create restart or logging storms.
- No failure or recovery path may change unrelated routing, DNS, DHCP, WAN, firewall, process, file, or hook state.

## 7. CLI and diagnostics

- The stable CLI surface shall be:

```text
nutmerlin status [--json]
nutmerlin diagnostics [--json]
nutmerlin service start|stop|restart
nutmerlin source show
nutmerlin source use-dummy
nutmerlin source configure-usbhid --vendor-id ID --product-id ID [--serial S | --busport P]
nutmerlin lan configure --address IPv4 --cidr CIDR
nutmerlin lan disable
nutmerlin client add NAME [--json]
nutmerlin client revoke CLIENT_ID
nutmerlin enable
nutmerlin disable
nutmerlin repair
nutmerlin update ARCHIVE
nutmerlin uninstall
```

- Commands shall reject unknown flags, excess arguments, and incompatible option combinations.
- Every operation shall provide stable human output and documented exit classes. Commands whose grammar includes `--json` shall instead provide the documented `nutmerlin.result.v1` JSON envelope.
- Exit classes shall use 0 success, 64 usage, 69 unavailable, 70 internal, 75 temporary, and 78 configuration refusal.
- Status shall expose an allowlist of common NUT values and explicitly represent missing/unavailable values. Numeric fields shall not be assumed present or reliable.
- Diagnostics shall identify the failed layer and a safe corrective action without revealing secrets.

## 8. Network exposure

- External NUT access shall be disabled by default and unavailable for dummy.
- The administrator shall explicitly enter one router LAN IPv4 listener address and one trusted IPv4 CIDR.
- Wildcard, `/0`, loopback, multicast, broadcast, WAN-equal, invalid, and default IPv6 exposure shall be rejected.
- `upsd` shall bind only loopback plus the selected LAN address.
- An owned firewall chain shall admit only the selected source CIDR to that address and port and deny other sources.
- Listener and firewall agreement shall be verified before exposure and reconciled after firewall restart.
- Network-facing `upsd` shall not run as root.

## 9. Secondary clients and secrets

- Each client shall receive a stable client ID and a unique credential generated from 24 bytes read from `/dev/urandom` and represented as 48 lowercase hexadecimal characters.
- The generated NUT role shall be only `upsmon secondary`, with no actions, instant commands, or administration.
- A new secret shall be shown once, stored in a root-only file, and absent from logs, arguments, status, diagnostics, packages, and documentation.
- Revocation shall produce and activate a complete new configuration and shall not be undone by last-known-good recovery.
- NUTMerlin shall not store client operating-system credentials, send client shutdown commands, or treat disconnect as powered-off evidence.

## 10. Lifecycle operations

- Fresh install and update shall remain monitoring-only.
- Disable shall close listener/firewall, stop owned NUT processes, remove the periodic job, and retain owned data.
- Repair shall restore only attributable files, modes, hook blocks, configuration selection, and service state.
- Complete uninstall shall require attributable `/opt` state to be present, close exposure, stop services, remove owned code/configuration/credentials/jobs/rules/blocks, and retain Entware packages.
- Missing storage shall permit safe disable but shall cause complete uninstall to refuse with residual-data guidance.
- Update shall be user-initiated from a local archive, validate the archive against a required adjacent `<archive>.sha256` sidecar plus its internal fixed-inventory checksum manifest, use one temporary code backup, smoke-test, and restore immediately on failure.
- v0.1 shall have no automatic update, long-lived release slot, rollback command, rollback quarantine, or release transaction journal.

## 11. Evidence and release

- Ordinary PRs shall pass POSIX/static, host unit/golden, real host dummy NUT, simulated Merlin lifecycle, security, documentation, and deterministic-package checks.
- Exact-router and physical-UPS evidence shall remain manual and separately claimed.
- The first alpha shall record the exact RT-AX86U Pro revision/firmware, Entware/NUT versions, storage, CP1500PFCLCD identity, and client test environment.
- Physical tests shall remain read-only except for harmless utility-input removal and USB reconnect. They shall not trigger host shutdown, FSD, deep discharge, writable variables, instant commands, or output operations.
- An alpha package shall be deterministic and published with a source tag and SHA-256 checksum. It shall not claim independent publisher authentication.
- OpenPGP roots, independent fingerprint channels, emergency root replacement, full feed locks, AMTM publication, broad matrices, and WebUI artifacts are later release work and shall not block v0.1 alpha.

## 12. Explicitly deferred

Router-side policies and actions; policy or target registries; action brokers, budgets, conflicts, dependencies, or concurrency; SSH, WinRM, Redfish, webhook, MQTT, or local-script execution; FSD; writable UPS administration or output control; action-reconciliation anchors; generalized clocks, transactions, rollback, history, support bundles, import/export, WebUI, additional drivers, general platform support, and release-root ceremony are outside v0.1.
