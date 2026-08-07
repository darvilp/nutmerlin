# AGENTS.md — NUTMerlin contributor instructions

## Mission

Build NUTMerlin v0.1 as a conventional Asuswrt-Merlin integration around Entware-provided Network UPS Tools. The product is a NUT server add-on, not a UPS protocol implementation or a centralized shutdown orchestrator.

The v0.1 path is:

```text
UPS -> Entware NUT on the Merlin router -> standard NUT secondary client
    -> client performs its own local shutdown
```

## Read first

Before changing code for a ticket, read in this order:

1. `CONTEXT.md`
2. `requirements.md`
3. `architecture.md`
4. `security.md`
5. `testing.md`
6. `hardware.md`
7. `development.md`
8. `plan.md`
9. Active ADRs listed in `decisions/README.md`

Only ADRs listed as active in `decisions/README.md` are binding for v0.1. Historical and deferred ADRs are not implementation requirements. Requirements define behavior, active ADRs settle durable trade-offs, architecture describes the implementation, security constrains it, testing defines evidence, and plan defines order.

## Environment and hardware

- The primary workspace is the WSL2 Linux filesystem; do not assume `/mnt/c`.
- Normal tests require neither an ASUS router nor a physical UPS.
- Real `dummy-ups` is the default development source and remains loopback-only.
- The RT-AX86U Pro is the exact production-reference router. Any deployment or modification requires `NUTMERLIN_ALLOW_PRODUCTION_ROUTER=1`.
- The CyberPower CP1500PFCLCD is the first physical reference UPS.
- The RT-AC3100 and other router or UPS models are outside the v0.1 critical path.
- WSL2 is not a native Windows shutdown agent. Direct USB attachment to WSL is optional.

## Runtime constraints

- Target POSIX `/bin/sh`; do not assume Bash.
- Use Entware NUT for drivers, `upsd`, `upsc`, and standard client semantics.
- Keep substantial code in `/jffs/addons/nutmerlin` and only small delimited blocks in Merlin user-script hooks.
- Do not permanently patch firmware files.
- Treat healthy preexisting Entware as a shared prerequisite. The installer may, after an explicit default-No prompt or `--install-dependencies`, run `opkg update` and one targeted install/refresh of the six required NUT package roots. The installed local menu may offer that same targeted operation only after an explicit default-No prompt; it has no noninteractive authorization. Never bootstrap or repair Entware, change feeds, run a blanket upgrade, downgrade packages, or remove packages.
- The only code download path is a generated release-specific fresh-install launcher: it pins one release archive and digest, stages below `/tmp`, verifies before extraction, and enters the existing menu. Installed updates remain local-archive-only. Do not add a generic downloader, automatic update check, or stream-to-shell install.
- Treat `/opt` as fallible. Keep high-frequency state and logs in `/tmp`, and do not write persistent state on every poll.
- Refuse foreign or ambiguously owned NUT deployments instead of adopting or overwriting them.
- Use complete owned NUT configuration sets selected atomically through `NUT_CONFPATH`, retaining only current and last-known-good.
- Keep the runtime small: an invoked CLI, narrow shell modules, NUT processes, Merlin hooks, and one periodic reconciler. Do not add a NUTMerlin daemon, database, journal, worker queue, or orchestration engine.

## Safety constraints

- Fresh installs and upgrades are monitoring-only.
- Keep dummy distinct, loopback-only, and unable to replace a real source automatically.
- Select a physical UPS by stable unique identity, never first match, bus number, or device number.
- Bind external NUT only to one explicitly configured router IPv4 address and one trusted IPv4 CIDR. Verify listener and firewall rules together. Never expose to WAN or wildcard addresses.
- Generate one restricted `upsmon secondary` credential per client. Store secrets in root-only files and show new secrets once.
- Do not expose arbitrary shell, raw driver options, raw NUT configuration, writable UPS variables, instant commands, FSD, output control, PDU operations, remote shutdown executors, or addon-management listeners.
- Never run network-facing `upsd` as root.
- Missing or ambiguous source, storage, configuration, ownership, listener, firewall, or credential state fails closed without disrupting unrelated router networking.

## Test safety

- Host and simulated-router tests use isolated roots and harmless process/firewall shims.
- Real NUT integration uses `dummy-ups` on loopback.
- Real-router tests use dummy first and require the production-router gate.
- Physical-UPS tests begin read-only and must not issue writable variables, instant commands, FSD, output-off, or deep-discharge operations.
- Host-shutdown testing is outside the v0.1 release gate. Any later such test requires `NUTMERLIN_ALLOW_HOST_SHUTDOWN=1`.
- `NUTMERLIN_ALLOW_UPS_COMMANDS=1` does not authorize any v0.1 operation; v0.1 registers no UPS command.

## Implementation discipline

- Work one GitHub ticket at a time using native issue dependencies as blocking authority.
- Start each ticket from a recorded clean commit and preserve unrelated changes and WIP branches.
- Establish failing behavior at the public CLI, generated configuration, real NUT process chain, or isolated Merlin adapter seam before implementation when practical.
- Make the smallest coherent change that proves the ticket's observable acceptance criteria.
- Run focused checks and the applicable full host gates. At the final ticket gate, use the `code-review` skill once to run the separate Standards and Specification reviews in parallel. Repeat only a targeted review when the first pass reports a substantive actionable finding; do not add review cycles after both axes are clean.
- Use one focused commit per completed ticket, push normally, add evidence, and close only after push and acceptance evidence.
- Do not merge, force-push, publish a release, delete WIP branches, or close umbrella issue #2.
- Escalate only a genuine new architecture, public interface, persistence/configuration, deployment, safety, or runtime-dependency decision.

## Complexity stopping rules

Stop and require a new architecture review if work proposes centralized actions, policy execution, FSD, a WebUI, a persistent event journal, multiple background workers, concurrent scheduling, a new runtime dependency, or a general transaction manager. If centralized orchestration returns later, evaluate a small compiled controller instead of growing the shell lifecycle code into that role.

## Issue tracker

Issues and PRDs are tracked in GitHub for `darvilp/nutmerlin`. Follow `docs/agents/issue-tracker.md`; canonical triage labels are documented in `docs/agents/triage-labels.md`.
