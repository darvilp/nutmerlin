#!/bin/sh

lifecycle_recovery_path() {
	printf '%s/nutmerlin/run/recovery.tsv\n' "$NUTMERLIN_TMP_ROOT"
}

lifecycle_recovery_read() {
	RECOVERY_FAILURES=0
	RECOVERY_PAUSE=0
	recovery_path=$(lifecycle_recovery_path)
	if [ ! -e "$recovery_path" ] && [ ! -L "$recovery_path" ]; then
		export RECOVERY_FAILURES RECOVERY_PAUSE
		return 0
	fi
	[ -f "$recovery_path" ] && [ ! -L "$recovery_path" ] || return 78
	[ "$(stat -c '%a' "$recovery_path")" = 600 ] || return 78
	[ "$(stat -c '%h' "$recovery_path")" = 1 ] || return 78
	[ "$(stat -c '%u' "$recovery_path")" = "$(id -u)" ] || return 78
	[ "$(wc -l <"$recovery_path")" -eq 3 ] || return 78
	[ "$(sed -n '1p' "$recovery_path")" = 'schema	nutmerlin.recovery.v1' ] || return 78
	recovery_tab=$(printf '\t')
	RECOVERY_FAILURES=$(awk -v tab="$recovery_tab" \
		'BEGIN { FS = tab } $1 == "failures" && $2 ~ /^[0-3]$/ { print $2 }' "$recovery_path")
	RECOVERY_PAUSE=$(awk -v tab="$recovery_tab" \
		'BEGIN { FS = tab } $1 == "pause" && $2 ~ /^[0-3]$/ { print $2 }' "$recovery_path")
	[ -n "$RECOVERY_FAILURES" ] && [ -n "$RECOVERY_PAUSE" ] || return 78
	export RECOVERY_FAILURES RECOVERY_PAUSE
}

lifecycle_recovery_write() {
	recovery_failures=$1
	recovery_pause=$2
	case $recovery_failures:$recovery_pause in
		[0-3]:[0-3]) ;;
		*) return 78 ;;
	esac
	recovery_path=$(lifecycle_recovery_path)
	recovery_candidate=$recovery_path.new
	[ ! -e "$recovery_candidate" ] && [ ! -L "$recovery_candidate" ] || return 78
	(umask 077 && printf 'schema\tnutmerlin.recovery.v1\nfailures\t%s\npause\t%s\n' \
		"$recovery_failures" "$recovery_pause" >"$recovery_candidate")
	mv "$recovery_candidate" "$recovery_path"
}

lifecycle_recovery_reset() {
	recovery_path=$(lifecycle_recovery_path)
	if [ -e "$recovery_path" ] || [ -L "$recovery_path" ]; then
		[ -f "$recovery_path" ] && [ ! -L "$recovery_path" ] || return 78
		rm -f -- "$recovery_path"
	fi
}

lifecycle_service_is_healthy() {
	entware_check || return 1
	server_record=$NUTMERLIN_TMP_ROOT/nutmerlin/run/upsd.pid
	driver_record=$NUTMERLIN_TMP_ROOT/nutmerlin/run/dummy-ups.pid
	service_pid_pair_is_owned_current "$server_record" "$driver_record" || return 1
	service_runtime_root=$NUTMERLIN_TMP_ROOT/nutmerlin
	export service_runtime_root
	service_query_dummy || return 1
	service_listener_is_loopback_only
}

lifecycle_require_available_installation() {
	storage_state=$(platform_storage_state) || return $?
	[ "$storage_state" = available ] || {
		printf 'lifecycle unavailable: storage=%s\n' "$storage_state" >&2
		return 69
	}
	ownership_verify_installed_state || {
		printf '%s\n' 'lifecycle refused: installed ownership evidence is incomplete' >&2
		return 78
	}
}

lifecycle_user_start() {
	lifecycle_require_available_installation || return $?
	service_start || return $?
	lifecycle_recovery_reset
	LIFECYCLE_MESSAGE='service is running'
	export LIFECYCLE_MESSAGE
}

lifecycle_user_stop() {
	service_stop || return $?
	lifecycle_recovery_reset
	LIFECYCLE_MESSAGE='owned service is stopped'
	export LIFECYCLE_MESSAGE
}

lifecycle_user_restart() {
	lifecycle_require_available_installation || return $?
	service_restart || return $?
	lifecycle_recovery_reset
	LIFECYCLE_MESSAGE='service restarted successfully'
	export LIFECYCLE_MESSAGE
}

lifecycle_record_failure() {
	lifecycle_recovery_read || return $?
	if [ "$RECOVERY_FAILURES" -lt 3 ]; then
		RECOVERY_FAILURES=$((RECOVERY_FAILURES + 1))
	fi
	if [ "$RECOVERY_FAILURES" -eq 3 ]; then
		RECOVERY_PAUSE=3
	fi
	lifecycle_recovery_write "$RECOVERY_FAILURES" "$RECOVERY_PAUSE"
}

lifecycle_reconcile() {
	storage_state=$(platform_storage_state) || return $?
	if [ "$storage_state" != available ]; then
		service_stop || {
			LIFECYCLE_MESSAGE="service close failed: storage=$storage_state"
			export LIFECYCLE_MESSAGE
			return 78
		}
		LIFECYCLE_MESSAGE="service unavailable: storage=$storage_state"
		export LIFECYCLE_MESSAGE
		return 69
	fi
	if [ "$(cat "$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/enabled" 2>/dev/null || :)" != 1 ]; then
		service_stop || return $?
		lifecycle_recovery_reset
		LIFECYCLE_MESSAGE='service is disabled'
		export LIFECYCLE_MESSAGE
		return 69
	fi
	ownership_verify_installed_state || {
		service_stop || :
		printf '%s\n' 'lifecycle refused: installed ownership evidence is incomplete' >&2
		return 78
	}
	lifecycle_recovery_read || return $?
	if [ "$RECOVERY_PAUSE" -gt 0 ]; then
		RECOVERY_PAUSE=$((RECOVERY_PAUSE - 1))
		lifecycle_recovery_write "$RECOVERY_FAILURES" "$RECOVERY_PAUSE" || return $?
		LIFECYCLE_MESSAGE="recovery paused: checks_remaining=$RECOVERY_PAUSE"
		export LIFECYCLE_MESSAGE
		return 75
	fi
	if lifecycle_service_is_healthy; then
		lifecycle_recovery_reset
		LIFECYCLE_MESSAGE='service is healthy'
		export LIFECYCLE_MESSAGE
		return 0
	fi
	if service_restart; then
		lifecycle_recovery_reset
		LIFECYCLE_MESSAGE='service recovered successfully'
		export LIFECYCLE_MESSAGE
		return 0
	fi
	lifecycle_record_failure || return $?
	LIFECYCLE_MESSAGE="recovery failed: failures=$RECOVERY_FAILURES pause=$RECOVERY_PAUSE"
	export LIFECYCLE_MESSAGE
	return 75
}

lifecycle_hook() {
	hook_event=$1
	hook_argument=${2:-}
	if [ "$hook_event" = reconcile ] && [ -n "$hook_argument" ]; then
		expected_schedule_id=$(cat "$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/installation.id" 2>/dev/null || :)
		[ "$hook_argument" = "$expected_schedule_id" ] || return 78
	fi
	case $hook_event in
		services-start)
			platform_cru_ensure || return $?
			lifecycle_reconcile
			;;
		post-mount | firewall-start | reconcile)
			lifecycle_reconcile
			;;
		services-stop)
			schedule_remove_status=0
			service_stop_status=0
			platform_cru_remove || schedule_remove_status=$?
			lifecycle_user_stop || service_stop_status=$?
			[ "$service_stop_status" -eq 0 ] || return "$service_stop_status"
			[ "$schedule_remove_status" -eq 0 ] || return "$schedule_remove_status"
			;;
		unmount)
			if platform_unmount_is_relevant "$hook_argument"; then
				lifecycle_user_stop
			else
				LIFECYCLE_MESSAGE='unrelated unmount ignored'
				export LIFECYCLE_MESSAGE
			fi
			;;
		*) return 64 ;;
	esac
}
