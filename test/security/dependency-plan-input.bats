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
	export NUTMERLIN_TEST_GPGV2_VERSION=2.4.8-1 NUTMERLIN_TEST_NUT_SAFETY=clear
	export NUTMERLIN_TEST_GPGV2_PROBE=available
	export NUTMERLIN_TEST_BINARY_PROBES=available NUTMERLIN_TEST_OPTION_PROBES=available
	export NUTMERLIN_TEST_CONFIGURATION_PROBE=available NUTMERLIN_TEST_DUMMY_SMOKE_PROBE=available
	export NUTMERLIN_TEST_REQUIRED_CLOSURE=complete
	NUTMERLIN_TEST_INSTALLED_STATUS=$NUTMERLIN_TEST_ROOT/installed.status
	export NUTMERLIN_TEST_INSTALLED_STATUS
	printf '%s\n' 'Package: gpgv2' 'Version: 2.4.8-1' 'Status: install user installed' >"$NUTMERLIN_TEST_INSTALLED_STATUS"
}

teardown() {
	host_harness_teardown
}

@test "dependency evidence is bounded and cannot inject structured output" {
	export NUTMERLIN_TEST_FEED_URL='bad"},"injected":true,'

	run "$REPOSITORY_ROOT/bin/nutmerlin" dependency-plan --json interactive

	[ "$status" -eq 78 ]
	printf '%s' "$output" | jq -e . >/dev/null
	[ "$(printf '%s' "$output" | jq -r '.entware.feed.url')" = "unknown" ]
	[ "$(printf '%s' "$output" | jq -r '.injected // false')" = "false" ]
	[ "$(printf '%s' "$output" | jq -r '.plan.disposition')" = "refuse" ]
	[ ! -e "$NUTMERLIN_EXTERNAL_CALL_LOG" ]
}

@test "test adapter refuses a symlinked installed-package database" {
	printf '%s\n' \
		'Package: gpgv2' 'Version: 2.4.8-1' 'Status: install user installed' '' \
		'Package: nut' 'Version: 2.8.4-1' 'Status: install user installed' \
		>"$NUTMERLIN_TEST_ROOT/outside.status"
	rm "$NUTMERLIN_TEST_INSTALLED_STATUS"
	ln -s "$NUTMERLIN_TEST_ROOT/outside.status" "$NUTMERLIN_TEST_INSTALLED_STATUS"

	run "$REPOSITORY_ROOT/bin/nutmerlin" dependency-plan --json interactive

	[ "$status" -eq 78 ]
	[ "$(printf '%s' "$output" | jq -r '.entware.package_database')" = "unhealthy" ]
	[ "$(printf '%s' "$output" | jq -r '.diagnostic.code')" = "package_database_unhealthy" ]
	[ "$(printf '%s' "$output" | jq -r '.plan.disposition')" = "refuse" ]
	[ ! -e "$NUTMERLIN_EXTERNAL_CALL_LOG" ]
}

@test "test adapter refuses oversized installed-package metadata" {
	dd if=/dev/zero of="$NUTMERLIN_TEST_INSTALLED_STATUS" bs=1 count=0 seek=16777217 2>/dev/null

	run "$REPOSITORY_ROOT/bin/nutmerlin" dependency-plan --json interactive

	[ "$status" -eq 78 ]
	[ "$(printf '%s' "$output" | jq -r '.entware.package_database')" = "unhealthy" ]
	[ "$(printf '%s' "$output" | jq -r '.diagnostic.code')" = "package_database_unhealthy" ]
	[ ! -e "$NUTMERLIN_EXTERNAL_CALL_LOG" ]
}

@test "dependency planning exposes no package mutation or injectable capability surface" {
	run "$REPOSITORY_ROOT/bin/nutmerlin" dependency-plan --json interactive current 'ssh;opkg upgrade'
	[ "$status" -eq 64 ]
	[ ! -e "$NUTMERLIN_EXTERNAL_CALL_LOG" ]

	run rg -n 'opkg[[:space:]]+(update|upgrade|install|remove|configure|download)' \
		"$REPOSITORY_ROOT/bin" "$REPOSITORY_ROOT/lib"
	[ "$status" -eq 1 ]
}

@test "missing native Entware returns a structured refusal instead of aborting" {
	run env \
		-u NUTMERLIN_ENABLE_TEST_ADAPTERS \
		-u NUTMERLIN_DEPENDENCY_ADAPTER \
		-u NUTMERLIN_ISOLATION_ROOT \
		-u NUTMERLIN_ENTWARE_ROOT \
		"$REPOSITORY_ROOT/bin/nutmerlin" dependency-plan --json interactive

	[ "$status" -eq 78 ]
	printf '%s' "$output" | jq -e . >/dev/null
	[ "$(printf '%s' "$output" | jq -r '.evidence_layer')" = "platform_probe" ]
	[ "$(printf '%s' "$output" | jq -r '.entware.root')" = "/opt" ]
	[ "$(printf '%s' "$output" | jq -r '.plan.disposition')" = "refuse" ]
	[ ! -e "$NUTMERLIN_EXTERNAL_CALL_LOG" ]
}
