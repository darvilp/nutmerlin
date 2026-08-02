#!/bin/sh

# Release catalog and adapter functions are provided by sibling modules.
# shellcheck disable=SC2154

dependency_parse_nut_version() {
	dependency_parse_version=$1
	case $dependency_parse_version in
		[0-9]*.[0-9]*.[0-9]*-[0-9]*) ;;
		*)
			printf '%s' invalid
			return
			;;
	esac
	dependency_parse_upstream=${dependency_parse_version%-*}
	dependency_parse_revision=${dependency_parse_version##*-}
	dependency_parse_major=${dependency_parse_upstream%%.*}
	dependency_parse_remainder=${dependency_parse_upstream#*.}
	dependency_parse_minor=${dependency_parse_remainder%%.*}
	dependency_parse_patch=${dependency_parse_remainder#*.}
	[ "$dependency_parse_patch" = "${dependency_parse_patch##*.}" ] || {
		printf '%s' invalid
		return
	}
	for dependency_parse_number in "$dependency_parse_major" "$dependency_parse_minor" "$dependency_parse_patch" "$dependency_parse_revision"; do
		case $dependency_parse_number in '' | *[!0-9]* | 0[0-9]*)
			printf '%s' invalid
			return
			;;
		esac
		[ "${#dependency_parse_number}" -le 6 ] || {
			printf '%s' invalid
			return
		}
	done
	printf '%s|%s|%s|%s' "$dependency_parse_major" "$dependency_parse_minor" "$dependency_parse_patch" "$dependency_parse_revision"
}

dependency_nut_version_relation() {
	dependency_relation_installed=$(dependency_parse_nut_version "$1")
	dependency_relation_candidate=$(dependency_parse_nut_version "$dependency_catalog_nut_version")
	if [ "$dependency_relation_installed" = invalid ] || [ "$dependency_relation_candidate" = invalid ]; then
		printf '%s' invalid
		return
	fi
	dependency_relation_installed_major=${dependency_relation_installed%%|*}
	dependency_relation_installed_rest=${dependency_relation_installed#*|}
	dependency_relation_installed_minor=${dependency_relation_installed_rest%%|*}
	dependency_relation_installed_rest=${dependency_relation_installed_rest#*|}
	dependency_relation_installed_patch=${dependency_relation_installed_rest%%|*}
	dependency_relation_installed_revision=${dependency_relation_installed_rest#*|}
	dependency_relation_candidate_major=${dependency_relation_candidate%%|*}
	dependency_relation_candidate_rest=${dependency_relation_candidate#*|}
	dependency_relation_candidate_minor=${dependency_relation_candidate_rest%%|*}
	dependency_relation_candidate_rest=${dependency_relation_candidate_rest#*|}
	dependency_relation_candidate_patch=${dependency_relation_candidate_rest%%|*}
	dependency_relation_candidate_revision=${dependency_relation_candidate_rest#*|}
	if [ "$dependency_relation_installed_major" -lt "$dependency_relation_candidate_major" ] ||
		{ [ "$dependency_relation_installed_major" -eq "$dependency_relation_candidate_major" ] && [ "$dependency_relation_installed_minor" -lt "$dependency_relation_candidate_minor" ]; } ||
		{ [ "$dependency_relation_installed_major" -eq "$dependency_relation_candidate_major" ] && [ "$dependency_relation_installed_minor" -eq "$dependency_relation_candidate_minor" ] && [ "$dependency_relation_installed_patch" -lt "$dependency_relation_candidate_patch" ]; } ||
		{ [ "$dependency_relation_installed_major" -eq "$dependency_relation_candidate_major" ] && [ "$dependency_relation_installed_minor" -eq "$dependency_relation_candidate_minor" ] && [ "$dependency_relation_installed_patch" -eq "$dependency_relation_candidate_patch" ] && [ "$dependency_relation_installed_revision" -lt "$dependency_relation_candidate_revision" ]; }; then
		printf '%s' older
	elif [ "$dependency_relation_installed_major" -eq "$dependency_relation_candidate_major" ] &&
		[ "$dependency_relation_installed_minor" -eq "$dependency_relation_candidate_minor" ] &&
		[ "$dependency_relation_installed_patch" -eq "$dependency_relation_candidate_patch" ] &&
		[ "$dependency_relation_installed_revision" -eq "$dependency_relation_candidate_revision" ]; then
		printf '%s' current
	else
		printf '%s' newer
	fi
}

dependency_classify_nut_cohort() {
	dependency_nut_count=0 dependency_nut_current_count=0
	dependency_nut_state=unknown dependency_nut_installed_version=unknown
	dependency_nut_first_version=
	while IFS= read -r dependency_nut_package; do
		dependency_nut_package_version=$(dependency_status_version "$dependency_nut_package")
		[ -n "$dependency_nut_package_version" ] && dependency_nut_count=$((dependency_nut_count + 1))
		[ "$dependency_nut_package_version" = "$dependency_catalog_nut_version" ] && dependency_nut_current_count=$((dependency_nut_current_count + 1))
		if [ -n "$dependency_nut_package_version" ]; then
			if [ -z "$dependency_nut_first_version" ]; then
				dependency_nut_first_version=$dependency_nut_package_version
			elif [ "$dependency_nut_package_version" != "$dependency_nut_first_version" ]; then
				dependency_nut_state=mixed
			fi
		fi
	done <<EOF
$(dependency_catalog_nut_roots)
EOF
	if [ "$dependency_nut_count" -eq 0 ]; then
		dependency_nut_state=absent dependency_nut_installed_version=not_installed
	elif [ "$dependency_nut_current_count" -eq 6 ]; then
		dependency_nut_state=current
		dependency_nut_installed_version=$dependency_catalog_nut_version
	elif [ "$dependency_nut_count" -lt 6 ]; then
		dependency_nut_state=incomplete
	elif [ "$dependency_nut_state" = mixed ]; then
		dependency_nut_installed_version=mixed
	else
		dependency_nut_installed_version=$(dependency_token "$dependency_nut_first_version")
		case $(dependency_nut_version_relation "$dependency_nut_installed_version") in
			older)
				if [ "$dependency_binary_probes" = available ] && [ "$dependency_option_probes" = available ] &&
					[ "$dependency_configuration_probe" = available ] && [ "$dependency_dummy_smoke_probe" = available ]; then
					dependency_nut_state=compatible_older
				else
					dependency_nut_state=older_unprobed
				fi
				;;
			newer) dependency_nut_state=newer ;;
			*) dependency_nut_state=invalid ;;
		esac
	fi
}

dependency_package_selected() {
	[ "$1" = core ] || { [ "$1" = ssh ] && [ "$dependency_capabilities" = ssh ]; }
}

dependency_append_json_item() {
	dependency_json_list=$1 dependency_json_item=$2
	if [ -n "$dependency_json_list" ]; then
		printf '%s,%s' "$dependency_json_list" "$dependency_json_item"
	else
		printf '%s' "$dependency_json_item"
	fi
}

dependency_build_plan() {
	dependency_mutations='' dependency_provenance='' dependency_transaction_bytes=0 dependency_temporary_bytes=0
	dependency_optional_mismatch=none
	dependency_upgrade_nut_cohort=no
	case $dependency_nut_state:$dependency_policy in
		compatible_older:current | older_unprobed:current) dependency_upgrade_nut_cohort=yes ;;
	esac
	while IFS='|' read -r dependency_group dependency_package dependency_version dependency_installed_bytes dependency_archive_bytes dependency_sha256; do
		dependency_package_selected "$dependency_group" || continue
		dependency_filename=${dependency_package}_${dependency_version}_${dependency_catalog_feed_architecture}.ipk
		dependency_from_version=$(dependency_status_version "$dependency_package")
		dependency_observed_version=$(dependency_token "${dependency_from_version:-not_installed}")
		dependency_provenance_item="{\"package\":\"$dependency_package\",\"version\":\"$dependency_version\",\"observed_version\":\"$dependency_observed_version\",\"architecture\":\"$dependency_catalog_feed_architecture\",\"filename\":\"$dependency_filename\",\"installed_bytes\":$dependency_installed_bytes,\"archive_bytes\":$dependency_archive_bytes,\"sha256\":\"$dependency_sha256\"}"
		dependency_provenance=$(dependency_append_json_item "$dependency_provenance" "$dependency_provenance_item")
		dependency_action=
		if [ "$dependency_nut_state" = absent ] && [ "$dependency_group" = core ] && [ -z "$dependency_from_version" ]; then
			dependency_action=install dependency_from_version=not_installed
		elif [ "$dependency_upgrade_nut_cohort" = yes ] && dependency_is_nut_cohort_package "$dependency_package"; then
			dependency_action=upgrade
		elif [ "$dependency_group" = ssh ] && [ -z "$dependency_from_version" ]; then
			dependency_action=install dependency_from_version=not_installed
		elif [ "$dependency_group" = ssh ] && [ "$dependency_from_version" != "$dependency_version" ]; then
			dependency_optional_mismatch=ssh_version_mismatch
		fi
		[ -n "$dependency_action" ] || continue
		dependency_mutation_item="{\"action\":\"$dependency_action\",\"package\":\"$dependency_package\",\"from\":\"$dependency_from_version\",\"to\":\"$dependency_version\",\"architecture\":\"$dependency_catalog_feed_architecture\",\"filename\":\"$dependency_filename\",\"installed_bytes\":$dependency_installed_bytes,\"archive_bytes\":$dependency_archive_bytes,\"sha256\":\"$dependency_sha256\"}"
		dependency_mutations=$(dependency_append_json_item "$dependency_mutations" "$dependency_mutation_item")
		dependency_transaction_bytes=$((dependency_transaction_bytes + dependency_installed_bytes))
		dependency_temporary_bytes=$((dependency_temporary_bytes + dependency_archive_bytes))
	done <<EOF
$(dependency_catalog_packages)
EOF
	dependency_required_bytes=$((dependency_transaction_bytes + dependency_temporary_bytes + 16777216))
}

dependency_build_retained_packages() {
	dependency_retained_packages=
	while IFS='|' read -r dependency_retained_package dependency_retained_version; do
		dependency_retained_package=$(dependency_token "$dependency_retained_package")
		dependency_retained_version=$(dependency_token "$dependency_retained_version")
		if [ "$dependency_retained_package" = unknown ] || [ "$dependency_retained_version" = unknown ]; then
			continue
		fi
		dependency_retained_item="{\"package\":\"$dependency_retained_package\",\"version\":\"$dependency_retained_version\"}"
		dependency_retained_packages=$(dependency_append_json_item "$dependency_retained_packages" "$dependency_retained_item")
	done <<EOF
$(dependency_status_records)
EOF
}

dependency_plan_run() {
	dependency_output_format=$1
	shift
	dependency_mode=${1:-}
	case $dependency_mode in
		interactive) dependency_policy=${2:-current} ;;
		unattended)
			[ "$#" -ge 2 ] || return 64
			dependency_policy=$2
			;;
		uninstall)
			[ "$#" -eq 1 ] || return 64
			dependency_policy=retain
			;;
		*) return 64 ;;
	esac
	dependency_capabilities=${3:-none}
	case $dependency_policy in none | current | keep-compatible | retain) ;; *) return 64 ;; esac
	[ "$dependency_mode" = unattended ] || [ "$dependency_policy" != none ] || return 64
	case $dependency_capabilities in none | ssh) ;; *) return 64 ;; esac
	dependency_selected_capabilities_json=
	[ "$dependency_capabilities" != ssh ] || dependency_selected_capabilities_json='"ssh"'

	if [ "${NUTMERLIN_DEPENDENCY_ADAPTER:-native}" = mock ] &&
		[ "${NUTMERLIN_ENABLE_TEST_ADAPTERS:-0}" = 1 ] && roots_are_isolated; then
		dependency_read_mock
	else
		dependency_read_native
	fi
	dependency_entware_root_report=$(dependency_token "$dependency_entware_root")
	dependency_conflicting_provider_version=$(dependency_token "$(dependency_status_version libnetsnmp-nossl)")
	[ "$dependency_conflicting_provider_version" != unknown ] || dependency_conflicting_provider_version=none

	dependency_classify_nut_cohort
	dependency_build_plan
	dependency_retained_packages=
	[ "$dependency_mode" != uninstall ] || dependency_build_retained_packages
	dependency_required_binaries=$(dependency_catalog_required_binaries_json)
	dependency_relationships=$(dependency_catalog_relationships_json)
	dependency_compatibility_diagnostic=none dependency_current_hardware_qualification=eligible
	case $dependency_nut_state in
		compatible_older)
			dependency_current_hardware_qualification=ineligible
			[ "$dependency_policy" = keep-compatible ] && dependency_compatibility_diagnostic=persistent
			;;
		older_unprobed) dependency_current_hardware_qualification=ineligible ;;
	esac
	dependency_diagnostic=dependency_evidence_invalid dependency_plan_disposition=refuse
	dependency_prerequisites_valid=no
	if [ "$dependency_entware_health" != healthy ]; then
		dependency_diagnostic=entware_health_invalid
	elif [ "$dependency_package_database" != healthy ]; then
		dependency_diagnostic=package_database_unhealthy
	elif [ "$dependency_feed_url" != "$dependency_catalog_configured_feed_url" ]; then
		dependency_diagnostic=unsupported_entware_feed
	elif [ "$dependency_configured_architecture" != "$dependency_catalog_feed_architecture" ]; then
		dependency_diagnostic=unsupported_configured_architecture
	elif [ "$dependency_feed_architecture" != "$dependency_catalog_feed_architecture" ]; then
		dependency_diagnostic=unsupported_feed_architecture
	elif [ "$dependency_feed_index_bytes" != "$dependency_catalog_index_bytes" ]; then
		dependency_diagnostic=feed_catalog_size_mismatch
	elif [ "$dependency_feed_index_sha256" != "$dependency_catalog_index_sha256" ]; then
		dependency_diagnostic=feed_catalog_mismatch
	elif [ "$dependency_gpgv2_version" != "$dependency_catalog_gpgv2_version" ]; then
		dependency_diagnostic=gpgv2_prerequisite_mismatch
	elif [ "$dependency_gpgv2_probe" != available ]; then
		dependency_diagnostic=gpgv2_binary_probe_failed
	elif [ "$dependency_conflicting_provider_version" != none ]; then
		dependency_diagnostic=conflicting_libnetsnmp_provider
	elif [ "$dependency_required_closure" = missing ]; then
		dependency_diagnostic=required_dependency_closure_incomplete
	elif [ "$dependency_required_closure" != complete ] && [ "$dependency_required_closure" != not_applicable ]; then
		dependency_diagnostic=required_dependency_closure_unknown
	else
		dependency_prerequisites_valid=yes
	fi
	if [ "$dependency_prerequisites_valid" = yes ]; then
		if [ "$dependency_nut_safety" = unsafe ]; then
			dependency_diagnostic=known_unsafe_cohort
		elif [ "$dependency_nut_safety" != clear ]; then
			dependency_diagnostic=compatibility_metadata_invalid
		else
			case $dependency_nut_state in
				current)
					if [ "$dependency_binary_probes" != available ] || [ "$dependency_option_probes" != available ]; then
						dependency_diagnostic=mandatory_current_probe_failed
					elif [ "$dependency_optional_mismatch" != none ]; then
						dependency_diagnostic=$dependency_optional_mismatch
					elif [ -n "$dependency_mutations" ]; then
						dependency_diagnostic=selected_optional_dependency_plan
						dependency_plan_disposition=proposed
					else
						dependency_diagnostic=current_cohort_no_changes
						dependency_plan_disposition=no_changes
					fi
					;;
				absent)
					dependency_diagnostic=fresh_current_cohort_plan
					dependency_plan_disposition=proposed
					;;
				compatible_older)
					if [ "$dependency_optional_mismatch" != none ]; then
						dependency_diagnostic=$dependency_optional_mismatch
					elif [ "$dependency_policy" = current ]; then
						dependency_diagnostic=compatible_older_upgrade_plan
						dependency_plan_disposition=proposed
					elif [ -n "$dependency_mutations" ]; then
						dependency_diagnostic=compatible_older_missing_requirements_plan
						dependency_plan_disposition=proposed
					else
						dependency_diagnostic=compatible_older_kept
						dependency_plan_disposition=no_changes
					fi
					;;
				older_unprobed)
					if [ "$dependency_policy" = current ]; then
						dependency_diagnostic=coherent_older_upgrade_plan
						dependency_plan_disposition=proposed
					else
						dependency_diagnostic=mandatory_compatibility_probe_failed
					fi
					;;
				incomplete | mixed) dependency_diagnostic=scoped_nut_repair_required ;;
				newer) dependency_diagnostic=automatic_downgrade_forbidden ;;
				invalid) dependency_diagnostic=installed_nut_version_invalid ;;
			esac
		fi
	fi
	if [ "$dependency_mode" = unattended ] && [ "$dependency_policy" = none ] &&
		[ "$dependency_plan_disposition" = proposed ]; then
		dependency_diagnostic=explicit_dependency_policy_required
		dependency_plan_disposition=refuse
	fi
	if [ "$dependency_required_closure" = missing ] || [ "$dependency_conflicting_provider_version" != none ]; then
		dependency_mutations=
		dependency_transaction_bytes=0 dependency_temporary_bytes=0 dependency_required_bytes=16777216
	fi
	if [ "$dependency_mode" = uninstall ]; then
		dependency_diagnostic=ordinary_uninstall_retains_entware
		dependency_plan_disposition=retain_all
		dependency_mutations=
		dependency_transaction_bytes=0 dependency_temporary_bytes=0 dependency_required_bytes=16777216
	fi
	dependency_operation_status=refused dependency_exit_class=configuration dependency_exit_status=78
	dependency_mutation_authority=refuse
	if [ "$dependency_evidence_layer" = platform_probe ]; then
		case $dependency_plan_disposition in
			proposed | no_changes | retain_all)
				dependency_operation_status=ok dependency_exit_class=success dependency_exit_status=0
				dependency_mutation_authority=not_granted
				;;
		esac
	fi

	if [ "$dependency_output_format" = json ]; then
		printf '%s\n' "{\"schema_version\":\"nutmerlin.management-result.v1\",\"operation\":\"dependency.plan.v1\",\"status\":\"$dependency_operation_status\",\"exit_class\":\"$dependency_exit_class\",\"evidence_layer\":\"$dependency_evidence_layer\",\"dry_run\":true,\"mutation_authority\":\"$dependency_mutation_authority\",\"mode\":\"$dependency_mode\",\"dependency_policy\":\"$dependency_policy\",\"selected_capabilities\":[$dependency_selected_capabilities_json],\"entware\":{\"root\":\"$dependency_entware_root_report\",\"health\":\"$dependency_entware_health\",\"package_manager\":\"$dependency_package_manager\",\"package_database\":\"$dependency_package_database\",\"feed\":{\"name\":\"$dependency_catalog_feed_name\",\"url\":\"$dependency_feed_url\",\"catalog_url\":\"$dependency_catalog_feed_url\",\"configured_architecture\":\"$dependency_configured_architecture\",\"architecture\":\"$dependency_feed_architecture\",\"index_bytes\":\"$dependency_feed_index_bytes\",\"catalog_index_bytes\":$dependency_catalog_index_bytes,\"index_sha256\":\"$dependency_feed_index_sha256\",\"catalog_index_sha256\":\"$dependency_catalog_index_sha256\",\"catalog_last_modified\":\"$dependency_catalog_index_last_modified\"}},\"catalog\":{\"schema_version\":\"$dependency_catalog_schema\",\"compatibility_metadata\":\"$dependency_compatibility_metadata\",\"compatibility_safety\":\"$dependency_nut_safety\",$dependency_relationships,\"required_binaries\":[$dependency_required_binaries],\"package_provenance\":[$dependency_provenance]},\"cohort\":{\"state\":\"$dependency_nut_state\",\"installed_version\":\"$dependency_nut_installed_version\",\"candidate_version\":\"$dependency_catalog_nut_version\",\"required_dependency_closure\":\"$dependency_required_closure\",\"binary_probes\":\"$dependency_binary_probes\",\"option_probes\":\"$dependency_option_probes\",\"configuration_probe\":\"$dependency_configuration_probe\",\"dummy_smoke_probe\":\"$dependency_dummy_smoke_probe\",\"compatibility_metadata_source\":\"release_catalog\",\"compatibility_diagnostic\":\"$dependency_compatibility_diagnostic\",\"current_hardware_qualification\":\"$dependency_current_hardware_qualification\"},\"prerequisites\":{\"gpgv2\":{\"path\":\"/opt/bin/gpgv2\",\"install_policy\":\"preexisting_only\",\"binary_probe\":\"$dependency_gpgv2_probe\",\"installed_version\":\"$dependency_gpgv2_version\",\"candidate_version\":\"$dependency_catalog_gpgv2_version\",\"architecture\":\"$dependency_catalog_feed_architecture\",\"filename\":\"$dependency_catalog_gpgv2_filename\",\"installed_bytes\":$dependency_catalog_gpgv2_installed_bytes,\"archive_bytes\":$dependency_catalog_gpgv2_archive_bytes,\"sha256\":\"$dependency_catalog_gpgv2_sha256\"}},\"plan\":{\"disposition\":\"$dependency_plan_disposition\",\"mutations\":[$dependency_mutations],\"retained_packages\":[$dependency_retained_packages]},\"space\":{\"transaction_bytes\":$dependency_transaction_bytes,\"temporary_bytes\":$dependency_temporary_bytes,\"headroom_bytes\":16777216,\"required_bytes\":$dependency_required_bytes},\"diagnostic\":{\"code\":\"$dependency_diagnostic\"}}"
	else
		printf '%s\n' "NUTMerlin dependency plan: $dependency_plan_disposition ($dependency_diagnostic)"
	fi
	return "$dependency_exit_status"
}
