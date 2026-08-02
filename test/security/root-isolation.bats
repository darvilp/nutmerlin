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

@test "self-check refuses non-isolated roots without invoking host controls" {
	run env \
		NUTMERLIN_ISOLATION_ROOT=/ \
		NUTMERLIN_ROUTER_ROOT=/jffs \
		NUTMERLIN_ENTWARE_ROOT=/opt \
		NUTMERLIN_STATUS_ROOT=/tmp \
		NUTMERLIN_WEB_ROOT=/www \
		NUTMERLIN_EXTERNAL_CALL_LOG="$NUTMERLIN_EXTERNAL_CALL_LOG" \
		"$REPOSITORY_ROOT/bin/nutmerlin" self-check --json

	[ "$status" -eq 78 ]
	[ "$(printf '%s' "$output" | jq -r '.status')" = "refused" ]
	[ "$(printf '%s' "$output" | jq -r '.exit_class')" = "configuration" ]
	[ "$(printf '%s' "$output" | jq -r '.health.isolated_roots')" = "false" ]
	[ ! -e "$NUTMERLIN_EXTERNAL_CALL_LOG" ]
}

@test "runtime source contains no forbidden command or listener surface" {
	run rg -n \
		'upscmd|upsrw|load[.]off|shutdown[.]|ForceOff|socat|netcat|nc -l|iptables|ip6tables|opkg[[:space:]]+(update|upgrade|install|remove|configure|download)' \
		"$REPOSITORY_ROOT/bin" "$REPOSITORY_ROOT/lib"

	[ "$status" -eq 1 ]
}

@test "self-check rejects lexical traversal outside the isolation root" {
	test_parent=$NUTMERLIN_TEST_ROOT/traversal
	mkdir -p "$test_parent/isolation" "$test_parent/outside"

	run env \
		NUTMERLIN_ISOLATION_ROOT="$test_parent/isolation" \
		NUTMERLIN_ROUTER_ROOT="$test_parent/isolation/../outside" \
		NUTMERLIN_ENTWARE_ROOT="$test_parent/isolation/../outside" \
		NUTMERLIN_STATUS_ROOT="$test_parent/isolation/../outside" \
		NUTMERLIN_WEB_ROOT="$test_parent/isolation/../outside" \
		"$REPOSITORY_ROOT/bin/nutmerlin" self-check --json

	[ "$status" -eq 78 ]
}
