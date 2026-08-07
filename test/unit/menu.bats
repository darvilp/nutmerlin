#!/usr/bin/env bats

setup() {
	REPOSITORY_ROOT=$(cd "$BATS_TEST_DIRNAME/../.." && pwd)
	# shellcheck source=test/lib/host-harness.sh
	. "$REPOSITORY_ROOT/test/lib/host-harness.sh"
	host_harness_setup
	# shellcheck source=test/lib/entware-fixture.sh
	. "$REPOSITORY_ROOT/test/lib/entware-fixture.sh"
	entware_fixture_setup
}

teardown() {
	host_harness_teardown
}

invoke_source_menu() {
	menu_input=$1
	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		NUTMERLIN_TEST_INTERACTIVE=1 \
		/bin/sh -c 'printf "%s" "$1" | "$2" menu' sh \
		"$menu_input" "$REPOSITORY_ROOT/bin/nutmerlin"
}

install_core() {
	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		"$REPOSITORY_ROOT/install.sh"
	[ "$status" -eq 0 ]
	installed_cli=$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/bin/nutmerlin
}

invoke_installed_menu() {
	menu_input=$1
	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		NUTMERLIN_TEST_INTERACTIVE=1 \
		/bin/sh -c 'printf "%s" "$1" | "$2" menu' sh "$menu_input" "$installed_cli"
}

invoke_installed_cli() {
	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		"$installed_cli" "$@"
}

owned_state_snapshot() {
	(
		cd "$NUTMERLIN_TEST_ROOT"
		find jffs opt -type f -print | sort | while IFS= read -r snapshot_path; do
			printf '%s  ' "$snapshot_path"
			sha256sum "$snapshot_path" | awk '{ print $1 }'
		done
	)
}

@test "packaged menu reports uninstalled state and quit changes nothing" {
	invoke_source_menu '3
q
'

	[ "$status" -eq 0 ]
	[[ "$output" == *'NUTMerlin 0.1.0-dev'* ]]
	[[ "$output" == *'State: not installed'* ]]
	[[ "$output" == *'i) Install NUTMerlin'* ]]
	[[ "$output" == *'q) Quit'* ]]
	[[ "$output" == *'Invalid selection; choose one listed item'* ]]
	[[ "$output" != *'not found'* ]]
	[[ "$output" == *'Menu closed; no changes were made'* ]]
	[ ! -e "$NUTMERLIN_JFFS_ROOT/addons/nutmerlin" ]
	[ ! -e "$NUTMERLIN_OPT_ROOT/etc/nutmerlin" ]
	[ ! -s "$NUTMERLIN_EXTERNAL_CALL_LOG" ]
}

@test "packaged menu never executes an unverified installed CLI" {
	foreign_code_root=$NUTMERLIN_JFFS_ROOT/addons/nutmerlin
	foreign_marker=$BATS_TEST_TMPDIR/foreign-cli-ran
	mkdir -p "$foreign_code_root/bin"
	printf '%s\n' '#!/bin/sh' "printf '%s\\n' ran >'$foreign_marker'" \
		>"$foreign_code_root/bin/nutmerlin"
	chmod 700 "$foreign_code_root/bin/nutmerlin"

	invoke_source_menu '1
q
'

	[ "$status" -eq 0 ]
	[[ "$output" == *'State: unavailable; installed ownership could not be verified'* ]]
	[[ "$output" == *'Invalid selection; choose one listed item'* ]]
	[[ "$output" != *'i) Install NUTMerlin'* ]]
	[ ! -e "$foreign_marker" ]
}

@test "packaged menu installs without silently authorizing Entware refresh" {
	invoke_source_menu 'i
y
n
q
'

	[ "$status" -eq 0 ]
	[[ "$output" == *'Install NUTMerlin? [y/N]'* ]]
	[[ "$output" == *'Refresh the six required Entware NUT packages? [y/N]'* ]]
	[[ "$output" == *'NUTMerlin installed: dummy is configured loopback-only'* ]]
	[[ "$output" == *'State: installed'* ]]
	[ -x "$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/bin/nutmerlin" ]
	[ -f "$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/lib/menu.sh" ]
	[ -d "$NUTMERLIN_OPT_ROOT/etc/nutmerlin" ]
	[ ! -s "$NUTMERLIN_EXTERNAL_CALL_LOG" ]
}

@test "installed menu delegates read-only status and diagnostics while invalid input is inert" {
	install_core
	owned_state_snapshot >"$BATS_TEST_TMPDIR/owned.before"

	invoke_installed_menu '1
2
not-a-choice
q
'

	[ "$status" -eq 0 ]
	[[ "$output" == *'State: installed'* ]]
	[[ "$output" == *'1) Status'* ]]
	[[ "$output" == *'2) Diagnostics'* ]]
	[[ "$output" == *'17) Uninstall'* ]]
	[[ "$output" == *'status:'* ]]
	[[ "$output" == *'diagnostics:'* ]]
	[[ "$output" == *'Invalid selection; choose one listed item'* ]]
	[[ "$output" != *'secret='* ]]
	owned_state_snapshot >"$BATS_TEST_TMPDIR/owned.after"
	cmp "$BATS_TEST_TMPDIR/owned.before" "$BATS_TEST_TMPDIR/owned.after"
}

@test "installed menu delegates the selected service action to the CLI" {
	install_core

	invoke_installed_menu '4
q
'

	[ "$status" -eq 0 ]
	[[ "$output" == *'service: ok: owned service is stopped'* ]]
	[ ! -e "$NUTMERLIN_TMP_ROOT/nutmerlin/run/upsd.pid" ]
}

@test "client add forwards one literal label and displays its secret only once" {
	install_core
	invoke_installed_cli disable
	[ "$status" -eq 0 ]

	invoke_installed_menu '10
server one + literal
q
'

	[ "$status" -eq 0 ]
	[[ "$output" == *'client.add: ok: secondary client created'* ]] || {
		printf '%s\n' "$output" >&2
		false
	}
	[ "$(printf '%s\n' "$output" | grep -Fc 'secret=')" -eq 1 ]
	current_id=$(cat "$NUTMERLIN_OPT_ROOT/etc/nutmerlin/config/current")
	client_record=$(find "$NUTMERLIN_OPT_ROOT/etc/nutmerlin/config/sets/$current_id/clients" \
		-mindepth 1 -maxdepth 1 -type f -print)
	awk -F '\t' '$1 == "label" && $2 == "server one + literal" { found = 1 } END { exit !found }' \
		"$client_record"
}

@test "disable and uninstall confirmations cancel safely before confirmed owned operations" {
	install_core

	invoke_installed_menu '13
n
13
y
14
17
n
17
y
q
'

	[ "$status" -eq 0 ]
	[[ "$output" == *'Disable NUTMerlin? [y/N]'* ]]
	[[ "$output" == *'Disable cancelled; no changes were made'* ]]
	[[ "$output" == *'disable: ok: NUTMerlin is disabled'* ]]
	[[ "$output" == *'repair: ok: NUTMerlin owned state repaired; service remains disabled'* ]]
	[[ "$output" == *'Uninstall NUTMerlin and remove all owned configuration and credentials? [y/N]'* ]]
	[[ "$output" == *'Uninstall cancelled; no changes were made'* ]]
	[[ "$output" == *'uninstall: ok: NUTMerlin owned artifacts removed; Entware packages retained'* ]]
	[[ "$output" == *'State: not installed'* ]]
	[ ! -e "$NUTMERLIN_JFFS_ROOT/addons/nutmerlin" ]
	[ ! -e "$NUTMERLIN_OPT_ROOT/etc/nutmerlin" ]
	[ -f "$NUTMERLIN_OPT_ROOT/lib/opkg/status" ]
}

@test "source and LAN menus require confirmation and forward closed literal values" {
	install_core
	invoke_installed_cli disable
	[ "$status" -eq 0 ]
	mkdir -m 700 "$NUTMERLIN_TEST_ROOT/platform"
	printf 'usb-a\t0764\t0501\tCPS123456\t003\t001\t009\n' \
		>"$NUTMERLIN_TEST_ROOT/platform/usb-devices.tsv"
	{
		printf 'schema\tnutmerlin.network.v1\n'
		printf 'lan_address\t192.168.50.1\n'
		printf 'lan_netmask\t255.255.255.0\n'
		printf 'wan_address\t203.0.113.2\n'
	} >"$NUTMERLIN_TEST_ROOT/platform/network.tsv"
	chmod 600 "$NUTMERLIN_TEST_ROOT/platform/usb-devices.tsv" \
		"$NUTMERLIN_TEST_ROOT/platform/network.tsv"

	invoke_installed_menu '7
0764
0501
s
CPS123456
y
8
192.168.50.1
192.168.50.0/24
y
9
n
9
y
6
n
6
y
q
'

	[ "$status" -eq 0 ]
	[[ "$output" == *'source: ok: usbhid source selected while service is disabled; identity=serial'* ]]
	[[ "$output" == *'lan: ok: trusted LAN configured while service is disabled; address=192.168.50.1 cidr=192.168.50.0/24'* ]]
	[[ "$output" == *'Trusted LAN disable cancelled'* ]]
	[[ "$output" == *'lan: ok: trusted LAN disabled while service is disabled'* ]]
	[[ "$output" == *'Source change cancelled'* ]]
	[[ "$output" == *'source: ok: dummy source selected while service is disabled'* ]]
	invoke_installed_cli source show
	[ "$status" -eq 0 ]
	[ "$output" = 'source: ok: active source is dummy; identity=simulation' ]
}

@test "update menu accepts one confirmed local archive and keeps the menu callable" {
	install_core
	invoke_installed_cli disable
	[ "$status" -eq 0 ]
	run make --no-print-directory -C "$REPOSITORY_ROOT" package
	[ "$status" -eq 0 ]
	package_path=$REPOSITORY_ROOT/dist/nutmerlin-core-dev.tar.gz

	invoke_installed_menu "15
$package_path
y
q
"

	[ "$status" -eq 0 ]
	[[ "$output" == *'Update from this local archive? [y/N]'* ]]
	[[ "$output" == *'update: ok: NUTMerlin updated to 0.1.0-dev; service remains disabled'* ]]
	[[ "$output" == *'State: installed'* ]]
	[ -f "$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/lib/menu.sh" ]
}

@test "Entware refresh menu preserves default no and runs only the six confirmed roots" {
	install_core
	opkg_calls=$NUTMERLIN_TEST_ROOT/opkg.calls
	printf '%s\n' '#!/bin/sh' \
		'printf "%s\n" "$*" >>"$NUTMERLIN_TEST_ROOT/opkg.calls"' \
		'exit 0' >"$NUTMERLIN_OPT_ROOT/bin/opkg"
	chmod 700 "$NUTMERLIN_OPT_ROOT/bin/opkg"

	invoke_installed_cli dependencies refresh
	[ "$status" -eq 0 ]
	[[ "$output" == *'required Entware NUT package refresh declined; compatible package set retained'* ]]
	[ ! -e "$opkg_calls" ]

	invoke_installed_menu '16
n
16
y
q
'

	[ "$status" -eq 0 ]
	[ "$(printf '%s\n' "$output" | grep -Fc 'Refresh the six required Entware NUT packages? [y/N]')" -eq 2 ]
	[[ "$output" == *'dependencies.refresh: ok: required Entware NUT package refresh declined; compatible package set retained'* ]]
	[[ "$output" == *'dependencies.refresh: ok: required Entware NUT packages refreshed and compatibility revalidated'* ]]
	[ "$(cat "$opkg_calls")" = $'update\ninstall nut nut-common nut-server nut-upsc nut-driver-dummy-ups nut-driver-usbhid-ups' ]
	[ "$(cat "$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/enabled")" = 1 ]
}

@test "client revoke requires confirmation and never redisplays the existing secret" {
	install_core
	invoke_installed_cli disable
	[ "$status" -eq 0 ]
	invoke_installed_cli client add revoke-me --json
	[ "$status" -eq 0 ]
	client_id=$(printf '%s\n' "$output" | jq -r '.details.client_id')

	invoke_installed_menu "11
$client_id
n
q
"

	[ "$status" -eq 0 ]
	[[ "$output" == *'Client revocation cancelled'* ]]
	[[ "$output" != *'secret='* ]]
	current_id=$(cat "$NUTMERLIN_OPT_ROOT/etc/nutmerlin/config/current")
	[ -f "$NUTMERLIN_OPT_ROOT/etc/nutmerlin/config/sets/$current_id/clients/$client_id" ]

	invoke_installed_menu "11
$client_id
y
q
"

	[ "$status" -eq 0 ]
	[[ "$output" == *'client.revoke: ok: secondary client revoked'* ]]
	[[ "$output" != *'secret='* ]]
	current_id=$(cat "$NUTMERLIN_OPT_ROOT/etc/nutmerlin/config/current")
	[ ! -e "$NUTMERLIN_OPT_ROOT/etc/nutmerlin/config/sets/$current_id/clients/$client_id" ]
}

@test "EOF overlong input and shell syntax cancel without mutation or evaluation" {
	install_core
	owned_state_snapshot >"$BATS_TEST_TMPDIR/owned.before"
	overlong_choice=$(printf '%065d' 0)
	overlong_confirmation=$(printf '%065d' 0)

	invoke_installed_menu "$overlong_choice
13
$overlong_confirmation
q
"
	[ "$status" -eq 0 ]
	[[ "$output" == *'Invalid selection; choose one listed item'* ]]
	[[ "$output" == *'Confirmation input is invalid; action cancelled'* ]]
	[ "$(cat "$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/enabled")" = 1 ]

	invoke_installed_menu '13
'
	[ "$status" -eq 0 ]
	[[ "$output" == *'Disable cancelled; no changes were made'* ]]

	overlong_label=$(printf '%065d' 0)
	invoke_installed_menu "10
$overlong_label
q
"
	[ "$status" -eq 0 ]
	[[ "$output" == *'Input must contain 1-64 characters'* ]]

	marker=$REPOSITORY_ROOT/menu-pwned
	[ ! -e "$marker" ]
	invoke_installed_menu '10
safe;touch menu-pwned
q
'
	[ "$status" -eq 0 ]
	[[ "$output" == *'client refused: name must be 1-64 safe display characters'* ]]
	[ ! -e "$marker" ]
	owned_state_snapshot >"$BATS_TEST_TMPDIR/owned.after"
	cmp "$BATS_TEST_TMPDIR/owned.before" "$BATS_TEST_TMPDIR/owned.after"
}

@test "menu refuses a noninteractive production invocation" {
	run "$REPOSITORY_ROOT/bin/nutmerlin" menu

	[ "$status" -eq 64 ]
	[ "$output" = 'menu refused: an interactive local terminal is required' ]
}
