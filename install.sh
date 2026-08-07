#!/bin/sh

set -eu

source_root=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)

install_dependencies=0
case $# in
	0) ;;
	1)
		[ "$1" = --install-dependencies ] || {
			printf '%s\n' 'usage: install.sh [--install-dependencies]' >&2
			exit 64
		}
		install_dependencies=1
		;;
	*)
		printf '%s\n' 'usage: install.sh [--install-dependencies]' >&2
		exit 64
		;;
esac

# shellcheck disable=SC1091
. "$source_root/lib/nutmerlin/paths.sh"
# shellcheck disable=SC1091
. "$source_root/lib/nutmerlin/entware.sh"
# shellcheck disable=SC1091
. "$source_root/lib/nutmerlin/configuration.sh"
# shellcheck disable=SC1091
. "$source_root/lib/nutmerlin/hooks.sh"
# shellcheck disable=SC1091
. "$source_root/lib/nutmerlin/platform.sh"
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
entware_plan_dependency_refresh "$install_dependencies"

install_refresh_dependencies() {
	refreshing_owned_installation=0
	entware_previous_enabled=
	entware_service_was_active=0
	if [ "$NUTMERLIN_OWNERSHIP_STATE" = owned ]; then
		refreshing_owned_installation=1
		installed_code_root=$NUTMERLIN_JFFS_ROOT/addons/nutmerlin
		entware_previous_enabled=$(cat "$installed_code_root/enabled")
		case $entware_previous_enabled in
			0 | 1) ;;
			*) return 78 ;;
		esac
		if [ -e "$NUTMERLIN_TMP_ROOT/nutmerlin/run/upsd.pid" ]; then
			entware_service_was_active=1
		fi
		printf '%s\n' 0 >"$installed_code_root/enabled"
		platform_cru_remove || {
			printf '%s\n' 'Entware package refresh refused: periodic recovery could not be stopped safely' >&2
			return 78
		}
		service_stop || {
			printf '%s\n' 'Entware package refresh refused: existing NUT service could not be stopped safely' >&2
			return 78
		}
	fi
	refresh_status=0
	entware_execute_dependency_refresh || refresh_status=$?
	post_refresh_ownership_status=0
	ownership_check_before_install || post_refresh_ownership_status=$?
	if [ "$post_refresh_ownership_status" -ne 0 ]; then
		printf '%s\n' 'Entware post-refresh ownership check failed; NUTMerlin remains disabled and stopped' >&2
		entware_refresh_failure_guidance
		return "$post_refresh_ownership_status"
	fi
	[ "$refresh_status" -eq 0 ] || return "$refresh_status"
	if [ "$refreshing_owned_installation" -eq 1 ]; then
		printf '%s\n' "$entware_previous_enabled" >"$installed_code_root/enabled"
		if [ "$entware_previous_enabled" -eq 1 ]; then
			platform_cru_ensure || {
				printf '%s\n' 0 >"$installed_code_root/enabled"
				printf '%s\n' 'Entware refresh recovery failed; NUTMerlin remains disabled and stopped' >&2
				return 75
			}
			if [ "$entware_service_was_active" -eq 1 ] && ! service_start; then
				printf '%s\n' 0 >"$installed_code_root/enabled"
				platform_cru_remove || :
				service_stop || :
				printf '%s\n' 'Entware refresh recovery failed; NUTMerlin remains disabled and stopped' >&2
				return 75
			fi
		fi
	fi
	return 0
}

if [ "$NUTMERLIN_ENTWARE_REFRESH_AUTHORIZED" -eq 1 ]; then
	if [ "$NUTMERLIN_OWNERSHIP_STATE" = owned ]; then
		service_run_locked install_refresh_dependencies
	else
		install_refresh_dependencies
	fi
fi

if [ "$NUTMERLIN_OWNERSHIP_STATE" = owned ]; then
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
NUTMERLIN_HOOK_INSTALL_ACTIVE=0
export NUTMERLIN_HOOK_INSTALL_ACTIVE

cleanup_incomplete_install() {
	[ "$install_complete" -eq 1 ] && return
	hook_rollback_status=0
	hooks_rollback_install || hook_rollback_status=$?
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
	if [ "$hook_rollback_status" -ne 0 ]; then
		printf '%s\n' 'NUTMerlin install cleanup retained a concurrently changed hook' >&2
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
hooks_write_metadata "$code_candidate" "$installation_id" "$code_root"
(
	cd "$code_candidate"
	sha256sum VERSION bin/nutmerlin entware.tsv hooks.tsv lib/*.sh share/dummy/cyberpower.dev >owned-files
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
hooks_install_all "$installation_id" "$code_root"
ownership_verify_code_root "$code_root" || exit 70
ownership_verify_config_root "$config_root" || exit 70
if [ "$(cat "$code_root/installation.id")" != "$(cat "$config_root/installation.id")" ]; then
	exit 70
fi
hooks_commit_install
install_complete=1
trap - EXIT HUP INT TERM

printf '%s\n' 'NUTMerlin installed: dummy is configured loopback-only'
