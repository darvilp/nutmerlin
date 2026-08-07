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

@test "development install refuses a preexisting managed-hook marker without adopting it" {
	entware_fixture_setup
	mkdir "$NUTMERLIN_JFFS_ROOT/scripts"
	hook_path=$NUTMERLIN_JFFS_ROOT/scripts/services-start
	printf '%s\n' '# BEGIN NUTMerlin managed block: foreign services-start' >"$hook_path"
	chmod 755 "$hook_path"

	run make --no-print-directory -C "$REPOSITORY_ROOT" install DESTDIR="$NUTMERLIN_TEST_ROOT"

	[ "$status" -eq 2 ]
	[[ "$output" == *'NUTMerlin install refused: foreign Merlin hook references NUT'* ]]
	[ "$(cat "$hook_path")" = '# BEGIN NUTMerlin managed block: foreign services-start' ]
	[ ! -e "$NUTMERLIN_JFFS_ROOT/addons/nutmerlin" ]
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

@test "local update has no downloader or package-manager path" {
	run rg -n \
		'curl|wget|ftp:|https?:|opkg|apk[[:space:]]|apt[[:space:]]|dnf[[:space:]]|yum[[:space:]]' \
		"$REPOSITORY_ROOT/lib/nutmerlin/update.sh"

	[ "$status" -eq 1 ]
}

@test "interactive menu has no evaluator downloader or raw NUT command surface" {
	run rg -n \
		'eval|(^|[[:space:]])(sh|ash|bash)[[:space:]]+-c|curl|wget|ftp:|https?:|upscmd|upsrw|FSD|NUT_CONFPATH|ups[.]conf|upsd[.]conf|upsd[.]users' \
		"$REPOSITORY_ROOT/lib/nutmerlin/menu.sh"

	[ "$status" -eq 1 ]
}

@test "fresh-install launcher is release-pinned and has no stream-to-shell surface" {
	make --no-print-directory -C "$REPOSITORY_ROOT" release-artifacts >/dev/null
	version=$(cat "$REPOSITORY_ROOT/VERSION")
	launcher=$REPOSITORY_ROOT/dist/nutmerlin-install-$version.sh

	[ "$(grep -Fc "https://github.com/darvilp/nutmerlin/releases/download/v$version/nutmerlin-core-$version.tar.gz" "$launcher")" -eq 1 ]
	[ "$(grep -Fc 'bootstrap_curl=/usr/sbin/curl' "$launcher")" -eq 1 ]
	run rg -n \
		'eval|wget|ftp:|http:|[|][[:space:]]*(/bin/)?(sh|ash|bash)([[:space:]]|$)' \
		"$launcher"

	[ "$status" -eq 1 ]
}

@test "documented one-line install stages its launcher in a private unpredictable workspace" {
	run rg -n 'NUTMERLIN_LAUNCHER="/tmp/nutmerlin-install-' "$REPOSITORY_ROOT/INSTALL.md"
	[ "$status" -eq 1 ]
	grep -F "mktemp -d '/tmp/nutmerlin-launcher.XXXXXX'" "$REPOSITORY_ROOT/INSTALL.md"
	grep -F "trap 'rm -rf -- \"\$NUTMERLIN_BOOTSTRAP_DIR\"' EXIT" "$REPOSITORY_ROOT/INSTALL.md"
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

@test "lifecycle refuses and preserves a foreign periodic job" {
	entware_fixture_setup
	make --no-print-directory -C "$REPOSITORY_ROOT" install DESTDIR="$NUTMERLIN_TEST_ROOT" >/dev/null
	platform_root=$NUTMERLIN_TEST_ROOT/platform
	mkdir -m 700 "$platform_root"
	printf 'NUTMerlin\t*/10 * * * *\t/foreign/maintenance\n' >"$platform_root/cru.tsv"
	chmod 600 "$platform_root/cru.tsv"
	cp "$platform_root/cru.tsv" "$BATS_TEST_TMPDIR/foreign-cru.tsv"
	installed_cli=$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/bin/nutmerlin

	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		"$installed_cli" hook services-start

	[ "$status" -eq 78 ]
	cmp "$BATS_TEST_TMPDIR/foreign-cru.tsv" "$platform_root/cru.tsv"

	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		"$installed_cli" hook services-stop

	[ "$status" -eq 78 ]
	cmp "$BATS_TEST_TMPDIR/foreign-cru.tsv" "$platform_root/cru.tsv"
}

@test "services-stop removes its exact periodic job even when process state is ambiguous" {
	entware_fixture_setup
	make --no-print-directory -C "$REPOSITORY_ROOT" install DESTDIR="$NUTMERLIN_TEST_ROOT" >/dev/null
	platform_root=$NUTMERLIN_TEST_ROOT/platform
	mkdir -m 700 "$platform_root"
	installation_id=$(cat "$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/installation.id")
	periodic_command="$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/bin/nutmerlin hook reconcile $installation_id"
	printf 'NUTMerlin\t*/5 * * * *\t%s\n' "$periodic_command" >"$platform_root/cru.tsv"
	chmod 600 "$platform_root/cru.tsv"
	outside_record=$BATS_TEST_TMPDIR/outside-stop-record
	printf '%s\n' untouched >"$outside_record"
	ln -s "$outside_record" "$NUTMERLIN_TMP_ROOT/nutmerlin/run/upsd.pid"
	installed_cli=$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/bin/nutmerlin

	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		"$installed_cli" hook services-stop

	[ "$status" -eq 78 ]
	[ ! -e "$platform_root/cru.tsv" ]
	[ "$(cat "$outside_record")" = untouched ]
}

@test "real NUT integration helper cannot address router roots or firewall tools" {
	run rg -n \
		'/jffs|/opt|iptables|ip6tables|nvram|service|opkg' \
		"$REPOSITORY_ROOT/test/integration/run-dummy-nut.sh"

	[ "$status" -eq 1 ]
}
