# NUTMerlin

NUTMerlin is a proposed Asuswrt-Merlin addon that turns a supported ASUS router into a user-friendly Network UPS Tools (NUT) server and power-event orchestration point.

The project should make the common UPS patterns accessible without replacing NUT:

1. **Network UPS server** — hosts independently monitor NUT and apply local shutdown policy.
2. **Coordinated shutdown** — NUT primary/secondary semantics and committed FSD workflows.
3. **Agentless shutdown** — centrally invoke SSH, webhooks, MQTT, WinRM, Redfish, or other executors.
4. **Load shedding** — stop noncritical systems or controllable outlet groups in stages.
5. **Alerts only** — publish events without taking shutdown action.
6. **Custom orchestration** — local scripts and external automation systems.

## Working names

- Display name: **NUTMerlin**
- Repository/package slug: `nutmerlin`
- CLI: `nutmerlin`
- Addon directory: `/jffs/addons/nutmerlin`

The name is intentionally NUT-specific. NUT remains the protocol and device engine; additional shutdown methods are executors around NUT events, not a replacement UPS stack.

## Design priorities

- Standards-based and client-neutral.
- Safe defaults; no UPS load-off commands enabled by default.
- Client-local pull mode is the recommended default.
- Reversible outage handling is distinct from committed FSD.
- LAN-only exposure by default.
- Entware packages are dependencies; NUTMerlin is the integration layer.
- The core must remain useful without cloud services.
- Hardware-specific behavior must be isolated behind capability detection.
- All dangerous operations require explicit opt-in and test gates.

## Confirmed reference environment

- UPS: CyberPower `CP1500PFCLCD`, supported through NUT `usbhid-ups`.
- Production router: ASUS RT-AX86U Pro running Asuswrt-Merlin.
- Optional legacy integration router: ASUS RT-AC3100, currently stock Asuswrt and eligible for the final 386 Merlin build.
- Client: native Windows NUT client for graceful shutdown.
- Development: Codex IDE beta against a WSL2-hosted repository.

Normal development and CI must run without either router or the physical UPS. The RT-AC3100 is an optional 386/ARMv7 integration profile, not a prerequisite. The RT-AX86U Pro and physical UPS are manually gated final hardware targets.

## Project documents

- [`requirements.md`](requirements.md) — functional and nonfunctional requirements.
- [`plan.md`](plan.md) — phased implementation plan and milestone exit criteria.
- [`architecture.md`](architecture.md) — components, state model, deployment patterns, and executor model.
- [`testing.md`](testing.md) — layered test strategy, simulator approach, hardware tests, and release matrix.
- [`hardware.md`](hardware.md) — confirmed devices, AP-mode bench topology, router qualification, and storage-media checks.
- [`development.md`](development.md) — WSL2, Codex, containers, deployment profiles, and safe development workflow.
- [`repository.md`](repository.md) — GitHub repository defaults, creation steps, CI, labels, and release model.
- [`PACKET-CHANGELOG.md`](PACKET-CHANGELOG.md) — changes made to this starter packet.
- [`security.md`](security.md) — threat model and required controls.
- [`backlog.md`](backlog.md) — prioritized feature backlog, including Redfish.
- [`AGENTS.md`](AGENTS.md) — instructions and guardrails for Codex and contributors.
- [`decisions/`](decisions/) — initial architecture decision records.
- [`test/scenarios/`](test/scenarios/) — starter `dummy-ups` fixtures.

## Status

Planning scaffold only. No production implementation exists yet. Repository defaults are accepted, but the GitHub repository has not been created by this packet.

## External dependencies

Expected runtime dependencies include selected Entware NUT packages such as:

- `nut-common`
- `nut-driver-usbhid-ups`
- `nut-driver-dummy-ups` for simulation
- `nut-server`
- `nut-upsc`
- `nut-upscmd` only when administrative commands are enabled
- `nut-upsmon`
- `nut-upssched`

Additional executors may add optional dependencies such as an SSH client, `curl`, or an MQTT publisher.

## Source references

See [`references.md`](references.md). Versions and package availability must be rechecked during implementation rather than assumed permanently.
