#!/usr/bin/env bats

setup() {
	REPOSITORY_ROOT=$(cd "$BATS_TEST_DIRNAME/../.." && pwd)
	export NUTMERLIN_TEST_STORAGE_PROBE_HELPER=$REPOSITORY_ROOT/test/lib/storage-durability-probe.py
	# shellcheck source=test/lib/host-harness.sh
	. "$REPOSITORY_ROOT/test/lib/host-harness.sh"
	host_harness_setup
	set_reference_storage
}

teardown() {
	host_harness_teardown
}

set_reference_storage() {
	export NUTMERLIN_ENABLE_TEST_ADAPTERS=1 NUTMERLIN_STORAGE_ADAPTER=probe
	export NUTMERLIN_STORAGE_PRESENT=available NUTMERLIN_STORAGE_FILESYSTEM=ext4
	export NUTMERLIN_STORAGE_JOURNALING=available
	export NUTMERLIN_STORAGE_MOUNT_STATE=read_write NUTMERLIN_STORAGE_MOUNT_OPTIONS=rw_exec_native
	export NUTMERLIN_STORAGE_OBSERVED_MOUNT_OPTIONS=rw,noatime
	export NUTMERLIN_STORAGE_MOUNT_SOURCE=/dev/test-storage NUTMERLIN_STORAGE_MOUNT_TARGET=$NUTMERLIN_ENTWARE_ROOT
	export NUTMERLIN_STORAGE_HEALTH_EVIDENCE=unavailable
	export NUTMERLIN_STORAGE_IDENTITY=storage-A NUTMERLIN_STORAGE_EXPECTED_IDENTITY=storage-A
	export NUTMERLIN_STORAGE_EXACT_PROFILE=qualified NUTMERLIN_STORAGE_AVAILABLE_BYTES=33554432
	export NUTMERLIN_STORAGE_TRANSACTION_BYTES=8388608 NUTMERLIN_STORAGE_TEMPORARY_BYTES=4194304
	for capability in OWNERSHIP_MODES CASE_SENSITIVITY LINK_SEMANTICS ATOMIC_RENAME FILE_FSYNC DIRECTORY_FSYNC EXCLUSIVE_LOCKING EXECUTABLES STABLE_IDENTITY INTERRUPTION_RECOVERY; do
		export "NUTMERLIN_STORAGE_$capability=available"
	done
}

run_preflight() {
	run "$REPOSITORY_ROOT/bin/nutmerlin" storage-preflight --json \
		"$NUTMERLIN_STORAGE_TRANSACTION_BYTES" "$NUTMERLIN_STORAGE_TEMPORARY_BYTES"
}

@test "native preflight inspects the configured Entware root without replacing it with host roots" {
	export NUTMERLIN_STORAGE_ADAPTER=native
	mkdir -p "$NUTMERLIN_TEST_ROOT/sys-block/sda1/device" "$NUTMERLIN_TEST_ROOT/dev"
	printf '%s\n' device-serial-a >"$NUTMERLIN_TEST_ROOT/sys-block/sda1/device/serial"
	printf '%s\n' "$NUTMERLIN_TEST_ROOT/dev/sda1 $NUTMERLIN_ENTWARE_ROOT ext4 rw,noatime 0 0" >"$NUTMERLIN_TEST_ROOT/mounts"
	printf '%s\n' '#!/bin/sh' 'printf "%s\n" filesystem-uuid-a' >"$NUTMERLIN_TEST_ROOT/bin/blkid"
	chmod 700 "$NUTMERLIN_TEST_ROOT/bin/blkid"
	export NUTMERLIN_TEST_MOUNTS_FILE=$NUTMERLIN_TEST_ROOT/mounts
	export NUTMERLIN_TEST_SYS_BLOCK_ROOT=$NUTMERLIN_TEST_ROOT/sys-block
	run "$REPOSITORY_ROOT/bin/nutmerlin" storage-preflight --json 0 0

	[ "$status" -eq 78 ]
	[ "$(printf '%s' "$output" | jq -r '.evidence_layer')" = "host_native_probe" ]
	[ "$(printf '%s' "$output" | jq -r '.mount.target')" = "$NUTMERLIN_ENTWARE_ROOT" ]
	[ "$(printf '%s' "$output" | jq -r '.mount.observed_options')" = "rw,noatime" ]
	first_identity=$(printf '%s' "$output" | jq -r '.storage.identity')
	[ "$first_identity" = "fsuuid-filesystem-uuid-a.serial-device-serial-a" ]

	printf '%s\n' device-serial-b >"$NUTMERLIN_TEST_ROOT/sys-block/sda1/device/serial"
	run "$REPOSITORY_ROOT/bin/nutmerlin" storage-preflight --json 0 0
	[ "$(printf '%s' "$output" | jq -r '.storage.identity')" != "$first_identity" ]
}

@test "storage sizing is supplied by closed operation inputs" {
	export NUTMERLIN_STORAGE_ADAPTER=mock
	export NUTMERLIN_STORAGE_TRANSACTION_BYTES=1 NUTMERLIN_STORAGE_TEMPORARY_BYTES=1
	run "$REPOSITORY_ROOT/bin/nutmerlin" storage-preflight --json 8388608 4194304

	[ "$status" -eq 78 ]
	[ "$(printf '%s' "$output" | jq -r '.space.transaction_bytes')" -eq 8388608 ]
	[ "$(printf '%s' "$output" | jq -r '.space.temporary_bytes')" -eq 4194304 ]
	[ "$(printf '%s' "$output" | jq -r '.space.required_bytes')" -eq 29360128 ]

	run "$REPOSITORY_ROOT/bin/nutmerlin" storage-preflight --json
	[ "$status" -eq 64 ]
}

@test "qualified journaled ext4 reference profile reports complete eligibility without authorizing simulated mutation" {
	run_preflight

	[ "$status" -eq 78 ]
	[ "$(printf '%s' "$output" | jq -r '.operation')" = "storage.preflight.v1" ]
	[ "$(printf '%s' "$output" | jq -r '.storage.profile')" = "reference_ext4" ]
	[ "$(printf '%s' "$output" | jq -r '.storage.eligibility')" = "eligible" ]
	[ "$(printf '%s' "$output" | jq -r '.evidence_layer')" = "host_disposable_probe" ]
	[ "$(printf '%s' "$output" | jq -r '.mutation.disposition')" = "refuse" ]
	[ "$(printf '%s' "$output" | jq -r '.space.required_bytes')" -eq 29360128 ]
	[ "$(printf '%s' "$output" | jq -r '.qualification.exact_profile')" = "qualified" ]
	[ "$(printf '%s' "$output" | jq -r '[.capabilities[] | select(.status != "available")] | length')" -eq 0 ]
	[ ! -e "$NUTMERLIN_EXTERNAL_CALL_LOG" ]
}

@test "ext4 reference requires positive journaling evidence" {
	export NUTMERLIN_STORAGE_JOURNALING=unknown
	run_preflight
	[ "$(printf '%s' "$output" | jq -r '.storage.eligibility')" = "ineligible" ]
	[ "$(printf '%s' "$output" | jq -r '.diagnostic.preflight_code')" = "ext4_journal_unknown" ]
}

@test "FAT family and permission emulation are refused before semantic mutation" {
	for filesystem in fat vfat exfat; do
		set_reference_storage
		export NUTMERLIN_STORAGE_FILESYSTEM=$filesystem
		run_preflight
		[ "$status" -eq 78 ]
		[ "$(printf '%s' "$output" | jq -r '.storage.eligibility')" = "ineligible" ]
		[ "$(printf '%s' "$output" | jq -r '.diagnostic.code')" = "incompatible_filesystem" ]
	done

	set_reference_storage
	export NUTMERLIN_STORAGE_MOUNT_OPTIONS=permission_emulation
	run_preflight
	[ "$(printf '%s' "$output" | jq -r '.diagnostic.code')" = "incompatible_mount_semantics" ]
	[ ! -e "$NUTMERLIN_EXTERNAL_CALL_LOG" ]
}

@test "non-reference filesystem requires an exact qualified profile" {
	export NUTMERLIN_STORAGE_FILESYSTEM=f2fs NUTMERLIN_STORAGE_EXACT_PROFILE=unqualified
	run_preflight

	[ "$(printf '%s' "$output" | jq -r '.storage.profile')" = "non_reference" ]
	[ "$(printf '%s' "$output" | jq -r '.diagnostic.code')" = "exact_profile_required" ]

	export NUTMERLIN_STORAGE_EXACT_PROFILE=qualified
	run_preflight
	[ "$(printf '%s' "$output" | jq -r '.storage.eligibility')" = "eligible" ]
}

@test "unknown or failed required semantics refuse with stable named diagnostics" {
	for evidence in 'LINK_SEMANTICS unknown link_semantics_unknown' 'DIRECTORY_FSYNC missing directory_fsync_missing' 'INTERRUPTION_RECOVERY incompatible interruption_recovery_incompatible'; do
		set -- $evidence
		set_reference_storage
		export NUTMERLIN_STORAGE_ADAPTER=mock
		export "NUTMERLIN_STORAGE_$1=$2"
		run_preflight
		[ "$(printf '%s' "$output" | jq -r '.diagnostic.code')" = "$3" ]
		[ "$(printf '%s' "$output" | jq -r '.storage.eligibility')" = "ineligible" ]
	done
}

@test "durability fixture failure makes interruption recovery unavailable and cleans disposable data" {
	export NUTMERLIN_TEST_DURABILITY_FAILURE=interruption-recovery
	run_preflight
	[ "$(printf '%s' "$output" | jq -r '.diagnostic.preflight_code')" = "interruption_recovery_missing" ]
	[ -z "$(find "$NUTMERLIN_ENTWARE_ROOT" -name '.nutmerlin-preflight.*' -print -quit)" ]
}

@test "read-only state and replacement identity are refused" {
	export NUTMERLIN_STORAGE_MOUNT_STATE=read_only
	run_preflight
	[ "$(printf '%s' "$output" | jq -r '.diagnostic.code')" = "storage_read_only" ]

	set_reference_storage
	export NUTMERLIN_STORAGE_IDENTITY=storage-B
	run_preflight
	[ "$(printf '%s' "$output" | jq -r '.diagnostic.code')" = "storage_identity_mismatch" ]
}

@test "space requirement includes calculated transaction temporary need and 16 MiB headroom" {
	export NUTMERLIN_STORAGE_AVAILABLE_BYTES=29360127
	run_preflight
	[ "$(printf '%s' "$output" | jq -r '.diagnostic.code')" = "insufficient_transaction_space" ]

	set_reference_storage
	export NUTMERLIN_STORAGE_TEMPORARY_BYTES=unknown
	export NUTMERLIN_TEST_DURABILITY_FAILURE=file-fsync
	run_preflight
	[ "$(printf '%s' "$output" | jq -r '.diagnostic.code')" = "transaction_size_uncomputable" ]
	[ "$(printf '%s' "$output" | jq -r '.capabilities.file_fsync.status')" = "available" ]
}

@test "late mount schedule is bounded and starts at most once" {
	for decision in '0 0 waiting 5' '5 0 probe 15' '15 5 probe 30' '120 60 probe 420' '420 120 probe 720'; do
		set -- $decision
		run "$REPOSITORY_ROOT/bin/nutmerlin" storage-readiness --json "$1" "$2" absent
		[ "$status" -eq 0 ]
		[ "$(printf '%s' "$output" | jq -r '.readiness.action')" = "$3" ]
		[ "$(printf '%s' "$output" | jq -r '.readiness.next_probe_seconds')" -eq "$4" ]
	done

	"$REPOSITORY_ROOT/bin/nutmerlin" storage-readiness --json 30 15 ready >"$NUTMERLIN_TEST_ROOT/claim-a" &
	first_pid=$!
	"$REPOSITORY_ROOT/bin/nutmerlin" storage-readiness --json 30 15 ready >"$NUTMERLIN_TEST_ROOT/claim-b" &
	second_pid=$!
	wait "$first_pid" "$second_pid"
	[ "$(jq -s '[.[].readiness.action] | map(select(. == "start_once")) | length' "$NUTMERLIN_TEST_ROOT/claim-a" "$NUTMERLIN_TEST_ROOT/claim-b")" -eq 1 ]
	run "$REPOSITORY_ROOT/bin/nutmerlin" storage-readiness --json 30 15 failed
	[ "$(printf '%s' "$output" | jq -r '.readiness.action')" = "retry_allowed" ]
	run "$REPOSITORY_ROOT/bin/nutmerlin" storage-readiness --json 30 15 ready
	[ "$(printf '%s' "$output" | jq -r '.readiness.action')" = "start_once" ]
}
