#!/bin/sh

service_id_is_valid() {
	service_id=$1
	[ "${#service_id}" -eq 32 ] || return 1
	case $service_id in
		*[!0-9a-f]*) return 1 ;;
	esac
}

service_resolve_current() {
	service_config_root=$NUTMERLIN_OPT_ROOT/etc/nutmerlin/config
	if [ ! -f "$service_config_root/current" ] || [ -L "$service_config_root/current" ]; then
		printf '%s\n' 'service unavailable: current configuration selector is missing' >&2
		return 69
	fi
	service_set_id=$(cat "$service_config_root/current")
	service_id_is_valid "$service_set_id" || {
		printf '%s\n' 'service refused: current configuration selector is invalid' >&2
		return 78
	}
	NUTMERLIN_ACTIVE_CONFIG=$service_config_root/sets/$service_set_id
	configuration_validate_set "$NUTMERLIN_ACTIVE_CONFIG" || {
		printf '%s\n' 'service refused: current configuration set is invalid' >&2
		return 78
	}
	export NUTMERLIN_ACTIVE_CONFIG
}

service_load_active_profile() {
	active_profile_set_id=${NUTMERLIN_ACTIVE_CONFIG##*/}
	configuration_read_model "$NUTMERLIN_ACTIVE_CONFIG" "$active_profile_set_id" || return 78
	SERVICE_SOURCE=$CONFIGURATION_SOURCE
	case $SERVICE_SOURCE in
		dummy)
			SERVICE_DRIVER_ROLE=dummy
			SERVICE_DRIVER_RECORD_NAME=dummy-ups.pid
			SERVICE_DRIVER_SOCKET_NAME=dummy-ups-dummy
			SERVICE_UPS_NAME=dummy
			;;
		ups)
			SERVICE_DRIVER_ROLE=usbhid
			SERVICE_DRIVER_RECORD_NAME=usbhid-ups.pid
			SERVICE_DRIVER_SOCKET_NAME=usbhid-ups-ups
			SERVICE_UPS_NAME=ups
			;;
		*) return 78 ;;
	esac
	export SERVICE_SOURCE SERVICE_DRIVER_ROLE SERVICE_DRIVER_RECORD_NAME
	export SERVICE_DRIVER_SOCKET_NAME SERVICE_UPS_NAME
}

service_load_active_driver_binary() {
	case $SERVICE_DRIVER_ROLE in
		dummy) SERVICE_DRIVER_BINARY=$NUTMERLIN_DUMMY_UPS_BIN ;;
		usbhid) SERVICE_DRIVER_BINARY=$NUTMERLIN_USBHID_UPS_BIN ;;
		*) return 78 ;;
	esac
	export SERVICE_DRIVER_BINARY
}

service_validate_active_source() {
	[ "$SERVICE_SOURCE" != ups ] || configuration_resolve_usb_identity \
		"$CONFIGURATION_VENDOR_ID" "$CONFIGURATION_PRODUCT_ID" \
		"$CONFIGURATION_IDENTITY_KIND" "$CONFIGURATION_IDENTITY_VALUE"
}

service_run_user() {
	if [ "${NUTMERLIN_ENABLE_TEST_ADAPTERS:-0}" = 1 ]; then
		service_user=${NUTMERLIN_TEST_RUN_USER:-}
	else
		service_user=nobody
	fi
	case $service_user in
		'' | *[!A-Za-z0-9_-]*) return 78 ;;
	esac
	id "$service_user" >/dev/null 2>&1 || return 69
	printf '%s\n' "$service_user"
}

service_prepare_runtime() {
	service_runtime_root=$NUTMERLIN_TMP_ROOT/nutmerlin
	runtime_owner_uid=$(id -u)
	runtime_service_uid=
	if [ "${NUTMERLIN_ENABLE_TEST_ADAPTERS:-0}" = 1 ]; then
		runtime_service_user=${NUTMERLIN_TEST_RUN_USER:-}
	else
		runtime_service_user=nobody
	fi
	if [ -n "$runtime_service_user" ]; then
		runtime_service_uid=$(id -u "$runtime_service_user" 2>/dev/null || :)
	fi
	for runtime_directory in "$service_runtime_root" "$service_runtime_root/lock" \
		"$service_runtime_root/run" "$service_runtime_root/state" "$service_runtime_root/log"; do
		if [ -e "$runtime_directory" ] || [ -L "$runtime_directory" ]; then
			[ -d "$runtime_directory" ] && [ ! -L "$runtime_directory" ] || return 78
			runtime_directory_uid=$(stat -c '%u' "$runtime_directory") || return 78
			if [ "$runtime_directory" = "$service_runtime_root/state" ]; then
				if [ "$runtime_directory_uid" != "$runtime_owner_uid" ]; then
					[ -n "$runtime_service_uid" ] &&
						[ "$runtime_directory_uid" = "$runtime_service_uid" ] || return 78
				fi
			else
				[ "$runtime_directory_uid" = "$runtime_owner_uid" ] || return 78
			fi
			if [ "$runtime_directory" = "$service_runtime_root" ]; then
				[ "$(stat -c '%a' "$runtime_directory")" = 711 ] || return 78
			else
				[ "$(stat -c '%a' "$runtime_directory")" = 700 ] || return 78
			fi
		else
			mkdir "$runtime_directory" || return 75
		fi
	done
	chmod 711 "$service_runtime_root" || return 75
	chmod 700 "$service_runtime_root/lock" "$service_runtime_root/run" \
		"$service_runtime_root/state" "$service_runtime_root/log" || return 75
}

service_lock_acquire() {
	service_prepare_runtime || return $?
	service_lifecycle_lock=$service_runtime_root/lock/lifecycle
	if ! mkdir -m 700 "$service_lifecycle_lock" 2>/dev/null; then
		printf '%s\n' 'service temporary failure: lifecycle work is already in progress' >&2
		return 75
	fi
	(umask 077 && printf '%s\n' "$$" >"$service_lifecycle_lock/owner") || {
		rmdir "$service_lifecycle_lock" 2>/dev/null || :
		return 75
	}
}

service_lock_release() {
	[ -n "${service_lifecycle_lock:-}" ] || return 0
	rm -f -- "$service_lifecycle_lock/owner"
	rmdir "$service_lifecycle_lock" 2>/dev/null || :
	service_lifecycle_lock=
}

service_run_locked() {
	service_lock_acquire || return $?
	trap 'service_lock_release' EXIT
	trap 'service_lock_release; exit 130' HUP INT TERM
	if "$@"; then
		locked_status=0
	else
		locked_status=$?
	fi
	service_lock_release
	trap - EXIT HUP INT TERM
	return "$locked_status"
}

service_pid_record_read() {
	pid_record_path=$1
	[ -f "$pid_record_path" ] && [ ! -L "$pid_record_path" ] || return 1
	[ "$(stat -c '%a' "$pid_record_path")" = 600 ] || return 1
	[ "$(stat -c '%h' "$pid_record_path")" = 1 ] || return 1
	[ "$(stat -c '%u' "$pid_record_path")" = "$(id -u)" ] || return 1
	service_tab=$(printf '\t')
	IFS=$service_tab read -r recorded_pid recorded_uid recorded_installation_id \
		recorded_set_id recorded_epoch recorded_binary <"$pid_record_path" || return 1
	[ "$(wc -l <"$pid_record_path")" -eq 1 ] || return 1
	[ -n "$recorded_pid" ] && [ -n "$recorded_uid" ] || return 1
	case $recorded_pid:$recorded_uid in
		*[!0-9:]*) return 1 ;;
	esac
	service_id_is_valid "$recorded_installation_id" || return 1
	service_id_is_valid "$recorded_set_id" || return 1
	service_id_is_valid "$recorded_epoch" || return 1
	[ -n "$recorded_binary" ] || return 1
}

service_binary_is_allowed() {
	allowed_role=$1
	allowed_binary=$2
	case $allowed_role:$allowed_binary in
		dummy:"$NUTMERLIN_OPT_ROOT"/lib/nut/dummy-ups | \
			dummy:"$NUTMERLIN_OPT_ROOT"/usr/lib/nut/dummy-ups | \
			usbhid:"$NUTMERLIN_OPT_ROOT"/lib/nut/usbhid-ups | \
			usbhid:"$NUTMERLIN_OPT_ROOT"/usr/lib/nut/usbhid-ups | \
			upsd:"$NUTMERLIN_OPT_ROOT"/lib/nut/upsd | \
			upsd:"$NUTMERLIN_OPT_ROOT"/sbin/upsd) return 0 ;;
		*) return 1 ;;
	esac
}

service_pid_is_owned() {
	owned_pid_file=$1
	owned_role=$2
	service_pid_record_read "$owned_pid_file" || return 1
	service_binary_is_allowed "$owned_role" "$recorded_binary" || return 1
	observed_executable=$(platform_process_executable "$recorded_pid" || :)
	[ -n "$observed_executable" ] || return 1
	case $observed_executable in
		"$recorded_binary" | "$recorded_binary (deleted)") ;;
		*)
			expected_executable=$(readlink -f "$recorded_binary" 2>/dev/null || :)
			[ -n "$expected_executable" ] && [ "$observed_executable" = "$expected_executable" ] || return 1
			;;
	esac
	observed_uid=$(platform_process_uid "$recorded_pid")
	[ "$observed_uid" = "$recorded_uid" ] || return 1
	installed_id=$(cat "$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/installation.id" 2>/dev/null || :)
	[ "$recorded_installation_id" = "$installed_id" ] || return 1
	expected_confpath=$NUTMERLIN_OPT_ROOT/etc/nutmerlin/config/sets/$recorded_set_id
	platform_process_has_environment "$recorded_pid" "NUT_CONFPATH=$expected_confpath" || return 1
	platform_process_has_environment "$recorded_pid" "NUTMERLIN_SERVICE_EPOCH=$recorded_epoch"
}

service_current_set_id() {
	service_current_path=$NUTMERLIN_OPT_ROOT/etc/nutmerlin/config/current
	[ -f "$service_current_path" ] && [ ! -L "$service_current_path" ] || return 1
	service_current_id=$(cat "$service_current_path")
	service_id_is_valid "$service_current_id" || return 1
	printf '%s\n' "$service_current_id"
}

service_pid_pair_is_owned_current() {
	pair_server_record=$1
	pair_driver_record=$2
	pair_driver_role=${3:-dummy}
	service_pid_is_owned "$pair_server_record" upsd || return 1
	service_pid_record_read "$pair_server_record" || return 1
	pair_server_set_id=$recorded_set_id
	pair_server_epoch=$recorded_epoch
	service_pid_is_owned "$pair_driver_record" "$pair_driver_role" || return 1
	service_pid_record_read "$pair_driver_record" || return 1
	pair_driver_set_id=$recorded_set_id
	pair_driver_epoch=$recorded_epoch
	pair_current_set_id=$(service_current_set_id) || return 1
	[ "$pair_server_set_id" = "$pair_driver_set_id" ] &&
		[ "$pair_server_set_id" = "$pair_current_set_id" ] &&
		[ "$pair_server_epoch" = "$pair_driver_epoch" ]
}

service_write_pid_record() {
	pid_record_path=$1
	process_pid=$2
	process_uid=$3
	installation_id=$4
	set_id=$5
	epoch_id=$6
	process_binary=$7
	[ ! -e "$pid_record_path" ] && [ ! -L "$pid_record_path" ] || return 78
	pid_record_id=$(configuration_random_id) || return 75
	pid_record_candidate=${pid_record_path}.candidate-$pid_record_id
	if [ -e "$pid_record_candidate" ] || [ -L "$pid_record_candidate" ]; then
		return 78
	fi
	(umask 077 && set -C && printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$process_pid" "$process_uid" \
		"$installation_id" "$set_id" "$epoch_id" "$process_binary" >"$pid_record_candidate") || {
		rm -f -- "$pid_record_candidate"
		return 75
	}
	chmod 600 "$pid_record_candidate" || {
		rm -f -- "$pid_record_candidate"
		return 75
	}
	if ! ln "$pid_record_candidate" "$pid_record_path" 2>/dev/null; then
		rm -f -- "$pid_record_candidate"
		return 78
	fi
	rm -f -- "$pid_record_candidate"
	service_pid_record_read "$pid_record_path" || return 78
	[ "$recorded_pid" = "$process_pid" ] && [ "$recorded_uid" = "$process_uid" ] &&
		[ "$recorded_installation_id" = "$installation_id" ] && [ "$recorded_set_id" = "$set_id" ] &&
		[ "$recorded_epoch" = "$epoch_id" ] && [ "$recorded_binary" = "$process_binary" ]
}

service_stop_pid_file() {
	stop_pid_file=$1
	stop_role=$2
	[ -e "$stop_pid_file" ] || [ -L "$stop_pid_file" ] || return 0
	service_pid_record_read "$stop_pid_file" || return 78
	stop_pid=$recorded_pid
	if platform_process_is_alive "$stop_pid"; then
		service_pid_is_owned "$stop_pid_file" "$stop_role" || return 78
		platform_process_signal "$stop_pid" || return 75
		stop_attempt=0
		while platform_process_is_alive "$stop_pid" && [ "$stop_attempt" -lt 10 ]; do
			stop_attempt=$((stop_attempt + 1))
			sleep 1
		done
		platform_process_is_alive "$stop_pid" && return 75
	fi
	rm -f -- "$stop_pid_file"
}

service_listener_is_clear() {
	service_listener_snapshot=$(platform_listener_snapshot) || return 69
	! printf '%s\n' "$service_listener_snapshot" | awk 'NR > 1 { print $4 }' | grep -Eq '(^|:)3493$'
}

service_listener_is_loopback_only() {
	service_listener_snapshot=$(platform_listener_snapshot) || return 69
	service_listener_addresses=$(printf '%s\n' "$service_listener_snapshot" | awk 'NR > 1 && $4 ~ /:3493$/ { print $4 }')
	[ "$service_listener_addresses" = '127.0.0.1:3493' ]
}

service_query_dummy() {
	query_attempt=0
	while [ "$query_attempt" -lt 10 ]; do
		if "$NUTMERLIN_UPSC_BIN" dummy@127.0.0.1 >"$service_runtime_root/run/upsc.out" \
			2>"$service_runtime_root/run/upsc.err"; then
			if grep -q '^device.model: CP1500PFCLCD$' "$service_runtime_root/run/upsc.out" &&
				grep -q '^ups.status: OL$' "$service_runtime_root/run/upsc.out"; then
				return 0
			fi
		fi
		query_attempt=$((query_attempt + 1))
		sleep 1
	done
	return 1
}

service_query_usbhid() {
	query_attempt=0
	while [ "$query_attempt" -lt 10 ]; do
		if "$NUTMERLIN_UPSC_BIN" ups@127.0.0.1 >"$service_runtime_root/run/upsc.out" \
			2>"$service_runtime_root/run/upsc.err"; then
			query_identity_matches=1
			case $CONFIGURATION_IDENTITY_KIND in
				serial)
					grep -Fx "device.serial: $CONFIGURATION_IDENTITY_VALUE" \
						"$service_runtime_root/run/upsc.out" >/dev/null || query_identity_matches=0
					;;
				busport)
					grep -Fx "driver.parameter.busport: ^$CONFIGURATION_IDENTITY_VALUE\$" \
						"$service_runtime_root/run/upsc.out" >/dev/null || query_identity_matches=0
					;;
				*) query_identity_matches=0 ;;
			esac
			if [ "$query_identity_matches" -eq 1 ] &&
				grep -Fx 'driver.name: usbhid-ups' "$service_runtime_root/run/upsc.out" >/dev/null &&
				grep -Eq '^ups[.]status: [A-Z]+([+ ][A-Z]+)*$' \
					"$service_runtime_root/run/upsc.out"; then
				return 0
			fi
		fi
		query_attempt=$((query_attempt + 1))
		sleep 1
	done
	return 1
}

service_query_active() {
	case $SERVICE_SOURCE in
		dummy) service_query_dummy ;;
		ups) service_query_usbhid ;;
		*) return 1 ;;
	esac
}

service_stop() {
	service_runtime_root=$NUTMERLIN_TMP_ROOT/nutmerlin
	service_stop_pid_file "$service_runtime_root/run/upsd.pid" upsd || {
		printf '%s\n' 'service refused: upsd process identity is not owned' >&2
		return 78
	}
	service_stop_pid_file "$service_runtime_root/run/dummy-ups.pid" dummy || {
		printf '%s\n' 'service refused: dummy-ups process identity is not owned' >&2
		return 78
	}
	service_stop_pid_file "$service_runtime_root/run/usbhid-ups.pid" usbhid || {
		printf '%s\n' 'service refused: usbhid-ups process identity is not owned' >&2
		return 78
	}
	service_listener_is_clear || {
		printf '%s\n' 'service refused: an unowned listener remains on port 3493' >&2
		return 78
	}
	SERVICE_MESSAGE='owned NUT processes are stopped'
	export SERVICE_MESSAGE
}

service_cleanup_failed_start() {
	if [ -n "${started_server_pid:-}" ]; then
		platform_process_signal "$started_server_pid" 2>/dev/null || :
		wait "$started_server_pid" 2>/dev/null || :
	fi
	if [ -n "${started_driver_pid:-}" ]; then
		platform_process_signal "$started_driver_pid" 2>/dev/null || :
		wait "$started_driver_pid" 2>/dev/null || :
	fi
	rm -f -- "$service_runtime_root/run/upsd.pid" "$service_runtime_root/run/dummy-ups.pid" \
		"$service_runtime_root/run/usbhid-ups.pid"
}

service_start() {
	entware_check
	service_resolve_current
	service_load_active_profile || {
		printf '%s\n' 'service refused: active source profile is invalid' >&2
		return 78
	}
	service_load_active_driver_binary || return $?
	service_validate_active_source || return $?
	service_user=$(service_run_user) || {
		printf '%s\n' 'service unavailable: unprivileged NUT user is unavailable' >&2
		return 69
	}
	service_runtime_root=$NUTMERLIN_TMP_ROOT/nutmerlin
	service_prepare_runtime || return $?
	chown "$service_user" "$service_runtime_root/state"
	service_driver_log=$service_runtime_root/log/$SERVICE_DRIVER_ROLE.log
	[ "$SERVICE_DRIVER_ROLE" != dummy ] || service_driver_log=$service_runtime_root/log/dummy-ups.log
	for service_log_path in "$service_driver_log" "$service_runtime_root/log/upsd.log"; do
		if [ -e "$service_log_path" ] || [ -L "$service_log_path" ]; then
			if [ ! -f "$service_log_path" ] || [ -L "$service_log_path" ] ||
				[ "$(stat -c '%h' "$service_log_path")" != 1 ]; then
				printf '%s\n' 'service refused: owned log path is unsafe' >&2
				return 78
			fi
		fi
	done

	server_pid_path=$service_runtime_root/run/upsd.pid
	driver_pid_path=$service_runtime_root/run/$SERVICE_DRIVER_RECORD_NAME
	case $SERVICE_DRIVER_ROLE in
		dummy) other_driver_pid_path=$service_runtime_root/run/usbhid-ups.pid ;;
		usbhid) other_driver_pid_path=$service_runtime_root/run/dummy-ups.pid ;;
		*) return 78 ;;
	esac
	if [ -e "$other_driver_pid_path" ] || [ -L "$other_driver_pid_path" ]; then
		printf '%s\n' 'service refused: partial or unsafe process state' >&2
		return 78
	fi
	server_pid_present=0
	driver_pid_present=0
	{ [ ! -e "$server_pid_path" ] && [ ! -L "$server_pid_path" ]; } || server_pid_present=1
	{ [ ! -e "$driver_pid_path" ] && [ ! -L "$driver_pid_path" ]; } || driver_pid_present=1
	if [ "$server_pid_present" -ne "$driver_pid_present" ]; then
		printf '%s\n' 'service refused: partial or unsafe process state' >&2
		return 78
	fi
	if [ "$server_pid_present" -eq 1 ]; then
		if service_pid_pair_is_owned_current "$server_pid_path" "$driver_pid_path" \
			"$SERVICE_DRIVER_ROLE" && service_query_active && service_listener_is_loopback_only; then
			SERVICE_MESSAGE="$SERVICE_UPS_NAME is already running on loopback"
			export SERVICE_MESSAGE
			return 0
		fi
		printf '%s\n' 'service refused: stale or mismatched owned process state' >&2
		return 78
	fi
	service_listener_is_clear || {
		printf '%s\n' 'service refused: port 3493 is already occupied' >&2
		return 78
	}

	started_driver_pid=
	started_server_pid=
	NUT_CONFPATH=$NUTMERLIN_ACTIVE_CONFIG
	NUT_STATEPATH=$service_runtime_root/state
	service_installation_id=$(cat "$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/installation.id")
	service_set_id=${NUTMERLIN_ACTIVE_CONFIG##*/}
	service_epoch=$(configuration_random_id)
	service_uid=$(id -u "$service_user")
	NUTMERLIN_SERVICE_EPOCH=$service_epoch
	export NUT_CONFPATH NUT_STATEPATH NUTMERLIN_SERVICE_EPOCH
	"$SERVICE_DRIVER_BINARY" -a "$SERVICE_UPS_NAME" -F -u "$service_user" \
		>"$service_driver_log" 2>&1 &
	started_driver_pid=$!
	if ! service_write_pid_record "$driver_pid_path" "$started_driver_pid" \
		"$service_uid" "$service_installation_id" "$service_set_id" "$service_epoch" \
		"$SERVICE_DRIVER_BINARY"; then
		service_cleanup_failed_start
		printf 'service refused: %s PID record could not be created safely\n' \
			"$SERVICE_DRIVER_ROLE" >&2
		return 78
	fi

	driver_attempt=0
	while [ ! -e "$service_runtime_root/state/$SERVICE_DRIVER_SOCKET_NAME" ] &&
		[ "$driver_attempt" -lt 10 ]; do
		platform_process_is_alive "$started_driver_pid" || break
		driver_attempt=$((driver_attempt + 1))
		sleep 1
	done
	if [ ! -e "$service_runtime_root/state/$SERVICE_DRIVER_SOCKET_NAME" ] ||
		! platform_process_is_alive "$started_driver_pid"; then
		service_cleanup_failed_start
		printf 'service temporary failure: %s did not start\n' "$SERVICE_DRIVER_ROLE" >&2
		return 75
	fi

	"$NUTMERLIN_UPSD_BIN" -F -u "$service_user" >"$service_runtime_root/log/upsd.log" 2>&1 &
	started_server_pid=$!
	if ! service_write_pid_record "$service_runtime_root/run/upsd.pid" "$started_server_pid" \
		"$service_uid" "$service_installation_id" "$service_set_id" "$service_epoch" \
		"$NUTMERLIN_UPSD_BIN"; then
		service_cleanup_failed_start
		printf '%s\n' 'service refused: upsd PID record could not be created safely' >&2
		return 78
	fi
	service_injected_failure=0
	if [ "${NUTMERLIN_ENABLE_TEST_ADAPTERS:-0}" = 1 ] &&
		[ "${NUTMERLIN_TEST_ACTIVATION_FAIL:-0}" = 1 ]; then
		service_injected_failure=1
	fi
	service_health_failure=
	if ! service_query_active; then
		service_health_failure=query
	elif ! service_listener_is_loopback_only; then
		service_health_failure=listener
	elif [ "$service_injected_failure" -eq 1 ]; then
		service_health_failure=injected
	fi
	if [ -n "$service_health_failure" ]; then
		service_cleanup_failed_start
		printf 'service temporary failure: owned %s health check failed: %s\n' \
			"$SERVICE_UPS_NAME" "$service_health_failure" >&2
		return 75
	fi

	SERVICE_MESSAGE="$SERVICE_UPS_NAME is running on loopback"
	export SERVICE_MESSAGE
}

service_restart() {
	service_stop || return $?
	service_start
}
