#!/usr/bin/env bats

setup() {
	REPOSITORY_ROOT=$(cd "$BATS_TEST_DIRNAME/../.." && pwd)
	# shellcheck source=test/lib/host-harness.sh
	. "$REPOSITORY_ROOT/test/lib/host-harness.sh"
	host_harness_setup
	# shellcheck source=test/lib/entware-fixture.sh
	. "$REPOSITORY_ROOT/test/lib/entware-fixture.sh"
}

@test "development install rejects a child root symlink before mutation" {
	entware_fixture_setup
	outside_root=$BATS_TEST_TMPDIR/outside
	mkdir "$outside_root"
	rmdir "$NUTMERLIN_JFFS_ROOT"
	ln -s "$outside_root" "$NUTMERLIN_JFFS_ROOT"

	run make --no-print-directory -C "$REPOSITORY_ROOT" install DESTDIR="$NUTMERLIN_TEST_ROOT"

	[ "$status" -eq 2 ]
	[[ "$output" == *'test roots must be canonical directories beneath the private test root'* ]]
	[ ! -e "$outside_root/addons" ]
	[ ! -e "$NUTMERLIN_EXTERNAL_CALL_LOG" ]
}

@test "development install rejects symlinked layout parents before mutation" {
	entware_fixture_setup
	outside_root=$BATS_TEST_TMPDIR/outside-parent
	mkdir "$outside_root"
	ln -s "$outside_root" "$NUTMERLIN_JFFS_ROOT/addons"

	run make --no-print-directory -C "$REPOSITORY_ROOT" install DESTDIR="$NUTMERLIN_TEST_ROOT"

	[ "$status" -eq 2 ]
	[[ "$output" == *'NUTMerlin install refused: layout parent is foreign or ambiguous'* ]]
	[ ! -e "$outside_root/nutmerlin" ]
}

@test "owned verification rejects a hard-linked code file even with recomputed checksums" {
	entware_fixture_setup
	make --no-print-directory -C "$REPOSITORY_ROOT" install DESTDIR="$NUTMERLIN_TEST_ROOT" >/dev/null
	code_root=$NUTMERLIN_JFFS_ROOT/addons/nutmerlin
	external_copy=$BATS_TEST_TMPDIR/external-result.sh
	cp "$code_root/lib/result.sh" "$external_copy"
	rm "$code_root/lib/result.sh"
	ln "$external_copy" "$code_root/lib/result.sh"
	(
		cd "$code_root"
		sha256sum VERSION bin/nutmerlin entware.tsv lib/*.sh share/dummy/cyberpower.dev >owned-files
	)

	run make --no-print-directory -C "$REPOSITORY_ROOT" install DESTDIR="$NUTMERLIN_TEST_ROOT"

	[ "$status" -eq 2 ]
	[[ "$output" == *'NUTMerlin install refused: existing NUTMerlin ownership evidence is incomplete or unverified'* ]]
	[ "$(stat -c '%h' "$code_root/lib/result.sh")" -eq 2 ]
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
		'upscmd|upsrw|load[.]off|shutdown[.]|FSD|ForceOff|socat|netcat|nc -l|^[[:space:]]*(opkg|/opt/bin/opkg)[[:space:]]+(update|upgrade|install|remove|configure|download)' \
		"$REPOSITORY_ROOT/bin" "$REPOSITORY_ROOT/lib"

	[ "$status" -eq 1 ]
}

@test "listener probes fail closed when socket state cannot be inspected" {
	empty_path=$NUTMERLIN_TEST_ROOT/empty-path
	mkdir "$empty_path"

	run env PATH="$empty_path" /bin/sh -c '. "$1"; service_listener_is_clear' \
		nutmerlin-test "$REPOSITORY_ROOT/lib/nutmerlin/service.sh"

	[ "$status" -eq 69 ]
}

@test "service lifecycle refuses ambiguous volatile-root ownership before mutation" {
	entware_fixture_setup
	make --no-print-directory -C "$REPOSITORY_ROOT" install DESTDIR="$NUTMERLIN_TEST_ROOT" >/dev/null
	runtime_root=$NUTMERLIN_TMP_ROOT/nutmerlin
	chmod 755 "$runtime_root"
	installed_cli=$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/bin/nutmerlin

	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		"$installed_cli" service start

	[ "$status" -eq 78 ]
	[ "$(stat -c '%a' "$runtime_root")" = 755 ]
}

@test "service start refuses a single unsafe PID path without following it" {
	entware_fixture_setup
	make --no-print-directory -C "$REPOSITORY_ROOT" install DESTDIR="$NUTMERLIN_TEST_ROOT" >/dev/null
	runtime_root=$NUTMERLIN_TMP_ROOT/nutmerlin
	outside_record=$BATS_TEST_TMPDIR/outside-record
	printf '%s\n' untouched >"$outside_record"
	ln -s "$outside_record" "$runtime_root/run/upsd.pid"
	installed_cli=$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/bin/nutmerlin

	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		"$installed_cli" service start

	[ "$status" -eq 78 ]
	[[ "$output" == *'service refused: partial or unsafe process state'* ]]
	[ "$(cat "$outside_record")" = untouched ]
}

@test "real NUT integration helper cannot address router roots or firewall tools" {
	run rg -n \
		'/jffs|/opt|iptables|ip6tables|nvram|service|opkg' \
		"$REPOSITORY_ROOT/test/integration/run-dummy-nut.sh"

	[ "$status" -eq 1 ]
}
