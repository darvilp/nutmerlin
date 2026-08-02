# NUTMerlin hardware, qualification, and bench safety

## 1. Reference environment is not the support contract

| Component | Maintainer use | Product meaning |
| --- | --- | --- |
| ASUS RT-AX86U Pro | Production-reference router | Manually gated exact-hardware evidence for one 3006.102.x model/revision/firmware; not proof of the family. |
| ASUS RT-AC3100 | Available spare, currently stock Asuswrt | Optional legacy Merlin 386/ARMv7 evidence only; no release or security-support promise. |
| CyberPower CP1500PFCLCD | Available physical UPS | Candidate usbhid-ups base/capability reports; not a runtime dependency or blanket supported-UPS claim. |
| Windows desktop | Possible native NUT secondary and graceful-shutdown target | Client example only; NUTMerlin remains client-neutral. |
| WSL2 with Codex IDE beta | Primary maintainer workspace | Development arrangement only; runtime and normal tests remain Linux/router based. |

NUTMerlin support is capability-based within the current AArch64 firmware-family contract. Exact model/revision qualification and exact UPS capability qualification are published evidence, not separate product tiers.

## 2. Platform support and hardware tiers

### 2.1 Supported platform contract

The intended current families are:

- 3004.388.x on AArch64;
- 3006.102.x on AArch64.

Only the latest NUTMerlin-qualified stable release in each family is supported. A new upstream stable must pass qualification before support moves. The prior qualified release then becomes compatibility-only without a grace period.

Mandatory capability probes determine eligibility. An eligible untested model remains inside the platform contract; an exact report makes it qualified hardware. Known reproducible incompatibility overrides general eligibility.

### 2.2 Exact hardware qualification

One complete reproducible report qualifies one exact router model and hardware revision for the recorded combination.

The report identifies:

- router model and hardware revision;
- exact firmware version and family;
- CPU architecture;
- Entware feed and exact relevant packages;
- NUT and addon versions;
- storage device, filesystem, and mount options;
- structured results and redacted diagnostics.

Every mandatory non-destructive core lifecycle, simulation, CLI, network, reboot, storage-fault, update/rollback, disable/enable, preservation, uninstall, and recovery check must pass without waiver or skip.

The optional WebUI has a separate qualification result for the same exact platform. Its report covers component add/remove/re-add, exact version/schema match, Addons API mounting, authenticated dispatch and nonce behavior, update/rollback component preservation, and core/CLI survival when UI integration fails. Missing or negative WebUI evidence does not revoke core qualification.

Qualification does not expire after a fixed calendar interval. A firmware, hardware revision, Entware feed/ABI, NUT major/minor, relevant NUTMerlin platform behavior, security advisory, or reproducible compatibility fault triggers fresh current evidence. A reproducible negative report revokes the affected qualification until resolution and retest.

### 2.3 UPS capability qualification

A NUT-compatible source is one exact UPS/driver/profile/NUT combination that:

- binds through a unique stable identity;
- produces stable OL;
- produces harmless short OB and recovery;
- handles stale or disconnect/reconnect;
- satisfies the base source profile without a writable command.

Each additional field or behavior is independent:

- LB;
- charge;
- runtime;
- voltage;
- load;
- overload;
- replace-battery;
- other status tokens.

A device-list entry, driver match, or successful upsc query does not qualify all telemetry. Reports label a field observed, qualified, known_unreliable, or absent.

## 3. Normal hardware-free path

Normal development and pull requests require only:

- a Linux host or WSL2 Linux workspace;
- platform/filesystem shims;
- a container or local NUT installation;
- isolated NUT dummy-ups;
- current Entware AArch64 package/ABI execution for release evidence.

No ordinary work waits for:

- the RT-AC3100;
- the RT-AX86U Pro;
- the CP1500PFCLCD;
- Windows shutdown;
- WSL USB passthrough;
- full firmware emulation.

## 4. RT-AX86U Pro production-reference target

The RT-AX86U Pro is an in-use production router. Every deployment or modification requires:

    NUTMERLIN_ALLOW_PRODUCTION_ROUTER=1

Before a test:

- identify the exact firmware and hardware revision;
- save current configuration and recovery instructions;
- verify the test does not alter routing/firewall/DNS beyond the exact NUTMerlin scope;
- use dummy-ups unless the test explicitly needs the physical UPS;
- keep action executors dry-run/harmless;
- prove missing/read-only /opt cannot trigger state-changing action;
- keep a separate local recovery path.

A successful report qualifies only its recorded combination and claims.

## 5. RT-AC3100 optional legacy target

The RT-AC3100 is useful only when its legacy platform supplies meaningful evidence. It is not part of the critical path, and setup may be skipped when cost, hardware condition, or architectural difference makes the result immaterial.

If used:

1. Record stock firmware and hardware revision.
2. Obtain and verify the final correct model-specific Merlin 386 image and recovery material.
3. Follow upstream transition/reset guidance; do not restore an old settings backup.
4. Enable only JFFS scripts and LAN-only administration needed by the test.
5. Keep WAN-port routing, remote administration, cloud/file/media services, WPS, and UPnP disabled unless a named test requires one.
6. Keep a local rescue utility, firmware copy, checksum, direct-access method, and reset/recovery instructions.
7. Store no production-only credential reusable on the RT-AX86U Pro.

Successful operation is legacy best-effort evidence, not current security maintenance.

## 6. Bench network topology

### 6.1 Recommended AP-mode legacy bench

    Windows/WSL development host -- primary trusted LAN
                                         |
                                         +-- RT-AC3100 LAN port, AP mode
                                                |
                                                +-- qualified Entware storage
                                                +-- optional UPS USB only for a named test

Recommended:

- static management address or DHCP reservation;
- WAN port unused;
- Wi-Fi disabled unless testing Wi-Fi behavior;
- SSH and web administration admitted only from named trusted hosts;
- no DHCP/NAT routing role;
- production and legacy credentials separated.

An unused WAN port does not remove internet egress in AP mode. Permit egress only for deliberate firmware/package setup or test, then block the legacy router at the primary router.

### 6.2 Router-mode firewall bench

Use an isolated router-mode subnet only when a test needs actual WAN/LAN separation. Keep WAN disconnected and ensure the development host has a recovery path that does not depend on the device under test.

## 7. Entware storage profiles

### 7.1 Reference profile

Recommended always-on profile:

- USB-attached SSD in a reliable enclosure;
- journaled ext4;
- execution enabled;
- native Unix ownership and modes;
- no swap;
- noatime recommended for endurance but not required for correctness.

A high-quality flash drive may be used for an intermittent test rig after validation; that does not confer an endurance promise. Brand, capacity, benchmark, SMART, or one successful fill test cannot prove remaining lifetime.

FAT, VFAT, and exFAT are incompatible. NTFS, F2FS, ext3, or another name receives no implied support.

### 7.2 Required semantic qualification

For the exact router/device/filesystem/mount options, use disposable data to prove:

- stable storage and mount identity across reboot/reconnect;
- persistent UID/GID;
- directory/file modes 0700, 0600, and 0640;
- case-sensitive stable names;
- regular, symlink, and hard-link distinctions;
- same-directory atomic rename;
- successful file and containing-directory fsync;
- reliable exclusive locks;
- executable Entware binaries;
- controlled interruption/remount without a mixed or silently lost journal or configuration generation.

Reject:

- noexec;
- read-only or unstable mounts;
- ownership/mode emulation;
- ignored chmod/chown;
- inconsistent link behavior;
- missing durable rename/fsync;
- unexplained I/O/reset/disconnect errors.

### 7.3 Media checks

Record identity and available health evidence with appropriate system tools such as lsusb, lsblk, udevadm, smartctl, dmesg, and fsck.

On empty disposable media, a complete F3 write/read cycle may detect false capacity and immediate corruption. It does not measure remaining endurance. A direct-device destructive probe must be performed only outside NUTMerlin automation, after positively identifying the exact expendable device and accepting total data loss.

SMART or wear data is optional evidence. Its absence does not fail support, and its presence does not replace filesystem/interruption tests.

### 7.4 Space and write behavior

Mutation requires the calculated transaction and package-manager temporary need plus at least 16 MiB post-transaction headroom.

Persistent layout budgets include:

- 4 MiB detailed safety journal reserve;
- 16 MiB default operational history;
- 8 MiB ordinary policy-version store;
- staged release/configuration material calculated before mutation.

High-frequency status stays in /tmp. No persistent poll record and no swap are required. JFFS receives only rare safety-boundary anchor updates, not operational history.

## 8. USB UPS attachment and identity

The preferred source identity is exact VID/PID/serial. The driver may bind only when the accepted profile resolves exactly one device.

If a UPS has no serial, a profile may use exact VID/PID plus accepted stable attributes only when exactly one candidate exists. USB bus/port and device node are supplemental diagnostics; they are never first-match authority.

Tests cover:

- reboot;
- cable removal/reinsert;
- device-node and bus/port change;
- duplicate compatible devices;
- replacement UPS;
- wrong/missing serial;
- driver restart breaker.

NUTMerlin never automatically substitutes dummy-ups when the real USB source fails.

## 9. Harmless physical UPS report

For the first public report:

1. Confirm exact UPS, driver profile, NUT, router, and addon identity.
2. Begin with read-only driver/upsd/upsc only.
3. Confirm stable OL.
4. Remove utility input briefly while keeping low-risk loads connected; confirm OB.
5. Restore input before deep discharge; confirm recovery.
6. Exercise either NUT stale behavior or USB disconnect/reconnect.
7. Confirm stable unique identity and no routing/log/process fault.
8. Record structured results and redacted diagnostics.

Do not:

- create a writable NUT administrative credential;
- run upscmd or upsrw;
- test load.off, shutdown.*, outlet, output cycle, or delayed power;
- deep-discharge the battery;
- use network infrastructure or important storage as a sacrificial load;
- infer reliability of every numeric field from the base report.

Field-specific runtime/charge qualification is a separate controlled report and should use replay for subsequent policy testing.

## 10. Windows and WSL roles

The runtime Windows pattern is:

    UPS -> NUT server on ASUS router -> native Windows NUT secondary -> local Windows shutdown

WSL2 is used for development, package tests, deployment, SSH, and NUT query. It is not the native Windows shutdown agent.

Direct USB attachment to WSL through usbipd-win is optional experiment infrastructure. The device cannot simultaneously belong to PowerPanel, a native client, and a WSL NUT driver; this path must not become a dependency.

Client testing progresses from:

1. read-only connection;
2. secondary authentication;
3. harmless local marker;
4. short-outage cancellation;
5. long-outage local action;
6. optional actual shutdown under NUTMERLIN_ALLOW_HOST_SHUTDOWN=1.

Client disconnect is never treated as proof that Windows is Off. Hibernation is Later.

## 11. Report handling and community hardware

Community reports use the same structured runner and evidence requirements as maintainer reports. A partial or anecdotal success may be published as community experience but does not confer qualification.

Public reports and support bundles:

- remove device serials and usernames where not needed;
- generalize LAN addresses/prefixes;
- pseudonymize target labels/IDs;
- contain no credentials, private keys, bearer/HMAC data, or reusable production endpoint;
- state every skipped test and the exact claim boundary.

A reproducible negative report is actionable evidence. It can revoke an exact qualification or establish known incompatibility without deleting the historical positive report for the old combination.
