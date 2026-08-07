#!/usr/bin/env bats

setup() {
	REPOSITORY_ROOT=$(cd "$BATS_TEST_DIRNAME/../.." && pwd)
	# shellcheck source=test/lib/host-harness.sh
	. "$REPOSITORY_ROOT/test/lib/host-harness.sh"
	host_harness_setup
	# shellcheck source=test/lib/entware-fixture.sh
	. "$REPOSITORY_ROOT/test/lib/entware-fixture.sh"
	unset NUTMERLIN_FIXTURE_OMIT_PACKAGE NUTMERLIN_FIXTURE_BAD_DUMMY_HELP
	NUTMERLIN_TEST_OPKG_MODE=success
	NUTMERLIN_TEST_OPKG_REQUIRE_STOPPED=0
	NUTMERLIN_TEST_OPKG_STATUS_AFTER=$NUTMERLIN_TEST_ROOT/opkg-status-after
	export NUTMERLIN_TEST_OPKG_MODE NUTMERLIN_TEST_OPKG_REQUIRE_STOPPED \
		NUTMERLIN_TEST_OPKG_STATUS_AFTER
}

teardown() {
	host_harness_teardown
}

write_post_refresh_status() {
	refresh_version=${1:-2.8.3-1}
	: >"$NUTMERLIN_TEST_OPKG_STATUS_AFTER"
	for package_name in nut nut-common nut-server nut-upsc nut-driver-dummy-ups nut-driver-usbhid-ups; do
		{
			printf 'Package: %s\n' "$package_name"
			printf 'Version: %s\n' "$refresh_version"
			printf '%s\n' 'Architecture: aarch64-3.10' 'Status: install user installed' ''
		} >>"$NUTMERLIN_TEST_OPKG_STATUS_AFTER"
	done
}

install_opkg_adapter() {
	write_post_refresh_status "${1:-2.8.3-1}"
	printf '%s\n' '#!/bin/sh' \
		'printf "opkg %s\n" "$*" >>"$NUTMERLIN_EXTERNAL_CALL_LOG"' \
		'if [ "$NUTMERLIN_TEST_OPKG_REQUIRE_STOPPED" = 1 ]; then' \
		'  [ "$(cat "$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/enabled")" = 0 ] || exit 98' \
		'  [ ! -e "$NUTMERLIN_TEST_ROOT/platform/firewall.tsv" ] || exit 98' \
		'  [ ! -e "$NUTMERLIN_TEST_ROOT/platform/cru.tsv" ] || exit 98' \
		'  [ -d "$NUTMERLIN_TMP_ROOT/nutmerlin/lock/lifecycle" ] || exit 98' \
		'fi' \
		'if [ "$1" = update ] && [ "$#" -eq 1 ]; then' \
		'  [ "$NUTMERLIN_TEST_OPKG_MODE" != fail-update ]' \
		'  exit $?' \
		'fi' \
		'expected="install nut nut-common nut-server nut-upsc nut-driver-dummy-ups nut-driver-usbhid-ups"' \
		'if [ "$*" = "$expected" ]; then' \
		'  if [ "$NUTMERLIN_TEST_OPKG_MODE" = partial-fail ]; then' \
		'    printf "%s\n" "#!/bin/sh" "printf '\''%s\\n'\'' '\''usage: dummy-ups -a ID'\''" >"$NUTMERLIN_OPT_ROOT/lib/nut/dummy-ups"' \
		'    chmod 700 "$NUTMERLIN_OPT_ROOT/lib/nut/dummy-ups"' \
		'    mkdir -p "$NUTMERLIN_OPT_ROOT/etc/nut"' \
		'    printf "%s\n" "[partial-package-state]" >"$NUTMERLIN_OPT_ROOT/etc/nut/ups.conf"' \
		'    exit 1' \
		'  fi' \
		'  [ "$NUTMERLIN_TEST_OPKG_MODE" != fail-install ] || exit 1' \
		'  if [ "$NUTMERLIN_TEST_OPKG_MODE" = incompatible-post ]; then' \
		'    printf "%s\n" "#!/bin/sh" "printf '\''%s\\n'\'' '\''usage: dummy-ups -a ID'\''" >"$NUTMERLIN_OPT_ROOT/lib/nut/dummy-ups"' \
		'    chmod 700 "$NUTMERLIN_OPT_ROOT/lib/nut/dummy-ups"' \
		'  elif [ "$NUTMERLIN_TEST_OPKG_MODE" = foreign-post ]; then' \
		'    cp "$NUTMERLIN_TEST_OPKG_STATUS_AFTER" "$NUTMERLIN_OPT_ROOT/lib/opkg/status"' \
		'    mkdir -p "$NUTMERLIN_OPT_ROOT/etc/nut"' \
		'    printf "%s\n" "[package-created]" >"$NUTMERLIN_OPT_ROOT/etc/nut/ups.conf"' \
		'  else' \
		'    cp "$NUTMERLIN_TEST_OPKG_STATUS_AFTER" "$NUTMERLIN_OPT_ROOT/lib/opkg/status"' \
		'  fi' \
		'  exit 0' \
		'fi' \
		'exit 99' >"$NUTMERLIN_OPT_ROOT/bin/opkg"
	chmod 700 "$NUTMERLIN_OPT_ROOT/bin/opkg"
}

invoke_install() {
	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		NUTMERLIN_TEST_OPKG_MODE="$NUTMERLIN_TEST_OPKG_MODE" \
		NUTMERLIN_TEST_OPKG_REQUIRE_STOPPED="$NUTMERLIN_TEST_OPKG_REQUIRE_STOPPED" \
		NUTMERLIN_TEST_OPKG_STATUS_AFTER="$NUTMERLIN_TEST_OPKG_STATUS_AFTER" \
		"$REPOSITORY_ROOT/install.sh" "$@"
}

invoke_interactive_install() {
	interactive_answer=$1
	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		NUTMERLIN_TEST_INTERACTIVE=1 \
		NUTMERLIN_TEST_OPKG_MODE="$NUTMERLIN_TEST_OPKG_MODE" \
		NUTMERLIN_TEST_OPKG_REQUIRE_STOPPED="$NUTMERLIN_TEST_OPKG_REQUIRE_STOPPED" \
		NUTMERLIN_TEST_OPKG_STATUS_AFTER="$NUTMERLIN_TEST_OPKG_STATUS_AFTER" \
		/bin/sh -c 'printf "%s\n" "$1" | "$2"' sh "$interactive_answer" \
		"$REPOSITORY_ROOT/install.sh"
}

invoke_installed_cli() {
	env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		"$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/bin/nutmerlin" "$@"
}

prepare_owned_lan_admission() {
	code_root=$NUTMERLIN_JFFS_ROOT/addons/nutmerlin
	printf '%s\n' 0 >"$code_root/enabled"
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
	invoke_installed_cli source configure-usbhid --vendor-id 0764 \
		--product-id 0501 --serial CPS123456 >/dev/null
	invoke_installed_cli lan configure --address 192.168.50.1 \
		--cidr 192.168.50.0/24 >/dev/null
	env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		/bin/sh -c '
			for module in paths configuration ownership platform; do
				. "$1/$module.sh"
			done
			paths_initialize
			platform_firewall_ensure 192.168.50.1 192.168.50.0/24
			platform_cru_ensure
		' sh "$code_root/lib"
	printf '%s\n' 1 >"$code_root/enabled"
}

@test "interactive compatible install defaults to no refresh and proceeds" {
	entware_fixture_setup
	install_opkg_adapter

	invoke_interactive_install ''

	[ "$status" -eq 0 ]
	[[ "$output" == *'Refresh the six required Entware NUT packages? [y/N]'* ]]
	[[ "$output" == *'NUTMerlin installed: dummy is configured loopback-only'* ]]
	[ ! -e "$NUTMERLIN_EXTERNAL_CALL_LOG" ]
}

@test "missing package decline stops without package or owned mutation" {
	NUTMERLIN_FIXTURE_OMIT_PACKAGE=nut-server
	entware_fixture_setup
	install_opkg_adapter

	invoke_interactive_install ''

	[ "$status" -eq 69 ]
	[[ "$output" == *'missing installed packages: nut-server'* ]]
	[[ "$output" == *'Refresh the six required Entware NUT packages? [y/N]'* ]]
	[[ "$output" == *'Recovery: rerun ./install.sh --install-dependencies'* ]]
	[ ! -e "$NUTMERLIN_EXTERNAL_CALL_LOG" ]
	[ ! -e "$NUTMERLIN_JFFS_ROOT/addons/nutmerlin" ]
	[ ! -e "$NUTMERLIN_OPT_ROOT/etc/nutmerlin" ]
}

@test "incompatible decline gives exact bounded recovery guidance" {
	NUTMERLIN_FIXTURE_BAD_DUMMY_HELP=1
	entware_fixture_setup
	install_opkg_adapter

	invoke_interactive_install ''

	[ "$status" -eq 78 ]
	[[ "$output" == *'dummy-ups lacks required options: -a -F'* ]]
	[[ "$output" == *'Recovery: rerun ./install.sh --install-dependencies'* ]]
	[[ "$output" == *'/opt/bin/opkg update; /opt/bin/opkg install nut nut-common nut-server nut-upsc nut-driver-dummy-ups nut-driver-usbhid-ups'* ]]
	[ ! -e "$NUTMERLIN_EXTERNAL_CALL_LOG" ]
}

@test "explicit dependency flag installs all six roots and re-probes them" {
	NUTMERLIN_FIXTURE_OMIT_PACKAGE=nut-server
	entware_fixture_setup
	install_opkg_adapter 2.8.3-1

	invoke_install --install-dependencies

	[ "$status" -eq 0 ]
	[ "$(cat "$NUTMERLIN_EXTERNAL_CALL_LOG")" = $'opkg update\nopkg install nut nut-common nut-server nut-upsc nut-driver-dummy-ups nut-driver-usbhid-ups' ]
	grep -Fx $'nut-server\t2.8.3-1\taarch64-3.10' \
		"$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/entware.tsv"
	[[ "$output" == *'Entware NUT package evidence before refresh:'* ]]
	[[ "$output" == *'Entware NUT package evidence after refresh:'* ]]
	[[ "$output" == *'Entware NUT package refresh completed and compatibility was re-verified'* ]]
	! rg -n 'opkg (upgrade|remove)|feeds|bootstrap' "$NUTMERLIN_EXTERNAL_CALL_LOG"
}

@test "compatible package version drift can decline refresh and proceed" {
	entware_fixture_setup
	install_opkg_adapter 2.8.5-1
	invoke_install
	[ "$status" -eq 0 ]
	cp "$NUTMERLIN_TEST_OPKG_STATUS_AFTER" "$NUTMERLIN_OPT_ROOT/lib/opkg/status"

	invoke_install

	[ "$status" -eq 0 ]
	[ "$output" = 'NUTMerlin already installed: owned state is complete' ]
	[ ! -e "$NUTMERLIN_EXTERNAL_CALL_LOG" ]
}

@test "interactive yes refreshes all six compatible roots rather than only missing packages" {
	entware_fixture_setup
	install_opkg_adapter 2.8.4-1

	invoke_interactive_install y

	[ "$status" -eq 0 ]
	[ "$(cat "$NUTMERLIN_EXTERNAL_CALL_LOG")" = $'opkg update\nopkg install nut nut-common nut-server nut-upsc nut-driver-dummy-ups nut-driver-usbhid-ups' ]
	grep -Fx $'nut\t2.8.4-1\taarch64-3.10' \
		"$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/entware.tsv"
}

@test "noninteractive input and unknown flags cannot authorize package mutation" {
	NUTMERLIN_FIXTURE_OMIT_PACKAGE=nut-server
	entware_fixture_setup
	install_opkg_adapter

	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		NUTMERLIN_TEST_OPKG_MODE=success \
		NUTMERLIN_TEST_OPKG_STATUS_AFTER="$NUTMERLIN_TEST_OPKG_STATUS_AFTER" \
		/bin/sh -c 'printf "y\n" | "$1"' sh "$REPOSITORY_ROOT/install.sh"
	[ "$status" -eq 69 ]
	[ ! -e "$NUTMERLIN_EXTERNAL_CALL_LOG" ]

	invoke_install --upgrade-entware
	[ "$status" -eq 64 ]
	[ ! -e "$NUTMERLIN_EXTERNAL_CALL_LOG" ]
}

@test "package failure leaves an existing owned installation disabled and stopped" {
	entware_fixture_setup
	install_opkg_adapter
	invoke_install
	[ "$status" -eq 0 ]
	code_root=$NUTMERLIN_JFFS_ROOT/addons/nutmerlin
	before_id=$(cat "$code_root/installation.id")
	NUTMERLIN_TEST_OPKG_MODE=fail-install

	invoke_install --install-dependencies

	[ "$status" -eq 75 ]
	[ "$(cat "$code_root/enabled")" = 0 ]
	[ "$(cat "$code_root/installation.id")" = "$before_id" ]
	[ -d "$NUTMERLIN_OPT_ROOT/etc/nutmerlin" ]
	[ ! -e "$NUTMERLIN_TMP_ROOT/nutmerlin/run/upsd.pid" ]
	[[ "$output" == *'package refresh failed; NUTMerlin remains disabled and stopped'* ]]
	[[ "$output" == *'Recovery: resolve the Entware error, then rerun ./install.sh --install-dependencies'* ]]
}

@test "occupied lifecycle lock refuses before disabling or invoking opkg" {
	entware_fixture_setup
	install_opkg_adapter
	invoke_install
	[ "$status" -eq 0 ]
	code_root=$NUTMERLIN_JFFS_ROOT/addons/nutmerlin
	lock_root=$NUTMERLIN_TMP_ROOT/nutmerlin/lock/lifecycle
	mkdir -m 700 "$lock_root"
	printf '%s\n' 12345 >"$lock_root/owner"
	chmod 600 "$lock_root/owner"

	invoke_install --install-dependencies

	[ "$status" -eq 75 ]
	[ "$(cat "$code_root/enabled")" = 1 ]
	[[ "$output" == *'lifecycle work is already in progress'* ]]
	[ ! -e "$NUTMERLIN_EXTERNAL_CALL_LOG" ]
}

@test "partial opkg failure still runs compatibility and foreign-state post-checks" {
	entware_fixture_setup
	install_opkg_adapter
	invoke_install
	[ "$status" -eq 0 ]
	NUTMERLIN_TEST_OPKG_MODE=partial-fail

	invoke_install --install-dependencies

	[ "$status" -eq 78 ]
	[ "$(cat "$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/enabled")" = 0 ]
	[[ "$output" == *'dummy-ups lacks required options: -a -F'* ]]
	[[ "$output" == *'Entware NUT package evidence after refresh:'* ]]
	[[ "$output" == *'foreign NUT configuration'* ]]
	[[ "$output" == *'Recovery: resolve the Entware error, then rerun ./install.sh --install-dependencies'* ]]
}

@test "owned recovery and trusted-LAN admission are closed before opkg runs" {
	entware_fixture_setup
	install_opkg_adapter
	invoke_install
	[ "$status" -eq 0 ]
	prepare_owned_lan_admission
	[ -e "$NUTMERLIN_TEST_ROOT/platform/firewall.tsv" ]
	[ -e "$NUTMERLIN_TEST_ROOT/platform/cru.tsv" ]
	NUTMERLIN_TEST_OPKG_REQUIRE_STOPPED=1

	invoke_install --install-dependencies

	[ "$status" -eq 0 ]
	[ ! -e "$NUTMERLIN_TEST_ROOT/platform/firewall.tsv" ]
	[ -e "$NUTMERLIN_TEST_ROOT/platform/cru.tsv" ]
	[ "$(cat "$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/enabled")" = 1 ]
	[ "$(cat "$NUTMERLIN_EXTERNAL_CALL_LOG")" = $'opkg update\nopkg install nut nut-common nut-server nut-upsc nut-driver-dummy-ups nut-driver-usbhid-ups' ]
}

@test "incompatible post-refresh state fails closed after exact package operations" {
	entware_fixture_setup
	install_opkg_adapter
	invoke_install
	[ "$status" -eq 0 ]
	NUTMERLIN_TEST_OPKG_MODE=incompatible-post

	invoke_install --install-dependencies

	[ "$status" -eq 78 ]
	[ "$(cat "$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/enabled")" = 0 ]
	[[ "$output" == *'dummy-ups lacks required options: -a -F'* ]]
	[[ "$output" == *'post-refresh compatibility failed; NUTMerlin remains disabled and stopped'* ]]
	[[ "$output" == *'Recovery: resolve the Entware error, then rerun ./install.sh --install-dependencies'* ]]
}

@test "unsafe opkg hard links or write permissions refuse before package mutation" {
	entware_fixture_setup
	install_opkg_adapter
	opkg_path=$NUTMERLIN_OPT_ROOT/bin/opkg
	ln "$opkg_path" "$NUTMERLIN_OPT_ROOT/bin/opkg-alias"

	invoke_install --install-dependencies
	[ "$status" -eq 78 ]
	[[ "$output" == *'package manager has unsafe ownership, links, or mode'* ]]
	[ ! -e "$NUTMERLIN_EXTERNAL_CALL_LOG" ]

	rm "$NUTMERLIN_OPT_ROOT/bin/opkg-alias"
	chmod 722 "$opkg_path"
	invoke_install --install-dependencies
	[ "$status" -eq 78 ]
	[[ "$output" == *'package manager has unsafe ownership, links, or mode'* ]]
	[ ! -e "$NUTMERLIN_EXTERNAL_CALL_LOG" ]
}

@test "foreign NUT state refuses before an explicitly requested package refresh" {
	entware_fixture_setup
	install_opkg_adapter
	mkdir -p "$NUTMERLIN_OPT_ROOT/etc/nut"
	printf '%s\n' '[foreign]' >"$NUTMERLIN_OPT_ROOT/etc/nut/ups.conf"

	invoke_install --install-dependencies

	[ "$status" -eq 78 ]
	[[ "$output" == *'foreign NUT configuration'* ]]
	[ ! -e "$NUTMERLIN_EXTERNAL_CALL_LOG" ]
}

@test "package-created foreign NUT configuration is refused by the post-refresh check" {
	entware_fixture_setup
	install_opkg_adapter
	NUTMERLIN_TEST_OPKG_MODE=foreign-post

	invoke_install --install-dependencies

	[ "$status" -eq 78 ]
	[[ "$output" == *'foreign NUT configuration'* ]]
	[[ "$output" == *'post-refresh ownership check failed'* ]]
	[ ! -e "$NUTMERLIN_JFFS_ROOT/addons/nutmerlin" ]
}
