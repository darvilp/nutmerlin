#!/bin/sh

# Release catalog variables and root isolation are provided by the caller.
# shellcheck disable=SC2034,SC2154

dependency_token() {
	case ${1:-} in
		'' | *[!A-Za-z0-9._:+/-]* | *..*) printf '%s' unknown ;;
		*)
			if [ "${#1}" -le 160 ]; then printf '%s' "$1"; else printf '%s' unknown; fi
			;;
	esac
}

dependency_status_version() {
	dependency_wanted_package=$1
	awk -v wanted="$dependency_wanted_package" '
		BEGIN { RS = ""; FS = "\n" }
		{
			package = version = status = ""
			for (line = 1; line <= NF; line++) {
				if ($line ~ /^Package: /) package = substr($line, 10)
				if ($line ~ /^Version: /) version = substr($line, 10)
				if ($line ~ /^Status: /) status = substr($line, 9)
			}
			if (package == wanted && status ~ /^install .* installed$/) print version
		}
	' "$dependency_installed_status_file"
}

dependency_status_records() {
	awk '
		BEGIN { RS = ""; FS = "\n" }
		{
			package = version = status = ""
			for (line = 1; line <= NF; line++) {
				if ($line ~ /^Package: /) package = substr($line, 10)
				if ($line ~ /^Version: /) version = substr($line, 10)
				if ($line ~ /^Status: /) status = substr($line, 9)
			}
			if (package != "" && version != "" && status ~ /^install .* installed$/) print package "|" version
		}
	' "$dependency_installed_status_file"
}

dependency_status_database_valid() {
	awk '
		BEGIN { RS = ""; FS = "\n"; valid = 1; records = 0 }
		{
			package = version = status = ""
			for (line = 1; line <= NF; line++) {
				if ($line ~ /^Package: /) package = substr($line, 10)
				if ($line ~ /^Version: /) version = substr($line, 10)
				if ($line ~ /^Status: /) status = substr($line, 9)
			}
			if (package !~ /^[A-Za-z0-9][A-Za-z0-9.+_-]*$/ ||
				version !~ /^[A-Za-z0-9][A-Za-z0-9.+_~:-]*$/ ||
				status !~ /^(install|deinstall) [A-Za-z]+ (installed|not-installed|config-files)$/ || seen[package]++) valid = 0
			records++
		}
		END { exit !(valid && records > 0) }
	' "$dependency_installed_status_file"
}

dependency_metadata_size() {
	wc -c <"$1" 2>/dev/null | awk 'NF == 1 && $1 ~ /^[0-9]+$/ { print $1 }'
}

dependency_metadata_size_within() {
	dependency_observed_metadata_size=$(dependency_metadata_size "$1")
	case $dependency_observed_metadata_size in '' | *[!0-9]*) return 1 ;; esac
	[ "$dependency_observed_metadata_size" -le "$2" ]
}

dependency_read_mock() {
	dependency_evidence_layer=host_simulation
	dependency_entware_health=$(dependency_token "${NUTMERLIN_TEST_ENTWARE_HEALTH:-unknown}")
	dependency_package_database=$(dependency_token "${NUTMERLIN_TEST_PACKAGE_DATABASE:-unknown}")
	dependency_feed_url=$(dependency_token "${NUTMERLIN_TEST_FEED_URL:-unknown}")
	dependency_configured_architecture=$(dependency_token "${NUTMERLIN_TEST_CONFIGURED_ARCHITECTURE:-unknown}")
	dependency_feed_architecture=$(dependency_token "${NUTMERLIN_TEST_FEED_ARCHITECTURE:-unknown}")
	dependency_feed_index_bytes=$(dependency_token "${NUTMERLIN_TEST_FEED_INDEX_BYTES:-unknown}")
	dependency_feed_index_sha256=$(dependency_token "${NUTMERLIN_TEST_FEED_INDEX_SHA256:-unknown}")
	dependency_gpgv2_version=$(dependency_token "${NUTMERLIN_TEST_GPGV2_VERSION:-unknown}")
	dependency_gpgv2_probe=$(dependency_token "${NUTMERLIN_TEST_GPGV2_PROBE:-unknown}")
	dependency_binary_probes=$(dependency_token "${NUTMERLIN_TEST_BINARY_PROBES:-unknown}")
	dependency_option_probes=$(dependency_token "${NUTMERLIN_TEST_OPTION_PROBES:-unknown}")
	dependency_configuration_probe=$(dependency_token "${NUTMERLIN_TEST_CONFIGURATION_PROBE:-unknown}")
	dependency_dummy_smoke_probe=$(dependency_token "${NUTMERLIN_TEST_DUMMY_SMOKE_PROBE:-unknown}")
	dependency_nut_safety=$(dependency_token "${NUTMERLIN_TEST_NUT_SAFETY:-unknown}")
	dependency_required_closure=$(dependency_token "${NUTMERLIN_TEST_REQUIRED_CLOSURE:-unknown}")
	dependency_installed_status_file=${NUTMERLIN_TEST_INSTALLED_STATUS:-}
	dependency_entware_root=${NUTMERLIN_ENTWARE_ROOT:-unknown}
	dependency_package_manager=available
	case $dependency_installed_status_file in
		"$NUTMERLIN_ISOLATION_ROOT"/*)
			if [ ! -f "$dependency_installed_status_file" ] || [ -L "$dependency_installed_status_file" ] ||
				! dependency_metadata_size_within "$dependency_installed_status_file" 16777216 ||
				! dependency_status_database_valid; then
				dependency_package_database=unhealthy
				dependency_installed_status_file=/dev/null
			fi
			;;
		*) dependency_package_database=unhealthy dependency_installed_status_file=/dev/null ;;
	esac
}

dependency_native_feed_url() {
	awk '$1 == "src/gz" && $2 == "entware" && NF == 3 { print $3 }' "$1"
}

dependency_native_configured_architecture() {
	awk '$1 == "arch" && $2 != "all" && NF == 3 { print $2 }' "$1"
}

dependency_native_binary_probe() {
	dependency_probe_path=$1 dependency_probe_version=$2
	[ -x "$dependency_probe_path" ] && [ ! -L "$dependency_probe_path" ] || return 1
	dependency_probe_output=$("$dependency_probe_path" -V 2>&1 || :)
	case $dependency_probe_output in *"${dependency_probe_version%-*}"*) return 0 ;; *) return 1 ;; esac
}

dependency_native_option_probe() {
	dependency_probe_path=$1
	shift
	dependency_probe_output=$("$dependency_probe_path" -h 2>&1 || :)
	for dependency_probe_option in "$@"; do
		[ -n "$dependency_probe_option" ] || continue
		case $dependency_probe_output in *"$dependency_probe_option"*) ;; *) return 1 ;; esac
	done
}

dependency_native_required_closure() {
	dependency_native_nut_present=no dependency_required_closure=not_applicable
	while IFS= read -r dependency_native_nut_root; do
		if [ -n "$(dependency_status_version "$dependency_native_nut_root")" ]; then
			dependency_native_nut_present=yes
			break
		fi
	done <<EOF
$(dependency_catalog_nut_roots)
EOF
	[ "$dependency_native_nut_present" = yes ] || return 0
	dependency_required_closure=complete
	while IFS='|' read -r dependency_native_group dependency_native_package _; do
		[ "$dependency_native_group" = core ] || continue
		if [ -z "$(dependency_status_version "$dependency_native_package")" ]; then
			dependency_required_closure=missing
			return
		fi
	done <<EOF
$(dependency_catalog_packages)
EOF
	return 0
}

dependency_read_native() {
	dependency_entware_root=/opt dependency_evidence_layer=platform_probe
	if [ "${NUTMERLIN_ENABLE_TEST_ADAPTERS:-0}" = 1 ] && roots_are_isolated; then
		dependency_entware_root=$NUTMERLIN_ENTWARE_ROOT
		dependency_evidence_layer=host_native_probe
	fi
	dependency_entware_health=unhealthy dependency_package_manager=missing dependency_package_database=unhealthy
	dependency_feed_url=unknown dependency_configured_architecture=unknown
	dependency_feed_architecture=unknown dependency_feed_index_bytes=unknown dependency_feed_index_sha256=unknown
	dependency_gpgv2_version=missing dependency_gpgv2_probe=missing
	dependency_binary_probes=missing dependency_option_probes=missing
	dependency_configuration_probe=missing dependency_dummy_smoke_probe=missing
	dependency_nut_safety=clear dependency_required_closure=unknown dependency_installed_status_file=/dev/null
	case $dependency_entware_root in /*) ;; *) return 0 ;; esac
	[ -d "$dependency_entware_root" ] && [ ! -L "$dependency_entware_root" ] || return 0
	dependency_opkg_path=$dependency_entware_root/bin/opkg
	dependency_status_path=$dependency_entware_root/lib/opkg/status
	dependency_feed_config=$dependency_entware_root/etc/opkg.conf
	dependency_feed_index=$dependency_entware_root/var/opkg-lists/$dependency_catalog_feed_name
	[ -x "$dependency_opkg_path" ] && [ ! -L "$dependency_opkg_path" ] || return 0
	dependency_package_manager=available
	for dependency_required_file in "$dependency_status_path" "$dependency_feed_config" "$dependency_feed_index"; do
		[ -f "$dependency_required_file" ] && [ ! -L "$dependency_required_file" ] && [ -r "$dependency_required_file" ] || return 0
	done
	dependency_metadata_size_within "$dependency_status_path" 16777216 || return 0
	dependency_metadata_size_within "$dependency_feed_config" 65536 || return 0
	dependency_installed_status_file=$dependency_status_path
	dependency_status_database_valid || return 0
	dependency_package_database=healthy
	dependency_native_required_closure
	dependency_feed_url=$(dependency_token "$(dependency_native_feed_url "$dependency_feed_config")")
	dependency_configured_architecture=$(dependency_token "$(dependency_native_configured_architecture "$dependency_feed_config")")
	dependency_feed_architecture=$(awk '$1 == "Architecture:" { print $2; exit }' "$dependency_feed_index")
	dependency_feed_architecture=$(dependency_token "$dependency_feed_architecture")
	dependency_feed_index_bytes=$(dependency_token "$(dependency_metadata_size "$dependency_feed_index")")
	dependency_entware_health=healthy
	if [ "$dependency_feed_url" != "$dependency_catalog_configured_feed_url" ] ||
		[ "$dependency_configured_architecture" != "$dependency_catalog_feed_architecture" ] ||
		[ "$dependency_feed_architecture" != "$dependency_catalog_feed_architecture" ] ||
		[ "$dependency_feed_index_bytes" != "$dependency_catalog_index_bytes" ]; then
		return 0
	fi
	dependency_feed_index_sha256=$(sha256sum "$dependency_feed_index" 2>/dev/null | awk 'NF == 2 { print $1 }')
	dependency_feed_index_sha256=$(dependency_token "$dependency_feed_index_sha256")
	if [ "$dependency_feed_index_sha256" != "$dependency_catalog_index_sha256" ]; then
		return 0
	fi
	dependency_gpgv2_version=$(dependency_token "$(dependency_status_version gpgv2)")
	dependency_gpgv2_path=$dependency_entware_root/bin/gpgv2
	if [ -x "$dependency_gpgv2_path" ] && [ ! -L "$dependency_gpgv2_path" ]; then
		dependency_gpgv2_output=$("$dependency_gpgv2_path" --version 2>&1 || :)
		case $dependency_gpgv2_output in
			*"${dependency_gpgv2_version%-*}"*) dependency_gpgv2_probe=available ;;
		esac
	fi
	dependency_native_nut_count=0 dependency_native_binary_ok=yes dependency_native_option_ok=yes
	while IFS='|' read -r dependency_native_package dependency_native_catalog_path dependency_native_option_1 dependency_native_option_2 dependency_native_option_3 dependency_native_option_4 dependency_native_option_5 _; do
		dependency_native_version=$(dependency_status_version "$dependency_native_package")
		[ -n "$dependency_native_version" ] || continue
		dependency_native_path=$dependency_entware_root${dependency_native_catalog_path#/opt}
		dependency_native_nut_count=$((dependency_native_nut_count + 1))
		dependency_native_binary_probe "$dependency_native_path" "$dependency_native_version" || dependency_native_binary_ok=no
		dependency_native_option_probe "$dependency_native_path" \
			"$dependency_native_option_1" "$dependency_native_option_2" "$dependency_native_option_3" \
			"$dependency_native_option_4" "$dependency_native_option_5" || dependency_native_option_ok=no
	done <<EOF
$(dependency_catalog_binary_records)
EOF
	if [ "$dependency_native_nut_count" -eq 0 ]; then
		dependency_binary_probes=pending_after_mutation dependency_option_probes=pending_after_mutation
		dependency_configuration_probe=pending_after_mutation dependency_dummy_smoke_probe=pending_after_mutation
	else
		[ "$dependency_native_binary_ok" = yes ] && dependency_binary_probes=available
		[ "$dependency_native_option_ok" = yes ] && dependency_option_probes=available
		dependency_configuration_probe=requires_isolated_package_probe
		dependency_dummy_smoke_probe=requires_isolated_package_probe
	fi
}
