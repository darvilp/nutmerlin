#!/bin/sh

set -eu

source_root=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)

# shellcheck disable=SC1091
. "$source_root/lib/nutmerlin/paths.sh"
# shellcheck disable=SC1091
. "$source_root/lib/nutmerlin/entware.sh"
# shellcheck disable=SC1091
. "$source_root/lib/nutmerlin/configuration.sh"
# shellcheck disable=SC1091
. "$source_root/lib/nutmerlin/ownership.sh"
# shellcheck disable=SC1091
. "$source_root/lib/nutmerlin/service.sh"

paths_initialize
if [ "${NUTMERLIN_ENABLE_TEST_ADAPTERS:-0}" != 1 ] &&
	[ "${NUTMERLIN_ALLOW_PRODUCTION_ROUTER:-0}" != 1 ]; then
	printf '%s\n' 'NUTMerlin install refused: set NUTMERLIN_ALLOW_PRODUCTION_ROUTER=1 for router installation' >&2
	exit 78
fi
ownership_check_before_install
entware_check

if [ "$NUTMERLIN_OWNERSHIP_STATE" = owned ]; then
	installed_entware_record=$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/entware.tsv
	if [ "$(cat "$installed_entware_record")" != "$NUTMERLIN_ENTWARE_RECORD" ]; then
		printf '%s\n' 'NUTMerlin install refused: observed Entware package versions differ from the owned record' >&2
		exit 78
	fi
	printf '%s\n' 'NUTMerlin already installed: owned state is complete'
	exit 0
fi

code_root=$NUTMERLIN_JFFS_ROOT/addons/nutmerlin
config_root=$NUTMERLIN_OPT_ROOT/etc/nutmerlin
runtime_root=$NUTMERLIN_TMP_ROOT/nutmerlin
installation_id=$(configuration_random_id)
code_candidate=$NUTMERLIN_JFFS_ROOT/addons/.nutmerlin-install-$installation_id
config_candidate=$NUTMERLIN_OPT_ROOT/etc/.nutmerlin-install-$installation_id
install_complete=0
installed_code_root=0
installed_config_root=0

cleanup_incomplete_install() {
	[ "$install_complete" -eq 1 ] && return
	for incomplete_path in "$code_candidate" "$config_candidate"; do
		case $incomplete_path in
			"$NUTMERLIN_JFFS_ROOT"/addons/.nutmerlin-install-* | \
				"$NUTMERLIN_OPT_ROOT"/etc/.nutmerlin-install-*)
				[ ! -e "$incomplete_path" ] || rm -rf -- "$incomplete_path"
				;;
		esac
	done
	if [ "$installed_config_root" -eq 1 ]; then
		rm -rf -- "$config_root"
	fi
	if [ "$installed_code_root" -eq 1 ]; then
		rm -rf -- "$code_root"
	fi
}

trap cleanup_incomplete_install EXIT HUP INT TERM

mkdir -p "$NUTMERLIN_JFFS_ROOT/addons" "$NUTMERLIN_OPT_ROOT/etc"
mkdir -m 755 "$code_candidate"
mkdir -m 755 "$code_candidate/bin" "$code_candidate/lib" "$code_candidate/share"
mkdir -m 755 "$code_candidate/share/dummy"
cp "$source_root/bin/nutmerlin" "$code_candidate/bin/nutmerlin"
cp "$source_root/lib/nutmerlin/"*.sh "$code_candidate/lib/"
cp "$source_root/share/dummy/cyberpower.dev" "$code_candidate/share/dummy/cyberpower.dev"
cp "$source_root/VERSION" "$code_candidate/VERSION"
chmod 755 "$code_candidate/bin/nutmerlin"
chmod 644 "$code_candidate/lib/"*.sh "$code_candidate/share/dummy/cyberpower.dev" "$code_candidate/VERSION"
printf '%s\n' "$installation_id" >"$code_candidate/installation.id"
printf '%s\n' '1' >"$code_candidate/enabled"
printf '%s\n' "$NUTMERLIN_ENTWARE_RECORD" >"$code_candidate/entware.tsv"
chmod 600 "$code_candidate/installation.id" "$code_candidate/enabled" "$code_candidate/entware.tsv"
(
	cd "$code_candidate"
	sha256sum VERSION bin/nutmerlin entware.tsv lib/*.sh share/dummy/cyberpower.dev >owned-files
)
chmod 600 "$code_candidate/owned-files"

mkdir -m 700 "$config_candidate"
printf '%s\n' "$installation_id" >"$config_candidate/installation.id"
chmod 600 "$config_candidate/installation.id"
configuration_create_initial "$config_candidate" "$code_root" "$runtime_root"

mv "$code_candidate" "$code_root"
installed_code_root=1
mv "$config_candidate" "$config_root"
installed_config_root=1
mkdir -m 711 "$runtime_root"
mkdir -m 700 "$runtime_root/lock" "$runtime_root/run" "$runtime_root/state" "$runtime_root/log"
ownership_verify_code_root "$code_root" || exit 70
ownership_verify_config_root "$config_root" || exit 70
if [ "$(cat "$code_root/installation.id")" != "$(cat "$config_root/installation.id")" ]; then
	exit 70
fi
install_complete=1
trap - EXIT HUP INT TERM

printf '%s\n' 'NUTMerlin installed: dummy is configured loopback-only'
