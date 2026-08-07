# Install NUTMerlin

NUTMerlin currently has no published release. The first alpha will publish three matching assets from one tagged commit:

- `nutmerlin-core-VERSION.tar.gz`
- `nutmerlin-core-VERSION.tar.gz.sha256`
- `nutmerlin-install-VERSION.sh`

## Fresh install from a published alpha

Replace `X.Y.Z` below with the exact published version. Run the command from an interactive router shell as an administrator:

```sh
(umask 077; NUTMERLIN_VERSION='X.Y.Z'; NUTMERLIN_BOOTSTRAP_DIR=$(mktemp -d '/tmp/nutmerlin-launcher.XXXXXX') || exit 75; trap 'rm -rf -- "$NUTMERLIN_BOOTSTRAP_DIR"' EXIT; trap 'exit 75' HUP INT TERM; NUTMERLIN_LAUNCHER="$NUTMERLIN_BOOTSTRAP_DIR/nutmerlin-install-${NUTMERLIN_VERSION}.sh"; /usr/sbin/curl -fL --retry 3 -o "$NUTMERLIN_LAUNCHER" "https://github.com/darvilp/nutmerlin/releases/download/v${NUTMERLIN_VERSION}/nutmerlin-install-${NUTMERLIN_VERSION}.sh" && chmod 700 "$NUTMERLIN_LAUNCHER" && NUTMERLIN_ALLOW_PRODUCTION_ROUTER=1 /bin/sh "$NUTMERLIN_LAUNCHER")
```

This is deliberately not a `curl | sh` command. The outer subshell downloads the named launcher into a private unpredictable directory and removes it on every exit. The launcher pins the same release's core archive and expected SHA-256. It downloads that archive into a second private directory below `/tmp`, verifies its digest and complete package contents, and then opens the existing NUTMerlin menu. Quitting or reaching end-of-input installs nothing, and both temporary workspaces are cleaned.

GitHub HTTPS plus the embedded SHA-256 provides basic alpha transport integrity; it is not an independent publisher signature. Inspect the launcher before running it when that distinction matters.

The menu first checks the router, ownership, foreign NUT state, storage, and Entware compatibility. If the six required NUT package roots are compatible, declining the default-No package refresh continues without changing Entware. If they are missing or incompatible, the menu explains the exact targeted refresh and proceeds only after affirmative confirmation. NUTMerlin never installs or repairs Entware itself, changes feeds, performs a blanket upgrade, downgrades, or removes packages.

## Install from a copied package

Download the matching core archive and `.sha256` sidecar on another machine, verify the published digest, copy both to the router, extract the archive privately, and run:

```sh
NUTMERLIN_ALLOW_PRODUCTION_ROUTER=1 ./install.sh
```

For the same explicit targeted package refresh without the interactive prompt:

```sh
NUTMERLIN_ALLOW_PRODUCTION_ROUTER=1 ./install.sh --install-dependencies
```

## After installation

Open the local management menu with:

```sh
/jffs/addons/nutmerlin/bin/nutmerlin menu
```

Installed updates remain deliberately offline and local:

```sh
NUTMERLIN_ALLOW_PRODUCTION_ROUTER=1 \
  /jffs/addons/nutmerlin/bin/nutmerlin update /local/path/nutmerlin-core-VERSION.tar.gz
```

The adjacent `.sha256` sidecar is required. The installed updater makes no network or Entware request.
