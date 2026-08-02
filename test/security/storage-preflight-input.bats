#!/usr/bin/env bats

setup() {
	REPOSITORY_ROOT=$(cd "$BATS_TEST_DIRNAME/../.." && pwd)
	export NUTMERLIN_TEST_STORAGE_PROBE_HELPER=$REPOSITORY_ROOT/test/lib/storage-durability-probe.py
	# shellcheck source=test/lib/host-harness.sh
	. "$REPOSITORY_ROOT/test/lib/host-harness.sh"
	host_harness_setup
	export NUTMERLIN_ENABLE_TEST_ADAPTERS=1 NUTMERLIN_STORAGE_ADAPTER=mock
	export NUTMERLIN_STORAGE_PRESENT=available NUTMERLIN_STORAGE_FILESYSTEM=ext4
	export NUTMERLIN_STORAGE_JOURNALING=available
	export NUTMERLIN_STORAGE_MOUNT_STATE=read_write NUTMERLIN_STORAGE_MOUNT_OPTIONS=rw_exec_native
	export NUTMERLIN_STORAGE_OBSERVED_MOUNT_OPTIONS=rw,noatime
	export NUTMERLIN_STORAGE_MOUNT_SOURCE=/dev/test-storage NUTMERLIN_STORAGE_MOUNT_TARGET=$NUTMERLIN_ENTWARE_ROOT
	export NUTMERLIN_STORAGE_HEALTH_EVIDENCE=unavailable
	export NUTMERLIN_STORAGE_IDENTITY=storage-A NUTMERLIN_STORAGE_EXPECTED_IDENTITY=storage-A
	export NUTMERLIN_STORAGE_EXACT_PROFILE=qualified NUTMERLIN_STORAGE_AVAILABLE_BYTES=33554432
	export NUTMERLIN_STORAGE_TRANSACTION_BYTES=0 NUTMERLIN_STORAGE_TEMPORARY_BYTES=0
	for capability in OWNERSHIP_MODES CASE_SENSITIVITY LINK_SEMANTICS ATOMIC_RENAME FILE_FSYNC DIRECTORY_FSYNC EXCLUSIVE_LOCKING EXECUTABLES STABLE_IDENTITY INTERRUPTION_RECOVERY; do
		export "NUTMERLIN_STORAGE_$capability=available"
	done
}

teardown() {
	host_harness_teardown
}

@test "storage evidence is bounded and cannot inject structured output" {
	export NUTMERLIN_STORAGE_IDENTITY='bad"},"injected":true,'
	export NUTMERLIN_STORAGE_AVAILABLE_BYTES=00033554432

	run "$REPOSITORY_ROOT/bin/nutmerlin" storage-preflight --json 0 0

	[ "$status" -eq 78 ]
	[ "$(printf '%s' "$output" | jq -r '.storage.identity')" = "unknown" ]
	[ "$(printf '%s' "$output" | jq -r '.diagnostic.preflight_code')" = "storage_identity_unknown" ]
	[ "$(printf '%s' "$output" | jq -r '.injected // false')" = "false" ]
	[ ! -e "$NUTMERLIN_EXTERNAL_CALL_LOG" ]
}

@test "test qualification cannot authorize outside the isolated adapter gate" {
	unset NUTMERLIN_ENABLE_TEST_ADAPTERS

	run "$REPOSITORY_ROOT/bin/nutmerlin" storage-preflight --json 0 0

	[ "$status" -eq 78 ]
	[ "$(printf '%s' "$output" | jq -r '.evidence_layer')" = "platform_probe" ]
	[ "$(printf '%s' "$output" | jq -r '.mount.target')" = "/opt" ]
	[ "$(printf '%s' "$output" | jq -r '.storage.eligibility')" = "ineligible" ]
	[ "$(printf '%s' "$output" | jq -r '.mutation.disposition')" = "refuse" ]
	[ -z "$(find "$NUTMERLIN_ENTWARE_ROOT" -mindepth 1 -print -quit)" ]
}

@test "symlinked storage root is refused before disposable probing" {
	mkdir "$NUTMERLIN_TEST_ROOT/link-target"
	ln -s "$NUTMERLIN_TEST_ROOT/link-target" "$NUTMERLIN_TEST_ROOT/link-root"
	export NUTMERLIN_STORAGE_ADAPTER=probe NUTMERLIN_ENTWARE_ROOT=$NUTMERLIN_TEST_ROOT/link-root
	run "$REPOSITORY_ROOT/bin/nutmerlin" storage-preflight --json 0 0
	[ "$status" -eq 78 ]
	[ "$(printf '%s' "$output" | jq -r '.evidence_layer')" = "platform_probe" ]
	[ -z "$(find "$NUTMERLIN_TEST_ROOT/link-target" -mindepth 1 -print -quit)" ]
}

@test "oversized sizing and malformed readiness input fail closed without effects" {
	export NUTMERLIN_STORAGE_AVAILABLE_BYTES=1000000000000000
	run "$REPOSITORY_ROOT/bin/nutmerlin" storage-preflight --json 1000000000000000 0
	[ "$(printf '%s' "$output" | jq -r '.diagnostic.preflight_code')" = "transaction_size_uncomputable" ]

	run "$REPOSITORY_ROOT/bin/nutmerlin" storage-readiness --json '5;service start' 0 absent
	[ "$status" -eq 64 ]
	[ ! -e "$NUTMERLIN_EXTERNAL_CALL_LOG" ]
}

@test "readiness failure cannot follow a symlinked status root" {
	mkdir "$NUTMERLIN_TEST_ROOT/outside-status"
	mkdir "$NUTMERLIN_TEST_ROOT/outside-status/storage-start.claim"
	rm -rf "$NUTMERLIN_STATUS_ROOT"
	ln -s "$NUTMERLIN_TEST_ROOT/outside-status" "$NUTMERLIN_STATUS_ROOT"

	run "$REPOSITORY_ROOT/bin/nutmerlin" storage-readiness --json 30 15 failed

	[ "$status" -eq 78 ]
	[ -d "$NUTMERLIN_TEST_ROOT/outside-status/storage-start.claim" ]
}

@test "readiness refuses a pre-created status root with weak ownership boundary" {
	chmod 777 "$NUTMERLIN_STATUS_ROOT"

	run "$REPOSITORY_ROOT/bin/nutmerlin" storage-readiness --json 30 15 ready

	[ "$status" -eq 78 ]
	[ ! -e "$NUTMERLIN_STATUS_ROOT/storage-start.claim" ]
}
