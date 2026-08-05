#!/usr/bin/env bats

setup() {
	REPOSITORY_ROOT=$(cd "$BATS_TEST_DIRNAME/../.." && pwd)
	# shellcheck source=test/lib/host-harness.sh
	. "$REPOSITORY_ROOT/test/lib/host-harness.sh"
	host_harness_setup
	# shellcheck source=test/lib/entware-fixture.sh
	. "$REPOSITORY_ROOT/test/lib/entware-fixture.sh"
	unset NUTMERLIN_FIXTURE_OMIT_PACKAGE NUTMERLIN_FIXTURE_BAD_DUMMY_HELP
}

@test "development install creates the owned dummy layout and atomic selector" {
	entware_fixture_setup

	run make --no-print-directory -C "$REPOSITORY_ROOT" install DESTDIR="$NUTMERLIN_TEST_ROOT"
	[ "$status" -eq 0 ]
	[ "$output" = 'NUTMerlin installed: dummy is configured loopback-only' ]

	code_root=$NUTMERLIN_JFFS_ROOT/addons/nutmerlin
	config_root=$NUTMERLIN_OPT_ROOT/etc/nutmerlin
	runtime_root=$NUTMERLIN_TMP_ROOT/nutmerlin
	[ "$(stat -c '%a' "$code_root")" = 755 ]
	[ "$(stat -c '%a' "$config_root")" = 700 ]
	[ "$(stat -c '%a' "$runtime_root")" = 711 ]

	installation_id=$(cat "$code_root/installation.id")
	[[ "$installation_id" =~ ^[0-9a-f]{32}$ ]]
	[ "$(cat "$config_root/installation.id")" = "$installation_id" ]
	[ "$(stat -c '%a' "$code_root/installation.id")" = 600 ]
	[ "$(stat -c '%a' "$config_root/installation.id")" = 600 ]
	[ "$(stat -c '%a' "$code_root/entware.tsv")" = 600 ]
	grep -Fx $'nut\t2.8.2-1\taarch64-3.10' "$code_root/entware.tsv"

	set_id=$(cat "$config_root/config/current")
	[[ "$set_id" =~ ^[0-9a-f]{32}$ ]]
	set_root=$config_root/config/sets/$set_id
	[ -d "$set_root" ]
	[ "$(stat -c '%a' "$set_root")" = 700 ]
	for owned_config in model.tsv ups.conf upsd.conf upsd.users SHA256SUMS; do
		[ -f "$set_root/$owned_config" ]
	done
	[ "$(stat -c '%a' "$set_root/ups.conf")" = 600 ]
	[ "$(stat -c '%a' "$set_root/upsd.conf")" = 600 ]
	[ "$(stat -c '%a' "$set_root/upsd.users")" = 600 ]
	(cd "$set_root" && sha256sum -c SHA256SUMS)

	grep -Fx $'source\tdummy' "$set_root/model.tsv"
	grep -Fx 'LISTEN 127.0.0.1 3493' "$set_root/upsd.conf"
	grep -Fx $'\tdriver = dummy-ups' "$set_root/ups.conf"
	grep -Fx $'\t'"port = $code_root/share/dummy/cyberpower.dev" "$set_root/ups.conf"
	[ ! -s "$set_root/upsd.users" ]
	run rg -n 'MONITOR|upsmon|allowfrom|actions|instcmds|FSD|SHUTDOWNCMD|load[.]off|LISTEN (0[.]0[.]0[.]0|::)' "$set_root"
	[ "$status" -eq 1 ]
	[ ! -e "$config_root/config/last-good" ]
	[ ! -d "$config_root/clients" ]
	[ ! -e "$NUTMERLIN_OPT_ROOT/etc/nut" ]
	[ ! -e "$NUTMERLIN_EXTERNAL_CALL_LOG" ]
}

@test "install appends one attributable block to every Merlin hook without changing its prefix" {
	entware_fixture_setup
	hook_root=$NUTMERLIN_JFFS_ROOT/scripts
	mkdir "$hook_root"
	for hook_name in services-start services-stop post-mount unmount firewall-start; do
		printf 'unrelated-%s' "$hook_name" >"$hook_root/$hook_name"
		chmod 755 "$hook_root/$hook_name"
		cp "$hook_root/$hook_name" "$BATS_TEST_TMPDIR/$hook_name.original"
	done

	make --no-print-directory -C "$REPOSITORY_ROOT" install DESTDIR="$NUTMERLIN_TEST_ROOT" >/dev/null
	installation_id=$(cat "$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/installation.id")
	for hook_name in services-start services-stop post-mount unmount firewall-start; do
		hook_path=$hook_root/$hook_name
		original_size=$(wc -c <"$BATS_TEST_TMPDIR/$hook_name.original")
		cmp -n "$original_size" "$BATS_TEST_TMPDIR/$hook_name.original" "$hook_path"
		[ "$(grep -c "^# BEGIN NUTMerlin managed block: $installation_id $hook_name$" "$hook_path")" -eq 1 ]
		[ "$(grep -c "^# END NUTMerlin managed block: $installation_id $hook_name$" "$hook_path")" -eq 1 ]
		grep -F "hook $hook_name" "$hook_path"
	done

	make --no-print-directory -C "$REPOSITORY_ROOT" install DESTDIR="$NUTMERLIN_TEST_ROOT" >/dev/null
	for hook_name in services-start services-stop post-mount unmount firewall-start; do
		[ "$(grep -c '^# BEGIN NUTMerlin managed block:' "$hook_root/$hook_name")" -eq 1 ]
	done
}

@test "installed status and diagnostics expose stable redacted lifecycle dimensions" {
	entware_fixture_setup
	make --no-print-directory -C "$REPOSITORY_ROOT" install DESTDIR="$NUTMERLIN_TEST_ROOT" >/dev/null
	installed_cli=$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/bin/nutmerlin

	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		"$installed_cli" status --json
	[ "$status" -eq 69 ]
	[ "$(printf '%s\n' "$output" | jq -r '.schema_version')" = nutmerlin.result.v1 ]
	[ "$(printf '%s\n' "$output" | jq -r '.details.installation')" = owned ]
	[ "$(printf '%s\n' "$output" | jq -r '.details.enabled')" = enabled ]
	[ "$(printf '%s\n' "$output" | jq -r '.details.storage')" = available ]
	[ "$(printf '%s\n' "$output" | jq -r '.details.source')" = dummy ]
	[ "$(printf '%s\n' "$output" | jq -r '.details.client_count')" = 0 ]
	[ "$(printf '%s\n' "$output" | jq -r '.details.recovery')" = ready ]

	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		"$installed_cli" diagnostics --json
	[ "$status" -eq 69 ]
	[ "$(printf '%s\n' "$output" | jq -r '.details.failed_layer')" = service ]
	[ "$(printf '%s\n' "$output" | jq -r '.details.remediation')" = 'run service start or wait for lifecycle reconciliation' ]
	run rg -n 'password|secret|serial' <<<"$output"
	[ "$status" -eq 1 ]
}

@test "owned disabled state remains attributable and reports disabled" {
	entware_fixture_setup
	make --no-print-directory -C "$REPOSITORY_ROOT" install DESTDIR="$NUTMERLIN_TEST_ROOT" >/dev/null
	code_root=$NUTMERLIN_JFFS_ROOT/addons/nutmerlin
	installed_cli=$code_root/bin/nutmerlin
	printf '%s\n' 0 >"$code_root/enabled"

	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		"$installed_cli" status --json

	[ "$status" -eq 69 ]
	[ "$(printf '%s\n' "$output" | jq -r '.details.installation')" = owned ]
	[ "$(printf '%s\n' "$output" | jq -r '.details.enabled')" = disabled ]
}

@test "failed hook installation restores every original hook byte for byte" {
	entware_fixture_setup
	hook_root=$NUTMERLIN_JFFS_ROOT/scripts
	mkdir "$hook_root"
	for hook_name in services-start services-stop post-mount unmount firewall-start; do
		printf 'original-%s-without-newline' "$hook_name" >"$hook_root/$hook_name"
		chmod 755 "$hook_root/$hook_name"
		cp -p "$hook_root/$hook_name" "$BATS_TEST_TMPDIR/$hook_name.original"
	done

	run env NUTMERLIN_TEST_HOOK_INSTALL_FAIL_AFTER=services-stop \
		make --no-print-directory -C "$REPOSITORY_ROOT" install DESTDIR="$NUTMERLIN_TEST_ROOT"

	[ "$status" -eq 2 ]
	for hook_name in services-start services-stop post-mount unmount firewall-start; do
		cmp "$BATS_TEST_TMPDIR/$hook_name.original" "$hook_root/$hook_name"
		[ "$(stat -c '%a' "$hook_root/$hook_name")" = 755 ]
	done
	[ ! -e "$NUTMERLIN_JFFS_ROOT/addons/nutmerlin" ]
	[ ! -e "$NUTMERLIN_OPT_ROOT/etc/nutmerlin" ]
}

@test "hook rollback retains and refuses a concurrently changed installed hook" {
	hook_root=$NUTMERLIN_JFFS_ROOT/scripts
	mkdir "$hook_root"
	for hook_name in services-start services-stop post-mount unmount firewall-start; do
		printf 'original-%s' "$hook_name" >"$hook_root/$hook_name"
		chmod 755 "$hook_root/$hook_name"
		cp -p "$hook_root/$hook_name" "$BATS_TEST_TMPDIR/$hook_name.original"
	done

	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		REPOSITORY_ROOT="$REPOSITORY_ROOT" \
		/bin/sh -c '
			. "$REPOSITORY_ROOT/lib/nutmerlin/paths.sh"
			. "$REPOSITORY_ROOT/lib/nutmerlin/hooks.sh"
			paths_initialize
			hooks_install_all 0123456789abcdef0123456789abcdef "$REPOSITORY_ROOT"
			printf "\nconcurrent-foreign-change\n" >>"$NUTMERLIN_JFFS_ROOT/scripts/services-stop"
			hooks_rollback_install
		'

	[ "$status" -eq 78 ]
	grep -Fx 'concurrent-foreign-change' "$hook_root/services-stop"
	for hook_name in services-start post-mount unmount firewall-start; do
		cmp "$BATS_TEST_TMPDIR/$hook_name.original" "$hook_root/$hook_name"
	done
}

@test "hook install never adopts a change made immediately after publication" {
	hook_root=$NUTMERLIN_JFFS_ROOT/scripts
	mkdir "$hook_root"
	for hook_name in services-start services-stop post-mount unmount firewall-start; do
		printf 'original-%s' "$hook_name" >"$hook_root/$hook_name"
		chmod 755 "$hook_root/$hook_name"
		cp -p "$hook_root/$hook_name" "$BATS_TEST_TMPDIR/$hook_name.original"
	done

	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		REPOSITORY_ROOT="$REPOSITORY_ROOT" \
		/bin/sh -c '
			. "$REPOSITORY_ROOT/lib/nutmerlin/paths.sh"
			. "$REPOSITORY_ROOT/lib/nutmerlin/hooks.sh"
			paths_initialize
			hooks_test_after_publish() {
				[ "$2" != services-stop ] || printf "\nconcurrent-after-publish\n" >>"$1"
			}
			hooks_install_all 0123456789abcdef0123456789abcdef "$REPOSITORY_ROOT" || install_status=$?
			[ "${install_status:-0}" -eq 78 ] || exit 1
			hooks_rollback_install
		'

	[ "$status" -eq 78 ]
	grep -Fx 'concurrent-after-publish' "$hook_root/services-stop"
	for hook_name in services-start post-mount unmount firewall-start; do
		cmp "$BATS_TEST_TMPDIR/$hook_name.original" "$hook_root/$hook_name"
	done
}

@test "development install refuses an unmarked destination root" {
	entware_fixture_setup
	rm "$NUTMERLIN_TEST_ROOT/.nutmerlin-test-root"

	run make --no-print-directory -C "$REPOSITORY_ROOT" install DESTDIR="$NUTMERLIN_TEST_ROOT"

	[ "$status" -eq 2 ]
	[[ "$output" == *'test root must carry private harness ownership evidence'* ]]
	[ ! -e "$NUTMERLIN_JFFS_ROOT/addons/nutmerlin" ]
}

@test "missing package refuses with exact administrator guidance" {
	NUTMERLIN_FIXTURE_OMIT_PACKAGE=nut-server
	entware_fixture_setup

	run make --no-print-directory -C "$REPOSITORY_ROOT" install DESTDIR="$NUTMERLIN_TEST_ROOT"
	[ "$status" -eq 2 ]
	[[ "$output" == *'Entware requirements unavailable: missing installed packages: nut-server'* ]]
	[[ "$output" == *'Review and run separately: opkg install nut-server'* ]]
	[ ! -e "$NUTMERLIN_JFFS_ROOT/addons/nutmerlin" ]
	[ ! -e "$NUTMERLIN_OPT_ROOT/etc/nutmerlin" ]
	[ ! -e "$NUTMERLIN_EXTERNAL_CALL_LOG" ]
}

@test "incompatible binary options refuse before mutation" {
	NUTMERLIN_FIXTURE_BAD_DUMMY_HELP=1
	entware_fixture_setup

	run make --no-print-directory -C "$REPOSITORY_ROOT" install DESTDIR="$NUTMERLIN_TEST_ROOT"
	[ "$status" -eq 2 ]
	[[ "$output" == *'Entware requirements incompatible: dummy-ups lacks required options: -a -F'* ]]
	[ ! -e "$NUTMERLIN_JFFS_ROOT/addons/nutmerlin" ]
	[ ! -e "$NUTMERLIN_OPT_ROOT/etc/nutmerlin" ]
	[ ! -e "$NUTMERLIN_EXTERNAL_CALL_LOG" ]
}

@test "unwritable Entware storage refuses before owned mutation" {
	entware_fixture_setup
	chmod 500 "$NUTMERLIN_OPT_ROOT"

	run make --no-print-directory -C "$REPOSITORY_ROOT" install DESTDIR="$NUTMERLIN_TEST_ROOT"
	chmod 700 "$NUTMERLIN_OPT_ROOT"

	[ "$status" -eq 2 ]
	[[ "$output" == *"Entware requirements unavailable: storage is not writable: $NUTMERLIN_OPT_ROOT"* ]]
	[ ! -e "$NUTMERLIN_JFFS_ROOT/addons/nutmerlin" ]
	[ ! -e "$NUTMERLIN_OPT_ROOT/etc/nutmerlin" ]
	[ ! -e "$NUTMERLIN_EXTERNAL_CALL_LOG" ]
}

teardown() {
	host_harness_teardown
}

@test "development install reports exact missing Entware guidance without mutation" {
	run make --no-print-directory -C "$REPOSITORY_ROOT" install DESTDIR="$NUTMERLIN_TEST_ROOT"

	[ "$status" -eq 2 ]
	[[ "$output" == *"Entware requirements unavailable: missing package metadata: $NUTMERLIN_OPT_ROOT/lib/opkg/status"* ]]
	[[ "$output" == *'Review and run separately: opkg install nut nut-common nut-server nut-upsc nut-driver-dummy-ups nut-driver-usbhid-ups'* ]]
	[ ! -e "$NUTMERLIN_JFFS_ROOT/addons/nutmerlin" ]
	[ ! -e "$NUTMERLIN_OPT_ROOT/etc/nutmerlin" ]
	[ ! -e "$NUTMERLIN_EXTERNAL_CALL_LOG" ]
}

@test "foreign ambient NUT configuration refuses before owned mutation" {
	entware_fixture_setup
	mkdir -p "$NUTMERLIN_OPT_ROOT/etc/nut"
	printf '%s\n' '[foreign]' >"$NUTMERLIN_OPT_ROOT/etc/nut/ups.conf"

	run make --no-print-directory -C "$REPOSITORY_ROOT" install DESTDIR="$NUTMERLIN_TEST_ROOT"

	[ "$status" -eq 2 ]
	[[ "$output" == *"NUTMerlin install refused: foreign NUT configuration: $NUTMERLIN_OPT_ROOT/etc/nut"* ]]
	[ "$(cat "$NUTMERLIN_OPT_ROOT/etc/nut/ups.conf")" = '[foreign]' ]
	[ ! -e "$NUTMERLIN_JFFS_ROOT/addons/nutmerlin" ]
	[ ! -e "$NUTMERLIN_OPT_ROOT/etc/nutmerlin" ]
	[ ! -e "$NUTMERLIN_EXTERNAL_CALL_LOG" ]
}

@test "repeat install is idempotent for complete matching owned evidence" {
	entware_fixture_setup
	make --no-print-directory -C "$REPOSITORY_ROOT" install DESTDIR="$NUTMERLIN_TEST_ROOT" >/dev/null
	code_root=$NUTMERLIN_JFFS_ROOT/addons/nutmerlin
	config_root=$NUTMERLIN_OPT_ROOT/etc/nutmerlin
	before_installation_id=$(cat "$code_root/installation.id")
	before_set_id=$(cat "$config_root/config/current")

	run make --no-print-directory -C "$REPOSITORY_ROOT" install DESTDIR="$NUTMERLIN_TEST_ROOT"

	[ "$status" -eq 0 ]
	[ "$output" = 'NUTMerlin already installed: owned state is complete' ]
	[ "$(cat "$code_root/installation.id")" = "$before_installation_id" ]
	[ "$(cat "$config_root/installation.id")" = "$before_installation_id" ]
	[ "$(cat "$config_root/config/current")" = "$before_set_id" ]
	[ "$(find "$config_root/config/sets" -mindepth 1 -maxdepth 1 -type d | wc -l)" -eq 1 ]
	[ ! -e "$NUTMERLIN_EXTERNAL_CALL_LOG" ]
}

@test "repeat install refuses corrupted owned evidence without repairing it" {
	entware_fixture_setup
	make --no-print-directory -C "$REPOSITORY_ROOT" install DESTDIR="$NUTMERLIN_TEST_ROOT" >/dev/null
	code_root=$NUTMERLIN_JFFS_ROOT/addons/nutmerlin
	config_root=$NUTMERLIN_OPT_ROOT/etc/nutmerlin
	printf '%s\n' '# foreign change' >>"$code_root/lib/result.sh"
	current_set_id=$(cat "$config_root/config/current")

	run make --no-print-directory -C "$REPOSITORY_ROOT" install DESTDIR="$NUTMERLIN_TEST_ROOT"

	[ "$status" -eq 2 ]
	[[ "$output" == *'NUTMerlin install refused: existing NUTMerlin ownership evidence is incomplete or unverified'* ]]
	[ "$(tail -1 "$code_root/lib/result.sh")" = '# foreign change' ]
	[ "$(cat "$config_root/config/current")" = "$current_set_id" ]
}

@test "repeat install refuses a checksummed configuration outside the closed dummy model" {
	entware_fixture_setup
	make --no-print-directory -C "$REPOSITORY_ROOT" install DESTDIR="$NUTMERLIN_TEST_ROOT" >/dev/null
	config_root=$NUTMERLIN_OPT_ROOT/etc/nutmerlin
	set_root=$config_root/config/sets/$(cat "$config_root/config/current")
	printf '%s\n' 'LISTEN 0.0.0.0 3493' >>"$set_root/upsd.conf"
	(cd "$set_root" && sha256sum model.tsv ups.conf upsd.conf upsd.users >SHA256SUMS)

	run make --no-print-directory -C "$REPOSITORY_ROOT" install DESTDIR="$NUTMERLIN_TEST_ROOT"

	[ "$status" -eq 2 ]
	[[ "$output" == *'existing NUTMerlin ownership evidence is incomplete or unverified'* ]]
}

@test "repeat install refuses unexpected owned-root objects of every type" {
	entware_fixture_setup
	make --no-print-directory -C "$REPOSITORY_ROOT" install DESTDIR="$NUTMERLIN_TEST_ROOT" >/dev/null
	code_root=$NUTMERLIN_JFFS_ROOT/addons/nutmerlin
	mkdir "$code_root/.foreign-directory"

	run make --no-print-directory -C "$REPOSITORY_ROOT" install DESTDIR="$NUTMERLIN_TEST_ROOT"

	[ "$status" -eq 2 ]
	[[ "$output" == *'existing NUTMerlin ownership evidence is incomplete or unverified'* ]]
}

@test "foreign ambient NUT path refuses when it is a file or symlink" {
	entware_fixture_setup
	ambient_root=$NUTMERLIN_OPT_ROOT/etc/nut
	mkdir -p "$NUTMERLIN_OPT_ROOT/etc"
	printf '%s\n' foreign >"$ambient_root"

	run make --no-print-directory -C "$REPOSITORY_ROOT" install DESTDIR="$NUTMERLIN_TEST_ROOT"
	[ "$status" -eq 2 ]
	[[ "$output" == *"foreign NUT configuration: $ambient_root"* ]]

	rm "$ambient_root"
	ln -s "$NUTMERLIN_TEST_ROOT" "$ambient_root"
	run make --no-print-directory -C "$REPOSITORY_ROOT" install DESTDIR="$NUTMERLIN_TEST_ROOT"
	[ "$status" -eq 2 ]
	[[ "$output" == *"foreign NUT configuration: $ambient_root"* ]]
}

@test "foreign hooks processes and listeners each refuse before mutation" {
	entware_fixture_setup
	mkdir -p "$NUTMERLIN_JFFS_ROOT/scripts"
	printf '%s\n' '#!/bin/sh' 'upsd -F' >"$NUTMERLIN_JFFS_ROOT/scripts/services-start"

	run make --no-print-directory -C "$REPOSITORY_ROOT" install DESTDIR="$NUTMERLIN_TEST_ROOT"
	[ "$status" -eq 2 ]
	[[ "$output" == *'NUTMerlin install refused: foreign Merlin hook references NUT'* ]]
	[ "$(tail -1 "$NUTMERLIN_JFFS_ROOT/scripts/services-start")" = 'upsd -F' ]
	rm "$NUTMERLIN_JFFS_ROOT/scripts/services-start"

	run env NUTMERLIN_TEST_FOREIGN_PROCESS=1 make --no-print-directory -C "$REPOSITORY_ROOT" install DESTDIR="$NUTMERLIN_TEST_ROOT"
	[ "$status" -eq 2 ]
	[[ "$output" == *'NUTMerlin install refused: foreign NUT process is active'* ]]

	run env NUTMERLIN_TEST_FOREIGN_LISTENER=1 make --no-print-directory -C "$REPOSITORY_ROOT" install DESTDIR="$NUTMERLIN_TEST_ROOT"
	[ "$status" -eq 2 ]
	[[ "$output" == *'NUTMerlin install refused: foreign TCP listener uses port 3493'* ]]

	[ ! -e "$NUTMERLIN_JFFS_ROOT/addons/nutmerlin" ]
	[ ! -e "$NUTMERLIN_OPT_ROOT/etc/nutmerlin" ]
	[ ! -e "$NUTMERLIN_EXTERNAL_CALL_LOG" ]
}
