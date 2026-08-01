# AGENTS.md — Codex and contributor instructions

## Mission

Build NUTMerlin as a safe Asuswrt-Merlin integration layer around Entware-provided Network UPS Tools. Do not create a new UPS protocol implementation.

## Read first

Before changing code, read:

1. `requirements.md`
2. `architecture.md`
3. `security.md`
4. `testing.md`
5. `hardware.md` and `development.md`
6. The relevant ADRs under `decisions/`

When requirements conflict, safety and explicit acceptance criteria take precedence.


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
- Treat `/opt` as Entware-backed persistent storage that may be absent or mounted late.
- Avoid frequent writes to JFFS or Entware media; no persistent write on every UPS poll.
- Never store secrets in `custom_settings.txt`, JavaScript, generated status pages, logs, or command-line arguments where avoidable.
- Bind NUT to selected trusted interfaces only.
- Never expose NUT or addon control endpoints to WAN by default.
- Never enable `load.off`, `shutdown.*`, PDU outlet-off, Redfish `ForceOff`, or equivalent destructive commands by default.
- Do not use NUT FSD as a cancelable outage timer.
- Distinguish reversible outage actions from committed shutdown actions.
- Do not assume a UPS reports reliable runtime, charge, voltage, or load values.
- Do not assume a client disconnect proves the operating system has powered off.
- The addon must remain client-neutral; WinNUT is one supported client, not a runtime dependency.

## Safety rules for tests

- Default all executors to dry-run.
- CI and simulator tests must use harmless marker commands.
- Real-router tests must use `dummy-ups` unless the test explicitly requires the real UPS.
- Real-UPS tests begin read-only.
- Real-router tests must tolerate missing or read-only `/opt` without destructive action.
- No automated test may issue an UPS output-off command.
- Tests that can shut down a host must require an explicit environment variable or physical confirmation gate.
- Test scripts must refuse to run destructive stages when the target is the production router unless an override is supplied.
- A failed or ambiguous policy must fail closed: log and avoid destructive action.

Suggested gate names:

```text
NUTMERLIN_ALLOW_HOST_SHUTDOWN=1
NUTMERLIN_ALLOW_UPS_COMMANDS=1
NUTMERLIN_ALLOW_PRODUCTION_ROUTER=1
```

`NUTMERLIN_ALLOW_UPS_COMMANDS` must not authorize output-off commands until a later project phase explicitly adds and tests that capability.

## Implementation shape

Prefer small modules with narrow interfaces:

- platform detection
- Entware/package management
- NUT configuration generation
- service lifecycle
- status collection
- policy evaluation
- executor dispatch
- web UI adapter
- audit logging

Keep policy evaluation independent from Merlin and NUT process management so it can be unit-tested on a normal Linux host.

## Configuration

- Generate NUT configuration from a validated internal model.
- Use atomic writes: write temporary file, validate, set ownership/mode, then rename.
- Back up the last known-good generated configuration.
- Preserve user-owned files unless NUTMerlin created and tracks them.
- Refuse ambiguous ownership rather than overwriting a preexisting manual NUT deployment.
- Validate all hostnames, addresses, usernames, commands, paths, durations, thresholds, and identifiers.
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
- start and finish timestamps
- dry-run flag
- exit/result status
- retry count
- redacted diagnostic message

Do not expose arbitrary shell execution through the normal web UI. The local-script executor may reference administrator-created scripts from an allowlisted directory.

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

Do not invent answers for unresolved product decisions. Record them in `backlog.md` or an ADR. Initial unresolved items include:

- minimum supported current Merlin firmware generation for public releases
- minimum supported Entware architecture/package versions
- UI placement and visual conventions
- long-term update channel and signing model
- whether central policy scheduling belongs in the MVP

## Agent skills

### Issue tracker

Issues and PRDs are tracked in GitHub Issues for `darvilp/nutmerlin`. See `docs/agents/issue-tracker.md`.

### Triage labels

The five canonical triage roles use their default label names. See `docs/agents/triage-labels.md`.

### Domain docs

This is a single-context repository: use root `CONTEXT.md` and ADRs under `decisions/`. See `docs/agents/domain.md`.
