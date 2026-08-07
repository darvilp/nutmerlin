# NUTMerlin v0.1 development guide

## 1. Workspace

Use a Linux filesystem checkout. WSL2 is supported; do not place the working tree under `/mnt/c` for normal Linux tooling. Normal development needs no router, UPS, Windows shutdown agent, or WSL USB passthrough.

## 2. Host tools

The repository checks require GNU Make, Bats, ShellCheck, shfmt, ripgrep, tar, gzip, `ss` from iproute2, and the host packages providing `dummy-ups`, `usbhid-ups`, `upsd`, and `upsc` for installation and `make test-nut`.

```sh
make bootstrap
make test
make test-nut
make package
```

`make test-nut` is mandatory. It starts real NUT processes only against disposable configuration and loopback state.

Bootstrap reports missing tools and never installs them. CI may install its disposable host test dependencies explicitly.

## 3. Ticket workflow

1. Verify branch, starting commit, clean/dirty paths, issue body/comments, and native blockers.
2. Read root documents in `AGENTS.md` order and relevant active ADRs.
3. Identify the public behavior seam: CLI, generated config, real NUT process chain, installer root, or Merlin adapter.
4. Add one failing behavioral test.
5. Implement only enough to pass it; repeat vertically.
6. Run focused and applicable full checks.
7. Review Standards and Specification separately against the starting commit.
8. Make one focused commit, push normally, add evidence, then close the ticket.

Do not combine tickets, implement future abstractions, or work concurrently in the shared worktree.

## 4. Isolated roots

Host tests set private paths for JFFS, Entware configuration, transient state, and platform command shims. Production code must accept those roots only when the explicit test-adapter gate is enabled and all roots are inside the harness's private temporary directory.

The harness must make it impossible to mutate real `/jffs`, `/opt`, firewall, cron, router services, or package state. NUT integration uses real NUT binaries but disposable configuration, state, PID, and socket paths.

## 5. Runtime dependencies

NUTMerlin treats Entware as shared and preexisting. It checks these NUT roots and their actual required binaries/options:

- `nut`
- `nut-common`
- `nut-server`
- `nut-upsc`
- `nut-driver-dummy-ups`
- `nut-driver-usbhid-ups`

The product does not lock the transitive feed or claim compatibility solely from version strings. Interactive installation and the installed menu offer a refresh of all six roots and default to no. Acceptance runs `opkg update` and one targeted install of those roots; normal dependency resolution is allowed. Installer-only noninteractive authorization requires `--install-dependencies`. Compatible decline proceeds without `opkg`; missing/incompatible decline stops with exact guidance. The operation prints bounded pre/post package evidence but stores no operational package history. NUTMerlin never installs or repairs Entware itself, changes feeds, invokes a blanket package upgrade, downgrades/removes packages, or installs optional roots.

No router runtime dependency may be added without an accepted decision.

## 6. Shell conventions

- Use POSIX `/bin/sh`, `set -eu`, quoted expansions, and private fixed roots.
- Use `mkdir` locks rather than assuming `flock`.
- Do not use `eval`, Bash arrays, process substitution, here-strings, or sourced mutable configuration.
- Validate identifiers, addresses, CIDRs, paths, numeric fields, USB attributes, and archive names before use.
- Wrap platform commands in the platform adapter.
- Keep JSON rendering bounded and correctly escaped without requiring router-side `jq`.
- Send diagnostics to stderr when stdout carries structured results or a once-only secret.

## 7. Development installation

`make install DESTDIR=<private-root>` installs the exact layout without touching the host system. `make package` creates the byte-deterministic `dist/nutmerlin-core-dev.tar.gz`, its adjacent `.sha256` sidecar, and an internal fixed-inventory manifest. Verify the sidecar before extracting a fresh-install package:

```sh
cd dist
sha256sum -c nutmerlin-core-dev.tar.gz.sha256
```

For the production-reference router, copy the archive through an existing administrator channel and run its local installer only with:

```sh
NUTMERLIN_ALLOW_PRODUCTION_ROUTER=1 ./install.sh
```

The default-No prompt is the normal package choice. For an explicitly noninteractive targeted NUT refresh, use:

```sh
NUTMERLIN_ALLOW_PRODUCTION_ROUTER=1 ./install.sh --install-dependencies
```

The package and installed core both provide the conventional local menu:

```sh
./bin/nutmerlin menu
/jffs/addons/nutmerlin/bin/nutmerlin menu
```

From an installed menu, “Refresh required Entware NUT packages” performs the same six-root compatibility check and default-No confirmation. No other Entware maintenance is exposed.

The installer never downloads NUTMerlin code or installs Entware itself. Preserve a separate router recovery path and inspect all proposed package, hook, and firewall changes before the first test.

An installed administrator can apply a copied local package and adjacent sidecar with:

```sh
NUTMERLIN_ALLOW_PRODUCTION_ROUTER=1 \
  /jffs/addons/nutmerlin/bin/nutmerlin update /local/path/nutmerlin-core-dev.tar.gz
```

Update makes no network or Entware request. It verifies the sidecar, archive inventory/types/modes, extracted manifest, current ownership, configuration, source, and network state before closing live surfaces and activating one staged code root. Success removes the one temporary backup; immediate failure restores it once.

## 8. Hardware progression

1. Host unit and real dummy integration.
2. Simulated Merlin lifecycle.
3. RT-AX86U Pro with dummy.
4. CP1500PFCLCD read-only on the router.
5. Trusted-LAN `upsc`.
6. Standard secondary-client authentication.

Never infer a later layer from an earlier one. The RT-AC3100 and other device/firmware combinations are post-v0.1 research.

## 9. Debugging and evidence

Record exact commands, exit status, versions, fixture/profile, and evidence layer. Redact secrets, full serials, usernames, and reusable network details before publishing. A client disconnect is not host-Off evidence, and a successful build is not router proof.
