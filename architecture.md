# NUTMerlin v0.1 architecture

## 1. System shape

```text
                           trusted IPv4 scope
                                  |
USB UPS -> usbhid-ups -> upsd ----+----> standard NUT secondary
                ^          ^                  owns local shutdown
                |          |
        generated config   +-- upsc/status
                ^
                |
     local POSIX-shell CLI and Merlin hooks
```

NUTMerlin invokes and configures Entware NUT. It does not replace any NUT protocol component and has no persistent controller process.

## 2. Components

### CLI and result renderer

`/jffs/addons/nutmerlin/bin/nutmerlin` validates the closed command surface and calls narrow modules. A small result module renders human output or the stable `nutmerlin.result.v1` JSON envelope and maps failures to documented exit codes.

The exact command grammar is:

```text
status [--json]
diagnostics [--json]
service start|stop|restart
source show
source use-dummy
source configure-usbhid --vendor-id ID --product-id ID [--serial S | --busport P]
lan configure --address IPv4 --cidr CIDR
lan disable
client add NAME [--json]
client revoke CLIENT_ID
enable | disable | repair | uninstall
update ARCHIVE
```

### Installer and ownership

The installer creates one code root under `/jffs`, one private configuration root under `/opt`, and delimited hook blocks. Matching installation IDs and fixed owned-object metadata distinguish owned, absent, foreign, and ambiguous state. Foreign or ambiguous state is never adopted.

### Configuration and profiles

The configuration module converts a closed typed model into a complete candidate directory. It owns exactly two source renderers: dummy and usbhid. It validates the candidate, writes a checksum manifest, and atomically replaces a small `current` selector on the same filesystem.

### Service lifecycle

The service module resolves `current` once, exports its `NUT_CONFPATH`, and controls the selected driver and `upsd`. It validates service identity through local `upsc` plus source-specific and network-specific checks. One volatile lock serializes lifecycle work.

### Merlin adapter

The platform module contains the only direct use of `/jffs/scripts`, `nvram`, `iptables`, `cru`, mount inspection, and process utilities. Host tests replace this external boundary with isolated roots and harmless shims. Internal NUT and configuration modules are not mocked.

## 3. Filesystem layout

```text
/jffs/addons/nutmerlin/
    bin/nutmerlin
    lib/*.sh
    share/dummy/cyberpower.dev
    VERSION
    installation.id
    entware.tsv
    hooks.tsv
    owned-files
    enabled

/opt/etc/nutmerlin/
    installation.id
    config/current
    config/last-good
    config/sets/<id>/model.tsv
    config/sets/<id>/ups.conf
    config/sets/<id>/upsd.conf
    config/sets/<id>/upsd.users
    config/sets/<id>/clients/<id>
    config/sets/<id>/SHA256SUMS

/tmp/nutmerlin/
    lock/
    run/
        recovery.tsv
    state/
    log/
```

Candidate directories are created beneath `/opt/etc/nutmerlin/config`, not `/tmp`, so selector replacement remains on one filesystem. Directories containing credentials are `0700`; secret/configuration files are `0600` or the narrowest mode required by the qualified Entware NUT identity.

The ambient `/opt/etc/nut` is never modified. Its unexpected configuration contributes to foreign-deployment refusal.

`entware.tsv` records only the six observed required package names, versions, and one consistent architecture at installation. It is bounded compatibility evidence, not a package lock or a claim that NUTMerlin owns those shared packages. An explicitly authorized refresh follows ADR 0083; every package remains installed on addon removal.

`hooks.tsv` records the exact owned block digest for each of the five Merlin hook files. Unrelated hook bytes remain outside those delimited blocks. `recovery.tsv` is a closed three-line volatile counter; healthy checks do not create it, success removes it, and reboot discards it.

## 4. Configuration activation

1. Acquire the lifecycle lock.
2. Read and validate the active typed model without `eval` or shell sourcing.
3. Create a private candidate set with a random ID.
4. Render all NUT files from closed data.
5. Validate paths, content, ownership, modes, checksum manifest, and available NUT parser/driver checks.
6. Close external admission and stop the affected NUT stack.
7. Atomically select the candidate through `current.new -> current`.
8. Start the exact set and prove driver, `upsd`, `upsc`, source identity, and applicable listener/firewall state.
9. On failure, select the old set once only when that cannot reopen a removed LAN or credential scope; otherwise keep the safer candidate selected and stopped.
10. On success, select the previous set as last-good and delete older sets.

Security-reducing changes—credential revocation, LAN narrowing/disable, addon disable—replace last-good with the new restricted state after successful activation. Automatic fallback may not reopen a scope or credential the administrator removed.

This is a two-set configuration mechanism, not a general release or transaction manager.

## 5. Source lifecycle

### Dummy

The release fixture and renderer create a `dummy` source. Its `upsd` listener is loopback-only. The fixture may produce safe status transitions in isolated integration tests, but it cannot appear as `ups`, inherit trusted-LAN admission, or become a fallback.

### Physical USB

The `ups` source is a closed `usbhid-ups` configuration. Discovery gathers bounded diagnostic attributes, but activation requires exact VID/PID plus stable serial or stable physical busport and exactly one match. Logical bus/device values are diagnostic only.

Source loss stops or leaves unavailable the driver path. The periodic reconciler retries under the bounded recovery schedule. A different, duplicate, or ambiguous source remains unavailable.

## 6. Merlin lifecycle

Managed blocks call one CLI hook entrypoint:

- `services-start`: ensure the `cru` entry and reconcile enabled state.
- `post-mount`: reconcile immediately when `/opt` becomes available.
- `services-stop`: close admission and stop NUT.
- `unmount`: close and stop before the relevant storage leaves.
- `firewall-start`: rebuild and verify only the owned NUT chain.

The periodic job runs every five minutes. On a failed health check it attempts recovery. Three consecutive failures pause active restart for three checks, after which one probe is allowed. The counter is volatile, success clears it, and reboot begins a fresh bounded cycle.

Status and diagnostics report the fixed dimensions `installation`, `enabled`, `storage`, `source`, `driver`, `upsd`, `upsc`, `listener`, `firewall`, `client_count`, and `recovery`. Diagnostics add one failed layer and one safe remediation. JSON uses the `nutmerlin.result.v1` envelope; these read paths write no persistent state.

## 7. Network path

Dummy always renders loopback only. A healthy real source may render loopback plus one administrator-entered router LAN address. Before that server starts, the platform adapter creates and verifies an owned firewall chain admitting one administrator-entered source CIDR and denying other sources to that address and TCP port 3493.

The firewall hook recreates the rule after firmware firewall rebuild. Failure to establish or verify the chain restores a known loopback-only set when safe, or leaves the selected service stopped when fallback could reopen removed access. NUTMerlin never rewrites unrelated chains or router network configuration.

## 8. Client credentials

Each client record contains a stable bounded ID, a generated username, and 24 random bytes from `/dev/urandom` represented as 48 lowercase hexadecimal characters. The renderer emits one `upsmon secondary` stanza per record and no other grant. Creation returns the secret once; subsequent status lists only client IDs and usernames. Revocation activates an entirely new set and invalidates any fallback containing the old secret.

NUTMerlin does not install or configure the remote client's shutdown command and does not interpret disconnect as shutdown completion.

## 9. Install, update, repair, and removal

The development installer supports an isolated destination root. Router installation requires explicit production gating and a healthy preexisting Entware installation. It performs ownership, foreign-NUT, storage, package-manager, and compatibility checks before offering a default-No targeted refresh. Interactive acceptance or `--install-dependencies` authorizes exactly `/opt/bin/opkg update` followed by one install invocation naming the six required NUT roots. Existing owned services, periodic recovery, and external admission are stopped before that mutation; failure remains disabled and stopped. Success re-probes the complete compatibility contract and rechecks foreign state before installation continues. The installer emits bounded pre/post package evidence for the user; it creates no package-history store. No lifecycle path mutates packages.

Update accepts a local fixed-format archive and requires an adjacent `<archive>.sha256` sidecar containing the archive digest and basename. After verifying that digest, it extracts into one private sibling code directory and verifies the internal fixed-inventory per-file checksum manifest. It then stops exposure/services, renames the current code root to one temporary backup, activates the candidate, and performs a smoke check. It immediately restores on failure and deletes the backup on success.

Repair is idempotent for complete consistent ownership. It can restore known modes, an unambiguous current/last-good selector, exact hook blocks, the periodic job, volatile directories, and the intended enabled or disabled service state; it does not reconstruct modified content or ambiguous ownership. Disable retains data but removes all live surfaces, including attributable firewall state when `/opt` is unavailable. Complete uninstall requires the owned `/opt` root to be present and removes only verified owned objects; Entware packages and foreign objects remain.

## 10. Failure invariants

- Code remains callable from JFFS when `/opt` is missing.
- Loss of `/opt`, source, configuration, listener, firewall, or ownership closes external access.
- No recovery selects dummy for real authority.
- No persistent write occurs on a status poll or watchdog success.
- No code path exposes arbitrary shell, raw NUT text, FSD, UPS commands, output control, or remote actions.
- No addon failure modifies unrelated routing, DNS, DHCP, WAN, firewall, hooks, files, or processes.

## 11. Future architecture boundary

WebUI, notifications, centralized actions, policies, history, or multi-source behavior require a new architecture review. A later concurrent orchestrator should be considered as a small compiled controller and must not be grown implicitly inside these shell modules.
