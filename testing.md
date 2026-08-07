# NUTMerlin v0.1 testing and evidence

Evidence is layered. Passing one layer never claims another. `make test-nut` is an enforced ordinary gate and uses real host NUT binaries.

## 1. Ordinary pull-request gates

### POSIX and static

- `sh -n` on every runtime/test shell file.
- `shellcheck -s sh`.
- `shfmt -d`.
- No Bash syntax, `eval`, untrusted sourcing, unsafe temporary paths, or writes outside isolated roots.
- Documentation link and active-ADR checks.

### Host unit and golden tests

Test behavior through the CLI, generated configuration, installer destination root, and platform adapter seams:

- Typed validation and bounded parsing.
- Stable human/JSON results and exit codes.
- Dummy and usbhid configuration goldens.
- Current/LKG selection and non-widening rollback.
- Ownership/foreign-state classification.
- Hook insertion, repair, and exact removal.
- Firewall/listener construction.
- Credential generation, once-only output, redaction, and revocation.
- Scripted local-menu navigation, confirmation defaults, literal-value forwarding, end-of-input safety, and once-only secret display.
- Recovery locking and bounded retry states.
- Archive inventory and path safety.
- Deterministic release-artifact generation and the generated fresh-install launcher as an external administrator would invoke it.
- Fresh-install download failure, truncation, digest mismatch, unsafe inventory/type/mode refusal, internal-manifest failure, foreign-state refusal, menu quit/end-of-input, cleanup, and the valid path into the existing menu.

Expected values shall be fixed specification examples, not values recomputed by the production implementation.

### Real host NUT integration

`make test-nut` shall use installed NUT binaries and a disposable root to:

1. Render the release dummy fixture.
2. Start real `dummy-ups` and `upsd` on loopback.
3. Query `dummy@127.0.0.1` with real `upsc`.
4. Confirm expected status values.
5. Restart and stop cleanly.
6. Prove invalid configuration leaves no running process.
7. Start, restart, query, and stop the installed chain through the interactive menu.

Mock process output cannot satisfy this layer. CI installs only host test packages; this does not modify router Entware.

### Simulated Merlin lifecycle

Use isolated fake `/jffs`, `/opt`, and `/tmp` roots plus boundary shims for `nvram`, mounts, `iptables`, `cru`, and process utilities. Cover:

- Install, repeat install, and foreign refusal.
- Delayed, missing, read-only, and replaced `/opt`.
- Every managed hook and duplicate/concurrent delivery.
- Reboot reconstruction and periodic reconciliation.
- Service death, failed restart, pause, probe, and recovery.
- Exact firewall insertion/removal and unrelated-rule preservation.
- Disable, repair, update failure/recovery, and uninstall.
- Fresh-install launcher behavior through an isolated private `/tmp` root and harmless curl adapter; tests may not contact GitHub or the host network.

Host shims must make writes to real `/jffs`, `/opt`, firewall, cron, or processes impossible.

## 2. Manual exact-router evidence

The RT-AX86U Pro test records exact hardware revision, Merlin build, architecture, Entware feed/NUT packages, storage, and addon commit/package. It requires `NUTMERLIN_ALLOW_PRODUCTION_ROUTER=1`.

Dummy comes first. Exercise install, hooks, CLI, delayed `/opt`, reboot, process failure, firewall rebuild, enable/disable, repair, update, unrelated-content preservation, and uninstall. This proves only the recorded router combination.

## 3. Manual physical-UPS evidence

The CP1500PFCLCD report records exact USB identity, NUT version, driver profile, router, and addon version. It proves:

- Unique stable binding.
- Stable OL.
- Brief harmless OB and return to OL.
- USB disconnect/reconnect.
- Missing and duplicate identity refusal where safely reproducible.
- `upsc` through the configured trusted LAN.
- Standard secondary-client authentication and revoked/wrong-secret failure.

Do not use FSD, host shutdown, writable variables, instant commands, output control, deep discharge, or important equipment as a sacrificial load. Numeric telemetry is recorded as observed, absent, or unreliable; it is not generally qualified.

## 4. Packaging evidence

- Build twice from one commit and compare bytes.
- Inspect exact archive paths, types, modes, owners, and timestamps.
- Reject absolute paths, traversal, unexpected symlinks, extra files, and duplicate entries.
- Smoke install, service check, update failure recovery, disable, and uninstall under isolated roots.
- Produce SHA-256 and identify the exact source commit.

## 5. Gate separation

Ordinary PRs require static, unit/golden, real host dummy, simulated Merlin, security, docs, and package tests. Exact-router and physical-UPS evidence are manual and do not block ordinary implementation. They block only the hardware claim and first alpha.

No emulator result, dummy result, package listing, or code presence may be described as exact-router or physical-UPS proof.
