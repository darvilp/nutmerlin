# NUTMerlin

NUTMerlin is a small Asuswrt-Merlin add-on for running Entware Network UPS Tools as a conventional NUT server.

The v0.1 design is intentionally narrow:

```text
UPS -> usbhid-ups on the Merlin router -> upsd on one trusted LAN scope
    -> standard NUT secondary client -> client-local shutdown
```

The router reports UPS state and manages the NUT service. It does not centrally dispatch or verify host shutdown.

## v0.1 capabilities

- Uses a preexisting healthy Entware installation and can explicitly install or refresh only its six required NUT package roots.
- Runs real `dummy-ups`, `upsd`, and `upsc` for development and diagnostics.
- Supports one loopback-only dummy profile and one uniquely identified `usbhid-ups` profile.
- Installs only attributable NUTMerlin files and refuses foreign NUT deployments.
- Generates complete owned NUT configurations with atomic selection and one last-known-good fallback.
- Integrates with Merlin lifecycle, mount, firewall, and shutdown hooks.
- Provides stable human-readable and JSON CLI status and diagnostics.
- Provides one local interactive menu for installation and routine administration.
- Provides a release-pinned fresh-install launcher that verifies its core before opening that menu.
- Exposes the real NUT source only to one explicit trusted IPv4 scope.
- Creates a unique restricted `upsmon secondary` credential for each client.
- Supports user-initiated disable, repair, update, and conservative uninstall.

The local lifecycle-management commands are:

```text
nutmerlin enable
nutmerlin disable
nutmerlin repair
nutmerlin update /local/path/nutmerlin-core-VERSION.tar.gz
nutmerlin uninstall
```

Disable retains configuration and credentials. Repair reconstructs only unambiguous owned modes, selectors, hook blocks, scheduling, and service state. Update requires an adjacent `.sha256` sidecar, validates the fixed internal manifest, uses one immediate temporary backup, and performs no download or Entware operation. Uninstall requires attributable `/opt` state, removes only verified NUTMerlin artifacts, and always retains every Entware package.

For a published alpha, `INSTALL.md` gives the version-pinned one-line download and launch command. The launcher downloads its matching core into private temporary storage, verifies it, and opens the same local menu; it makes no persistent change by itself. For a copied or unpacked package, run `./bin/nutmerlin menu`; after installation, run `/jffs/addons/nutmerlin/bin/nutmerlin menu`. The fixed menu delegates to the same CLI and keeps confirmation prompts for consequential changes. Its Entware option checks and, only after an explicit default-No confirmation, refreshes the six required NUT package roots; it does not perform general Entware maintenance.

## Deliberate exclusions

v0.1 has no router-side outage policy, remote shutdown executor, action journal, FSD workflow, writable UPS administration, output control, WebUI, webhook, MQTT, SSH, WinRM, Redfish, support bundle, configuration import/export, or broad hardware matrix.

## Current status

The owned dummy core, Merlin lifecycle, uniquely identified USB source, exact trusted-LAN exposure, restricted secondary-client credentials, owned-only lifecycle management, deterministic package, local user-initiated update, interactive menu, and release-pinned fresh-install path are implemented and covered by host-safe tests. Exact router/UPS evidence remains on the v0.1 track in `plan.md`. No physical-UPS claim has yet been made. This repository is development software and not a published release.

## Development

Normal development runs on Linux or WSL2 without a router or physical UPS:

```sh
make bootstrap
make test
make test-nut
make package
make release-artifacts
```

See `development.md` and `testing.md`. Real-router modification is always manually gated with `NUTMERLIN_ALLOW_PRODUCTION_ROUTER=1`.

## Safety boundary

NUTMerlin never bootstraps or repairs Entware, changes feeds, runs a blanket package upgrade, downgrades/removes packages, adopts a foreign NUT deployment, binds NUT to WAN or wildcard addresses, automatically replaces a failed physical source with simulation, or registers a writable UPS/output command. Its only package mutation is an explicitly authorized targeted refresh of the six required NUT roots.

## Documentation authority

`requirements.md` defines v0.1 behavior. Active decisions are listed in `decisions/README.md`; all other ADRs are historical or deferred. `architecture.md`, `security.md`, `testing.md`, and `plan.md` describe implementation and evidence without creating additional authority.

License: GPL-3.0-or-later.
