#!/bin/sh

# Local archive validation and activation are implemented through this module.

update_expected_archive_inventory() {
	printf '%s\n' 'LICENSE
MANIFEST.sha256
README.md
VERSION
bin/
bin/nutmerlin
install.sh
lib/
lib/nutmerlin/
lib/nutmerlin/client.sh
lib/nutmerlin/configuration.sh
lib/nutmerlin/entware.sh
lib/nutmerlin/hooks.sh
lib/nutmerlin/lifecycle.sh
lib/nutmerlin/management.sh
lib/nutmerlin/ownership.sh
lib/nutmerlin/paths.sh
lib/nutmerlin/platform.sh
lib/nutmerlin/result.sh
lib/nutmerlin/service.sh
lib/nutmerlin/status.sh
lib/nutmerlin/update.sh
share/
share/dummy/
share/dummy/cyberpower.dev'
}

update_expected_archive_metadata() {
	printf '%s\n' '-rw-r--r-- LICENSE
-rw-r--r-- MANIFEST.sha256
-rw-r--r-- README.md
-rw-r--r-- VERSION
drwxr-xr-x bin/
-rwxr-xr-x bin/nutmerlin
-rwxr-xr-x install.sh
drwxr-xr-x lib/
drwxr-xr-x lib/nutmerlin/
-rw-r--r-- lib/nutmerlin/client.sh
-rw-r--r-- lib/nutmerlin/configuration.sh
-rw-r--r-- lib/nutmerlin/entware.sh
-rw-r--r-- lib/nutmerlin/hooks.sh
-rw-r--r-- lib/nutmerlin/lifecycle.sh
-rw-r--r-- lib/nutmerlin/management.sh
-rw-r--r-- lib/nutmerlin/ownership.sh
-rw-r--r-- lib/nutmerlin/paths.sh
-rw-r--r-- lib/nutmerlin/platform.sh
-rw-r--r-- lib/nutmerlin/result.sh
-rw-r--r-- lib/nutmerlin/service.sh
-rw-r--r-- lib/nutmerlin/status.sh
-rw-r--r-- lib/nutmerlin/update.sh
drwxr-xr-x share/
drwxr-xr-x share/dummy/
-rw-r--r-- share/dummy/cyberpower.dev'
}

update_expected_manifest_inventory() {
	printf '%s\n' 'LICENSE
README.md
VERSION
bin/nutmerlin
install.sh
lib/nutmerlin/client.sh
lib/nutmerlin/configuration.sh
lib/nutmerlin/entware.sh
lib/nutmerlin/hooks.sh
lib/nutmerlin/lifecycle.sh
lib/nutmerlin/management.sh
lib/nutmerlin/ownership.sh
lib/nutmerlin/paths.sh
lib/nutmerlin/platform.sh
lib/nutmerlin/result.sh
lib/nutmerlin/service.sh
lib/nutmerlin/status.sh
lib/nutmerlin/update.sh
share/dummy/cyberpower.dev'
}

update_validate_archive_sidecar() {
	update_requested_archive=$1
	case $update_requested_archive in
		'' | *[!A-Za-z0-9_./-]* | *://*)
			printf '%s\n' 'update refused: archive must be a local path using safe characters' >&2
			return 78
			;;
	esac
	[ "${#update_requested_archive}" -le 512 ] || return 78
	if [ ! -f "$update_requested_archive" ] || [ -L "$update_requested_archive" ] ||
		[ "$(stat -c '%h' "$update_requested_archive" 2>/dev/null || :)" != 1 ]; then
		printf '%s\n' 'update refused: local archive is missing or unsafe' >&2
		return 78
	fi
	update_requested_sidecar=$update_requested_archive.sha256
	if [ ! -f "$update_requested_sidecar" ] || [ -L "$update_requested_sidecar" ] ||
		[ "$(stat -c '%h' "$update_requested_sidecar" 2>/dev/null || :)" != 1 ]; then
		printf '%s\n' 'update refused: adjacent SHA-256 sidecar is missing or unsafe' >&2
		return 78
	fi
	[ "$(wc -l <"$update_requested_sidecar")" -eq 1 ] || {
		printf '%s\n' 'update refused: adjacent SHA-256 sidecar is malformed' >&2
		return 78
	}
	update_archive_basename=${update_requested_archive##*/}
	update_expected_digest=$(awk -v archive_name="$update_archive_basename" '
		NF == 2 && $2 == archive_name && length($1) == 64 && $1 !~ /[^0-9a-f]/ {
			print $1
			matched++
		}
		END { if (matched != 1) exit 1 }
	' "$update_requested_sidecar") || {
		printf '%s\n' 'update refused: adjacent SHA-256 sidecar is malformed' >&2
		return 78
	}
	[ "$(cat "$update_requested_sidecar")" = \
		"$update_expected_digest  $update_archive_basename" ] || {
		printf '%s\n' 'update refused: adjacent SHA-256 sidecar is malformed' >&2
		return 78
	}
	update_observed_digest=$(sha256sum "$update_requested_archive" | awk '{ print $1 }') || return 75
	[ "$update_observed_digest" = "$update_expected_digest" ] || {
		printf '%s\n' 'update refused: archive SHA-256 does not match its sidecar' >&2
		return 78
	}
	update_archive_inventory=$(tar -tzf "$update_requested_archive" 2>/dev/null) || {
		printf '%s\n' 'update refused: archive cannot be read as a core package' >&2
		return 78
	}
	[ "$update_archive_inventory" = "$(update_expected_archive_inventory)" ] || {
		printf '%s\n' 'update refused: archive inventory is not the fixed core inventory' >&2
		return 78
	}
	update_archive_verbose=$(tar -tvzf "$update_requested_archive" 2>/dev/null) || {
		printf '%s\n' 'update refused: archive metadata cannot be inspected' >&2
		return 78
	}
	update_archive_metadata=$(printf '%s\n' "$update_archive_verbose" |
		awk '{ print $1, $NF }') || return 78
	[ "$update_archive_metadata" = "$(update_expected_archive_metadata)" ] || {
		printf '%s\n' 'update refused: archive types or modes are unsafe' >&2
		return 78
	}
	UPDATE_ARCHIVE_PAYLOAD_KB=$(printf '%s\n' "$update_archive_verbose" | awk '
		$3 !~ /^[0-9]+$/ { exit 1 }
		{ total += int(($3 + 1023) / 1024) }
		END { if (total < 1) exit 1; printf "%.0f\n", total }
	') || {
		printf '%s\n' 'update refused: archive size metadata is invalid' >&2
		return 78
	}
	case $UPDATE_ARCHIVE_PAYLOAD_KB in
		'' | *[!0-9]* | ??????????*)
			printf '%s\n' 'update refused: archive payload is too large' >&2
			return 78
			;;
	esac
	UPDATE_ARCHIVE=$update_requested_archive
	UPDATE_ARCHIVE_DIGEST=$update_observed_digest
	export UPDATE_ARCHIVE UPDATE_ARCHIVE_DIGEST UPDATE_ARCHIVE_PAYLOAD_KB
}

update_validate_jffs_capacity() {
	update_required_jffs_kb=$((UPDATE_ARCHIVE_PAYLOAD_KB + 1024))
	if [ "${NUTMERLIN_ENABLE_TEST_ADAPTERS:-0}" = 1 ] &&
		[ -n "${NUTMERLIN_TEST_JFFS_AVAILABLE_KB:-}" ]; then
		update_available_jffs_kb=$NUTMERLIN_TEST_JFFS_AVAILABLE_KB
	else
		update_available_jffs_kb=$(df -Pk "$NUTMERLIN_JFFS_ROOT/addons" 2>/dev/null |
			awk 'NR == 2 { print $4 }')
	fi
	case $update_available_jffs_kb in
		'' | *[!0-9]*)
			printf '%s\n' 'update unavailable: JFFS free space could not be read' >&2
			return 69
			;;
	esac
	[ "$update_available_jffs_kb" -ge "$update_required_jffs_kb" ] || {
		printf 'update unavailable: JFFS does not have enough free space; need %s KiB\n' \
			"$update_required_jffs_kb" >&2
		return 69
	}
}

update_preflight_installed_state() {
	if [ "${NUTMERLIN_ENABLE_TEST_ADAPTERS:-0}" != 1 ] &&
		[ "${NUTMERLIN_ALLOW_PRODUCTION_ROUTER:-0}" != 1 ]; then
		printf '%s\n' 'update refused: set NUTMERLIN_ALLOW_PRODUCTION_ROUTER=1 for router modification' >&2
		return 78
	fi
	update_storage_state=$(platform_storage_state) || return $?
	[ "$update_storage_state" = available ] || {
		printf 'update unavailable: storage=%s\n' "$update_storage_state" >&2
		return 69
	}
	ownership_verify_installed_state || {
		printf '%s\n' 'update refused: installed ownership evidence is incomplete' >&2
		return 78
	}
	management_live_surfaces_are_owned || return $?
	entware_check || return $?
	service_resolve_current || return $?
	service_load_active_profile || return $?
	service_load_active_driver_binary || return $?
	service_validate_active_source || return $?
	service_validate_active_network || return $?
	update_addons_root=$NUTMERLIN_JFFS_ROOT/addons
	ownership_layout_parent_is_safe "$update_addons_root" || return 78
	update_validate_jffs_capacity || return $?
	if [ -n "$(find "$update_addons_root" -mindepth 1 -maxdepth 1 \
		\( -name '.nutmerlin-update-*' -o -name '.nutmerlin-backup-*' \) \
		-print -quit)" ]; then
		printf '%s\n' 'update refused: stale or ambiguous update workspace is present' >&2
		return 78
	fi
}

update_cleanup_stage() {
	[ -n "${UPDATE_STAGE:-}" ] || return 0
	case $UPDATE_STAGE in
		"$NUTMERLIN_JFFS_ROOT"/addons/.nutmerlin-update-*)
			[ ! -e "$UPDATE_STAGE" ] || rm -rf -- "$UPDATE_STAGE"
			;;
		*) return 78 ;;
	esac
	UPDATE_STAGE=
	export UPDATE_STAGE
}

update_verify_extracted_file() {
	update_extracted_path=$1
	update_extracted_mode=$2
	[ -f "$UPDATE_STAGE/$update_extracted_path" ] &&
		[ ! -L "$UPDATE_STAGE/$update_extracted_path" ] || return 1
	[ "$(stat -c '%a' "$UPDATE_STAGE/$update_extracted_path")" = \
		"$update_extracted_mode" ] || return 1
	[ "$(stat -c '%h' "$UPDATE_STAGE/$update_extracted_path")" = 1 ] || return 1
	[ "$(stat -c '%u' "$UPDATE_STAGE/$update_extracted_path")" = "$(id -u)" ]
}

update_verify_extracted_archive() {
	[ -d "$UPDATE_STAGE" ] && [ ! -L "$UPDATE_STAGE" ] || return 1
	[ "$(stat -c '%a' "$UPDATE_STAGE")" = 700 ] || return 1
	[ "$(stat -c '%u' "$UPDATE_STAGE")" = "$(id -u)" ] || return 1
	for update_extracted_directory in bin lib lib/nutmerlin share share/dummy; do
		[ -d "$UPDATE_STAGE/$update_extracted_directory" ] &&
			[ ! -L "$UPDATE_STAGE/$update_extracted_directory" ] || return 1
		[ "$(stat -c '%a' "$UPDATE_STAGE/$update_extracted_directory")" = 755 ] || return 1
		[ "$(stat -c '%u' "$UPDATE_STAGE/$update_extracted_directory")" = "$(id -u)" ] || return 1
	done
	for update_extracted_file in LICENSE MANIFEST.sha256 README.md VERSION \
		lib/nutmerlin/client.sh lib/nutmerlin/configuration.sh \
		lib/nutmerlin/entware.sh lib/nutmerlin/hooks.sh \
		lib/nutmerlin/lifecycle.sh lib/nutmerlin/management.sh \
		lib/nutmerlin/ownership.sh lib/nutmerlin/paths.sh \
		lib/nutmerlin/platform.sh lib/nutmerlin/result.sh \
		lib/nutmerlin/service.sh lib/nutmerlin/status.sh \
		lib/nutmerlin/update.sh share/dummy/cyberpower.dev; do
		update_verify_extracted_file "$update_extracted_file" 644 || return 1
	done
	update_verify_extracted_file bin/nutmerlin 755 || return 1
	update_verify_extracted_file install.sh 755 || return 1
	[ "$(find "$UPDATE_STAGE" -mindepth 1 -type f | wc -l)" -eq 20 ] || return 1
	[ "$(find "$UPDATE_STAGE" -mindepth 1 -type d | wc -l)" -eq 5 ] || return 1
	[ -z "$(find "$UPDATE_STAGE" -mindepth 1 ! -type f ! -type d -print -quit)" ] || return 1
	update_manifest_inventory=$(awk '{ print $2 }' "$UPDATE_STAGE/MANIFEST.sha256") || return 1
	[ "$update_manifest_inventory" = "$(update_expected_manifest_inventory)" ] || return 1
	(
		cd "$UPDATE_STAGE"
		sha256sum -c MANIFEST.sha256 >/dev/null 2>&1
	) || return 1
	[ "$(wc -l <"$UPDATE_STAGE/VERSION")" -eq 1 ] || return 1
	update_candidate_version=$(cat "$UPDATE_STAGE/VERSION")
	[ "${#update_candidate_version}" -le 64 ] || return 1
	printf '%s\n' "$update_candidate_version" |
		grep -Eq '^[0-9]+[.][0-9]+[.][0-9]+(-[A-Za-z0-9.]+)?$' || return 1
	UPDATE_VERSION=$update_candidate_version
	export UPDATE_VERSION
}

update_stage_archive() {
	update_stage_id=$(configuration_random_id) || return 75
	UPDATE_STAGE=$NUTMERLIN_JFFS_ROOT/addons/.nutmerlin-update-$update_stage_id
	export UPDATE_STAGE
	[ ! -e "$UPDATE_STAGE" ] && [ ! -L "$UPDATE_STAGE" ] || return 78
	mkdir -m 700 "$UPDATE_STAGE" || return 75
	if ! (umask 077 && tar -xzf "$UPDATE_ARCHIVE" -C "$UPDATE_STAGE"); then
		update_cleanup_stage || :
		printf '%s\n' 'update refused: core archive extraction failed' >&2
		return 78
	fi
	chmod 700 "$UPDATE_STAGE" || {
		update_cleanup_stage || :
		return 75
	}
	chmod 755 "$UPDATE_STAGE/bin" "$UPDATE_STAGE/lib" \
		"$UPDATE_STAGE/lib/nutmerlin" "$UPDATE_STAGE/share" \
		"$UPDATE_STAGE/share/dummy" "$UPDATE_STAGE/bin/nutmerlin" \
		"$UPDATE_STAGE/install.sh" || {
		update_cleanup_stage || :
		return 75
	}
	chmod 644 "$UPDATE_STAGE/LICENSE" "$UPDATE_STAGE/MANIFEST.sha256" \
		"$UPDATE_STAGE/README.md" "$UPDATE_STAGE/VERSION" \
		"$UPDATE_STAGE/lib/nutmerlin/"*.sh \
		"$UPDATE_STAGE/share/dummy/cyberpower.dev" || {
		update_cleanup_stage || :
		return 75
	}
	update_verify_extracted_archive || {
		update_cleanup_stage || :
		printf '%s\n' 'update refused: extracted core manifest verification failed' >&2
		return 78
	}
}

update_prepare_code_candidate() {
	update_current_code=$NUTMERLIN_JFFS_ROOT/addons/nutmerlin
	for update_packaged_library in "$UPDATE_STAGE/lib/nutmerlin/"*.sh; do
		[ -f "$update_packaged_library" ] && [ ! -L "$update_packaged_library" ] || return 78
		mv "$update_packaged_library" "$UPDATE_STAGE/lib/" || return 75
	done
	rmdir "$UPDATE_STAGE/lib/nutmerlin" || return 78
	for update_package_only_file in LICENSE MANIFEST.sha256 README.md install.sh; do
		update_package_only_mode=644
		[ "$update_package_only_file" != install.sh ] || update_package_only_mode=755
		update_verify_extracted_file "$update_package_only_file" \
			"$update_package_only_mode" || return 78
		rm -f -- "$UPDATE_STAGE/$update_package_only_file" || return 75
	done
	for update_preserved_file in installation.id enabled entware.tsv hooks.tsv; do
		[ -f "$update_current_code/$update_preserved_file" ] &&
			[ ! -L "$update_current_code/$update_preserved_file" ] || return 78
		cp "$update_current_code/$update_preserved_file" \
			"$UPDATE_STAGE/$update_preserved_file" || return 75
		chmod 600 "$UPDATE_STAGE/$update_preserved_file" || return 75
	done
	(
		cd "$UPDATE_STAGE"
		sha256sum VERSION bin/nutmerlin entware.tsv hooks.tsv lib/*.sh \
			share/dummy/cyberpower.dev >owned-files
	) || return 75
	chmod 600 "$UPDATE_STAGE/owned-files" || return 75
	chmod 755 "$UPDATE_STAGE" "$UPDATE_STAGE/bin" "$UPDATE_STAGE/lib" \
		"$UPDATE_STAGE/share" "$UPDATE_STAGE/share/dummy" || return 75
	ownership_verify_code_payload "$UPDATE_STAGE" || {
		printf '%s\n' 'update refused: staged code ownership verification failed' >&2
		return 78
	}
}

update_test_checkpoint() {
	update_checkpoint=$1
	if [ "${NUTMERLIN_ENABLE_TEST_ADAPTERS:-0}" = 1 ] &&
		[ "${NUTMERLIN_TEST_UPDATE_FAIL_AFTER:-}" = "$update_checkpoint" ]; then
		printf 'update temporary failure after %s\n' "$update_checkpoint" >&2
		return 75
	fi
}

update_test_signal_checkpoint() {
	update_signal_checkpoint=$1
	if [ "${NUTMERLIN_ENABLE_TEST_ADAPTERS:-0}" = 1 ] &&
		[ "${NUTMERLIN_TEST_UPDATE_SIGNAL_AFTER:-}" = "$update_signal_checkpoint" ]; then
		kill -TERM "$$"
	fi
}

update_test_recovery_cleanup() {
	if [ "${NUTMERLIN_ENABLE_TEST_ADAPTERS:-0}" = 1 ] &&
		[ "${NUTMERLIN_TEST_UPDATE_RECOVERY_CLEANUP_FAIL:-0}" = 1 ]; then
		printf '%s\n' 'update recovery cleanup test failure' >&2
		return 75
	fi
}

update_remove_verified_code_root() {
	update_remove_root=$1
	case $update_remove_root in
		"$NUTMERLIN_JFFS_ROOT"/addons/.nutmerlin-update-* | \
			"$NUTMERLIN_JFFS_ROOT"/addons/.nutmerlin-backup-*) ;;
		*) return 78 ;;
	esac
	if [ ! -e "$update_remove_root" ] && [ ! -L "$update_remove_root" ]; then
		return 0
	fi
	ownership_verify_code_payload "$update_remove_root" || return 78
	rm -rf -- "$update_remove_root"
}

update_restore_backup() {
	update_restore_status=0
	platform_firewall_remove_owned || update_restore_status=$?
	service_stop || update_restore_status=$?
	platform_cru_remove || update_restore_status=$?
	update_test_recovery_cleanup || update_restore_status=$?
	update_candidate_moved=0
	if ownership_verify_code_payload "$update_code_root" &&
		[ ! -e "$update_failed_root" ] && [ ! -L "$update_failed_root" ]; then
		if mv "$update_code_root" "$update_failed_root"; then
			update_candidate_moved=1
		else
			update_restore_status=75
		fi
	else
		update_restore_status=78
	fi
	update_backup_restored=0
	if [ "$update_candidate_moved" -eq 1 ] &&
		ownership_verify_code_payload "$update_backup_root"; then
		if mv "$update_backup_root" "$update_code_root"; then
			update_backup_restored=1
		else
			update_restore_status=75
		fi
	else
		update_restore_status=78
	fi
	if [ "$update_backup_restored" -eq 1 ]; then
		management_write_enabled 0 || update_restore_status=$?
		ownership_verify_installed_state || update_restore_status=78
	fi
	if [ "$update_backup_restored" -eq 1 ] && [ "$update_restore_status" -eq 0 ]; then
		management_write_enabled "$update_previous_enabled" || update_restore_status=$?
		if [ "$update_restore_status" -eq 0 ] && [ "$update_previous_enabled" -eq 1 ]; then
			platform_cru_ensure || update_restore_status=$?
			service_start || update_restore_status=$?
		fi
	fi
	if [ "$update_candidate_moved" -eq 1 ]; then
		update_remove_verified_code_root "$update_failed_root" || update_restore_status=$?
	fi
	if [ "$update_restore_status" -ne 0 ]; then
		if [ -d "$update_code_root" ] && [ ! -L "$update_code_root" ]; then
			management_write_enabled 0 || :
		fi
		platform_cru_remove || :
		platform_firewall_remove_owned || :
		service_stop || :
		if [ "$update_backup_restored" -eq 1 ]; then
			printf '%s\n' \
				'update recovery incomplete; the previous code was restored disabled and requires repair' >&2
		else
			printf '%s\n' 'update recovery failed; manual recovery is required' >&2
		fi
		return 75
	fi
	printf '%s\n' 'update activation failed; the previous code was restored' >&2
	return 75
}

update_resume_previous_state() {
	management_write_enabled "$update_previous_enabled" || return $?
	if [ "$update_previous_enabled" -eq 1 ]; then
		platform_cru_ensure || return $?
		service_start || return $?
	fi
}

update_candidate_runtime_smoke() {
	update_smoke_code_root=$1
	update_smoke_enabled=$2
	"$update_smoke_code_root/bin/nutmerlin" source show >/dev/null || return $?
	UPDATE_SERVICE_MESSAGE=$(
		(
			for update_smoke_library in paths entware configuration hooks platform \
				ownership service lifecycle; do
				# shellcheck disable=SC1090
				. "$update_smoke_code_root/lib/$update_smoke_library.sh"
			done
			paths_initialize
			ownership_verify_installed_state || exit $?
			entware_check || exit $?
			service_resolve_current || exit $?
			service_load_active_profile || exit $?
			service_load_active_driver_binary || exit $?
			service_validate_active_source || exit $?
			service_validate_active_network || exit $?
			if [ "$update_smoke_enabled" -eq 1 ]; then
				lifecycle_user_start >/dev/null || exit $?
				printf '%s\n' "$SERVICE_MESSAGE"
			else
				printf '%s\n' 'service remains disabled'
			fi
		)
	) || return $?
	export UPDATE_SERVICE_MESSAGE
}

update_recover_interrupted() {
	case ${UPDATE_PHASE:-complete} in
		staging)
			update_cleanup_stage || :
			;;
		closing | backup | active)
			if [ -n "${update_backup_root:-}" ] &&
				{ [ -e "$update_backup_root" ] || [ -L "$update_backup_root" ]; }; then
				if [ -e "${update_code_root:-}" ] || [ -L "${update_code_root:-}" ]; then
					update_restore_backup || :
				elif ownership_verify_code_payload "$update_backup_root" &&
					mv "$update_backup_root" "$update_code_root"; then
					update_cleanup_stage || :
					management_write_enabled "$update_previous_enabled" || :
					if [ "$update_previous_enabled" -eq 1 ]; then
						platform_cru_ensure || :
						service_start || :
					fi
				fi
			else
				update_cleanup_stage || :
				update_resume_previous_state || :
			fi
			;;
		committed | complete) ;;
	esac
}

update_signal_traps_install() {
	trap 'exit 129' HUP
	trap 'exit 130' INT
	trap 'exit 143' TERM
}

update_exit_cleanup() {
	update_exit_status=$1
	trap - EXIT HUP INT TERM
	update_recover_interrupted
	service_lock_release
	exit "$update_exit_status"
}

update_activate_candidate() {
	update_code_root=$NUTMERLIN_JFFS_ROOT/addons/nutmerlin
	update_installation_id=$(cat "$update_code_root/installation.id")
	update_previous_enabled=$(cat "$update_code_root/enabled")
	case $update_previous_enabled in
		0 | 1) ;;
		*) return 78 ;;
	esac
	update_backup_root=$NUTMERLIN_JFFS_ROOT/addons/.nutmerlin-backup-$update_installation_id
	update_failed_root=$UPDATE_STAGE
	[ ! -e "$update_backup_root" ] && [ ! -L "$update_backup_root" ] || return 78
	UPDATE_PHASE=closing
	export UPDATE_PHASE
	management_disable_locked || return $?
	update_test_signal_checkpoint closing
	UPDATE_PHASE=backup
	export UPDATE_PHASE
	if ! mv "$update_code_root" "$update_backup_root"; then
		update_resume_previous_state || :
		UPDATE_PHASE=complete
		export UPDATE_PHASE
		return 75
	fi
	update_test_signal_checkpoint backup
	if ! mv "$UPDATE_STAGE" "$update_code_root"; then
		if mv "$update_backup_root" "$update_code_root"; then
			update_resume_previous_state || :
		fi
		UPDATE_PHASE=complete
		export UPDATE_PHASE
		return 75
	fi
	UPDATE_STAGE=
	export UPDATE_STAGE
	UPDATE_PHASE=active
	export UPDATE_PHASE
	update_test_signal_checkpoint activation
	update_activation_status=0
	update_test_checkpoint activation || update_activation_status=$?
	if [ "$update_activation_status" -eq 0 ]; then
		ownership_verify_installed_state || update_activation_status=78
	fi
	if [ "$update_activation_status" -eq 0 ]; then
		update_candidate_runtime_smoke "$update_code_root" "$update_previous_enabled" ||
			update_activation_status=$?
	fi
	update_test_checkpoint smoke || update_activation_status=$?
	if [ "$update_activation_status" -ne 0 ]; then
		if update_restore_backup; then
			update_restore_result=0
		else
			update_restore_result=$?
		fi
		UPDATE_PHASE=complete
		export UPDATE_PHASE
		return "$update_restore_result"
	fi
	UPDATE_PHASE=committed
	export UPDATE_PHASE
	trap '' HUP INT TERM
	update_remove_verified_code_root "$update_backup_root" || return $?
	update_signal_traps_install
	UPDATE_PHASE=complete
	export UPDATE_PHASE
	if [ "$update_previous_enabled" -eq 0 ]; then
		UPDATE_MESSAGE="NUTMerlin updated to $UPDATE_VERSION; service remains disabled"
	else
		UPDATE_MESSAGE="NUTMerlin updated to $UPDATE_VERSION; $UPDATE_SERVICE_MESSAGE"
	fi
	export UPDATE_MESSAGE
}

update_run_locked() {
	update_preflight_installed_state || return $?
	update_stage_archive || return $?
	if update_prepare_code_candidate; then
		:
	else
		update_prepare_status=$?
		update_cleanup_stage || :
		return "$update_prepare_status"
	fi
	if update_activate_candidate; then
		return 0
	else
		update_activation_result=$?
		update_cleanup_stage || :
		return "$update_activation_result"
	fi
}

update_run() {
	update_validate_archive_sidecar "$1" || return $?
	update_preflight_installed_state || return $?
	service_lock_acquire || return $?
	UPDATE_PHASE=staging
	export UPDATE_PHASE
	trap 'update_exit_cleanup $?' EXIT
	update_signal_traps_install
	if update_run_locked; then
		update_run_status=0
	else
		update_run_status=$?
		update_recover_interrupted
	fi
	UPDATE_PHASE=complete
	export UPDATE_PHASE
	service_lock_release
	trap - EXIT HUP INT TERM
	return "$update_run_status"
}
