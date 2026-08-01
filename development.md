# NUTMerlin development workflow

## 1. Primary environment

The primary development environment is:

- Windows 11 host
- WSL2 Linux distribution
- Codex IDE beta connected to the WSL workspace
- Git and GitHub CLI inside WSL
- Docker or Podman for disposable NUT integration tests

The project must remain usable from an ordinary Linux host; WSL-specific behavior belongs in development documentation and adapters, not in runtime code.

## 2. Repository location

Keep the repository in the WSL Linux filesystem:

```sh
mkdir -p ~/src
cd ~/src
git clone git@github.com:danielarvilpayne/nutmerlin.git
cd nutmerlin
```

Do not use `/mnt/c/...` as the primary working tree. Linux build and test tools perform better and have fewer permission/line-ending edge cases when the repository is stored under the WSL filesystem.

Open the directory through the Codex IDE's WSL integration. From WSL, Windows Explorer can inspect it with:

```sh
explorer.exe .
```

## 3. Host prerequisites

Ubuntu/Debian baseline:

```sh
sudo apt update
sudo apt install -y \
  git gh make shellcheck shfmt bats jq curl \
  openssh-client rsync netcat-openbsd \
  python3 python3-venv smartmontools f3
```

Install either Docker Engine/Docker Desktop integration or Podman. The project should not require both.

Verify:

```sh
git --version
gh --version
shellcheck --version
shfmt --version
bats --version
docker version || podman version
```

## 4. Expected repository commands

The initial scaffold should converge on these stable entry points:

```sh
make bootstrap
make lint
make test
make test-unit
make test-nut
make test-security
make package
make docs-check
```

Optional hardware commands:

```sh
make router-probe PROFILE=ac3100
make deploy PROFILE=ac3100
make router-smoke PROFILE=ac3100
make router-report PROFILE=ac3100
```

Production hardware requires an explicit gate:

```sh
NUTMERLIN_ALLOW_PRODUCTION_ROUTER=1 make deploy PROFILE=ax86u-pro
```

No default Make target may deploy to a router, shut down a host, issue an administrative UPS command, or require hardware.

## 5. Local configuration

Do not commit router addresses, usernames, private keys, or local paths. Use an ignored file such as:

```text
.env.local
config/local/router-ac3100.conf
```

Example non-secret profile:

```ini
NUTMERLIN_ROUTER_HOST=nutmerlin-ac3100
NUTMERLIN_ROUTER_PORT=22
NUTMERLIN_ROUTER_USER=admin
NUTMERLIN_ROUTER_CLASS=legacy-test
NUTMERLIN_ROUTER_PRODUCTION=0
```

Store the SSH key in the normal WSL SSH directory and pin the host key in `~/.ssh/known_hosts`.

## 6. Codex working instructions

Codex should work in small reviewable stages:

1. Read `AGENTS.md`, `requirements.md`, `architecture.md`, `security.md`, and `testing.md`.
2. Implement or update one milestone slice.
3. Add tests before claiming completion.
4. Run the relevant `make` targets.
5. Summarize changed requirements, safety impact, and untested hardware assumptions.
6. Commit on a feature branch only after tests pass.
7. Open a draft pull request for review rather than pushing directly to `main`.

Codex must not:

- assume the RT-AC3100 is available
- ask for real-UPS testing when `dummy-ups` can cover the behavior
- install packages on a router without an explicit hardware task
- use the production RT-AX86U Pro by default
- place the repository on `/mnt/c`
- modify Windows shutdown configuration from WSL during ordinary tests

## 7. WSL networking

Default WSL2 NAT mode is sufficient for outbound connections from WSL to LAN devices in the normal topology:

```sh
ssh admin@nutmerlin-ac3100
curl http://nutmerlin-ac3100/
nc -vz nutmerlin-ac3100 3493
```

Mirrored networking is optional. Use it only when a router or other LAN device must initiate a connection to a service listening inside WSL or when NAT/VPN behavior prevents the needed traffic.

When running a webhook test server inside WSL, prefer one of:

- invoke it from WSL-local tests only
- expose it through the Windows host with an explicit firewall rule
- enable mirrored networking for that test environment

Do not weaken the Windows or Hyper-V firewall globally just to simplify a test.

## 8. USB access from WSL2

Direct USB access is optional. The normal development path uses `dummy-ups`, and the normal real hardware path attaches the UPS to an ASUS router.

For a deliberate direct-USB experiment, Windows can share a USB device with WSL2 through `usbipd-win`. Treat this as a separate test profile because the device cannot simultaneously be owned by PowerPanel, WinNUT, and the WSL NUT driver.

Direct WSL USB experiments must not become a prerequisite for CI or normal development.

## 9. Native Windows client testing

Use a native Windows NUT client or Windows service for production-style behavior. WSL2 must not be responsible for shutting down Windows.

Test progression:

1. connect and display state
2. invoke a harmless marker action
3. verify short-outage cancellation
4. verify long-outage action
5. enable actual shutdown only with an explicit gate and saved work

## 10. Suggested first Codex work sequence

1. Create the repository scaffold and CI.
2. Implement mock filesystem roots and Merlin command shims.
3. Implement structured settings validation and NUT config rendering.
4. Add golden-file tests.
5. Bring up containerized `dummy-ups`, `upsd`, and `upsc`.
6. Implement status normalization.
7. Add the reversible timer state machine.
8. Add packaging and a no-op/mock deployment profile.
9. Only then prepare the optional RT-AC3100.
