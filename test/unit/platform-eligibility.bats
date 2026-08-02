#!/usr/bin/env bats

setup() {
	REPOSITORY_ROOT=$(cd "$BATS_TEST_DIRNAME/../.." && pwd)
	# shellcheck source=test/lib/host-harness.sh
	. "$REPOSITORY_ROOT/test/lib/host-harness.sh"
	host_harness_setup
}

teardown() {
	host_harness_teardown
}

set_probe_safe_profile() {
	export NUTMERLIN_ENABLE_TEST_ADAPTERS=1 NUTMERLIN_PLATFORM_ADAPTER=mock
	export NUTMERLIN_PLATFORM_FIRMWARE_FAMILY=3004.388.x NUTMERLIN_PLATFORM_FIRMWARE_VERSION=3004.388.8
	export NUTMERLIN_PLATFORM_ARCHITECTURE=aarch64 NUTMERLIN_PLATFORM_MODEL=RT-TEST NUTMERLIN_PLATFORM_HARDWARE_REVISION=A1
	export NUTMERLIN_TEST_QUALIFIED_3004=3004.388.8 NUTMERLIN_TEST_QUALIFIED_3006=3006.102.5 NUTMERLIN_TEST_INCOMPATIBILITY_SCOPE=none
	export NUTMERLIN_PROBE_FIRMWARE=available NUTMERLIN_PROBE_ARCHITECTURE=available NUTMERLIN_PROBE_HOOKS=available
	export NUTMERLIN_PROBE_ADDONS_API=available NUTMERLIN_PROBE_FIREWALL=available NUTMERLIN_PROBE_PROCESS_IDENTITY=available
	export NUTMERLIN_PROBE_MOUNTS=available NUTMERLIN_PROBE_BOOT_IDENTITY=available
	export NUTMERLIN_PROBE_CLOCK_EVIDENCE=available NUTMERLIN_PROBE_RESOURCE_LIMITS=available
}

@test "exact qualified simulation reports support without authorizing install" {
	set_probe_safe_profile

	run "$REPOSITORY_ROOT/bin/nutmerlin" platform-eligibility --json

	[ "$status" -eq 78 ]
	[ "$(printf '%s' "$output" | jq -r '.operation')" = "platform.eligibility.v1" ]
	[ "$(printf '%s' "$output" | jq -r '.support.class')" = "supported" ]
	[ "$(printf '%s' "$output" | jq -r '.support.code')" = "qualified_current_platform" ]
	[ "$(printf '%s' "$output" | jq -r '.installation.disposition')" = "refuse" ]
	[ "$(printf '%s' "$output" | jq -r '.support.acknowledgment_required')" = "false" ]
	[ "$(printf '%s' "$output" | jq -r '[.installation[] | select(. == "allow" or . == "allow_with_acknowledgment")] | length')" -eq 0 ]
	[ "$(printf '%s' "$output" | jq -r '.diagnostic.code')" = "simulation_evidence_only" ]
	[ "$(printf '%s' "$output" | jq -r '.evidence_layer')" = "host_simulation" ]
	[ "$(printf '%s' "$output" | jq -r '.platform.model')" = "RT-TEST" ]
	[ "$(printf '%s' "$output" | jq -r '.platform.hardware_revision')" = "A1" ]
	[ ! -e "$NUTMERLIN_EXTERNAL_CALL_LOG" ]
}

@test "recognized current-family firmware without exact qualification is compatibility only" {
	set_probe_safe_profile
	export NUTMERLIN_PLATFORM_FIRMWARE_FAMILY=3006.102.x
	export NUTMERLIN_PLATFORM_FIRMWARE_VERSION=3006.102.4

	run "$REPOSITORY_ROOT/bin/nutmerlin" platform-eligibility --json

	[ "$status" -eq 78 ]
	[ "$(printf '%s' "$output" | jq -r '.support.class')" = "compatibility_only" ]
	[ "$(printf '%s' "$output" | jq -r '.support.acknowledgment_required')" = "true" ]
	[ "$(printf '%s' "$output" | jq -r '.support.code')" = "firmware_not_qualified_stable" ]

	export NUTMERLIN_PLATFORM_FIRMWARE_VERSION=3006.102.5
	run "$REPOSITORY_ROOT/bin/nutmerlin" platform-eligibility --json
	[ "$status" -eq 78 ]
	[ "$(printf '%s' "$output" | jq -r '.support.class')" = "supported" ]
}

@test "Merlin 386 on ARMv7 is legacy best effort with acknowledgment" {
	set_probe_safe_profile
	export NUTMERLIN_PLATFORM_FIRMWARE_FAMILY=386.x
	export NUTMERLIN_PLATFORM_FIRMWARE_VERSION=386.14
	export NUTMERLIN_PLATFORM_ARCHITECTURE=armv7l

	run "$REPOSITORY_ROOT/bin/nutmerlin" platform-eligibility --json

	[ "$status" -eq 78 ]
	[ "$(printf '%s' "$output" | jq -r '.support.class')" = "legacy_best_effort" ]
	[ "$(printf '%s' "$output" | jq -r '.support.acknowledgment_required')" = "true" ]
	[ "$(printf '%s' "$output" | jq -r '.support.code')" = "legacy_merlin_386_armv7" ]
}

@test "probe-safe unsupported platform is experimental with acknowledgment" {
	set_probe_safe_profile
	export NUTMERLIN_PLATFORM_FIRMWARE_FAMILY=3007.1.x
	export NUTMERLIN_PLATFORM_FIRMWARE_VERSION=3007.1.1

	run "$REPOSITORY_ROOT/bin/nutmerlin" platform-eligibility --json

	[ "$status" -eq 78 ]
	[ "$(printf '%s' "$output" | jq -r '.support.class')" = "experimental_unsupported" ]
	[ "$(printf '%s' "$output" | jq -r '.support.acknowledgment_required')" = "true" ]
	[ "$(printf '%s' "$output" | jq -r '.support.code')" = "outside_supported_platform_contract" ]
}

@test "missing core capability is refused with stable named diagnostics" {
	set_probe_safe_profile
	export NUTMERLIN_PROBE_HOOKS=missing

	run "$REPOSITORY_ROOT/bin/nutmerlin" platform-eligibility --json

	[ "$status" -eq 78 ]
	[ "$(printf '%s' "$output" | jq -r '.support.class')" = "supported" ]
	[ "$(printf '%s' "$output" | jq -r '.installation.disposition')" = "refuse" ]
	[ "$(printf '%s' "$output" | jq -r '.diagnostic.code')" = "core_capability_missing" ]
	[ "$(printf '%s' "$output" | jq -r '.diagnostic.capability')" = "hooks" ]
}

@test "unknown core evidence and known core incompatibility fail closed" {
	set_probe_safe_profile
	export NUTMERLIN_PROBE_FIREWALL=unknown
	run "$REPOSITORY_ROOT/bin/nutmerlin" platform-eligibility --json

	[ "$status" -eq 78 ]
	[ "$(printf '%s' "$output" | jq -r '.diagnostic.code')" = "core_capability_unknown" ]
	[ "$(printf '%s' "$output" | jq -r '.diagnostic.capability')" = "firewall" ]

	set_probe_safe_profile
	export NUTMERLIN_TEST_INCOMPATIBILITY_SCOPE=core
	run "$REPOSITORY_ROOT/bin/nutmerlin" platform-eligibility --json

	[ "$status" -eq 78 ]
	[ "$(printf '%s' "$output" | jq -r '.diagnostic.code')" = "known_core_incompatibility" ]
}

@test "optional unknown capabilities limit only their scoped features" {
	set_probe_safe_profile
	export NUTMERLIN_PROBE_ADDONS_API=unknown
	export NUTMERLIN_PROBE_CLOCK_EVIDENCE=unknown
	export NUTMERLIN_PROBE_RESOURCE_LIMITS=unknown
	export NUTMERLIN_PLATFORM_MODEL=UNQUALIFIED-MODEL
	export NUTMERLIN_PLATFORM_HARDWARE_REVISION=REV-Z

	run "$REPOSITORY_ROOT/bin/nutmerlin" platform-eligibility --json

	[ "$status" -eq 78 ]
	[ "$(printf '%s' "$output" | jq -r '.support.class')" = "supported" ]
	[ "$(printf '%s' "$output" | jq -r '.capabilities.addons_api.scope')" = "webui" ]
	[ "$(printf '%s' "$output" | jq -r '.capabilities.clock_evidence.scope')" = "wall_clock_security" ]
	[ "$(printf '%s' "$output" | jq -r '.capabilities.resource_limits.scope')" = "local_script" ]
	[ "$(printf '%s' "$output" | jq -r '[.capabilities[]] | length')" -eq 10 ]
	[ "$(printf '%s' "$output" | jq -r '.platform.model')" = "UNQUALIFIED-MODEL" ]
	[ "$(printf '%s' "$output" | jq -r '.platform.hardware_revision')" = "REV-Z" ]
}

@test "native adapter reports unqualified semantic probes as unknown without mutation" {
	export NUTMERLIN_PLATFORM_ADAPTER=native

	run "$REPOSITORY_ROOT/bin/nutmerlin" platform-eligibility --json

	[ "$status" -eq 78 ]
	[ "$(printf '%s' "$output" | jq -r '.evidence_layer')" = "platform_probe" ]
	[ "$(printf '%s' "$output" | jq -r '.support.class')" = "ineligible" ]
	[ "$(printf '%s' "$output" | jq -r '.capabilities.hooks.status')" = "unknown" ]
	[ "$(printf '%s' "$output" | jq -r '.capabilities.firewall.status')" = "unknown" ]
	[ "$(printf '%s' "$output" | jq -r '.capabilities.mounts.status')" = "unknown" ]
	[ "$(wc -l <"$NUTMERLIN_EXTERNAL_CALL_LOG")" -eq 3 ]
	[ "$(sed -n '1p' "$NUTMERLIN_EXTERNAL_CALL_LOG")" = "$NUTMERLIN_TEST_ROOT/bin/nvram get extendno" ]
	[ "$(sed -n '2p' "$NUTMERLIN_EXTERNAL_CALL_LOG")" = "$NUTMERLIN_TEST_ROOT/bin/nvram get productid" ]
	[ "$(sed -n '3p' "$NUTMERLIN_EXTERNAL_CALL_LOG")" = "$NUTMERLIN_TEST_ROOT/bin/nvram get hardware_version" ]
}

@test "known optional incompatibility disables only the affected capability" {
	set_probe_safe_profile
	export NUTMERLIN_TEST_INCOMPATIBILITY_SCOPE=webui

	run "$REPOSITORY_ROOT/bin/nutmerlin" platform-eligibility --json

	[ "$status" -eq 78 ]
	[ "$(printf '%s' "$output" | jq -r '.support.class')" = "supported" ]
	[ "$(printf '%s' "$output" | jq -r '.capabilities.addons_api.status')" = "incompatible" ]
	[ "$(printf '%s' "$output" | jq -r '.installation.disposition')" = "refuse" ]
	[ "$(printf '%s' "$output" | jq -r '.support.acknowledgment_required')" = "false" ]
}
