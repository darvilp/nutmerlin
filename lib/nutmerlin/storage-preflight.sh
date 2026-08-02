#!/bin/sh

storage_token() {
	storage_value=${1:-}
	if [ -z "$storage_value" ] || [ "${#storage_value}" -gt 96 ]; then
		printf '%s' unknown
		return
	fi
	case $storage_value in
		*[!A-Za-z0-9._+-]*) printf '%s' unknown ;;
		*) printf '%s' "$storage_value" ;;
	esac
}

storage_evidence() {
	case ${1:-unknown} in
		available | missing | unknown | incompatible) printf '%s' "${1:-unknown}" ;;
		*) printf '%s' unknown ;;
	esac
}

storage_path() {
	case ${1:-} in '' | *[!A-Za-z0-9._/+:-]* | *..*) printf '%s' unknown ;; *) printf '%s' "$1" ;; esac
}

storage_option_list() {
	case ${1:-} in
		'' | *[!A-Za-z0-9._,+-=]*) printf '%s' unknown ;;
		*)
			if [ "${#1}" -le 256 ]; then printf '%s' "$1"; else printf '%s' unknown; fi
			;;
	esac
}

storage_read_unknown() {
	storage_present=unknown storage_filesystem=unknown storage_journaling=unknown storage_mount_state=unknown storage_mount_options=unknown
	storage_observed_mount_options=unknown
	storage_mount_source=unknown storage_mount_target=unknown storage_health_evidence=unknown
	storage_identity=unknown storage_expected_identity=unknown storage_exact_profile=unknown
	storage_available_bytes=unknown storage_transaction_bytes=unknown storage_temporary_bytes=unknown
	storage_ownership_modes=unknown storage_case_sensitivity=unknown storage_link_semantics=unknown
	storage_atomic_rename=unknown storage_file_fsync=unknown storage_directory_fsync=unknown
	storage_exclusive_locking=unknown storage_executables=unknown storage_stable_identity=unknown
	storage_interruption_recovery=unknown
}

storage_read_mock() {
	storage_present=$(storage_evidence "${NUTMERLIN_STORAGE_PRESENT:-}")
	storage_filesystem=$(storage_token "${NUTMERLIN_STORAGE_FILESYSTEM:-}")
	storage_journaling=$(storage_evidence "${NUTMERLIN_STORAGE_JOURNALING:-}")
	storage_mount_state=$(storage_token "${NUTMERLIN_STORAGE_MOUNT_STATE:-}")
	storage_mount_options=$(storage_token "${NUTMERLIN_STORAGE_MOUNT_OPTIONS:-}")
	storage_observed_mount_options=$(storage_option_list "${NUTMERLIN_STORAGE_OBSERVED_MOUNT_OPTIONS:-}")
	storage_mount_source=$(storage_path "${NUTMERLIN_STORAGE_MOUNT_SOURCE:-}")
	storage_mount_target=$(storage_path "${NUTMERLIN_STORAGE_MOUNT_TARGET:-}")
	storage_health_evidence=$(storage_token "${NUTMERLIN_STORAGE_HEALTH_EVIDENCE:-}")
	storage_identity=$(storage_token "${NUTMERLIN_STORAGE_IDENTITY:-}")
	storage_expected_identity=$(storage_token "${NUTMERLIN_STORAGE_EXPECTED_IDENTITY:-}")
	storage_exact_profile=$(storage_token "${NUTMERLIN_STORAGE_EXACT_PROFILE:-}")
	storage_available_bytes=$(storage_token "${NUTMERLIN_STORAGE_AVAILABLE_BYTES:-}")
	storage_transaction_bytes=$(storage_token "${NUTMERLIN_STORAGE_TRANSACTION_BYTES:-}")
	storage_temporary_bytes=$(storage_token "${NUTMERLIN_STORAGE_TEMPORARY_BYTES:-}")
	storage_ownership_modes=$(storage_evidence "${NUTMERLIN_STORAGE_OWNERSHIP_MODES:-}")
	storage_case_sensitivity=$(storage_evidence "${NUTMERLIN_STORAGE_CASE_SENSITIVITY:-}")
	storage_link_semantics=$(storage_evidence "${NUTMERLIN_STORAGE_LINK_SEMANTICS:-}")
	storage_atomic_rename=$(storage_evidence "${NUTMERLIN_STORAGE_ATOMIC_RENAME:-}")
	storage_file_fsync=$(storage_evidence "${NUTMERLIN_STORAGE_FILE_FSYNC:-}")
	storage_directory_fsync=$(storage_evidence "${NUTMERLIN_STORAGE_DIRECTORY_FSYNC:-}")
	storage_exclusive_locking=$(storage_evidence "${NUTMERLIN_STORAGE_EXCLUSIVE_LOCKING:-}")
	storage_executables=$(storage_evidence "${NUTMERLIN_STORAGE_EXECUTABLES:-}")
	storage_stable_identity=$(storage_evidence "${NUTMERLIN_STORAGE_STABLE_IDENTITY:-}")
	storage_interruption_recovery=$(storage_evidence "${NUTMERLIN_STORAGE_INTERRUPTION_RECOVERY:-}")
}

storage_native_identity() {
	identity_mount_source=$1 identity_sys_block_root=$2
	identity_uuid=$(storage_token "$(blkid -s UUID -o value "$identity_mount_source" 2>/dev/null || :)")
	identity_block_name=${identity_mount_source##*/}
	identity_block_name=$(storage_token "$identity_block_name")
	identity_serial=unknown
	if [ "$identity_block_name" != unknown ]; then
		identity_block_path=$(readlink -f "$identity_sys_block_root/$identity_block_name" 2>/dev/null || :)
		for identity_serial_path in "$identity_block_path/device/serial" "${identity_block_path%/*}/device/serial"; do
			if [ ! -f "$identity_serial_path" ] || [ -L "$identity_serial_path" ]; then
				continue
			fi
			identity_serial=$(storage_token "$(cat "$identity_serial_path" 2>/dev/null || :)")
			[ "$identity_serial" != unknown ] && break
		done
	fi
	if [ "$identity_uuid" != unknown ] && [ "$identity_serial" != unknown ]; then
		storage_identity=$(storage_token "fsuuid-$identity_uuid.serial-$identity_serial")
	else
		storage_identity=unknown
	fi
}

storage_read_native() {
	storage_read_unknown
	storage_root=${NUTMERLIN_ENTWARE_ROOT:-/opt}
	storage_mounts_file=/proc/mounts storage_sys_block_root=/sys/class/block
	if [ "${NUTMERLIN_ENABLE_TEST_ADAPTERS:-0}" = 1 ] && roots_are_isolated; then
		case ${NUTMERLIN_TEST_MOUNTS_FILE:-} in "$NUTMERLIN_ISOLATION_ROOT"/*) storage_mounts_file=$NUTMERLIN_TEST_MOUNTS_FILE ;; esac
		case ${NUTMERLIN_TEST_SYS_BLOCK_ROOT:-} in "$NUTMERLIN_ISOLATION_ROOT"/*) storage_sys_block_root=$NUTMERLIN_TEST_SYS_BLOCK_ROOT ;; esac
	fi
	case $storage_root in /*) ;; *) return ;; esac
	storage_mount_target=$(storage_path "$storage_root")
	if [ ! -d "$storage_root" ] || [ -L "$storage_root" ]; then
		storage_present=missing
		return
	fi
	storage_present=available storage_mount_state=unknown storage_mount_options=unknown
	while read -r mount_source mount_target mount_filesystem mount_options _; do
		[ "$mount_target" = "$storage_root" ] || continue
		storage_filesystem=$(storage_token "$mount_filesystem")
		storage_mount_source=$(storage_path "$mount_source")
		storage_observed_mount_options=$(storage_option_list "$mount_options")
		case ,$mount_options, in *,ro,*) storage_mount_state=read_only ;; *,rw,*) storage_mount_state=read_write ;; esac
		case ,$mount_options, in *,noexec,* | *,uid=* | *,gid=* | *,umask=* | *,fmask=* | *,dmask=*) ;; *) storage_mount_options=rw_exec_native ;; esac
		storage_native_identity "$mount_source" "$storage_sys_block_root"
		break
	done <"$storage_mounts_file"
	storage_qualification_load
	available_blocks=$(df -Pk "$storage_root" 2>/dev/null | awk 'END {print $4}')
	storage_number_valid "$available_blocks" && storage_available_bytes=$((available_blocks * 1024))
}

storage_probe_allowed() {
	[ "$storage_present" = available ] && [ "$storage_mount_state" = read_write ] &&
		[ "$storage_mount_options" = rw_exec_native ] && [ "$storage_identity" != unknown ] || return 1
	[ "$storage_expected_identity" != unknown ] && [ "$storage_identity" = "$storage_expected_identity" ] || return 1
	case $storage_filesystem in fat | vfat | exfat | unknown) return 1 ;; esac
	[ "$storage_filesystem" != ext4 ] || [ "$storage_journaling" = available ] || return 1
	[ "$storage_exact_profile" = qualified ] || return 1
	storage_number_valid "$storage_available_bytes" &&
		storage_number_valid "$storage_transaction_bytes" &&
		storage_number_valid "$storage_temporary_bytes" || return 1
	storage_preprobe_required_bytes=$((storage_transaction_bytes + storage_temporary_bytes + 16777216))
	[ "$storage_available_bytes" -ge "$storage_preprobe_required_bytes" ]
}

storage_probe_cleanup() {
	case ${probe_root:-} in
		"$NUTMERLIN_ENTWARE_ROOT"/.nutmerlin-preflight.*) rm -rf -- "$probe_root" ;;
	esac
}

storage_probe_disposable() {
	storage_ownership_modes=missing storage_case_sensitivity=missing storage_link_semantics=missing
	storage_atomic_rename=missing storage_exclusive_locking=missing storage_executables=missing
	probe_root=$(mktemp -d "$NUTMERLIN_ENTWARE_ROOT/.nutmerlin-preflight.XXXXXX") || return
	trap storage_probe_cleanup EXIT HUP INT TERM
	chmod 700 "$probe_root"
	printf '%s\n' lower >"$probe_root/name" && printf '%s\n' upper >"$probe_root/NAME"
	printf '%s\n' data >"$probe_root/private" && chmod 600 "$probe_root/private"
	cp "$probe_root/private" "$probe_root/group" && chmod 640 "$probe_root/group"
	probe_owner=$(stat -c '%u:%g' "$probe_root")
	[ "$(stat -c '%a:%u:%g' "$probe_root")" = "700:$probe_owner" ] &&
		[ "$(stat -c '%a:%u:%g' "$probe_root/private")" = "600:$probe_owner" ] &&
		[ "$(stat -c '%a:%u:%g' "$probe_root/group")" = "640:$probe_owner" ] && storage_ownership_modes=available
	[ "$(cat "$probe_root/name")" = lower ] && [ "$(cat "$probe_root/NAME")" = upper ] && storage_case_sensitivity=available
	ln "$probe_root/private" "$probe_root/hard" && ln -s private "$probe_root/symbolic" &&
		[ "$(stat -c '%d:%i' "$probe_root/private")" = "$(stat -c '%d:%i' "$probe_root/hard")" ] &&
		[ -L "$probe_root/symbolic" ] && storage_link_semantics=available
	printf '%s\n' selected >"$probe_root/candidate" && mv "$probe_root/candidate" "$probe_root/selected" &&
		[ "$(cat "$probe_root/selected")" = selected ] && storage_atomic_rename=available
	mkdir "$probe_root/lock" && ! mkdir "$probe_root/lock" 2>/dev/null && storage_exclusive_locking=available
	printf '%s\n' '#!/bin/sh' 'exit 0' >"$probe_root/executable" && chmod 700 "$probe_root/executable" &&
		"$probe_root/executable" && storage_executables=available
	if [ "$storage_evidence_layer" = host_disposable_probe ]; then
		storage_file_fsync=missing storage_directory_fsync=missing storage_interruption_recovery=missing
		nutmerlin-storage-durability-probe file-fsync "$probe_root" 2>/dev/null && storage_file_fsync=available
		nutmerlin-storage-durability-probe directory-fsync "$probe_root" 2>/dev/null && storage_directory_fsync=available
		nutmerlin-storage-durability-probe interruption-recovery "$probe_root" 2>/dev/null && storage_interruption_recovery=available
	fi
	storage_probe_cleanup
	trap - EXIT HUP INT TERM
}

storage_number_valid() {
	case ${1:-} in
		'' | *[!0-9]* | 0[0-9]*) return 1 ;;
	esac
	[ "${#1}" -le 15 ]
}

storage_find_evidence() {
	wanted_storage_evidence=$1
	for storage_probe in \
		"ownership_modes:$storage_ownership_modes" "case_sensitivity:$storage_case_sensitivity" \
		"link_semantics:$storage_link_semantics" "atomic_rename:$storage_atomic_rename" \
		"file_fsync:$storage_file_fsync" "directory_fsync:$storage_directory_fsync" \
		"exclusive_locking:$storage_exclusive_locking" "executables:$storage_executables" \
		"stable_identity:$storage_stable_identity" "interruption_recovery:$storage_interruption_recovery"; do
		if [ "${storage_probe#*:}" = "$wanted_storage_evidence" ]; then
			storage_diagnostic_capability=${storage_probe%%:*}
			return 0
		fi
	done
	return 1
}

storage_classify() {
	storage_profile=unknown storage_eligibility=ineligible storage_diagnostic_capability=none
	storage_diagnostic_code=storage_evidence_unknown storage_required_bytes=unknown
	case $storage_filesystem in
		ext4) storage_profile=reference_ext4 ;;
		fat | vfat | exfat)
			storage_profile=incompatible storage_diagnostic_code=incompatible_filesystem
			return
			;;
		unknown) return ;;
		*) storage_profile=non_reference ;;
	esac
	if [ "$storage_present" != available ]; then
		storage_diagnostic_code=storage_${storage_present}
	elif [ "$storage_mount_state" = read_only ]; then
		storage_diagnostic_code=storage_read_only
	elif [ "$storage_mount_state" != read_write ]; then
		storage_diagnostic_code=mount_state_unknown
	elif [ "$storage_mount_options" != rw_exec_native ]; then
		storage_diagnostic_code=incompatible_mount_semantics
	elif [ "$storage_profile" = reference_ext4 ] && [ "$storage_journaling" != available ]; then
		storage_diagnostic_code=ext4_journal_${storage_journaling}
	elif [ "$storage_identity" = unknown ] || [ "$storage_expected_identity" = unknown ]; then
		storage_diagnostic_code=storage_identity_unknown
	elif [ "$storage_identity" != "$storage_expected_identity" ]; then
		storage_diagnostic_code=storage_identity_mismatch
	elif [ "$storage_exact_profile" != qualified ]; then
		storage_diagnostic_code=exact_profile_required
	elif storage_find_evidence incompatible; then
		storage_diagnostic_code=${storage_diagnostic_capability}_incompatible
	elif storage_find_evidence missing; then
		storage_diagnostic_code=${storage_diagnostic_capability}_missing
	elif storage_find_evidence unknown; then
		storage_diagnostic_code=${storage_diagnostic_capability}_unknown
	elif ! storage_number_valid "$storage_available_bytes" || ! storage_number_valid "$storage_transaction_bytes" ||
		! storage_number_valid "$storage_temporary_bytes"; then
		storage_diagnostic_code=transaction_size_uncomputable
	else
		storage_required_bytes=$((storage_transaction_bytes + storage_temporary_bytes + 16777216))
		if [ "$storage_available_bytes" -lt "$storage_required_bytes" ]; then
			storage_diagnostic_code=insufficient_transaction_space
		else
			storage_eligibility=eligible storage_diagnostic_code=qualified_storage_profile
		fi
	fi
}

storage_preflight_run() {
	storage_evidence_layer=invalid storage_disposable_probe=disabled
	storage_operation_transaction_bytes=$2 storage_operation_temporary_bytes=$3
	if [ "${NUTMERLIN_STORAGE_ADAPTER:-native}" = mock ] &&
		[ "${NUTMERLIN_ENABLE_TEST_ADAPTERS:-0}" = 1 ] && roots_are_isolated; then
		storage_evidence_layer=host_simulation
		storage_read_mock
	elif [ "${NUTMERLIN_STORAGE_ADAPTER:-native}" = probe ] &&
		[ "${NUTMERLIN_ENABLE_TEST_ADAPTERS:-0}" = 1 ] && roots_are_isolated; then
		storage_evidence_layer=host_disposable_probe
		storage_read_mock
		storage_disposable_probe=enabled
	else
		if [ "${NUTMERLIN_ENABLE_TEST_ADAPTERS:-0}" = 1 ] && roots_are_isolated; then
			storage_evidence_layer=host_native_probe
		else
			storage_evidence_layer=platform_probe
		fi
		storage_read_native
		storage_disposable_probe=enabled
	fi
	storage_transaction_bytes=$(storage_token "$storage_operation_transaction_bytes")
	storage_temporary_bytes=$(storage_token "$storage_operation_temporary_bytes")
	if [ "$storage_disposable_probe" = enabled ] && storage_probe_allowed; then
		storage_probe_disposable
	fi
	storage_classify
	mutation_disposition=refuse operation_status=refused operation_exit_class=configuration operation_exit_status=78
	storage_effective_diagnostic=$storage_diagnostic_code
	if [ "$storage_eligibility" = eligible ]; then
		if [ "$storage_evidence_layer" = platform_probe ]; then
			mutation_disposition=allow
			operation_status=ok operation_exit_class=success operation_exit_status=0
		else
			storage_effective_diagnostic=simulation_evidence_only
		fi
	fi
	if [ "$1" = json ]; then
		printf '%s\n' "{\"schema_version\":\"nutmerlin.management-result.v1\",\"operation\":\"storage.preflight.v1\",\"status\":\"$operation_status\",\"exit_class\":\"$operation_exit_class\",\"evidence_layer\":\"$storage_evidence_layer\",\"storage\":{\"profile\":\"$storage_profile\",\"filesystem\":\"$storage_filesystem\",\"identity\":\"$storage_identity\",\"eligibility\":\"$storage_eligibility\"},\"mount\":{\"source\":\"$storage_mount_source\",\"target\":\"$storage_mount_target\",\"state\":\"$storage_mount_state\",\"options\":\"$storage_mount_options\",\"observed_options\":\"$storage_observed_mount_options\",\"health_evidence\":\"$storage_health_evidence\"},\"qualification\":{\"exact_profile\":\"$storage_exact_profile\"},\"mutation\":{\"disposition\":\"$mutation_disposition\"},\"space\":{\"available_bytes\":\"$storage_available_bytes\",\"transaction_bytes\":\"$storage_transaction_bytes\",\"temporary_bytes\":\"$storage_temporary_bytes\",\"required_bytes\":\"$storage_required_bytes\",\"headroom_bytes\":16777216},\"diagnostic\":{\"code\":\"$storage_effective_diagnostic\",\"preflight_code\":\"$storage_diagnostic_code\",\"capability\":\"$storage_diagnostic_capability\"},\"capabilities\":{\"journaling\":{\"status\":\"$storage_journaling\"},\"ownership_modes\":{\"status\":\"$storage_ownership_modes\"},\"case_sensitivity\":{\"status\":\"$storage_case_sensitivity\"},\"link_semantics\":{\"status\":\"$storage_link_semantics\"},\"atomic_rename\":{\"status\":\"$storage_atomic_rename\"},\"file_fsync\":{\"status\":\"$storage_file_fsync\"},\"directory_fsync\":{\"status\":\"$storage_directory_fsync\"},\"exclusive_locking\":{\"status\":\"$storage_exclusive_locking\"},\"executables\":{\"status\":\"$storage_executables\"},\"stable_identity\":{\"status\":\"$storage_stable_identity\"},\"interruption_recovery\":{\"status\":\"$storage_interruption_recovery\"}}}"
	else
		printf '%s\n' "NUTMerlin storage: $storage_eligibility ($storage_effective_diagnostic)"
	fi
	return "$operation_exit_status"
}

storage_readiness_root_valid() {
	[ -d "$NUTMERLIN_STATUS_ROOT" ] && [ ! -L "$NUTMERLIN_STATUS_ROOT" ] || return 1
	readiness_root_owner=$(stat -c '%u' "$NUTMERLIN_STATUS_ROOT" 2>/dev/null) || return 1
	readiness_root_mode=$(stat -c '%a' "$NUTMERLIN_STATUS_ROOT" 2>/dev/null) || return 1
	[ "$readiness_root_owner" = "$(id -u)" ] && [ "$readiness_root_mode" = 700 ] || return 1
	readiness_canonical_root=$(CDPATH='' cd -P -- "$NUTMERLIN_STATUS_ROOT" 2>/dev/null && pwd -P) || return 1
	[ "$readiness_canonical_root" = "$NUTMERLIN_STATUS_ROOT" ]
}

storage_readiness_run() {
	output_format=$1 elapsed_seconds=$2 last_probe_seconds=$3 readiness_state=$4
	storage_number_valid "$elapsed_seconds" && storage_number_valid "$last_probe_seconds" || return 64
	case $readiness_state in
		started) readiness_action=already_started next_probe_seconds=$last_probe_seconds ;;
		failed)
			storage_readiness_root_valid || return 78
			readiness_claim=$NUTMERLIN_STATUS_ROOT/storage-start.claim
			if [ -e "$readiness_claim" ] || [ -L "$readiness_claim" ]; then
				[ -d "$readiness_claim" ] && [ ! -L "$readiness_claim" ] || return 78
				rmdir "$readiness_claim" 2>/dev/null || return 78
			fi
			readiness_action=retry_allowed next_probe_seconds=$last_probe_seconds
			;;
		ready)
			umask 077
			if [ -e "$NUTMERLIN_STATUS_ROOT" ]; then
				storage_readiness_root_valid || return 78
			else
				mkdir "$NUTMERLIN_STATUS_ROOT" 2>/dev/null || :
				storage_readiness_root_valid || return 78
			fi
			readiness_claim=$NUTMERLIN_STATUS_ROOT/storage-start.claim
			if [ -e "$readiness_claim" ] || [ -L "$readiness_claim" ]; then
				[ -d "$readiness_claim" ] && [ ! -L "$readiness_claim" ] || return 78
				readiness_action=already_started
			elif mkdir "$readiness_claim" 2>/dev/null; then
				readiness_action=start_once
			elif [ -d "$readiness_claim" ] && [ ! -L "$readiness_claim" ]; then
				readiness_action=already_started
			else
				return 78
			fi
			next_probe_seconds=$last_probe_seconds
			;;
		absent)
			case $last_probe_seconds in
				0) due_seconds=5 next_after_due=15 ;;
				5) due_seconds=15 next_after_due=30 ;;
				15) due_seconds=30 next_after_due=60 ;;
				30) due_seconds=60 next_after_due=120 ;;
				60) due_seconds=120 next_after_due=420 ;;
				*) due_seconds=$((last_probe_seconds + 300)) next_after_due=$((due_seconds + 300)) ;;
			esac
			if [ "$elapsed_seconds" -ge "$due_seconds" ]; then
				readiness_action=probe next_probe_seconds=$next_after_due
			else
				readiness_action=waiting next_probe_seconds=$due_seconds
			fi
			;;
		*) return 64 ;;
	esac
	if [ "$output_format" = json ]; then
		printf '%s\n' "{\"schema_version\":\"nutmerlin.management-result.v1\",\"operation\":\"storage.readiness.v1\",\"status\":\"ok\",\"exit_class\":\"success\",\"readiness\":{\"action\":\"$readiness_action\",\"next_probe_seconds\":$next_probe_seconds}}"
	else
		printf '%s\n' "NUTMerlin storage readiness: $readiness_action; next: $next_probe_seconds"
	fi
}
