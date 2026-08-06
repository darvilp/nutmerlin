#!/bin/sh

ownership_refuse() {
	printf 'NUTMerlin install refused: %s\n' "$1" >&2
	return 78
}

ownership_id_is_valid() {
	ownership_id=$1
	[ "${#ownership_id}" -eq 32 ] || return 1
	case $ownership_id in
		*[!0-9a-f]*) return 1 ;;
	esac
}

ownership_entry_count_is() {
	entry_count_root=$1
	expected_entry_count=$2
	[ "$(find "$entry_count_root" -mindepth 1 -maxdepth 1 | wc -l)" -eq "$expected_entry_count" ]
}

ownership_layout_parent_is_safe() {
	layout_parent=$1
	if [ -e "$layout_parent" ] || [ -L "$layout_parent" ]; then
		[ -d "$layout_parent" ] && [ ! -L "$layout_parent" ] || return 1
		[ "$(stat -c '%u' "$layout_parent")" = "$(id -u)" ] || return 1
	fi
}

ownership_verify_code_root() {
	verified_code_root=$1
	ownership_expected_uid=$(id -u)
	[ -d "$verified_code_root" ] && [ ! -L "$verified_code_root" ] || return 1
	[ "$(stat -c '%a' "$verified_code_root")" = 755 ] || return 1
	[ "$(stat -c '%u' "$verified_code_root")" = "$ownership_expected_uid" ] || return 1
	ownership_entry_count_is "$verified_code_root" 9 || return 1
	for owned_code_directory in bin lib share share/dummy; do
		[ -d "$verified_code_root/$owned_code_directory" ] &&
			[ ! -L "$verified_code_root/$owned_code_directory" ] || return 1
		[ "$(stat -c '%a' "$verified_code_root/$owned_code_directory")" = 755 ] || return 1
		[ "$(stat -c '%u' "$verified_code_root/$owned_code_directory")" = "$ownership_expected_uid" ] || return 1
	done
	ownership_entry_count_is "$verified_code_root/bin" 1 || return 1
	ownership_entry_count_is "$verified_code_root/lib" 11 || return 1
	ownership_entry_count_is "$verified_code_root/share" 1 || return 1
	ownership_entry_count_is "$verified_code_root/share/dummy" 1 || return 1
	for owned_code_file in VERSION bin/nutmerlin \
		lib/client.sh lib/configuration.sh lib/entware.sh lib/hooks.sh lib/lifecycle.sh lib/ownership.sh lib/paths.sh \
		lib/platform.sh lib/result.sh lib/service.sh lib/status.sh \
		share/dummy/cyberpower.dev installation.id enabled entware.tsv hooks.tsv owned-files; do
		[ -f "$verified_code_root/$owned_code_file" ] &&
			[ ! -L "$verified_code_root/$owned_code_file" ] || return 1
		[ "$(stat -c '%h' "$verified_code_root/$owned_code_file")" = 1 ] || return 1
		[ "$(stat -c '%u' "$verified_code_root/$owned_code_file")" = "$ownership_expected_uid" ] || return 1
	done
	[ "$(find "$verified_code_root" -type f | wc -l)" -eq 19 ] || return 1
	[ "$(stat -c '%a' "$verified_code_root/installation.id")" = 600 ] || return 1
	[ "$(stat -c '%a' "$verified_code_root/enabled")" = 600 ] || return 1
	[ "$(stat -c '%a' "$verified_code_root/entware.tsv")" = 600 ] || return 1
	[ "$(stat -c '%a' "$verified_code_root/hooks.tsv")" = 600 ] || return 1
	[ "$(stat -c '%a' "$verified_code_root/owned-files")" = 600 ] || return 1
	[ "$(stat -c '%a' "$verified_code_root/bin/nutmerlin")" = 755 ] || return 1
	[ "$(stat -c '%a' "$verified_code_root/VERSION")" = 644 ] || return 1
	[ "$(stat -c '%a' "$verified_code_root/share/dummy/cyberpower.dev")" = 644 ] || return 1
	for owned_library in "$verified_code_root"/lib/*.sh; do
		[ "$(stat -c '%a' "$owned_library")" = 644 ] || return 1
	done
	case $(cat "$verified_code_root/enabled") in
		0 | 1) ;;
		*) return 1 ;;
	esac
	manifest_inventory=$(awk '{ print $2 }' "$verified_code_root/owned-files")
	[ "$manifest_inventory" = 'VERSION
bin/nutmerlin
entware.tsv
hooks.tsv
lib/client.sh
lib/configuration.sh
lib/entware.sh
lib/hooks.sh
lib/lifecycle.sh
lib/ownership.sh
lib/paths.sh
lib/platform.sh
lib/result.sh
lib/service.sh
lib/status.sh
share/dummy/cyberpower.dev' ] || return 1
	(cd "$verified_code_root" && sha256sum -c owned-files >/dev/null 2>&1) || return 1
	hooks_verify_all "$verified_code_root" || return 1
}

ownership_verify_config_root() {
	verified_config_root=$1
	ownership_expected_uid=$(id -u)
	[ -d "$verified_config_root" ] && [ ! -L "$verified_config_root" ] || return 1
	[ "$(stat -c '%a' "$verified_config_root")" = 700 ] || return 1
	[ "$(stat -c '%u' "$verified_config_root")" = "$ownership_expected_uid" ] || return 1
	ownership_entry_count_is "$verified_config_root" 2 || return 1
	for owned_config_directory in config config/sets; do
		[ -d "$verified_config_root/$owned_config_directory" ] &&
			[ ! -L "$verified_config_root/$owned_config_directory" ] || return 1
		[ "$(stat -c '%a' "$verified_config_root/$owned_config_directory")" = 700 ] || return 1
		[ "$(stat -c '%u' "$verified_config_root/$owned_config_directory")" = "$ownership_expected_uid" ] || return 1
	done
	for owned_config_file in installation.id config/current; do
		[ -f "$verified_config_root/$owned_config_file" ] &&
			[ ! -L "$verified_config_root/$owned_config_file" ] || return 1
		[ "$(stat -c '%a' "$verified_config_root/$owned_config_file")" = 600 ] || return 1
		[ "$(stat -c '%h' "$verified_config_root/$owned_config_file")" = 1 ] || return 1
		[ "$(stat -c '%u' "$verified_config_root/$owned_config_file")" = "$ownership_expected_uid" ] || return 1
	done
	current_set_id=$(cat "$verified_config_root/config/current")
	ownership_id_is_valid "$current_set_id" || return 1
	configuration_validate_set "$verified_config_root/config/sets/$current_set_id" || return 1
	last_good_set_id=
	if [ -e "$verified_config_root/config/last-good" ]; then
		[ -f "$verified_config_root/config/last-good" ] &&
			[ ! -L "$verified_config_root/config/last-good" ] || return 1
		[ "$(stat -c '%a' "$verified_config_root/config/last-good")" = 600 ] || return 1
		[ "$(stat -c '%h' "$verified_config_root/config/last-good")" = 1 ] || return 1
		[ "$(stat -c '%u' "$verified_config_root/config/last-good")" = "$ownership_expected_uid" ] || return 1
		last_good_set_id=$(cat "$verified_config_root/config/last-good")
		ownership_id_is_valid "$last_good_set_id" || return 1
		[ "$last_good_set_id" != "$current_set_id" ] || return 1
		configuration_validate_set "$verified_config_root/config/sets/$last_good_set_id" || return 1
	fi
	config_entry_count=2
	set_entry_count=1
	if [ -n "$last_good_set_id" ]; then
		config_entry_count=3
		set_entry_count=2
	fi
	ownership_entry_count_is "$verified_config_root/config" "$config_entry_count" || return 1
	ownership_entry_count_is "$verified_config_root/config/sets" "$set_entry_count" || return 1
	for observed_set_root in "$verified_config_root/config/sets"/*; do
		[ -e "$observed_set_root" ] || continue
		observed_set_id=${observed_set_root##*/}
		case $observed_set_id in
			"$current_set_id" | "$last_good_set_id") ;;
			*) return 1 ;;
		esac
	done
}

ownership_verify_installed_state() {
	installed_code_root=$NUTMERLIN_JFFS_ROOT/addons/nutmerlin
	installed_config_root=$NUTMERLIN_OPT_ROOT/etc/nutmerlin
	ownership_verify_code_root "$installed_code_root" || return 78
	ownership_verify_config_root "$installed_config_root" || return 78
	installed_code_id=$(cat "$installed_code_root/installation.id")
	installed_config_id=$(cat "$installed_config_root/installation.id")
	ownership_id_is_valid "$installed_code_id" || return 78
	[ "$installed_code_id" = "$installed_config_id" ] || return 78
}

ownership_has_foreign_hook() {
	hook_root=$NUTMERLIN_JFFS_ROOT/scripts
	[ -d "$hook_root" ] || return 1
	for hook_path in "$hook_root"/*; do
		[ -e "$hook_path" ] || [ -L "$hook_path" ] || continue
		if [ -L "$hook_path" ] && [ ! -f "$hook_path" ]; then
			return 0
		fi
		if [ ! -f "$hook_path" ]; then
			continue
		fi
		if grep -E '(^|[^[:alnum:]_-])(upsd|upsdrvctl|dummy-ups|usbhid-ups|NUT_CONFPATH)([^[:alnum:]_-]|$)' \
			"$hook_path" >/dev/null 2>&1; then
			return 0
		fi
		if grep -F 'NUTMerlin managed block:' "$hook_path" >/dev/null 2>&1; then
			hook_basename=${hook_path##*/}
			case ${NUTMERLIN_OWNERSHIP_STATE:-absent}:$hook_basename in
				owned:services-start | owned:services-stop | owned:post-mount | \
					owned:unmount | owned:firewall-start) ;;
				*) return 0 ;;
			esac
		fi
	done
	return 1
}

ownership_check_live_foreign_state() {
	if [ "${NUTMERLIN_ENABLE_TEST_ADAPTERS:-0}" = 1 ]; then
		[ "${NUTMERLIN_TEST_FOREIGN_PROCESS:-0}" != 1 ] || ownership_refuse 'foreign NUT process is active'
		[ "${NUTMERLIN_TEST_FOREIGN_LISTENER:-0}" != 1 ] || ownership_refuse 'foreign TCP listener uses port 3493'
	fi

	# BusyBox ps is the portable Merlin process-list boundary.
	process_snapshot=$(platform_process_snapshot) || {
		ownership_refuse 'NUT process state cannot be verified'
		return $?
	}
	# shellcheck disable=SC2009
	nut_process_snapshot=$(printf '%s\n' "$process_snapshot" |
		grep -E '[ /](upsd|upsdrvctl|dummy-ups|usbhid-ups)([[:space:]]|$)' || :)
	if [ -n "$nut_process_snapshot" ]; then
		if [ "${NUTMERLIN_OWNERSHIP_STATE:-absent}" != owned ] ||
			! command -v service_pid_is_owned >/dev/null 2>&1; then
			ownership_refuse 'foreign NUT process is active'
			return $?
		fi
		owned_runtime_root=$NUTMERLIN_TMP_ROOT/nutmerlin
		owned_server_record=$owned_runtime_root/run/upsd.pid
		owned_dummy_record=$owned_runtime_root/run/dummy-ups.pid
		owned_usbhid_record=$owned_runtime_root/run/usbhid-ups.pid
		owned_driver_count=0
		if [ -e "$owned_dummy_record" ] || [ -L "$owned_dummy_record" ]; then
			owned_driver_record=$owned_dummy_record
			owned_driver_role=dummy
			owned_driver_count=$((owned_driver_count + 1))
		fi
		if [ -e "$owned_usbhid_record" ] || [ -L "$owned_usbhid_record" ]; then
			owned_driver_record=$owned_usbhid_record
			owned_driver_role=usbhid
			owned_driver_count=$((owned_driver_count + 1))
		fi
		[ "$owned_driver_count" -eq 1 ] || {
			ownership_refuse 'active NUT driver process identity is ambiguous'
			return $?
		}
		service_pid_is_owned "$owned_server_record" upsd || {
			ownership_refuse 'active upsd process identity is ambiguous'
			return $?
		}
		service_pid_record_read "$owned_server_record" || return 78
		# service_pid_record_read exports the parsed record fields.
		# shellcheck disable=SC2154
		owned_server_pid=$recorded_pid
		service_pid_is_owned "$owned_driver_record" "$owned_driver_role" || {
			ownership_refuse 'active NUT driver process identity is ambiguous'
			return $?
		}
		service_pid_record_read "$owned_driver_record" || return 78
		# shellcheck disable=SC2154
		owned_driver_pid=$recorded_pid
		printf '%s\n' "$nut_process_snapshot" | awk \
			-v server_pid="$owned_server_pid" -v driver_pid="$owned_driver_pid" '
			{
				owned = 0
				for (field = 1; field <= NF; field++) {
					if ($field == server_pid) { owned = 1; saw_server = 1 }
					if ($field == driver_pid) { owned = 1; saw_driver = 1 }
				}
				if (!owned) exit 1
			}
			END { if (!saw_server || !saw_driver) exit 1 }
		' || {
			ownership_refuse 'an additional foreign NUT process is active'
			return $?
		}
		if ! service_resolve_current >/dev/null 2>&1 ||
			! service_load_active_profile >/dev/null 2>&1; then
			ownership_refuse 'active NUT network profile cannot be verified'
			return $?
		fi
		service_network_is_expected || {
			ownership_refuse 'owned NUT listener state cannot be verified'
			return $?
		}
		return 0
	fi
	if [ "${NUTMERLIN_OWNERSHIP_STATE:-absent}" = owned ]; then
		for stale_record in "$NUTMERLIN_TMP_ROOT/nutmerlin/run/upsd.pid" \
			"$NUTMERLIN_TMP_ROOT/nutmerlin/run/dummy-ups.pid" \
			"$NUTMERLIN_TMP_ROOT/nutmerlin/run/usbhid-ups.pid"; do
			if [ -e "$stale_record" ] || [ -L "$stale_record" ]; then
				ownership_refuse 'stale or unsafe owned process state is present'
				return $?
			fi
		done
	fi
	if [ "${NUTMERLIN_ENABLE_TEST_ADAPTERS:-0}" = 1 ]; then
		return 0
	fi
	listener_snapshot=$(platform_listener_snapshot) || {
		ownership_refuse 'TCP listener state cannot be verified'
		return $?
	}
	if printf '%s\n' "$listener_snapshot" | awk 'NR > 1 { print $4 }' | grep -Eq '(^|:)3493$'; then
		ownership_refuse 'foreign TCP listener uses port 3493'
		return $?
	fi
}

ownership_check_before_install() {
	owned_code_root=$NUTMERLIN_JFFS_ROOT/addons/nutmerlin
	owned_config_root=$NUTMERLIN_OPT_ROOT/etc/nutmerlin
	ambient_nut_root=$NUTMERLIN_OPT_ROOT/etc/nut
	owned_runtime_root=$NUTMERLIN_TMP_ROOT/nutmerlin
	for layout_parent in "$NUTMERLIN_JFFS_ROOT/addons" "$NUTMERLIN_JFFS_ROOT/scripts" \
		"$NUTMERLIN_OPT_ROOT/etc"; do
		ownership_layout_parent_is_safe "$layout_parent" || {
			ownership_refuse "layout parent is foreign or ambiguous: $layout_parent"
			return $?
		}
	done

	NUTMERLIN_OWNERSHIP_STATE=absent
	if [ -e "$owned_code_root" ] || [ -e "$owned_config_root" ]; then
		if [ ! -e "$owned_code_root" ] || [ ! -e "$owned_config_root" ] ||
			! ownership_verify_code_root "$owned_code_root" ||
			! ownership_verify_config_root "$owned_config_root"; then
			ownership_refuse 'existing NUTMerlin ownership evidence is incomplete or unverified'
			return $?
		fi
		code_installation_id=$(cat "$owned_code_root/installation.id")
		config_installation_id=$(cat "$owned_config_root/installation.id")
		if ! ownership_id_is_valid "$code_installation_id" ||
			[ "$code_installation_id" != "$config_installation_id" ]; then
			ownership_refuse 'NUTMerlin installation identities are invalid or mismatched'
			return $?
		fi
		NUTMERLIN_OWNERSHIP_STATE=owned
	fi
	if [ "$NUTMERLIN_OWNERSHIP_STATE" = absent ] &&
		{ [ -e "$owned_runtime_root" ] || [ -L "$owned_runtime_root" ]; }; then
		ownership_refuse 'foreign or stale NUTMerlin runtime state is present'
		return $?
	fi
	if [ -e "$ambient_nut_root" ] || [ -L "$ambient_nut_root" ]; then
		if [ -L "$ambient_nut_root" ] || [ ! -d "$ambient_nut_root" ] ||
			[ -n "$(find "$ambient_nut_root" -mindepth 1 -maxdepth 1 -print -quit)" ]; then
			ownership_refuse "foreign NUT configuration: $ambient_nut_root"
			return $?
		fi
	fi
	if ownership_has_foreign_hook; then
		ownership_refuse 'foreign Merlin hook references NUT'
		return $?
	fi
	ownership_check_live_foreign_state
	export NUTMERLIN_OWNERSHIP_STATE
}
