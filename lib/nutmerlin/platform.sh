#!/bin/sh

platform_process_snapshot() {
	ps 2>/dev/null
}

platform_listener_snapshot() {
	command -v ss >/dev/null 2>&1 || return 69
	ss -ltn 2>/dev/null
}

platform_process_is_alive() {
	kill -0 "$1" 2>/dev/null
}

platform_process_signal() {
	kill "$1"
}

platform_process_executable() {
	readlink "/proc/$1/exe" 2>/dev/null
}

platform_process_uid() {
	awk '/^Uid:/ { print $2; exit }' "/proc/$1/status" 2>/dev/null
}

platform_process_has_environment() {
	platform_environment_pid=$1
	platform_environment_value=$2
	tr '\000' '\n' <"/proc/$platform_environment_pid/environ" 2>/dev/null |
		grep -Fx "$platform_environment_value" >/dev/null
}

platform_storage_state() {
	case ${NUTMERLIN_TEST_STORAGE_STATE:-} in
		missing | read_only | replaced | ownership_mismatch | unknown)
			printf '%s\n' "$NUTMERLIN_TEST_STORAGE_STATE"
			return 0
			;;
		'' | available) ;;
		*) return 78 ;;
	esac
	if [ ! -e "$NUTMERLIN_OPT_ROOT" ] && [ ! -L "$NUTMERLIN_OPT_ROOT" ]; then
		printf '%s\n' missing
		return 0
	fi
	if [ ! -d "$NUTMERLIN_OPT_ROOT" ] || [ -L "$NUTMERLIN_OPT_ROOT" ]; then
		printf '%s\n' replaced
		return 0
	fi
	if [ "${NUTMERLIN_ENABLE_TEST_ADAPTERS:-0}" = 1 ]; then
		if [ ! -w "$NUTMERLIN_OPT_ROOT" ]; then
			printf '%s\n' read_only
			return 0
		fi
	else
		storage_device=$(df -P "$NUTMERLIN_OPT_ROOT" 2>/dev/null | awk 'NR == 2 { print $1 }')
		[ -n "$storage_device" ] || {
			printf '%s\n' unknown
			return 0
		}
		storage_options=$(awk -v device="$storage_device" '$1 == device { print $4; exit }' /proc/mounts 2>/dev/null)
		[ -n "$storage_options" ] || {
			printf '%s\n' unknown
			return 0
		}
		case ,$storage_options, in
			*,ro,*)
				printf '%s\n' read_only
				return 0
				;;
		esac
	fi
	platform_config_root=$NUTMERLIN_OPT_ROOT/etc/nutmerlin
	if [ ! -d "$platform_config_root" ] || [ -L "$platform_config_root" ]; then
		printf '%s\n' replaced
		return 0
	fi
	platform_code_id=$(cat "$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/installation.id" 2>/dev/null || :)
	platform_config_id=$(cat "$platform_config_root/installation.id" 2>/dev/null || :)
	if [ -z "$platform_code_id" ] || [ "$platform_code_id" != "$platform_config_id" ]; then
		printf '%s\n' replaced
		return 0
	fi
	if ! ownership_verify_config_root "$platform_config_root"; then
		printf '%s\n' ownership_mismatch
		return 0
	fi
	printf '%s\n' available
}

platform_cru_command() {
	platform_schedule_id=$(cat "$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/installation.id" 2>/dev/null || :)
	ownership_id_is_valid "$platform_schedule_id" || return 78
	printf '%s/bin/nutmerlin hook reconcile %s\n' \
		"$NUTMERLIN_JFFS_ROOT/addons/nutmerlin" "$platform_schedule_id"
}

platform_cru_expected_record() {
	periodic_command=$(platform_cru_command) || return $?
	printf 'NUTMerlin\t*/5 * * * *\t%s\n' "$periodic_command"
}

platform_cru_adapter_state() {
	platform_cru_path=$NUTMERLIN_TEST_ROOT/platform/cru.tsv
	if [ ! -e "$platform_cru_path" ] && [ ! -L "$platform_cru_path" ]; then
		return 1
	fi
	[ -f "$platform_cru_path" ] && [ ! -L "$platform_cru_path" ] || return 78
	[ "$(stat -c '%a' "$platform_cru_path")" = 600 ] || return 78
	[ "$(stat -c '%h' "$platform_cru_path")" = 1 ] || return 78
	[ "$(stat -c '%u' "$platform_cru_path")" = "$(id -u)" ] || return 78
	platform_expected_record=$(platform_cru_expected_record) || return $?
	[ "$(wc -l <"$platform_cru_path")" -eq 1 ] || return 78
	[ "$(cat "$platform_cru_path")" = "$platform_expected_record" ] || return 78
}

platform_cru_listing_state() {
	platform_listing=$1
	periodic_command=$(platform_cru_command) || return $?
	platform_expected_line="*/5 * * * * $periodic_command #NUTMerlin#"
	platform_named_count=$(printf '%s\n' "$platform_listing" | grep -Fc '#NUTMerlin#' || :)
	platform_command_count=$(printf '%s\n' "$platform_listing" | grep -Fc "$periodic_command" || :)
	if [ "$platform_named_count" -eq 0 ] && [ "$platform_command_count" -eq 0 ]; then
		return 1
	fi
	[ "$platform_named_count" -eq 1 ] && [ "$platform_command_count" -eq 1 ] || return 78
	printf '%s\n' "$platform_listing" | grep -Fx "$platform_expected_line" >/dev/null || return 78
}

platform_cru_ensure() {
	periodic_command=$(platform_cru_command) || return $?
	if [ "${NUTMERLIN_ENABLE_TEST_ADAPTERS:-0}" = 1 ]; then
		platform_state_root=$NUTMERLIN_TEST_ROOT/platform
		if [ -e "$platform_state_root" ] || [ -L "$platform_state_root" ]; then
			[ -d "$platform_state_root" ] && [ ! -L "$platform_state_root" ] || return 78
			[ "$(stat -c '%a' "$platform_state_root")" = 700 ] || return 78
			[ "$(stat -c '%u' "$platform_state_root")" = "$(id -u)" ] || return 78
		else
			mkdir -m 700 "$platform_state_root" || return 75
		fi
		if platform_cru_adapter_state; then
			return 0
		else
			platform_cru_state=$?
			[ "$platform_cru_state" -eq 1 ] || return "$platform_cru_state"
		fi
		platform_cru_candidate=$platform_state_root/cru.tsv.new
		[ ! -e "$platform_cru_candidate" ] && [ ! -L "$platform_cru_candidate" ] || return 78
		(umask 077 && set -C && platform_cru_expected_record >"$platform_cru_candidate") || {
			rm -f -- "$platform_cru_candidate"
			return 75
		}
		if ! ln "$platform_cru_candidate" "$platform_state_root/cru.tsv" 2>/dev/null; then
			rm -f -- "$platform_cru_candidate"
			return 78
		fi
		rm -f -- "$platform_cru_candidate"
		platform_cru_adapter_state
		return $?
	fi
	command -v cru >/dev/null 2>&1 || return 69
	cru_listing=$(cru l 2>/dev/null) || return 75
	if platform_cru_listing_state "$cru_listing"; then
		return 0
	else
		platform_cru_state=$?
		[ "$platform_cru_state" -eq 1 ] || return "$platform_cru_state"
	fi
	cru a NUTMerlin "*/5 * * * * $periodic_command" || return 75
	cru_listing=$(cru l 2>/dev/null) || return 75
	platform_cru_listing_state "$cru_listing" || return 75
}

platform_cru_remove() {
	if [ "${NUTMERLIN_ENABLE_TEST_ADAPTERS:-0}" = 1 ]; then
		platform_cru_path=$NUTMERLIN_TEST_ROOT/platform/cru.tsv
		if platform_cru_adapter_state; then
			:
		else
			platform_cru_state=$?
			[ "$platform_cru_state" -eq 1 ] && return 0
			return "$platform_cru_state"
		fi
		rm -f -- "$platform_cru_path"
		return 0
	fi
	command -v cru >/dev/null 2>&1 || return 69
	cru_listing=$(cru l 2>/dev/null) || return 75
	if platform_cru_listing_state "$cru_listing"; then
		cru d NUTMerlin >/dev/null 2>&1 || return 75
		cru_listing=$(cru l 2>/dev/null) || return 75
		if platform_cru_listing_state "$cru_listing"; then
			return 75
		else
			platform_cru_state=$?
			[ "$platform_cru_state" -eq 1 ] || return "$platform_cru_state"
		fi
		return 0
	else
		platform_cru_state=$?
		[ "$platform_cru_state" -eq 1 ] && return 0
		return "$platform_cru_state"
	fi
}

platform_client_count() {
	client_set_root=$1
	client_root=$client_set_root/clients
	if [ ! -e "$client_root" ] && [ ! -L "$client_root" ]; then
		printf '%s\n' 0
		return 0
	fi
	[ -d "$client_root" ] && [ ! -L "$client_root" ] || return 78
	find "$client_root" -mindepth 1 -maxdepth 1 -type f | wc -l
}

platform_unmount_is_relevant() {
	unmount_candidate=${1:-}
	if [ -z "$unmount_candidate" ]; then
		return 0
	fi
	[ "${#unmount_candidate}" -le 256 ] || return 1
	case $unmount_candidate in
		/*) ;;
		*) return 1 ;;
	esac
	[ "$unmount_candidate" = "$NUTMERLIN_OPT_ROOT" ] && return 0
	resolved_opt_root=$(readlink -f "$NUTMERLIN_OPT_ROOT" 2>/dev/null || :)
	case $resolved_opt_root in
		"$unmount_candidate" | "$unmount_candidate"/*) return 0 ;;
		*) return 1 ;;
	esac
}
