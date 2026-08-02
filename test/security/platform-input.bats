#!/usr/bin/env bats

setup() {
	REPOSITORY_ROOT=$(cd "$BATS_TEST_DIRNAME/../.." && pwd)
	# shellcheck source=test/lib/host-harness.sh
	. "$REPOSITORY_ROOT/test/lib/host-harness.sh"
	host_harness_setup
	export NUTMERLIN_ENABLE_TEST_ADAPTERS=1 NUTMERLIN_PLATFORM_ADAPTER=mock
	export NUTMERLIN_PLATFORM_FIRMWARE_FAMILY=3004.388.x NUTMERLIN_PLATFORM_FIRMWARE_VERSION=3004.388.8
	export NUTMERLIN_PLATFORM_ARCHITECTURE=aarch64 NUTMERLIN_PLATFORM_MODEL=RT-TEST NUTMERLIN_PLATFORM_HARDWARE_REVISION=A1
	export NUTMERLIN_TEST_QUALIFIED_3004=3004.388.8 NUTMERLIN_TEST_QUALIFIED_3006=3006.102.5 NUTMERLIN_TEST_INCOMPATIBILITY_SCOPE=none
	for probe_name in FIRMWARE ARCHITECTURE HOOKS ADDONS_API FIREWALL PROCESS_IDENTITY MOUNTS BOOT_IDENTITY CLOCK_EVIDENCE RESOURCE_LIMITS; do
		export "NUTMERLIN_PROBE_$probe_name=available"
	done
}

teardown() {
	host_harness_teardown
}

@test "invalid or oversized adapter evidence is bounded and fails closed" {
	export NUTMERLIN_PLATFORM_MODEL='bad"},"injected":true,'
	export NUTMERLIN_PROBE_HOOKS='available; service restart'
	export NUTMERLIN_PLATFORM_HARDWARE_REVISION=$(printf '%097d' 0)

	run "$REPOSITORY_ROOT/bin/nutmerlin" platform-eligibility --json

	[ "$status" -eq 78 ]
	[ "$(printf '%s' "$output" | jq -r '.platform.model')" = "unknown" ]
	[ "$(printf '%s' "$output" | jq -r '.platform.hardware_revision')" = "unknown" ]
	[ "$(printf '%s' "$output" | jq -r '.diagnostic.capability')" = "hooks" ]
	[ "$(printf '%s' "$output" | jq -r '.injected // false')" = "false" ]
	[ ! -e "$NUTMERLIN_EXTERNAL_CALL_LOG" ]
}

@test "mock qualification evidence is refused outside the isolated test gate" {
	unset NUTMERLIN_ENABLE_TEST_ADAPTERS

	run "$REPOSITORY_ROOT/bin/nutmerlin" platform-eligibility --json

	[ "$status" -eq 78 ]
	[ "$(printf '%s' "$output" | jq -r '.evidence_layer')" = "invalid" ]
	[ "$(printf '%s' "$output" | jq -r '.support.class')" = "ineligible" ]
}

@test "arbitrary normalized or cross-family versions never become supported" {
	export NUTMERLIN_PLATFORM_FIRMWARE_VERSION=foo NUTMERLIN_TEST_QUALIFIED_3004=foo
	run "$REPOSITORY_ROOT/bin/nutmerlin" platform-eligibility --json
	[ "$(printf '%s' "$output" | jq -r '.support.class')" = "ineligible" ]
	[ "$(printf '%s' "$output" | jq -r '.platform.qualified_stable')" = "none" ]

	oversized_version=$(printf '%097d' 0)
	export NUTMERLIN_PLATFORM_FIRMWARE_VERSION=$oversized_version NUTMERLIN_TEST_QUALIFIED_3004=$oversized_version
	run "$REPOSITORY_ROOT/bin/nutmerlin" platform-eligibility --json
	[ "$(printf '%s' "$output" | jq -r '.support.class')" = "ineligible" ]

	export NUTMERLIN_PLATFORM_FIRMWARE_VERSION=3006.102.5 NUTMERLIN_TEST_QUALIFIED_3004=3006.102.5
	run "$REPOSITORY_ROOT/bin/nutmerlin" platform-eligibility --json
	[ "$(printf '%s' "$output" | jq -r '.support.class')" = "ineligible" ]

	for malformed_version in 3004.388.8garbage 3004.388._1 3004.388.8__1; do
		export NUTMERLIN_PLATFORM_FIRMWARE_VERSION=$malformed_version NUTMERLIN_TEST_QUALIFIED_3004=$malformed_version
		run "$REPOSITORY_ROOT/bin/nutmerlin" platform-eligibility --json
		[ "$(printf '%s' "$output" | jq -r '.support.class')" = "ineligible" ]
	done
}
