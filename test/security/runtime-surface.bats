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

@test "host harness confines all roots beneath one private directory" {
	[ "$(stat -c '%a' "$NUTMERLIN_TEST_ROOT")" = 700 ]
	for test_root in "$NUTMERLIN_JFFS_ROOT" "$NUTMERLIN_OPT_ROOT" "$NUTMERLIN_TMP_ROOT"; do
		[ -d "$test_root" ]
		[ ! -L "$test_root" ]
		[[ "$test_root" == "$NUTMERLIN_TEST_ROOT"/* ]]
	done
}

@test "uninstalled status invokes no router or package controls" {
	run "$REPOSITORY_ROOT/bin/nutmerlin" status --json

	[ "$status" -eq 69 ]
	[ ! -e "$NUTMERLIN_EXTERNAL_CALL_LOG" ]
}

@test "runtime exposes no writable UPS or remote-action surface" {
	run rg -n \
		'upscmd|upsrw|load[.]off|shutdown[.]|FSD|ForceOff|socat|netcat|nc -l|opkg[[:space:]]+(update|upgrade|install|remove|configure|download)' \
		"$REPOSITORY_ROOT/bin" "$REPOSITORY_ROOT/lib"

	[ "$status" -eq 1 ]
}

@test "real NUT integration helper cannot address router roots or firewall tools" {
	run rg -n \
		'/jffs|/opt|iptables|ip6tables|nvram|service|opkg' \
		"$REPOSITORY_ROOT/test/integration/run-dummy-nut.sh"

	[ "$status" -eq 1 ]
}
