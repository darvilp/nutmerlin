#!/bin/sh

# shellcheck disable=SC2034 # result text is consumed by the sourcing CLI

management_test_checkpoint() {
	management_checkpoint=$1
	if [ "${NUTMERLIN_ENABLE_TEST_ADAPTERS:-0}" = 1 ] &&
		[ "${NUTMERLIN_TEST_MANAGEMENT_FAIL_AFTER:-}" = "$management_checkpoint" ]; then
		printf 'management temporary failure after %s\n' "$management_checkpoint" >&2
		return 75
	fi
}

management_code_is_repairable() {
	ownership_verify_code_contents "$NUTMERLIN_JFFS_ROOT/addons/nutmerlin"
}

management_set_is_repairable() (
	management_set_root=$1
	management_set_id=${management_set_root##*/}
	ownership_id_is_valid "$management_set_id" || return 1
	management_expected_uid=$(id -u)
	[ -d "$management_set_root" ] && [ ! -L "$management_set_root" ] || return 1
	[ "$(stat -c '%u' "$management_set_root")" = "$management_expected_uid" ] || return 1
	management_set_entry_count=5
	if [ -e "$management_set_root/clients" ] || [ -L "$management_set_root/clients" ]; then
		management_set_entry_count=6
	fi
	[ "$(find "$management_set_root" -mindepth 1 -maxdepth 1 | wc -l)" -eq \
		"$management_set_entry_count" ] || return 1
	management_set_scratch_parent=$(mktemp -d \
		"$NUTMERLIN_TMP_ROOT/.nutmerlin-set-repair-check.XXXXXX") || return 1
	trap 'rm -rf -- "$management_set_scratch_parent"' EXIT HUP INT TERM
	management_set_scratch=$management_set_scratch_parent/$management_set_id
	mkdir -m 700 "$management_set_scratch" || return 1
	for management_set_file in model.tsv ups.conf upsd.conf upsd.users SHA256SUMS; do
		management_set_path=$management_set_root/$management_set_file
		[ -f "$management_set_path" ] && [ ! -L "$management_set_path" ] || return 1
		[ "$(stat -c '%h' "$management_set_path")" = 1 ] || return 1
		[ "$(stat -c '%u' "$management_set_path")" = "$management_expected_uid" ] || return 1
		cp "$management_set_path" "$management_set_scratch/$management_set_file" || return 1
		chmod 600 "$management_set_scratch/$management_set_file" || return 1
	done
	if [ "$management_set_entry_count" -eq 6 ]; then
		management_client_root=$management_set_root/clients
		[ -d "$management_client_root" ] && [ ! -L "$management_client_root" ] || return 1
		[ "$(stat -c '%u' "$management_client_root")" = "$management_expected_uid" ] || return 1
		for management_hidden_client in "$management_client_root"/.[!.]* \
			"$management_client_root"/..?*; do
			[ ! -e "$management_hidden_client" ] && [ ! -L "$management_hidden_client" ] || return 1
		done
		management_client_count=$(find "$management_client_root" -mindepth 1 -maxdepth 1 | wc -l)
		[ "$management_client_count" -ge 1 ] && [ "$management_client_count" -le 64 ] || return 1
		mkdir -m 700 "$management_set_scratch/clients" || return 1
		for management_client_path in "$management_client_root"/*; do
			management_client_id=${management_client_path##*/}
			configuration_client_id_is_valid "$management_client_id" || return 1
			[ -f "$management_client_path" ] && [ ! -L "$management_client_path" ] || return 1
			[ "$(stat -c '%h' "$management_client_path")" = 1 ] || return 1
			[ "$(stat -c '%u' "$management_client_path")" = "$management_expected_uid" ] || return 1
			cp "$management_client_path" "$management_set_scratch/clients/$management_client_id" || return 1
			chmod 600 "$management_set_scratch/clients/$management_client_id" || return 1
		done
	fi
	configuration_validate_set "$management_set_scratch"
)

management_selector_value() {
	management_selector_path=$1
	management_expected_uid=$2
	[ -f "$management_selector_path" ] && [ ! -L "$management_selector_path" ] || return 1
	[ "$(stat -c '%h' "$management_selector_path")" = 1 ] || return 1
	[ "$(stat -c '%u' "$management_selector_path")" = "$management_expected_uid" ] || return 1
	management_selector_id=$(cat "$management_selector_path")
	ownership_id_is_valid "$management_selector_id" || return 1
	printf '%s\n' "$management_selector_id"
}

management_config_is_repairable() {
	management_config_root=$NUTMERLIN_OPT_ROOT/etc/nutmerlin
	management_code_root=$NUTMERLIN_JFFS_ROOT/addons/nutmerlin
	management_expected_uid=$(id -u)
	[ -d "$management_config_root" ] && [ ! -L "$management_config_root" ] || return 1
	[ "$(stat -c '%u' "$management_config_root")" = "$management_expected_uid" ] || return 1
	ownership_entry_count_is "$management_config_root" 2 || return 1
	management_config_id_path=$management_config_root/installation.id
	[ -f "$management_config_id_path" ] && [ ! -L "$management_config_id_path" ] || return 1
	[ "$(stat -c '%h' "$management_config_id_path")" = 1 ] || return 1
	[ "$(stat -c '%u' "$management_config_id_path")" = "$management_expected_uid" ] || return 1
	management_config_id=$(cat "$management_config_id_path")
	[ "$management_config_id" = "$(cat "$management_code_root/installation.id")" ] || return 1
	ownership_id_is_valid "$management_config_id" || return 1
	management_selector_root=$management_config_root/config
	management_sets_root=$management_selector_root/sets
	[ -d "$management_selector_root" ] && [ ! -L "$management_selector_root" ] || return 1
	[ -d "$management_sets_root" ] && [ ! -L "$management_sets_root" ] || return 1
	[ "$(stat -c '%u' "$management_selector_root")" = "$management_expected_uid" ] || return 1
	[ "$(stat -c '%u' "$management_sets_root")" = "$management_expected_uid" ] || return 1
	management_set_count=$(find "$management_sets_root" -mindepth 1 -maxdepth 1 | wc -l)
	[ "$management_set_count" -ge 1 ] && [ "$management_set_count" -le 2 ] || return 1
	management_set_one=
	management_set_two=
	for management_set_root in "$management_sets_root"/*; do
		management_set_id=${management_set_root##*/}
		management_set_is_repairable "$management_set_root" || return 1
		if [ -z "$management_set_one" ]; then
			management_set_one=$management_set_id
		else
			management_set_two=$management_set_id
		fi
	done
	MANAGEMENT_CURRENT_ID=
	MANAGEMENT_LAST_GOOD_ID=
	management_current_path=$management_selector_root/current
	management_last_good_path=$management_selector_root/last-good
	if [ -e "$management_current_path" ] || [ -L "$management_current_path" ]; then
		MANAGEMENT_CURRENT_ID=$(management_selector_value "$management_current_path" \
			"$management_expected_uid") || return 1
	fi
	if [ -e "$management_last_good_path" ] || [ -L "$management_last_good_path" ]; then
		MANAGEMENT_LAST_GOOD_ID=$(management_selector_value "$management_last_good_path" \
			"$management_expected_uid") || return 1
	fi
	management_selector_entry_count=1
	[ -z "$MANAGEMENT_CURRENT_ID" ] || management_selector_entry_count=$((management_selector_entry_count + 1))
	[ -z "$MANAGEMENT_LAST_GOOD_ID" ] || management_selector_entry_count=$((management_selector_entry_count + 1))
	[ "$(find "$management_selector_root" -mindepth 1 -maxdepth 1 | wc -l)" -eq \
		"$management_selector_entry_count" ] || return 1
	case $management_set_count in
		1)
			[ -z "$MANAGEMENT_CURRENT_ID" ] || [ "$MANAGEMENT_CURRENT_ID" = "$management_set_one" ] || return 1
			[ -z "$MANAGEMENT_LAST_GOOD_ID" ] || return 1
			MANAGEMENT_CURRENT_ID=$management_set_one
			;;
		2)
			if [ -z "$MANAGEMENT_CURRENT_ID" ] && [ -z "$MANAGEMENT_LAST_GOOD_ID" ]; then
				return 1
			fi
			if [ -z "$MANAGEMENT_CURRENT_ID" ]; then
				case $MANAGEMENT_LAST_GOOD_ID in
					"$management_set_one") MANAGEMENT_CURRENT_ID=$management_set_two ;;
					"$management_set_two") MANAGEMENT_CURRENT_ID=$management_set_one ;;
					*) return 1 ;;
				esac
			elif [ -z "$MANAGEMENT_LAST_GOOD_ID" ]; then
				case $MANAGEMENT_CURRENT_ID in
					"$management_set_one") MANAGEMENT_LAST_GOOD_ID=$management_set_two ;;
					"$management_set_two") MANAGEMENT_LAST_GOOD_ID=$management_set_one ;;
					*) return 1 ;;
				esac
			fi
			[ "$MANAGEMENT_CURRENT_ID" != "$MANAGEMENT_LAST_GOOD_ID" ] || return 1
			case $MANAGEMENT_CURRENT_ID:$MANAGEMENT_LAST_GOOD_ID in
				"$management_set_one:$management_set_two" | \
					"$management_set_two:$management_set_one") ;;
				*) return 1 ;;
			esac
			;;
	esac
	export MANAGEMENT_CURRENT_ID MANAGEMENT_LAST_GOOD_ID
}

management_repair_code_modes() {
	management_code_root=$NUTMERLIN_JFFS_ROOT/addons/nutmerlin
	chmod 755 "$management_code_root" "$management_code_root/bin" "$management_code_root/lib" \
		"$management_code_root/share" "$management_code_root/share/dummy" || return 75
	chmod 755 "$management_code_root/bin/nutmerlin" || return 75
	chmod 644 "$management_code_root/VERSION" "$management_code_root/lib/"*.sh \
		"$management_code_root/share/dummy/cyberpower.dev" || return 75
	chmod 600 "$management_code_root/installation.id" "$management_code_root/enabled" \
		"$management_code_root/entware.tsv" "$management_code_root/hooks.tsv" \
		"$management_code_root/owned-files" || return 75
	ownership_verify_code_payload "$management_code_root"
}

management_repair_config() {
	management_config_root=$NUTMERLIN_OPT_ROOT/etc/nutmerlin
	management_selector_root=$management_config_root/config
	management_sets_root=$management_selector_root/sets
	chmod 700 "$management_config_root" "$management_selector_root" "$management_sets_root" || return 75
	chmod 600 "$management_config_root/installation.id" || return 75
	for management_set_root in "$management_sets_root"/*; do
		chmod 700 "$management_set_root" || return 75
		chmod 600 "$management_set_root/model.tsv" "$management_set_root/ups.conf" \
			"$management_set_root/upsd.conf" "$management_set_root/upsd.users" \
			"$management_set_root/SHA256SUMS" || return 75
		if [ -d "$management_set_root/clients" ]; then
			chmod 700 "$management_set_root/clients" || return 75
			chmod 600 "$management_set_root/clients/"* || return 75
		fi
	done
	if [ -e "$management_selector_root/current" ]; then
		chmod 600 "$management_selector_root/current" || return 75
	else
		configuration_select_set "$management_selector_root" current \
			"$MANAGEMENT_CURRENT_ID" || return $?
	fi
	if [ -n "$MANAGEMENT_LAST_GOOD_ID" ]; then
		if [ -e "$management_selector_root/last-good" ]; then
			chmod 600 "$management_selector_root/last-good" || return 75
		else
			configuration_select_set "$management_selector_root" last-good \
				"$MANAGEMENT_LAST_GOOD_ID" || return $?
		fi
	fi
	ownership_verify_config_root "$management_config_root"
}

management_write_enabled() {
	management_enabled_value=$1
	case $management_enabled_value in
		0 | 1) ;;
		*) return 78 ;;
	esac
	management_code_root=$NUTMERLIN_JFFS_ROOT/addons/nutmerlin
	management_enabled_path=$management_code_root/enabled
	[ -f "$management_enabled_path" ] && [ ! -L "$management_enabled_path" ] || return 78
	[ "$(stat -c '%a' "$management_enabled_path")" = 600 ] || return 78
	[ "$(stat -c '%h' "$management_enabled_path")" = 1 ] || return 78
	[ "$(stat -c '%u' "$management_enabled_path")" = "$(id -u)" ] || return 78
	management_enabled_candidate=$management_code_root/enabled.new
	[ ! -e "$management_enabled_candidate" ] && [ ! -L "$management_enabled_candidate" ] || return 78
	(umask 077 && printf '%s\n' "$management_enabled_value" >"$management_enabled_candidate") || {
		rm -f -- "$management_enabled_candidate"
		return 75
	}
	chmod 600 "$management_enabled_candidate" || {
		rm -f -- "$management_enabled_candidate"
		return 75
	}
	mv "$management_enabled_candidate" "$management_enabled_path"
}

management_ids_match() {
	management_code_id=$(cat "$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/installation.id" \
		2>/dev/null || :)
	management_config_id=$(cat "$NUTMERLIN_OPT_ROOT/etc/nutmerlin/installation.id" \
		2>/dev/null || :)
	ownership_id_is_valid "$management_code_id" &&
		[ "$management_code_id" = "$management_config_id" ]
}

management_ambient_nut_is_clear() {
	management_ambient_nut_root=$NUTMERLIN_OPT_ROOT/etc/nut
	if [ ! -e "$management_ambient_nut_root" ] && [ ! -L "$management_ambient_nut_root" ]; then
		return 0
	fi
	[ -d "$management_ambient_nut_root" ] && [ ! -L "$management_ambient_nut_root" ] &&
		[ -z "$(find "$management_ambient_nut_root" -mindepth 1 -maxdepth 1 -print -quit)" ]
}

management_live_surfaces_are_owned() {
	platform_cru_owned_or_absent || {
		printf '%s\n' 'management refused: periodic job state is foreign or ambiguous' >&2
		return 78
	}
	platform_firewall_owned_or_absent || {
		printf '%s\n' 'management refused: firewall state is foreign or ambiguous' >&2
		return 78
	}
	management_ambient_nut_is_clear || {
		printf '%s\n' 'management refused: foreign ambient NUT configuration is present' >&2
		return 78
	}
	NUTMERLIN_OWNERSHIP_STATE=owned
	export NUTMERLIN_OWNERSHIP_STATE
	if ownership_has_foreign_hook; then
		printf '%s\n' 'management refused: foreign Merlin hook references NUT' >&2
		return 78
	fi
	ownership_check_live_foreign_state
}

management_record_close_status() {
	management_observed_status=$1
	if [ "$management_close_status" -eq 0 ]; then
		management_close_status=$management_observed_status
	fi
}

management_disable_locked() {
	management_code_root=$NUTMERLIN_JFFS_ROOT/addons/nutmerlin
	ownership_verify_code_payload "$management_code_root" || {
		printf '%s\n' 'disable refused: installed code ownership evidence is incomplete' >&2
		return 78
	}
	hooks_repairable_all "$management_code_root" || {
		printf '%s\n' 'disable refused: Merlin hook state is modified or ambiguous' >&2
		return 78
	}
	management_storage_state=$(platform_storage_state) || return $?
	case $management_storage_state in
		available | read_only)
			if ! ownership_verify_config_root "$NUTMERLIN_OPT_ROOT/etc/nutmerlin" ||
				! management_ids_match; then
				printf '%s\n' 'disable refused: installed ownership evidence is incomplete' >&2
				return 78
			fi
			;;
		missing)
			NUTMERLIN_ALLOW_MISSING_ACTIVE_CONFIG=1
			export NUTMERLIN_ALLOW_MISSING_ACTIVE_CONFIG
			;;
		*)
			printf 'disable refused: /opt state is %s\n' "$management_storage_state" >&2
			return 78
			;;
	esac
	management_live_surfaces_are_owned || return $?
	management_write_enabled 0 || return $?
	management_close_status=0
	management_test_checkpoint enabled || management_record_close_status $?
	platform_firewall_remove_owned || management_record_close_status $?
	management_test_checkpoint firewall || management_record_close_status $?
	service_stop || management_record_close_status $?
	management_test_checkpoint service || management_record_close_status $?
	platform_cru_remove || management_record_close_status $?
	management_test_checkpoint schedule || management_record_close_status $?
	lifecycle_recovery_reset || management_record_close_status $?
	management_test_checkpoint recovery || management_record_close_status $?
	[ "$management_close_status" -eq 0 ] || return "$management_close_status"
	MANAGEMENT_MESSAGE='NUTMerlin is disabled; owned data and Entware packages were retained'
	export MANAGEMENT_MESSAGE
}

management_disable() {
	service_run_locked management_disable_locked
}

management_enable_locked() {
	management_storage_state=$(platform_storage_state) || return $?
	[ "$management_storage_state" = available ] || {
		printf 'enable unavailable: storage=%s\n' "$management_storage_state" >&2
		return 69
	}
	ownership_verify_installed_state || {
		printf '%s\n' 'enable refused: installed ownership evidence is incomplete' >&2
		return 78
	}
	management_live_surfaces_are_owned || return $?
	entware_check || return $?
	service_resolve_current || return $?
	service_load_active_profile || {
		printf '%s\n' 'enable refused: active source profile is invalid' >&2
		return 78
	}
	service_load_active_driver_binary || return $?
	service_validate_active_source || return $?
	service_validate_active_network || return $?
	management_write_enabled 1 || return $?
	management_enable_status=0
	platform_cru_ensure || management_enable_status=$?
	if [ "$management_enable_status" -ne 0 ]; then
		management_write_enabled 0 || :
		return "$management_enable_status"
	fi
	service_start || return $?
	MANAGEMENT_MESSAGE="NUTMerlin is enabled; $SERVICE_MESSAGE"
	export MANAGEMENT_MESSAGE
}

management_enable() {
	service_run_locked management_enable_locked
}

management_repair_locked() {
	management_code_root=$NUTMERLIN_JFFS_ROOT/addons/nutmerlin
	management_config_root=$NUTMERLIN_OPT_ROOT/etc/nutmerlin
	management_code_is_repairable || {
		printf '%s\n' 'repair refused: owned code content is modified or ambiguous' >&2
		return 78
	}
	management_config_is_repairable || {
		printf '%s\n' 'repair refused: owned configuration is modified or ambiguous' >&2
		return 78
	}
	hooks_repairable_all "$management_code_root" || {
		printf '%s\n' 'repair refused: Merlin hook state is modified or ambiguous' >&2
		return 78
	}
	management_ids_match || {
		printf '%s\n' 'repair refused: installation identities are invalid or mismatched' >&2
		return 78
	}
	management_live_surfaces_are_owned || return $?
	management_repair_code_modes || return $?
	management_test_checkpoint code || return $?
	management_repair_config || return $?
	management_test_checkpoint configuration || return $?
	hooks_repair_all "$management_code_root" || {
		printf '%s\n' 'repair refused: Merlin hook state is modified or ambiguous' >&2
		return 78
	}
	management_test_checkpoint hooks || return $?
	ownership_verify_installed_state || return 78
	management_enabled=$(cat "$management_code_root/enabled")
	if [ "$management_enabled" -eq 0 ]; then
		platform_cru_remove || return $?
		service_stop || return $?
		platform_firewall_remove_owned || return $?
		lifecycle_recovery_reset || return $?
		MANAGEMENT_MESSAGE='NUTMerlin owned state repaired; service remains disabled'
	else
		entware_check || return $?
		platform_cru_ensure || return $?
		service_start || return $?
		MANAGEMENT_MESSAGE="NUTMerlin owned state repaired; $SERVICE_MESSAGE"
	fi
	export MANAGEMENT_MESSAGE
}

management_repair() {
	service_run_locked management_repair_locked
}

management_runtime_file_is_owned() {
	management_runtime_file=$1
	[ -f "$management_runtime_file" ] && [ ! -L "$management_runtime_file" ] || return 1
	[ "$(stat -c '%h' "$management_runtime_file")" = 1 ] || return 1
	[ "$(stat -c '%u' "$management_runtime_file")" = "$(id -u)" ] || return 1
}

management_runtime_is_owned() {
	management_runtime_root=$NUTMERLIN_TMP_ROOT/nutmerlin
	if [ ! -e "$management_runtime_root" ] && [ ! -L "$management_runtime_root" ]; then
		return 0
	fi
	[ -d "$management_runtime_root" ] && [ ! -L "$management_runtime_root" ] || return 1
	[ "$(stat -c '%a' "$management_runtime_root")" = 711 ] || return 1
	[ "$(stat -c '%u' "$management_runtime_root")" = "$(id -u)" ] || return 1
	ownership_entry_count_is "$management_runtime_root" 4 || return 1
	for management_runtime_directory in lock run state log; do
		management_runtime_directory_path=$management_runtime_root/$management_runtime_directory
		[ -d "$management_runtime_directory_path" ] &&
			[ ! -L "$management_runtime_directory_path" ] || return 1
		[ "$(stat -c '%a' "$management_runtime_directory_path")" = 700 ] || return 1
	done
	[ "$(stat -c '%u' "$management_runtime_root/lock")" = "$(id -u)" ] || return 1
	[ "$(stat -c '%u' "$management_runtime_root/run")" = "$(id -u)" ] || return 1
	[ "$(stat -c '%u' "$management_runtime_root/log")" = "$(id -u)" ] || return 1
	management_runtime_service_user=$(service_run_user) || return 1
	management_runtime_service_uid=$(id -u "$management_runtime_service_user") || return 1
	management_state_uid=$(stat -c '%u' "$management_runtime_root/state") || return 1
	case $management_state_uid in
		"$(id -u)" | "$management_runtime_service_uid") ;;
		*) return 1 ;;
	esac
	for management_lock_entry in "$management_runtime_root/lock"/*; do
		[ -e "$management_lock_entry" ] || [ -L "$management_lock_entry" ] || continue
		[ "${management_lock_entry##*/}" = lifecycle ] || return 1
		[ -d "$management_lock_entry" ] && [ ! -L "$management_lock_entry" ] || return 1
		[ "$(stat -c '%a' "$management_lock_entry")" = 700 ] || return 1
		[ "$(stat -c '%u' "$management_lock_entry")" = "$(id -u)" ] || return 1
		ownership_entry_count_is "$management_lock_entry" 1 || return 1
		management_runtime_file_is_owned "$management_lock_entry/owner" || return 1
	done
	for management_run_entry in "$management_runtime_root/run"/*; do
		[ -e "$management_run_entry" ] || [ -L "$management_run_entry" ] || continue
		case ${management_run_entry##*/} in
			upsd.pid | dummy-ups.pid | usbhid-ups.pid | recovery.tsv | upsc.out | upsc.err) ;;
			*) return 1 ;;
		esac
		management_runtime_file_is_owned "$management_run_entry" || return 1
	done
	for management_log_entry in "$management_runtime_root/log"/*; do
		[ -e "$management_log_entry" ] || [ -L "$management_log_entry" ] || continue
		case ${management_log_entry##*/} in
			dummy-ups.log | usbhid.log | upsd.log) ;;
			*) return 1 ;;
		esac
		management_runtime_file_is_owned "$management_log_entry" || return 1
	done
	for management_state_entry in "$management_runtime_root/state"/*; do
		[ -e "$management_state_entry" ] || [ -L "$management_state_entry" ] || continue
		case ${management_state_entry##*/} in
			dummy-ups-dummy)
				management_state_role=dummy
				management_state_record=$management_runtime_root/run/dummy-ups.pid
				;;
			usbhid-ups-ups)
				management_state_role=usbhid
				management_state_record=$management_runtime_root/run/usbhid-ups.pid
				;;
			*) return 1 ;;
		esac
		[ "$(find "$management_state_entry" -prune -type s -print)" = \
			"$management_state_entry" ] || return 1
		[ "$(stat -c '%u' "$management_state_entry")" = "$management_runtime_service_uid" ] || return 1
		service_pid_is_owned "$management_state_record" "$management_state_role" || return 1
	done
}

management_runtime_is_removable() {
	management_runtime_is_owned || return 1
	management_runtime_root=$NUTMERLIN_TMP_ROOT/nutmerlin
	[ -z "$(find "$management_runtime_root/state" -mindepth 1 -maxdepth 1 -print -quit)" ] || return 1
	for management_stopped_record in "$management_runtime_root/run/upsd.pid" \
		"$management_runtime_root/run/dummy-ups.pid" \
		"$management_runtime_root/run/usbhid-ups.pid"; do
		[ ! -e "$management_stopped_record" ] && [ ! -L "$management_stopped_record" ] || return 1
	done
}

management_uninstall_state_is_owned() {
	management_code_root=$NUTMERLIN_JFFS_ROOT/addons/nutmerlin
	management_config_root=$NUTMERLIN_OPT_ROOT/etc/nutmerlin
	ownership_verify_code_payload "$management_code_root" || return 1
	ownership_verify_config_root "$management_config_root" || return 1
	management_code_id=$(cat "$management_code_root/installation.id")
	[ "$management_code_id" = "$(cat "$management_config_root/installation.id")" ] || return 1
	hooks_repairable_all "$management_code_root" || return 1
	management_runtime_is_owned || return 1
	for management_layout_parent in "$NUTMERLIN_JFFS_ROOT/addons" \
		"$NUTMERLIN_JFFS_ROOT/scripts" "$NUTMERLIN_OPT_ROOT/etc"; do
		ownership_layout_parent_is_safe "$management_layout_parent" || return 1
	done
	management_live_surfaces_are_owned
}

management_uninstall_locked() {
	management_code_root=$NUTMERLIN_JFFS_ROOT/addons/nutmerlin
	management_config_root=$NUTMERLIN_OPT_ROOT/etc/nutmerlin
	management_runtime_root=$NUTMERLIN_TMP_ROOT/nutmerlin
	management_uninstall_state_is_owned || {
		printf '%s\n' 'uninstall refused: installed ownership evidence is incomplete' >&2
		return 78
	}
	management_disable_locked || return $?
	hooks_remove_all "$management_code_root" || {
		printf '%s\n' 'uninstall refused: Merlin hook state is modified or ambiguous' >&2
		return 78
	}
	management_test_checkpoint hooks || return $?
	case $management_runtime_root in
		"$NUTMERLIN_TMP_ROOT"/nutmerlin) ;;
		*) return 78 ;;
	esac
	management_test_checkpoint runtime || return $?
	management_runtime_is_removable || return 78
	rm -rf -- "$management_runtime_root" || return 75
	management_test_checkpoint config || return $?
	ownership_verify_config_root "$management_config_root" || return 78
	rm -rf -- "$management_config_root" || return 75
	ownership_verify_code_payload "$management_code_root" || return 78
	hooks_repairable_all "$management_code_root" || return 78
	rm -rf -- "$management_code_root" || return 75
	MANAGEMENT_MESSAGE='NUTMerlin owned artifacts removed; Entware packages retained'
	export MANAGEMENT_MESSAGE
}

management_uninstall() {
	management_code_root=$NUTMERLIN_JFFS_ROOT/addons/nutmerlin
	management_config_root=$NUTMERLIN_OPT_ROOT/etc/nutmerlin
	if [ ! -e "$management_code_root" ] && [ ! -L "$management_code_root" ] &&
		[ ! -e "$management_config_root" ] && [ ! -L "$management_config_root" ]; then
		MANAGEMENT_MESSAGE='NUTMerlin is already uninstalled; no artifacts changed'
		export MANAGEMENT_MESSAGE
		return 0
	fi
	management_storage_state=$(platform_storage_state) || return $?
	if [ "$management_storage_state" != available ]; then
		case $management_storage_state in
			missing | read_only)
				management_disable || return $?
				printf 'uninstall unavailable: attributable /opt state is %s; NUTMerlin was disabled but residual data may remain at /opt/etc/nutmerlin\n' \
					"$management_storage_state" >&2
				return 69
				;;
			*)
				printf 'uninstall refused: /opt state is %s; ambiguous data was retained without mutation\n' \
					"$management_storage_state" >&2
				return 78
				;;
		esac
	fi
	management_uninstall_state_is_owned || {
		printf '%s\n' 'uninstall refused: no complete owned installation is present' >&2
		return 78
	}
	service_run_locked management_uninstall_locked
}
