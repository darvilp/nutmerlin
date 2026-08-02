#!/bin/sh

platform_token_or_unknown() {
	platform_token=${1:-}
	if [ -z "$platform_token" ] || [ "${#platform_token}" -gt 96 ]; then
		printf '%s' unknown
		return
	fi
	case $platform_token in
		*[!A-Za-z0-9._+-]*) printf '%s' unknown ;;
		*) printf '%s' "$platform_token" ;;
	esac
}

platform_probe_or_unknown() {
	case ${1:-unknown} in
		available | missing | unknown | incompatible) printf '%s' "${1:-unknown}" ;;
		*) printf '%s' unknown ;;
	esac
}

platform_read_unknown() {
	platform_firmware_family=unknown platform_firmware_version=unknown
	platform_architecture=unknown platform_model=unknown platform_hardware_revision=unknown
	probe_firmware=unknown probe_architecture=unknown probe_hooks=unknown probe_addons_api=unknown
	probe_firewall=unknown probe_process_identity=unknown probe_mounts=unknown probe_boot_identity=unknown
	probe_clock_evidence=unknown probe_resource_limits=unknown
}

platform_read_mock() {
	platform_firmware_family=$(platform_token_or_unknown "${NUTMERLIN_PLATFORM_FIRMWARE_FAMILY:-}")
	platform_firmware_version=$(platform_token_or_unknown "${NUTMERLIN_PLATFORM_FIRMWARE_VERSION:-}")
	platform_architecture=$(platform_token_or_unknown "${NUTMERLIN_PLATFORM_ARCHITECTURE:-}")
	platform_model=$(platform_token_or_unknown "${NUTMERLIN_PLATFORM_MODEL:-}")
	platform_hardware_revision=$(platform_token_or_unknown "${NUTMERLIN_PLATFORM_HARDWARE_REVISION:-}")
	probe_firmware=$(platform_probe_or_unknown "${NUTMERLIN_PROBE_FIRMWARE:-}")
	probe_architecture=$(platform_probe_or_unknown "${NUTMERLIN_PROBE_ARCHITECTURE:-}")
	probe_hooks=$(platform_probe_or_unknown "${NUTMERLIN_PROBE_HOOKS:-}")
	probe_addons_api=$(platform_probe_or_unknown "${NUTMERLIN_PROBE_ADDONS_API:-}")
	probe_firewall=$(platform_probe_or_unknown "${NUTMERLIN_PROBE_FIREWALL:-}")
	probe_process_identity=$(platform_probe_or_unknown "${NUTMERLIN_PROBE_PROCESS_IDENTITY:-}")
	probe_mounts=$(platform_probe_or_unknown "${NUTMERLIN_PROBE_MOUNTS:-}")
	probe_boot_identity=$(platform_probe_or_unknown "${NUTMERLIN_PROBE_BOOT_IDENTITY:-}")
	probe_clock_evidence=$(platform_probe_or_unknown "${NUTMERLIN_PROBE_CLOCK_EVIDENCE:-}")
	probe_resource_limits=$(platform_probe_or_unknown "${NUTMERLIN_PROBE_RESOURCE_LIMITS:-}")
}

platform_read_native() {
	platform_firmware_version=$(platform_token_or_unknown "$(nvram get extendno 2>/dev/null || :)")
	platform_architecture=$(platform_token_or_unknown "$(uname -m 2>/dev/null || :)")
	platform_model=$(platform_token_or_unknown "$(nvram get productid 2>/dev/null || :)")
	platform_hardware_revision=$(platform_token_or_unknown "$(nvram get hardware_version 2>/dev/null || :)")
	case $platform_firmware_version in
		3004.388.*) platform_firmware_family=3004.388.x ;;
		3006.102.*) platform_firmware_family=3006.102.x ;;
		386.*) platform_firmware_family=386.x ;;
		unknown) platform_firmware_family=unknown ;;
		*) platform_firmware_family=unsupported ;;
	esac
	[ "$platform_firmware_version" = unknown ] && probe_firmware=unknown || probe_firmware=available
	[ "$platform_architecture" = unknown ] && probe_architecture=unknown || probe_architecture=available
	probe_hooks=unknown probe_addons_api=unknown probe_firewall=unknown
	probe_process_identity=unknown probe_mounts=unknown probe_boot_identity=unknown
	probe_clock_evidence=unknown probe_resource_limits=unknown
}

platform_find_core_probe_state() {
	wanted_probe_state=$1
	for core_probe in \
		"firmware:$probe_firmware" \
		"architecture:$probe_architecture" \
		"hooks:$probe_hooks" \
		"firewall:$probe_firewall" \
		"process_identity:$probe_process_identity" \
		"mounts:$probe_mounts" \
		"boot_identity:$probe_boot_identity"; do
		if [ "${core_probe#*:}" = "$wanted_probe_state" ]; then
			diagnostic_capability=${core_probe%%:*}
			return 0
		fi
	done
	return 1
}

platform_apply_known_incompatibility() {
	case $(platform_known_incompatibility_scope) in
		webui) probe_addons_api=incompatible ;;
		wall_clock_security) probe_clock_evidence=incompatible ;;
		local_script) probe_resource_limits=incompatible ;;
	esac
}

platform_classify() {
	support_class=ineligible support_acknowledgment_required=false platform_disposition=refuse install_disposition=refuse
	diagnostic_code=platform_identity_invalid diagnostic_capability=none
	qualified_stable=$(platform_qualified_stable "$platform_firmware_family")
	known_incompatibility_scope=$(platform_known_incompatibility_scope)

	case $platform_firmware_family:$platform_architecture in
		386.x:armv7l)
			if platform_version_matches_family "$platform_firmware_family" "$platform_firmware_version"; then
				support_class=legacy_best_effort support_acknowledgment_required=true platform_disposition=allow_with_acknowledgment diagnostic_code=legacy_merlin_386_armv7
			fi
			;;
		3004.388.x:aarch64 | 3006.102.x:aarch64)
			if ! platform_version_matches_family "$platform_firmware_family" "$platform_firmware_version"; then
				:
			elif [ "$qualified_stable" != none ] && [ "$platform_firmware_version" = "$qualified_stable" ]; then
				support_class=supported platform_disposition=allow diagnostic_code=qualified_current_platform
			else
				support_class=compatibility_only support_acknowledgment_required=true platform_disposition=allow_with_acknowledgment diagnostic_code=firmware_not_qualified_stable
			fi
			;;
		*)
			if [ "$platform_firmware_family" != unknown ] && [ "$platform_firmware_version" != unknown ] &&
				[ "$platform_architecture" != unknown ]; then
				support_class=experimental_unsupported support_acknowledgment_required=true platform_disposition=allow_with_acknowledgment diagnostic_code=outside_supported_platform_contract
			fi
			;;
	esac

	support_code=$diagnostic_code
	install_disposition=$platform_disposition
	if [ "$known_incompatibility_scope" = core ]; then
		install_disposition=refuse
		diagnostic_code=known_core_incompatibility
	elif platform_find_core_probe_state incompatible; then
		install_disposition=refuse
		diagnostic_code=core_capability_incompatible
	elif platform_find_core_probe_state missing; then
		install_disposition=refuse
		diagnostic_code=core_capability_missing
	elif platform_find_core_probe_state unknown; then
		install_disposition=refuse
		diagnostic_code=core_capability_unknown
	elif [ "$platform_evidence_layer" = host_simulation ]; then
		install_disposition=refuse
		diagnostic_code=simulation_evidence_only
	fi
}

platform_eligibility_run() {
	output_format=$1
	platform_evidence_layer=invalid
	case ${NUTMERLIN_PLATFORM_ADAPTER:-native} in
		native)
			platform_evidence_layer=platform_probe
			platform_read_native
			;;
		mock)
			if [ "${NUTMERLIN_ENABLE_TEST_ADAPTERS:-0}" = 1 ] && roots_are_isolated; then
				platform_evidence_layer=host_simulation
				platform_read_mock
			else
				platform_read_unknown
			fi
			;;
		*) platform_read_unknown ;;
	esac
	platform_qualification_load
	platform_apply_known_incompatibility
	platform_classify

	if [ "$install_disposition" = refuse ]; then
		result_status=refused exit_class=configuration result_code=78
	else
		result_status=ok exit_class=success result_code=0
	fi
	if [ "$output_format" = json ]; then
		printf '%s\n' "{\"schema_version\":\"nutmerlin.management-result.v1\",\"operation\":\"platform.eligibility.v1\",\"status\":\"$result_status\",\"exit_class\":\"$exit_class\",\"evidence_layer\":\"$platform_evidence_layer\",\"support\":{\"class\":\"$support_class\",\"code\":\"$support_code\",\"acknowledgment_required\":$support_acknowledgment_required},\"installation\":{\"disposition\":\"$install_disposition\"},\"diagnostic\":{\"code\":\"$diagnostic_code\",\"capability\":\"$diagnostic_capability\"},\"platform\":{\"firmware_family\":\"$platform_firmware_family\",\"firmware_version\":\"$platform_firmware_version\",\"qualified_stable\":\"$qualified_stable\",\"architecture\":\"$platform_architecture\",\"model\":\"$platform_model\",\"hardware_revision\":\"$platform_hardware_revision\"},\"capabilities\":{\"firmware\":{\"scope\":\"core\",\"status\":\"$probe_firmware\"},\"architecture\":{\"scope\":\"core\",\"status\":\"$probe_architecture\"},\"hooks\":{\"scope\":\"core\",\"status\":\"$probe_hooks\"},\"addons_api\":{\"scope\":\"webui\",\"status\":\"$probe_addons_api\"},\"firewall\":{\"scope\":\"core\",\"status\":\"$probe_firewall\"},\"process_identity\":{\"scope\":\"core\",\"status\":\"$probe_process_identity\"},\"mounts\":{\"scope\":\"core\",\"status\":\"$probe_mounts\"},\"boot_identity\":{\"scope\":\"core\",\"status\":\"$probe_boot_identity\"},\"clock_evidence\":{\"scope\":\"wall_clock_security\",\"status\":\"$probe_clock_evidence\"},\"resource_limits\":{\"scope\":\"local_script\",\"status\":\"$probe_resource_limits\"}}}"
	else
		printf '%s\n' "NUTMerlin platform: $support_class; install: $install_disposition ($diagnostic_code)"
	fi
	return "$result_code"
}
