#!/usr/bin/env bats

setup() {
	REPOSITORY_ROOT=$(cd "$BATS_TEST_DIRNAME/../.." && pwd)
	# shellcheck source=test/lib/host-harness.sh
	. "$REPOSITORY_ROOT/test/lib/host-harness.sh"
	host_harness_setup
	export NUTMERLIN_ENABLE_TEST_ADAPTERS=1 NUTMERLIN_DEPENDENCY_ADAPTER=mock
	export NUTMERLIN_TEST_ENTWARE_HEALTH=healthy NUTMERLIN_TEST_PACKAGE_DATABASE=healthy
	export NUTMERLIN_TEST_FEED_URL=http://bin.entware.net/aarch64-k3.10
	export NUTMERLIN_TEST_CONFIGURED_ARCHITECTURE=aarch64-3.10
	export NUTMERLIN_TEST_FEED_ARCHITECTURE=aarch64-3.10
	export NUTMERLIN_TEST_FEED_INDEX_BYTES=1659256
	export NUTMERLIN_TEST_FEED_INDEX_SHA256=b1f04218d93d967d79fdf8d58badd759c3fd44dda4edeb2d68670f9fbbff1283
	export NUTMERLIN_TEST_GPGV2_VERSION=2.4.8-1
	export NUTMERLIN_TEST_GPGV2_PROBE=available
	export NUTMERLIN_TEST_BINARY_PROBES=available NUTMERLIN_TEST_OPTION_PROBES=available
	export NUTMERLIN_TEST_CONFIGURATION_PROBE=available NUTMERLIN_TEST_DUMMY_SMOKE_PROBE=available
	export NUTMERLIN_TEST_NUT_SAFETY=clear
	export NUTMERLIN_TEST_REQUIRED_CLOSURE=complete
	NUTMERLIN_TEST_INSTALLED_STATUS=$NUTMERLIN_TEST_ROOT/installed.status
	export NUTMERLIN_TEST_INSTALLED_STATUS
	: >"$NUTMERLIN_TEST_INSTALLED_STATUS"
}

teardown() {
	host_harness_teardown
}

install_status() {
	for package_record in "$@"; do
		package_name=${package_record%%=*}
		package_version=${package_record#*=}
		printf 'Package: %s\nVersion: %s\nStatus: install user installed\n\n' \
			"$package_name" "$package_version" >>"$NUTMERLIN_TEST_INSTALLED_STATUS"
	done
}

@test "current coherent dependency cohort produces a no-change dry-run" {
	install_status \
		gpgv2=2.4.8-1 \
		nut=2.8.4-1 nut-common=2.8.4-1 nut-server=2.8.4-1 nut-upsc=2.8.4-1 \
		nut-driver-usbhid-ups=2.8.4-1 nut-driver-dummy-ups=2.8.4-1

	run "$REPOSITORY_ROOT/bin/nutmerlin" dependency-plan --json interactive

	[ "$status" -eq 78 ]
	[ "$(printf '%s' "$output" | jq -r '.operation')" = "dependency.plan.v1" ]
	[ "$(printf '%s' "$output" | jq -r '.evidence_layer')" = "host_simulation" ]
	[ "$(printf '%s' "$output" | jq -r '.cohort.state')" = "current" ]
	[ "$(printf '%s' "$output" | jq -r '.plan.disposition')" = "no_changes" ]
	[ "$(printf '%s' "$output" | jq -r '.plan.mutations | length')" -eq 0 ]
	[ "$(printf '%s' "$output" | jq -r '.dry_run')" = "true" ]
	[ "$(printf '%s' "$output" | jq -r '.mutation_authority')" = "refuse" ]
	[ ! -e "$NUTMERLIN_EXTERNAL_CALL_LOG" ]
}

@test "fresh plan installs only the complete required current cohort" {
	install_status gpgv2=2.4.8-1

	run "$REPOSITORY_ROOT/bin/nutmerlin" dependency-plan --json interactive

	[ "$status" -eq 78 ]
	[ "$(printf '%s' "$output" | jq -r '.cohort.state')" = "absent" ]
	[ "$(printf '%s' "$output" | jq -r '.selected_capabilities | length')" -eq 0 ]
	[ "$(printf '%s' "$output" | jq -r '.plan.disposition')" = "proposed" ]
	[ "$(printf '%s' "$output" | jq -r '.plan.mutations | length')" -eq 27 ]
	[ "$(printf '%s' "$output" | jq -r '[.plan.mutations[] | select(.action != "install")] | length')" -eq 0 ]
	for package_name in nut nut-common nut-server nut-upsc nut-driver-usbhid-ups nut-driver-dummy-ups libnetsnmp-ssl; do
		[ "$(printf '%s' "$output" | jq --arg package_name "$package_name" -r '[.plan.mutations[] | select(.package == $package_name)] | length')" -eq 1 ]
	done
	[ "$(printf '%s' "$output" | jq -r '[.plan.mutations[] | select(.package == "nut-upscmd" or .package == "nut-upsrw" or .package == "nut-upsmon" or .package == "nut-upssched" or .package == "nut-web-cgi" or .package == "nut-avahi" or .package == "nut-driver-snmp-ups")] | length')" -eq 0 ]
	[ "$(printf '%s' "$output" | jq -r '.space.transaction_bytes')" -eq 14663680 ]
	[ "$(printf '%s' "$output" | jq -r '.space.temporary_bytes')" -eq 5718248 ]
	[ "$(printf '%s' "$output" | jq -r '.space.required_bytes')" -eq 37159144 ]
	[ "$(printf '%s' "$output" | jq -r '[.plan.mutations[] | select(.architecture != "aarch64-3.10" or .sha256 == "unknown")] | length')" -eq 0 ]
	[ ! -e "$NUTMERLIN_EXTERNAL_CALL_LOG" ]
}

@test "fresh planning leaves an already installed compatible transitive package unchanged" {
	install_status gpgv2=2.4.8-1 libc=2.26-1

	run "$REPOSITORY_ROOT/bin/nutmerlin" dependency-plan --json interactive

	[ "$(printf '%s' "$output" | jq -r '.plan.disposition')" = "proposed" ]
	[ "$(printf '%s' "$output" | jq -r '.plan.mutations | length')" -eq 26 ]
	[ "$(printf '%s' "$output" | jq -r '[.plan.mutations[] | select(.package == "libc")] | length')" -eq 0 ]
	[ "$(printf '%s' "$output" | jq -r '[.plan.mutations[] | select(.action == "upgrade" or .action == "remove")] | length')" -eq 0 ]
	[ "$(printf '%s' "$output" | jq -r '.catalog.package_provenance[] | select(.package == "libc") | .observed_version')" = "2.26-1" ]
}

@test "interactive planning defaults a coherent older NUT cohort to a scoped current upgrade" {
	install_status \
		gpgv2=2.4.8-1 \
		nut=2.8.3-1 nut-common=2.8.3-1 nut-server=2.8.3-1 nut-upsc=2.8.3-1 \
		nut-driver-usbhid-ups=2.8.3-1 nut-driver-dummy-ups=2.8.3-1

	run "$REPOSITORY_ROOT/bin/nutmerlin" dependency-plan --json interactive

	[ "$status" -eq 78 ]
	[ "$(printf '%s' "$output" | jq -r '.dependency_policy')" = "current" ]
	[ "$(printf '%s' "$output" | jq -r '.cohort.state')" = "compatible_older" ]
	[ "$(printf '%s' "$output" | jq -r '.plan.disposition')" = "proposed" ]
	[ "$(printf '%s' "$output" | jq -r '.plan.mutations | length')" -eq 6 ]
	[ "$(printf '%s' "$output" | jq -r '[.plan.mutations[] | select(.action != "upgrade" or .from != "2.8.3-1" or .to != "2.8.4-1")] | length')" -eq 0 ]
	[ "$(printf '%s' "$output" | jq -r '.space.transaction_bytes')" -eq 1146880 ]
	[ "$(printf '%s' "$output" | jq -r '.space.temporary_bytes')" -eq 395079 ]

	export NUTMERLIN_TEST_CONFIGURATION_PROBE=missing NUTMERLIN_TEST_DUMMY_SMOKE_PROBE=missing
	run "$REPOSITORY_ROOT/bin/nutmerlin" dependency-plan --json interactive current
	[ "$(printf '%s' "$output" | jq -r '.cohort.state')" = "older_unprobed" ]
	[ "$(printf '%s' "$output" | jq -r '.plan.disposition')" = "proposed" ]
	[ "$(printf '%s' "$output" | jq -r '.plan.mutations | length')" -eq 6 ]
	[ "$(printf '%s' "$output" | jq -r '.diagnostic.code')" = "coherent_older_upgrade_plan" ]
	[ ! -e "$NUTMERLIN_EXTERNAL_CALL_LOG" ]
}

@test "interactive planning explicitly keeps an older cohort only after mandatory probes" {
	install_status \
		gpgv2=2.4.8-1 \
		nut=2.8.3-1 nut-common=2.8.3-1 nut-server=2.8.3-1 nut-upsc=2.8.3-1 \
		nut-driver-usbhid-ups=2.8.3-1 nut-driver-dummy-ups=2.8.3-1

	run "$REPOSITORY_ROOT/bin/nutmerlin" dependency-plan --json interactive keep-compatible

	[ "$status" -eq 78 ]
	[ "$(printf '%s' "$output" | jq -r '.dependency_policy')" = "keep-compatible" ]
	[ "$(printf '%s' "$output" | jq -r '.cohort.state')" = "compatible_older" ]
	[ "$(printf '%s' "$output" | jq -r '.cohort.compatibility_diagnostic')" = "persistent" ]
	[ "$(printf '%s' "$output" | jq -r '.cohort.current_hardware_qualification')" = "ineligible" ]
	[ "$(printf '%s' "$output" | jq -r '.plan.disposition')" = "no_changes" ]
	[ "$(printf '%s' "$output" | jq -r '.plan.mutations | length')" -eq 0 ]

	export NUTMERLIN_TEST_OPTION_PROBES=missing
	run "$REPOSITORY_ROOT/bin/nutmerlin" dependency-plan --json interactive keep-compatible
	[ "$(printf '%s' "$output" | jq -r '.cohort.state')" = "older_unprobed" ]
	[ "$(printf '%s' "$output" | jq -r '.cohort.compatibility_diagnostic')" = "none" ]
	[ "$(printf '%s' "$output" | jq -r '.plan.disposition')" = "refuse" ]
	[ "$(printf '%s' "$output" | jq -r '.diagnostic.code')" = "mandatory_compatibility_probe_failed" ]

	export NUTMERLIN_TEST_OPTION_PROBES=available NUTMERLIN_TEST_DUMMY_SMOKE_PROBE=missing
	run "$REPOSITORY_ROOT/bin/nutmerlin" dependency-plan --json interactive keep-compatible
	[ "$(printf '%s' "$output" | jq -r '.cohort.state')" = "older_unprobed" ]
	[ "$(printf '%s' "$output" | jq -r '.cohort.dummy_smoke_probe')" = "missing" ]
	[ "$(printf '%s' "$output" | jq -r '.plan.disposition')" = "refuse" ]
	[ ! -e "$NUTMERLIN_EXTERNAL_CALL_LOG" ]
}

@test "compatibility-only keep may install selected missing requirements without upgrading NUT" {
	install_status \
		gpgv2=2.4.8-1 \
		nut=2.8.3-1 nut-common=2.8.3-1 nut-server=2.8.3-1 nut-upsc=2.8.3-1 \
		nut-driver-usbhid-ups=2.8.3-1 nut-driver-dummy-ups=2.8.3-1

	run "$REPOSITORY_ROOT/bin/nutmerlin" dependency-plan --json interactive keep-compatible ssh

	[ "$(printf '%s' "$output" | jq -r '.plan.disposition')" = "proposed" ]
	[ "$(printf '%s' "$output" | jq -r '.plan.mutations | length')" -eq 3 ]
	[ "$(printf '%s' "$output" | jq -r '[.plan.mutations[] | select((.package | startswith("openssh-")) and .action == "install")] | length')" -eq 3 ]
	[ "$(printf '%s' "$output" | jq -r '[.plan.mutations[] | select(.package | startswith("nut"))] | length')" -eq 0 ]
	[ "$(printf '%s' "$output" | jq -r '.cohort.compatibility_diagnostic')" = "persistent" ]
}

@test "unattended mutation requires an explicit dependency policy" {
	install_status gpgv2=2.4.8-1

	run "$REPOSITORY_ROOT/bin/nutmerlin" dependency-plan --json unattended none

	[ "$status" -eq 78 ]
	[ "$(printf '%s' "$output" | jq -r '.plan.disposition')" = "refuse" ]
	[ "$(printf '%s' "$output" | jq -r '.plan.mutations | length')" -eq 27 ]
	[ "$(printf '%s' "$output" | jq -r '.diagnostic.code')" = "explicit_dependency_policy_required" ]

	run "$REPOSITORY_ROOT/bin/nutmerlin" dependency-plan --json unattended current
	[ "$(printf '%s' "$output" | jq -r '.plan.disposition')" = "proposed" ]
	[ "$(printf '%s' "$output" | jq -r '.diagnostic.code')" = "fresh_current_cohort_plan" ]
	[ ! -e "$NUTMERLIN_EXTERNAL_CALL_LOG" ]
}

@test "SSH packages appear only when the SSH capability is explicitly selected" {
	install_status \
		gpgv2=2.4.8-1 \
		nut=2.8.4-1 nut-common=2.8.4-1 nut-server=2.8.4-1 nut-upsc=2.8.4-1 \
		nut-driver-usbhid-ups=2.8.4-1 nut-driver-dummy-ups=2.8.4-1

	run "$REPOSITORY_ROOT/bin/nutmerlin" dependency-plan --json interactive current none
	[ "$(printf '%s' "$output" | jq -r '[.catalog.package_provenance[] | select(.package | startswith("openssh-"))] | length')" -eq 0 ]

	run "$REPOSITORY_ROOT/bin/nutmerlin" dependency-plan --json interactive current ssh
	[ "$status" -eq 78 ]
	[ "$(printf '%s' "$output" | jq -r '.selected_capabilities[0]')" = "ssh" ]
	[ "$(printf '%s' "$output" | jq -r '.plan.disposition')" = "proposed" ]
	[ "$(printf '%s' "$output" | jq -r '.plan.mutations | length')" -eq 3 ]
	[ "$(printf '%s' "$output" | jq -r '[.plan.mutations[] | select((.package | startswith("openssh-")) and .to == "10.2_p1-1")] | length')" -eq 3 ]
	[ ! -e "$NUTMERLIN_EXTERNAL_CALL_LOG" ]
}

@test "untrusted feed and verifier prerequisites refuse without adding repair actions" {
	install_status gpgv2=2.4.8-1

	export NUTMERLIN_TEST_CONFIGURED_ARCHITECTURE=armv7-3.2
	run "$REPOSITORY_ROOT/bin/nutmerlin" dependency-plan --json interactive
	[ "$(printf '%s' "$output" | jq -r '.plan.disposition')" = "refuse" ]
	[ "$(printf '%s' "$output" | jq -r '.diagnostic.code')" = "unsupported_configured_architecture" ]

	export NUTMERLIN_TEST_CONFIGURED_ARCHITECTURE=aarch64-3.10
	export NUTMERLIN_TEST_FEED_ARCHITECTURE=armv7-3.2
	run "$REPOSITORY_ROOT/bin/nutmerlin" dependency-plan --json interactive
	[ "$(printf '%s' "$output" | jq -r '.plan.disposition')" = "refuse" ]
	[ "$(printf '%s' "$output" | jq -r '.diagnostic.code')" = "unsupported_feed_architecture" ]

	export NUTMERLIN_TEST_FEED_ARCHITECTURE=aarch64-3.10
	export NUTMERLIN_TEST_FEED_INDEX_BYTES=1
	run "$REPOSITORY_ROOT/bin/nutmerlin" dependency-plan --json interactive
	[ "$(printf '%s' "$output" | jq -r '.diagnostic.code')" = "feed_catalog_size_mismatch" ]

	export NUTMERLIN_TEST_FEED_INDEX_BYTES=1659256
	export NUTMERLIN_TEST_FEED_INDEX_SHA256=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
	run "$REPOSITORY_ROOT/bin/nutmerlin" dependency-plan --json interactive
	[ "$(printf '%s' "$output" | jq -r '.diagnostic.code')" = "feed_catalog_mismatch" ]

	export NUTMERLIN_TEST_FEED_INDEX_SHA256=b1f04218d93d967d79fdf8d58badd759c3fd44dda4edeb2d68670f9fbbff1283
	export NUTMERLIN_TEST_GPGV2_VERSION=missing
	run "$REPOSITORY_ROOT/bin/nutmerlin" dependency-plan --json interactive
	[ "$(printf '%s' "$output" | jq -r '.diagnostic.code')" = "gpgv2_prerequisite_mismatch" ]
	[ "$(printf '%s' "$output" | jq -r '[.plan.mutations[] | select(.package == "gpgv2")] | length')" -eq 0 ]

	export NUTMERLIN_TEST_GPGV2_VERSION=2.4.8-1 NUTMERLIN_TEST_GPGV2_PROBE=missing
	run "$REPOSITORY_ROOT/bin/nutmerlin" dependency-plan --json interactive
	[ "$(printf '%s' "$output" | jq -r '.diagnostic.code')" = "gpgv2_binary_probe_failed" ]
	[ ! -e "$NUTMERLIN_EXTERNAL_CALL_LOG" ]
}

@test "mixed incomplete unsafe and newer cohorts fail closed without repair or downgrade" {
	install_status gpgv2=2.4.8-1 nut=2.8.4-1 nut-common=2.8.4-1 nut-server=2.8.4-1 nut-upsc=2.8.4-1 nut-driver-usbhid-ups=2.8.4-1
	run "$REPOSITORY_ROOT/bin/nutmerlin" dependency-plan --json interactive
	[ "$(printf '%s' "$output" | jq -r '.cohort.state')" = "incomplete" ]
	[ "$(printf '%s' "$output" | jq -r '.diagnostic.code')" = "scoped_nut_repair_required" ]
	[ "$(printf '%s' "$output" | jq -r '.plan.mutations | length')" -eq 0 ]

	: >"$NUTMERLIN_TEST_INSTALLED_STATUS"
	install_status gpgv2=2.4.8-1 nut=2.8.4-1 nut-common=2.8.4-1 nut-server=2.8.4-1 nut-upsc=2.8.4-1 nut-driver-usbhid-ups=2.8.4-1 nut-driver-dummy-ups=2.8.3-1
	run "$REPOSITORY_ROOT/bin/nutmerlin" dependency-plan --json interactive
	[ "$(printf '%s' "$output" | jq -r '.cohort.state')" = "mixed" ]
	[ "$(printf '%s' "$output" | jq -r '.diagnostic.code')" = "scoped_nut_repair_required" ]

	: >"$NUTMERLIN_TEST_INSTALLED_STATUS"
	install_status gpgv2=2.4.8-1 nut=2.8.5-1 nut-common=2.8.5-1 nut-server=2.8.5-1 nut-upsc=2.8.5-1 nut-driver-usbhid-ups=2.8.5-1 nut-driver-dummy-ups=2.8.5-1
	run "$REPOSITORY_ROOT/bin/nutmerlin" dependency-plan --json interactive current
	[ "$(printf '%s' "$output" | jq -r '.cohort.state')" = "newer" ]
	[ "$(printf '%s' "$output" | jq -r '.diagnostic.code')" = "automatic_downgrade_forbidden" ]
	[ "$(printf '%s' "$output" | jq -r '.plan.mutations | length')" -eq 0 ]

	export NUTMERLIN_TEST_NUT_SAFETY=unsafe
	run "$REPOSITORY_ROOT/bin/nutmerlin" dependency-plan --json interactive current
	[ "$(printf '%s' "$output" | jq -r '.diagnostic.code')" = "known_unsafe_cohort" ]
	[ "$(printf '%s' "$output" | jq -r '.plan.disposition')" = "refuse" ]
	[ ! -e "$NUTMERLIN_EXTERNAL_CALL_LOG" ]
}

@test "an installed NUT cohort with a missing required transitive dependency is refused" {
	install_status \
		gpgv2=2.4.8-1 \
		nut=2.8.4-1 nut-common=2.8.4-1 nut-server=2.8.4-1 nut-upsc=2.8.4-1 \
		nut-driver-usbhid-ups=2.8.4-1 nut-driver-dummy-ups=2.8.4-1
	export NUTMERLIN_TEST_REQUIRED_CLOSURE=missing

	run "$REPOSITORY_ROOT/bin/nutmerlin" dependency-plan --json interactive

	[ "$(printf '%s' "$output" | jq -r '.cohort.required_dependency_closure')" = "missing" ]
	[ "$(printf '%s' "$output" | jq -r '.diagnostic.code')" = "required_dependency_closure_incomplete" ]
	[ "$(printf '%s' "$output" | jq -r '.plan.disposition')" = "refuse" ]
	[ "$(printf '%s' "$output" | jq -r '.plan.mutations | length')" -eq 0 ]
}

@test "a conflicting historical libnetsnmp provider is refused rather than replaced" {
	install_status gpgv2=2.4.8-1 libnetsnmp-nossl=5.9.4-1

	run "$REPOSITORY_ROOT/bin/nutmerlin" dependency-plan --json interactive

	[ "$(printf '%s' "$output" | jq -r '.diagnostic.code')" = "conflicting_libnetsnmp_provider" ]
	[ "$(printf '%s' "$output" | jq -r '.plan.disposition')" = "refuse" ]
	[ "$(printf '%s' "$output" | jq -r '.plan.mutations | length')" -eq 0 ]
	[ "$(printf '%s' "$output" | jq -r '.plan.retained_packages | length')" -eq 0 ]
}

@test "ordinary uninstall retains every Entware package" {
	install_status gpgv2=2.4.8-1 nut=2.8.4-1 foreign-addon-package=7.0-2

	run "$REPOSITORY_ROOT/bin/nutmerlin" dependency-plan --json uninstall

	[ "$status" -eq 78 ]
	[ "$(printf '%s' "$output" | jq -r '.mode')" = "uninstall" ]
	[ "$(printf '%s' "$output" | jq -r '.plan.disposition')" = "retain_all" ]
	[ "$(printf '%s' "$output" | jq -r '.plan.mutations | length')" -eq 0 ]
	[ "$(printf '%s' "$output" | jq -r '.plan.retained_packages | length')" -eq 3 ]
	[ "$(printf '%s' "$output" | jq -r '[.plan.retained_packages[] | select(.package == "foreign-addon-package" and .version == "7.0-2")] | length')" -eq 1 ]
	[ "$(printf '%s' "$output" | jq -r '.diagnostic.code')" = "ordinary_uninstall_retains_entware" ]
	[ ! -e "$NUTMERLIN_EXTERNAL_CALL_LOG" ]
}

@test "native adapter inspects the selected Entware root without invoking its package manager" {
	export NUTMERLIN_DEPENDENCY_ADAPTER=native
	mkdir -p "$NUTMERLIN_ENTWARE_ROOT/bin" "$NUTMERLIN_ENTWARE_ROOT/etc" \
		"$NUTMERLIN_ENTWARE_ROOT/lib/opkg" "$NUTMERLIN_ENTWARE_ROOT/var/opkg-lists"
	printf '%s\n' '#!/bin/sh' 'exit 99' >"$NUTMERLIN_ENTWARE_ROOT/bin/opkg"
	chmod 700 "$NUTMERLIN_ENTWARE_ROOT/bin/opkg"
	printf '%s\n' 'src/gz entware http://bin.entware.net/aarch64-k3.10' 'arch all 100' 'arch aarch64-3.10 160' >"$NUTMERLIN_ENTWARE_ROOT/etc/opkg.conf"
	printf '%s\n' 'Package: gpgv2' 'Version: 2.4.8-1' 'Status: install user installed' >"$NUTMERLIN_ENTWARE_ROOT/lib/opkg/status"
	printf '%s\n' 'Package: fixture' 'Architecture: aarch64-3.10' 'test fixture is intentionally not the release feed index' >"$NUTMERLIN_ENTWARE_ROOT/var/opkg-lists/entware"
	printf '%s\n' '#!/bin/sh' 'printf "%s\n" gpgv2-probed >>"$NUTMERLIN_EXTERNAL_CALL_LOG"' 'printf "%s\n" "gpgv (GnuPG) 2.4.8"' >"$NUTMERLIN_ENTWARE_ROOT/bin/gpgv2"
	chmod 700 "$NUTMERLIN_ENTWARE_ROOT/bin/gpgv2"

	run "$REPOSITORY_ROOT/bin/nutmerlin" dependency-plan --json interactive

	[ "$status" -eq 78 ]
	[ "$(printf '%s' "$output" | jq -r '.evidence_layer')" = "host_native_probe" ]
	[ "$(printf '%s' "$output" | jq -r '.entware.root')" = "$NUTMERLIN_ENTWARE_ROOT" ]
	[ "$(printf '%s' "$output" | jq -r '.entware.health')" = "healthy" ]
	[ "$(printf '%s' "$output" | jq -r '.entware.package_database')" = "healthy" ]
	[ "$(printf '%s' "$output" | jq -r '.diagnostic.code')" = "feed_catalog_size_mismatch" ]
	[ ! -e "$NUTMERLIN_EXTERNAL_CALL_LOG" ]
}

@test "planner reports the exact verifier binary and NUT option contract" {
	install_status \
		gpgv2=2.4.8-1 \
		nut=2.8.4-1 nut-common=2.8.4-1 nut-server=2.8.4-1 nut-upsc=2.8.4-1 \
		nut-driver-usbhid-ups=2.8.4-1 nut-driver-dummy-ups=2.8.4-1

	run "$REPOSITORY_ROOT/bin/nutmerlin" dependency-plan --json interactive

	[ "$(printf '%s' "$output" | jq -r '.catalog.required_binaries | length')" -eq 5 ]
	[ "$(printf '%s' "$output" | jq -r '.entware.feed.url')" = "http://bin.entware.net/aarch64-k3.10" ]
	[ "$(printf '%s' "$output" | jq -r '.entware.feed.catalog_url')" = "https://bin.entware.net/aarch64-k3.10" ]
	[ "$(printf '%s' "$output" | jq -r '.entware.feed.catalog_index_bytes')" -eq 1659256 ]
	[ "$(printf '%s' "$output" | jq -r '.catalog.required_roots | length')" -eq 6 ]
	[ "$(printf '%s' "$output" | jq -r '.catalog.optional_roots.ssh | length')" -eq 3 ]
	[ "$(printf '%s' "$output" | jq -r '.catalog.virtual_providers.libnetsnmp')" = "libnetsnmp-ssl" ]
	[ "$(printf '%s' "$output" | jq -r '.catalog.package_relationships | length')" -eq 30 ]
	[ "$(printf '%s' "$output" | jq -r '.catalog.package_relationships[] | select(.package == "nut-common") | .depends')" = "libc, libssp, librt, libpthread, nut, libnetsnmp, libusb-compat, libneon, libopenssl" ]
	[ "$(printf '%s' "$output" | jq -r '.catalog.package_relationships[] | select(.package == "libnetsnmp-ssl") | .provides')" = "libnetsnmp-ssl-any, libnetsnmp" ]
	[ "$(printf '%s' "$output" | jq -r '[.catalog.required_binaries[] | select(.path == "/opt/sbin/upsd" and (.required_options | contains("-F")))] | length')" -eq 1 ]
	[ "$(printf '%s' "$output" | jq -r '[.catalog.required_binaries[] | select(.path == "/opt/sbin/upsdrvctl" and (.required_options | contains("-t")))] | length')" -eq 1 ]
	[ "$(printf '%s' "$output" | jq -r '[.catalog.required_binaries[] | select(.path == "/opt/lib/nut/usbhid-ups" and (.required_options | contains("-a")))] | length')" -eq 1 ]
	[ "$(printf '%s' "$output" | jq -r '[.catalog.required_binaries[] | select(.required_options | contains("NUT_CONFPATH"))] | length')" -eq 0 ]
	[ "$(printf '%s' "$output" | jq -r '[.catalog.required_binaries[] | select(.path == "/opt/sbin/upsd" and .environment_contract == "NUT_CONFPATH")] | length')" -eq 1 ]
	[ "$(printf '%s' "$output" | jq -r '.prerequisites.gpgv2.path')" = "/opt/bin/gpgv2" ]
	[ "$(printf '%s' "$output" | jq -r '.prerequisites.gpgv2.install_policy')" = "preexisting_only" ]
	[ "$(printf '%s' "$output" | jq -r '.prerequisites.gpgv2.sha256')" = "2df7a6554da8a7704bee6ec586aa4a5e1696e49e0663fb312d806bb0534be906" ]
	[ "$(printf '%s' "$output" | jq -r '.cohort.compatibility_metadata_source')" = "release_catalog" ]
}
