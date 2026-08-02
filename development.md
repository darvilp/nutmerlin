# NUTMerlin development workflow

## 1. Primary and portable environments

The primary maintainer environment is:

- Windows 11 host;
- WSL2 Linux distribution;
- Codex IDE beta attached to the WSL workspace;
- Git and GitHub CLI inside WSL;
- Docker or Podman for disposable NUT and protocol test systems.

The repository and all normal tests must also work on an ordinary Linux host. WSL-specific behavior belongs in development/test guidance, never in the router runtime contract.

Store the working tree in the Linux filesystem:

    mkdir -p ~/src
    cd ~/src
    git clone git@github.com:darvilp/nutmerlin.git
    cd nutmerlin

Do not use /mnt/c as the normal working tree for Linux tools. It introduces avoidable filesystem, permission, line-ending, and performance differences.

## 2. Documentation and decision authority

Before changing product behavior, read:

1. AGENTS.md;
2. requirements.md;
3. architecture.md;
4. security.md;
5. testing.md;
6. hardware.md;
7. the relevant accepted ADRs under decisions/.

Use root CONTEXT.md for canonical domain terminology. decisions/ is the only ADR hierarchy; do not create docs/adr or another parallel structure.

Behavior changes must update the affected requirements, architecture, security invariants, tests, milestone boundary, backlog, and ADR when a genuinely new hard-to-reverse decision is made. Code must not silently override accepted documentation.

## 3. Host prerequisites

An Ubuntu/Debian development host normally needs:

    sudo apt update
    sudo apt install -y \
      git gh make shellcheck shfmt bats jq ripgrep curl \
      openssh-client rsync netcat-openbsd \
      python3 python3-venv smartmontools f3

Install Docker or Podman according to the host environment; the project should not require both.

NUT/Entware binaries used for release qualification come from the exact test cohort, not from whatever host package happens to be installed.

## 4. Stable repository command surface

The implemented host-safe command surface is:

    make bootstrap
    make lint
    make test
    make test-unit
    make test-security
    make docs-check
    make package

`make bootstrap` checks host prerequisites and never installs or changes them.
The remaining commands operate only on the checkout and disposable host-test
roots. `make test-nut` will be added with the isolated `dummy-ups` integration
ticket; it is not an alias for host-unit evidence.

The first complete local CLI operation is:

    bin/nutmerlin self-check
    bin/nutmerlin self-check --json

The JSON result schema is `nutmerlin.management-result.v1`, and the versioned
operation identifier is `core.self-check.v1`. Current stable exit classes are
`success` (process status 0), `usage` (64), and `configuration` (78). The
self-check creates disposable isolated roots when the harness has not supplied
them. It performs no router, firewall, service, Entware, NUT, WebUI, or hardware
mutation.

Platform eligibility uses the same local controller:

    bin/nutmerlin platform-eligibility
    bin/nutmerlin platform-eligibility --json

Operation `platform.eligibility.v1` reports support classification separately from installation disposition. The version-controlled production qualification profile initially names no qualified firmware release; support claims remain absent until release evidence supplies exact versions. Native semantic probes that have not been qualified report `unknown`. Host simulations are explicitly labeled and cannot create production qualification evidence or authorize installation.

Optional manually invoked hardware/evidence commands should use explicit profiles:

    make router-probe PROFILE=ac3100
    make deploy PROFILE=ac3100
    make router-smoke PROFILE=ac3100
    make router-report PROFILE=ac3100

Production hardware requires:

    NUTMERLIN_ALLOW_PRODUCTION_ROUTER=1 make deploy PROFILE=ax86u-pro

An actual host-shutdown test requires:

    NUTMERLIN_ALLOW_HOST_SHUTDOWN=1

NUTMERLIN_ALLOW_UPS_COMMANDS may gate future harmless administrative test scaffolding, but it does not authorize load.off, shutdown.*, outlet actions, Redfish ForceOff, or any output-control operation through P2.

No default target may:

- deploy or mutate a router;
- modify the RT-AX86U Pro;
- shut down a host;
- issue a writable UPS/PDU command;
- require a router, UPS, BMC, or Windows machine;
- install dependencies on a shared Entware system.

## 5. Local configuration and sensitive values

Do not commit:

- router addresses or source subnets;
- usernames;
- private keys, passwords, bearer/HMAC values, or NUT credentials;
- certificate/CA/pin material;
- physical device serials;
- target labels/topology;
- local filesystem paths.

Use ignored local profiles, for example:

    .env.local
    config/local/router-ac3100.conf

An ordinary non-secret profile may contain:

    NUTMERLIN_ROUTER_HOST=nutmerlin-ac3100
    NUTMERLIN_ROUTER_PORT=22
    NUTMERLIN_ROUTER_USER=admin
    NUTMERLIN_ROUTER_CLASS=legacy-test
    NUTMERLIN_ROUTER_PRODUCTION=0

Keep developer SSH private keys in the normal protected SSH store and pin the independently verified host fingerprint. Local test credentials must never be reused on production hardware.

## 6. Normal development loop

For each bounded change:

1. Identify the controlling requirement and ADR.
2. Add or update the smallest hardware-free test that demonstrates the behavior or safety invariant.
3. Change only the relevant platform-neutral module or narrow adapter.
4. Run focused tests, then the required stable command set.
5. Verify no unrelated worktree changes, secret, endpoint, or hardware dependency entered the change.
6. Update affected documentation and evidence claims.
7. Review standards and specification conformance before committing.

Do not claim:

- a test passed when a dependency or hardware layer was skipped;
- an emulator/container result qualifies a router;
- a router dummy-ups result qualifies a physical UPS;
- one physical UPS report qualifies all telemetry;
- a network disconnect proves a host is Off;
- a dry-run grants production authority.

## 7. Platform-neutral implementation boundary

All normal logic should run under isolated host roots and named platform adapters.

Direct Merlin calls belong behind adapter functions for:

- NVRAM;
- firmware/Addons API;
- optional WebUI component mounting, removal, and service-event integration;
- user-script hooks;
- firewall inspection/application;
- mount/storage identity;
- services/processes;
- accounts/privilege;
- boot/time synchronization;
- syslog/resource limits.

Runtime shell is POSIX /bin/sh unless a component’s accepted contract says otherwise. Do not assume Bash.

The host harness must make it impossible to alter the developer’s real /jffs, /opt, web root, firewall, services, or opkg state.

## 8. Entware development rules

NUTMerlin treats Entware as a shared prerequisite.

During normal host work:

- simulate opkg plans and failures;
- use disposable roots/containers for package mutation;
- do not run blanket upgrade;
- do not pin an old package as the compatibility solution;
- do not vendor/private-build NUT;
- test a coherent older cohort only as compatibility-only;
- record exact package provenance.

During release qualification, execute the current supported AArch64 cohort, including gpgv2 and every advertised optional dependency. Recheck feed contents at release time.

Never bootstrap, format, repair, or replace Entware as a NUTMerlin development side effect.

## 9. WSL networking

Default WSL2 NAT is normally sufficient for outbound SSH and NUT queries to LAN targets:

    ssh admin@nutmerlin-ac3100
    nc -vz nutmerlin-ac3100 3493
    upsc ups@nutmerlin-ac3100

Mirrored networking is optional and only needed when a LAN test target must initiate traffic into WSL or host NAT/VPN behavior prevents the required path.

For a webhook/MQTT test service:

- prefer same-environment/container traffic;
- expose through the Windows host only with an exact temporary firewall rule; or
- use mirrored networking for the named test.

Never weaken Windows, Hyper-V, router, or LAN firewall policy globally to simplify a test.

## 10. USB access from WSL2

Direct WSL USB is optional. The normal development source is dummy-ups, and the normal physical source attaches to a gated ASUS router.

For a deliberate experiment, usbipd-win may attach a device to WSL. Record that the UPS cannot simultaneously be owned by PowerPanel, a native Windows NUT client, and the WSL driver.

Direct WSL USB must not become a CI, release, or contributor prerequisite.

## 11. Router profiles and gates

### mock

Host filesystem, process, network, clock, and Merlin-command shims. This is the normal development profile.

### current-3004 and current-3006

Simulated capability profiles representing the currently qualified firmware-family contracts. Their behavior is test data, not exact hardware qualification.

### ac3100

Optional legacy Merlin 386/ARMv7 profile. It may be skipped when unavailable or uninformative. Use dummy-ups first, isolate internet egress, and store no reusable production secret.

### ax86u-pro

Production-reference exact-hardware profile. Every deployment or mutation requires NUTMERLIN_ALLOW_PRODUCTION_ROUTER=1 and a task-specific safety checklist.

### physical UPS profiles

Each physical profile identifies exact device/driver/NUT evidence and begins read-only. It never enables a writable/output command.

## 12. Native Windows client tests

Use a native Windows NUT client/service for production-style client-local behavior; WSL2 is not the shutdown agent.

Progression:

1. read-only query;
2. restricted secondary authentication;
3. harmless local marker;
4. short-outage cancellation;
5. long-outage local action;
6. optional actual graceful shutdown with the explicit gate and saved work.

Keep protocol-level client-neutral tests even when one particular Windows client is used. Hibernation is outside P0–P2.

## 13. Repository and review workflow

Project defaults:

- public darvilp/nutmerlin;
- GPL-3.0-or-later;
- GitHub Actions host CI;
- protected main;
- feature branches and draft pull requests;
- manual hardware workflows outside ordinary PR gates.

Preserve unrelated dirty-worktree changes. Stage only intended paths. A milestone/capability is not complete because files exist; every applicable exit gate in plan.md and evidence rule in testing.md must pass.

Release artifacts are produced by CI, authenticated offline, and installed only through the signed-manifest contract. Development convenience never bypasses first-install, safe-window, rollback, or release-root requirements.
