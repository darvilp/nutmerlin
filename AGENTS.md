# AGENTS.md — Codex and contributor instructions

## Mission

Build NUTMerlin as a safe Asuswrt-Merlin integration layer around Entware-provided Network UPS Tools. Do not create a new UPS protocol implementation.

## Read first

Before changing code, read:

1. `CONTEXT.md`
2. `requirements.md`
3. `architecture.md`
4. `security.md`
5. `testing.md`
6. `hardware.md` and `development.md`
7. The relevant ADRs under `decisions/`

Accepted ADRs control when a summary is less precise. When requirements still conflict, safety and explicit acceptance criteria take precedence.


## Maintainer environment and hardware policy

- The primary maintainer environment is Codex IDE beta with the repository stored in the WSL2 Linux filesystem.
- Do not assume `/mnt/c` is the working tree.
- All normal tests must pass without an ASUS router or physical UPS.
- `dummy-ups` is the default UPS source for development.
- The RT-AC3100 is an optional legacy 386/ARMv7 target; do not block work waiting for it.
- The RT-AX86U Pro is a production-reference target and requires `NUTMERLIN_ALLOW_PRODUCTION_ROUTER=1` for deployment or modification.
- WSL2 is not the native Windows shutdown agent.
- Direct USB attachment to WSL is optional and must not become a project dependency.

## Core constraints

- Target POSIX `/bin/sh` compatible with Asuswrt-Merlin unless a component explicitly documents another runtime.
- Do not assume Bash.
- Do not patch or replace firmware files permanently.
- Use Merlin Addons API and user-script hooks.
- Keep substantial logic in `/jffs/addons/nutmerlin`; insert only small dispatch blocks into `/jffs/scripts/*`.
- Treat healthy preexisting Entware as a shared prerequisite; never bootstrap, format, repair, or own Entware.
- Treat `/opt` as fallible persistent storage that may be absent, late, read-only, or replaced.
- Avoid frequent writes to JFFS or Entware media; no persistent write on every UPS poll.
- Never store secrets in `custom_settings.txt`, JavaScript, generated status pages, logs, or command-line arguments where avoidable.
- Bind NUT to one explicitly confirmed trusted IPv4 scope by default and verify both listener and firewall admission.
- Never expose NUT to WAN by default, and expose no standalone addon-management listener through P2.
- Do not register `load.off`, `shutdown.*`, PDU outlet control, Redfish `ForceOff`, restoration, or equivalent abrupt/output operations through P2.
- Do not use NUT FSD as a cancelable outage timer.
- Production FSD remains unavailable until its complete lifecycle is separately accepted and qualified.
- Distinguish reversible outage actions from committed shutdown actions.
- Use one authoritative real UPS source through P2; keep `dummy-ups` distinct, loopback-only, and unable to inherit production authority.
- Do not assume a UPS reports reliable runtime, charge, voltage, or load values.
- Do not assume a client disconnect proves the operating system has powered off.
- The addon must remain client-neutral; WinNUT is one client example, not a runtime dependency or router-side executor.
- Fresh installs and upgrades remain monitoring-only.
- No transport may downgrade identity, encryption, protocol version, or address scope automatically.

## Safety rules for tests

- Default all executors to dry-run.
- CI and simulator tests must use harmless marker commands.
- Real-router tests must use `dummy-ups` unless the test explicitly requires the real UPS.
- Real-UPS tests begin read-only.
- Real-router tests must tolerate missing or read-only `/opt` without destructive action.
- No automated test may issue a UPS output-off command.
- Tests that can shut down a host must require an explicit environment variable or physical confirmation gate.
- Test scripts must refuse to run destructive stages when the target is the production router unless an override is supplied.
- A failed or ambiguous source, policy, binding, action, storage, network, or ownership state must fail closed.

Suggested gate names:

```text
NUTMERLIN_ALLOW_HOST_SHUTDOWN=1
NUTMERLIN_ALLOW_UPS_COMMANDS=1
NUTMERLIN_ALLOW_PRODUCTION_ROUTER=1
```

`NUTMERLIN_ALLOW_UPS_COMMANDS` does not register or authorize any output-control operation through P2.

## Implementation shape

Prefer small modules with narrow interfaces:

- platform detection
- Entware/package management
- ownership and release lifecycle
- immutable NUT configuration generation
- NUT source/service lifecycle
- status collection
- policy evaluation
- action coordination and execution broker
- optional web UI adapter
- operational history and safety journal

Keep policy evaluation independent from Merlin and NUT process management so it can be unit-tested on a normal Linux host. Keep privileged lifecycle and broker operations separate from unprivileged status, policy, and UI work.

## Configuration

- Generate complete immutable NUT configuration generations from a validated internal model.
- Render into a new private generation, validate, set ownership/mode, hash/seal, and atomically select it.
- Resolve one exact generation per service epoch and set `NUT_CONFPATH` for every managed NUT process.
- Retain only active and last-known-good sealed generations after staging.
- Preserve user-owned files unless NUTMerlin created and tracks them.
- Refuse ambiguous ownership rather than overwriting a preexisting manual NUT deployment.
- Validate all hostnames, addresses, usernames, typed operation values, paths, durations, thresholds, and identifiers.
- Never interpolate untrusted input into a shell command.
- Store complex target and policy data in dedicated files under `/jffs/addons/nutmerlin` or `/opt/etc/nutmerlin`, not in the shared 8 KB addon settings store.

## Executor contract

Every executor should implement the conceptual operations:

```text
validate(target, action)
test(target, action)
execute(target, action, event)
verify(target, action, execution_result)
describe_capabilities()
```

Execution results must include:

- executor name
- target ID
- policy ID
- event ID
- policy and operation version
- start and finish timestamps
- dry-run flag
- exit/result status
- retry count
- evidence grade
- redacted diagnostic message

Do not expose arbitrary shell execution through the UI or CLI. Shutdown-client onboarding is not an executor. Local scripts are imported immutable POSIX-shell artifacts and are available only on platform profiles that qualify unprivileged execution, resource/process containment, and no network egress without root fallback.

## Coding and test quality

Expected checks:

- repository under the WSL Linux filesystem for Linux-tool workflows
- `shellcheck`
- `shfmt -d`
- unit tests for parsing, validation, state transitions, and config generation
- integration tests against NUT `dummy-ups`
- golden-file tests for generated configuration
- manually gated install/upgrade/uninstall tests on an optional Merlin router when available
- security tests for input injection and interface binding

Do not mark a milestone complete by code presence alone. Meet the exit criteria in `plan.md`.

## Documentation changes

Update requirements, architecture, security, tests, and ADRs when behavior changes. Avoid silently changing semantics in code.

## Open questions

Do not invent answers for unresolved product decisions. Record research in `backlog.md`; create a new ADR under `decisions/` only when a hard-to-reverse trade-off is actually settled. Current unresolved subjects include:

- two independent release-root fingerprint publication channels and emergency root replacement
- platform evidence for same-boot clock synchronization and Merlin web nonce integration
- platform qualification for unprivileged/no-egress local scripts
- optional NUT TLS interoperability
- a reproducible Entware WinRM client stack and target Off verification
- Redfish BMC roles that permit GracefulShutdown while denying broader power authority
- additional NUT driver and non-ext4 storage profiles
- the separately deferred production FSD, output control, restoration, direct SNMP/PDU, multi-source, scheduling, and catalog models

## Agent skills

### Issue tracker

Issues and PRDs are tracked in GitHub Issues for `darvilp/nutmerlin`. See `docs/agents/issue-tracker.md`.

### Triage labels

The five canonical triage roles use their default label names. See `docs/agents/triage-labels.md`.

### Domain docs

This is a single-context repository: use root `CONTEXT.md` and ADRs under `decisions/`. See `docs/agents/domain.md`.
