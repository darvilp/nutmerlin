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

@test "core self-check returns the versioned monitoring-only result" {
	run "$REPOSITORY_ROOT/bin/nutmerlin" self-check --json

	[ "$status" -eq 0 ]
	[ "$(printf '%s' "$output" | jq -r '.schema_version')" = "nutmerlin.management-result.v1" ]
	[ "$(printf '%s' "$output" | jq -r '.operation')" = "core.self-check.v1" ]
	[ "$(printf '%s' "$output" | jq -r '.status')" = "ok" ]
	[ "$(printf '%s' "$output" | jq -r '.exit_class')" = "success" ]
	[ "$(printf '%s' "$output" | jq -r '.health.monitoring_only')" = "true" ]
	[ "$(printf '%s' "$output" | jq -r '.health.isolated_roots')" = "true" ]
	[ "$(printf '%s' "$output" | jq -r '.health.external_effects')" = "false" ]
	[ ! -e "$NUTMERLIN_EXTERNAL_CALL_LOG" ]
}

@test "host harness creates a private real isolation root" {
	[ -d "$NUTMERLIN_TEST_ROOT" ]
	[ ! -L "$NUTMERLIN_TEST_ROOT" ]
	[ "$(stat -c '%a' "$NUTMERLIN_TEST_ROOT")" = "700" ]
}
