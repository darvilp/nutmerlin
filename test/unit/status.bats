#!/usr/bin/env bats

setup() {
	REPOSITORY_ROOT=$(cd "$BATS_TEST_DIRNAME/../.." && pwd)
}

@test "status returns the stable JSON result when no core is installed" {
	run "$REPOSITORY_ROOT/bin/nutmerlin" status --json

	[ "$status" -eq 69 ]
	[ "$(printf '%s' "$output" | jq -r '.schema_version')" = 'nutmerlin.result.v1' ]
	[ "$(printf '%s' "$output" | jq -r '.command')" = 'status' ]
	[ "$(printf '%s' "$output" | jq -r '.status')" = 'unavailable' ]
	[ "$(printf '%s' "$output" | jq -r '.exit_class')" = 'unavailable' ]
	[ "$(printf '%s' "$output" | jq -r '.message')" = 'NUTMerlin core is not installed' ]
}

@test "status human output reports the same unavailable state" {
	run "$REPOSITORY_ROOT/bin/nutmerlin" status

	[ "$status" -eq 69 ]
	[ "$output" = 'status: unavailable: NUTMerlin core is not installed' ]
}

@test "status rejects unknown and excess arguments" {
	run "$REPOSITORY_ROOT/bin/nutmerlin" status --yaml
	[ "$status" -eq 64 ]

	run "$REPOSITORY_ROOT/bin/nutmerlin" status --json excess
	[ "$status" -eq 64 ]

	marker_path=$BATS_TEST_TMPDIR/not-allowed
	run "$REPOSITORY_ROOT/bin/nutmerlin" status "; touch $marker_path"
	[ "$status" -eq 64 ]
	[ ! -e "$marker_path" ]
}
