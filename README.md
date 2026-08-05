# NUTMerlin

NUTMerlin is a small Asuswrt-Merlin add-on for running Entware Network UPS Tools as a conventional NUT server.

The v0.1 design is intentionally narrow:

```text
UPS -> usbhid-ups on the Merlin router -> upsd on one trusted LAN scope
    -> standard NUT secondary client -> client-local shutdown
```

The router reports UPS state and manages the NUT service. It does not centrally dispatch or verify host shutdown.

## v0.1 capabilities

- Uses a preexisting healthy Entware installation.
- Runs real `dummy-ups`, `upsd`, and `upsc` for development and diagnostics.
- Supports one loopback-only dummy profile and one uniquely identified `usbhid-ups` profile.
- Installs only attributable NUTMerlin files and refuses foreign NUT deployments.
- Generates complete owned NUT configurations with atomic selection and one last-known-good fallback.
- Integrates with Merlin lifecycle, mount, firewall, and shutdown hooks.
- Provides stable human-readable and JSON CLI status and diagnostics.
- Exposes the real NUT source only to one explicit trusted IPv4 scope.
- Creates a unique restricted `upsmon secondary` credential for each client.
- Supports user-initiated disable, repair, update, and conservative uninstall.

## Deliberate exclusions

v0.1 has no router-side outage policy, remote shutdown executor, action journal, FSD workflow, writable UPS administration, output control, WebUI, webhook, MQTT, SSH, WinRM, Redfish, support bundle, configuration import/export, or broad hardware matrix.

## Current status

The owned dummy core, Merlin lifecycle slice, and closed uniquely identified USB-source profile are implemented. Isolated install, real `dummy-ups`/`upsd`/`upsc`, five managed hooks, bounded recovery, local status/diagnostics, and host USB identity fixtures are covered by tests. Trusted-LAN exposure, client credentials, conservative removal, and exact router/UPS evidence remain on the v0.1 track in `plan.md`. No physical-UPS claim has yet been made. This repository is development software and not a published release.

## Development

Normal development runs on Linux or WSL2 without a router or physical UPS:

```sh
make bootstrap
make test
make test-nut
make package
```

See `development.md` and `testing.md`. Real-router modification is always manually gated with `NUTMERLIN_ALLOW_PRODUCTION_ROUTER=1`.

## Safety boundary

NUTMerlin never bootstraps or repairs Entware, never adopts a foreign NUT deployment, never binds NUT to WAN or wildcard addresses, never automatically replaces a failed physical source with simulation, and registers no writable UPS or output command.

## Documentation authority

`requirements.md` defines v0.1 behavior. Active decisions are listed in `decisions/README.md`; all other ADRs are historical or deferred. `architecture.md`, `security.md`, `testing.md`, and `plan.md` describe implementation and evidence without creating additional authority.

License: GPL-3.0-or-later.
