#!/usr/bin/env bats

setup() {
	REPOSITORY_ROOT=$(cd "$BATS_TEST_DIRNAME/../.." && pwd)
	# shellcheck source=test/lib/host-harness.sh
	. "$REPOSITORY_ROOT/test/lib/host-harness.sh"
	host_harness_setup
	# shellcheck source=test/lib/entware-fixture.sh
	. "$REPOSITORY_ROOT/test/lib/entware-fixture.sh"
	entware_fixture_setup
	make --no-print-directory -C "$REPOSITORY_ROOT" install DESTDIR="$NUTMERLIN_TEST_ROOT" \
		>/dev/null
	code_root=$NUTMERLIN_JFFS_ROOT/addons/nutmerlin
	config_root=$NUTMERLIN_OPT_ROOT/etc/nutmerlin
	installed_cli=$code_root/bin/nutmerlin
}

teardown() {
	host_harness_teardown
}

invoke_cli() {
	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		NUTMERLIN_TEST_STORAGE_STATE="${NUTMERLIN_TEST_STORAGE_STATE:-}" \
		NUTMERLIN_TEST_MANAGEMENT_FAIL_AFTER="${NUTMERLIN_TEST_MANAGEMENT_FAIL_AFTER:-}" \
		"$installed_cli" "$@"
}

invoke_platform() {
	env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		/bin/sh -c '
			for module in paths configuration hooks ownership platform; do
				. "$1/$module.sh"
			done
			paths_initialize
			"$2"
		' sh "$code_root/lib" "$1"
}

prepare_owned_lan_admission() {
	printf '%s\n' 0 >"$code_root/enabled"
	mkdir -p "$NUTMERLIN_TEST_ROOT/platform"
	chmod 700 "$NUTMERLIN_TEST_ROOT/platform"
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
	invoke_cli source configure-usbhid --vendor-id 0764 \
		--product-id 0501 --serial CPS123456
	[ "$status" -eq 0 ]
	invoke_cli lan configure --address 192.168.50.1 --cidr 192.168.50.0/24
	[ "$status" -eq 0 ]
	env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		/bin/sh -c '
			for module in paths configuration hooks ownership platform; do
				. "$1/$module.sh"
			done
			paths_initialize
			platform_firewall_ensure 192.168.50.1 192.168.50.0/24
			platform_cru_ensure
		' sh "$code_root/lib"
	printf '%s\n' 1 >"$code_root/enabled"
}

@test "disable removes live recovery surfaces and retains owned data and Entware" {
	printf '%s\n' 0 >"$code_root/enabled"
	invoke_cli client add server-a
	[ "$status" -eq 0 ]
	client_set=$(cat "$config_root/config/current")
	client_record_count=$(find "$config_root/config/sets/$client_set/clients" \
		-mindepth 1 -maxdepth 1 -type f | wc -l)
	[ "$client_record_count" -eq 1 ]
	printf '%s\n' 1 >"$code_root/enabled"
	invoke_platform platform_cru_ensure
	cp "$NUTMERLIN_OPT_ROOT/lib/opkg/status" "$BATS_TEST_TMPDIR/opkg-status.before"

	invoke_cli disable

	[ "$status" -eq 0 ]
	[ "$output" = 'disable: ok: NUTMerlin is disabled; owned data and Entware packages were retained' ]
	[ "$(cat "$code_root/enabled")" = 0 ]
	[ -d "$code_root" ]
	[ -d "$config_root" ]
	[ "$(find "$config_root/config/sets/$client_set/clients" \
		-mindepth 1 -maxdepth 1 -type f | wc -l)" -eq 1 ]
	[ ! -e "$NUTMERLIN_TEST_ROOT/platform/cru.tsv" ]
	cmp "$BATS_TEST_TMPDIR/opkg-status.before" "$NUTMERLIN_OPT_ROOT/lib/opkg/status"
	for hook_name in services-start services-stop post-mount unmount firewall-start; do
		[ "$(grep -c '^# BEGIN NUTMerlin managed block:' \
			"$NUTMERLIN_JFFS_ROOT/scripts/$hook_name")" -eq 1 ]
	done

	invoke_cli disable
	[ "$status" -eq 0 ]
	[ "$output" = 'disable: ok: NUTMerlin is disabled; owned data and Entware packages were retained' ]
}

@test "services-start preserves disabled state with available or missing Entware storage" {
	invoke_cli disable
	[ "$status" -eq 0 ]
	for storage in available missing; do
		NUTMERLIN_TEST_STORAGE_STATE=$storage
		invoke_cli hook services-start
		[ "$status" -eq 69 ]
		[ "$(cat "$code_root/enabled")" = 0 ]
		[ ! -e "$NUTMERLIN_TEST_ROOT/platform/cru.tsv" ]
		[ ! -e "$NUTMERLIN_TMP_ROOT/nutmerlin/run/upsd.pid" ]
		[ ! -e "$NUTMERLIN_TMP_ROOT/nutmerlin/run/dummy-ups.pid" ]
	done
}

@test "disable closes attributable LAN state when Entware storage is missing" {
	prepare_owned_lan_admission
	[ -e "$NUTMERLIN_TEST_ROOT/platform/firewall.tsv" ]
	[ -e "$NUTMERLIN_TEST_ROOT/platform/cru.tsv" ]
	offline_config=$BATS_TEST_TMPDIR/offline-config
	mv "$config_root" "$offline_config"
	NUTMERLIN_TEST_STORAGE_STATE=missing

	invoke_cli disable

	[ "$status" -eq 0 ]
	[ "$(cat "$code_root/enabled")" = 0 ]
	[ ! -e "$NUTMERLIN_TEST_ROOT/platform/firewall.tsv" ]
	[ ! -e "$NUTMERLIN_TEST_ROOT/platform/cru.tsv" ]
	[ -d "$offline_config" ]
	[ -f "$offline_config/installation.id" ]
	for hook_name in services-start services-stop post-mount unmount firewall-start; do
		[ "$(grep -c '^# BEGIN NUTMerlin managed block:' \
			"$NUTMERLIN_JFFS_ROOT/scripts/$hook_name")" -eq 1 ]
	done
}

@test "missing-storage disable refuses modified code before changing live surfaces" {
	prepare_owned_lan_admission
	offline_config=$BATS_TEST_TMPDIR/offline-modified-code-config
	mv "$config_root" "$offline_config"
	NUTMERLIN_TEST_STORAGE_STATE=missing
	printf '%s\n' '# modified' >>"$code_root/lib/status.sh"
	cp "$code_root/enabled" "$BATS_TEST_TMPDIR/enabled.before"
	cp "$NUTMERLIN_TEST_ROOT/platform/cru.tsv" "$BATS_TEST_TMPDIR/cru.before"
	cp "$NUTMERLIN_TEST_ROOT/platform/firewall.tsv" "$BATS_TEST_TMPDIR/firewall.before"

	invoke_cli disable

	[ "$status" -eq 78 ]
	[[ "$output" == *'disable refused: installed code ownership evidence is incomplete'* ]]
	cmp "$BATS_TEST_TMPDIR/enabled.before" "$code_root/enabled"
	cmp "$BATS_TEST_TMPDIR/cru.before" "$NUTMERLIN_TEST_ROOT/platform/cru.tsv"
	cmp "$BATS_TEST_TMPDIR/firewall.before" "$NUTMERLIN_TEST_ROOT/platform/firewall.tsv"
}

@test "disable fault checkpoints still converge every live surface closed" {
	for checkpoint in enabled firewall service schedule recovery; do
		prepare_owned_lan_admission
		NUTMERLIN_TEST_MANAGEMENT_FAIL_AFTER=$checkpoint

		invoke_cli disable

		[ "$status" -eq 75 ]
		[ "$(cat "$code_root/enabled")" = 0 ]
		[ ! -e "$NUTMERLIN_TEST_ROOT/platform/firewall.tsv" ]
		[ ! -e "$NUTMERLIN_TEST_ROOT/platform/cru.tsv" ]
		unset NUTMERLIN_TEST_MANAGEMENT_FAIL_AFTER
	done
}

@test "service start refuses incompatible Entware before launching the driver" {
	cat >"$NUTMERLIN_OPT_ROOT/lib/nut/dummy-ups" <<'DRIVER'
#!/bin/sh
if [ "$1" = -h ]; then
	printf '%s\n' 'usage: dummy-ups -a ID'
	exit 0
fi
: >"$NUTMERLIN_TEST_ROOT/driver-was-started"
exit 1
DRIVER

	invoke_cli service start
	[ "$status" -eq 78 ]
	[[ "$output" == *'dummy-ups lacks required options'* ]]
	[ ! -e "$NUTMERLIN_TEST_ROOT/driver-was-started" ]
	[ ! -e "$NUTMERLIN_TMP_ROOT/nutmerlin/run/dummy-ups.pid" ]
	[ ! -e "$NUTMERLIN_TMP_ROOT/nutmerlin/run/upsd.pid" ]
	[ ! -e "$NUTMERLIN_TEST_ROOT/platform/firewall.tsv" ]
}

@test "enable revalidates the selected source before changing disabled state" {
	prepare_owned_lan_admission
	invoke_cli disable
	[ "$status" -eq 0 ]
	rm "$NUTMERLIN_TEST_ROOT/platform/usb-devices.tsv"

	invoke_cli enable

	[ "$status" -eq 69 ]
	[[ "$output" == *'source unavailable: no USB device matches the configured vendor/product'* ]]
	[ "$(cat "$code_root/enabled")" = 0 ]
	[ ! -e "$NUTMERLIN_TEST_ROOT/platform/cru.tsv" ]
	[ ! -e "$NUTMERLIN_TEST_ROOT/platform/firewall.tsv" ]
}

@test "repair restores a missing attributable hook block while staying disabled" {
	invoke_cli disable
	[ "$status" -eq 0 ]
	installation_id=$(cat "$code_root/installation.id")
	hook_path=$NUTMERLIN_JFFS_ROOT/scripts/post-mount
	: >"$hook_path"
	chmod 755 "$hook_path"

	invoke_cli repair

	[ "$status" -eq 0 ]
	[ "$output" = 'repair: ok: NUTMerlin owned state repaired; service remains disabled' ]
	[ "$(grep -c "^# BEGIN NUTMerlin managed block: $installation_id post-mount$" \
		"$hook_path")" -eq 1 ]
	[ "$(grep -c "^# END NUTMerlin managed block: $installation_id post-mount$" \
		"$hook_path")" -eq 1 ]
	[ "$(cat "$code_root/enabled")" = 0 ]
	[ ! -e "$NUTMERLIN_TEST_ROOT/platform/cru.tsv" ]

	invoke_cli repair
	[ "$status" -eq 0 ]
	[ "$output" = 'repair: ok: NUTMerlin owned state repaired; service remains disabled' ]
}

@test "repair restores attributable modes and an unambiguous missing current selector" {
	invoke_cli disable
	[ "$status" -eq 0 ]
	set_id=$(cat "$config_root/config/current")
	rm "$config_root/config/current"
	chmod 700 "$code_root/bin/nutmerlin"
	chmod 600 "$code_root/lib/status.sh"
	chmod 755 "$config_root"
	chmod 750 "$config_root/config/sets/$set_id"
	chmod 640 "$config_root/config/sets/$set_id/ups.conf"

	invoke_cli repair

	[ "$status" -eq 0 ]
	[ "$(cat "$config_root/config/current")" = "$set_id" ]
	[ "$(stat -c '%a' "$code_root/bin/nutmerlin")" = 755 ]
	[ "$(stat -c '%a' "$code_root/lib/status.sh")" = 644 ]
	[ "$(stat -c '%a' "$config_root")" = 700 ]
	[ "$(stat -c '%a' "$config_root/config/sets/$set_id")" = 700 ]
	[ "$(stat -c '%a' "$config_root/config/sets/$set_id/ups.conf")" = 600 ]
	[ "$(cat "$code_root/enabled")" = 0 ]
}

@test "repair reconstructs the missing last-good selector from exactly two valid sets" {
	invoke_cli disable
	[ "$status" -eq 0 ]
	previous_set=$(cat "$config_root/config/current")
	invoke_cli source use-dummy
	[ "$status" -eq 0 ]
	current_set=$(cat "$config_root/config/current")
	[ "$current_set" != "$previous_set" ]
	[ "$(cat "$config_root/config/last-good")" = "$previous_set" ]
	rm "$config_root/config/last-good"

	invoke_cli repair

	[ "$status" -eq 0 ]
	[ "$(cat "$config_root/config/current")" = "$current_set" ]
	[ "$(cat "$config_root/config/last-good")" = "$previous_set" ]
	[ "$(find "$config_root/config/sets" -mindepth 1 -maxdepth 1 -type d | wc -l)" -eq 2 ]
}

@test "repair refuses modified hook evidence before changing repairable state" {
	invoke_cli disable
	[ "$status" -eq 0 ]
	chmod 700 "$code_root/bin/nutmerlin"
	missing_hook=$NUTMERLIN_JFFS_ROOT/scripts/post-mount
	modified_hook=$NUTMERLIN_JFFS_ROOT/scripts/services-stop
	: >"$missing_hook"
	chmod 755 "$missing_hook"
	printf '%s\n' 'foreign concurrent change' >>"$modified_hook"

	invoke_cli repair

	[ "$status" -eq 78 ]
	[[ "$output" == *'repair refused: Merlin hook state is modified or ambiguous'* ]]
	[ "$(stat -c '%a' "$code_root/bin/nutmerlin")" = 700 ]
	[ ! -s "$missing_hook" ]
	[ "$(tail -1 "$modified_hook")" = 'foreign concurrent change' ]
}

@test "repair refuses ambiguous scheduler state before changing repairable modes" {
	invoke_platform platform_cru_ensure
	printf '%s\n' 'foreign schedule change' >>"$NUTMERLIN_TEST_ROOT/platform/cru.tsv"
	chmod 700 "$code_root/bin/nutmerlin"
	cp "$NUTMERLIN_TEST_ROOT/platform/cru.tsv" "$BATS_TEST_TMPDIR/cru.before"

	invoke_cli repair

	[ "$status" -eq 78 ]
	[ "$(stat -c '%a' "$code_root/bin/nutmerlin")" = 700 ]
	cmp "$BATS_TEST_TMPDIR/cru.before" "$NUTMERLIN_TEST_ROOT/platform/cru.tsv"
}

@test "uninstall removes only attributable artifacts and retains Entware and hook prefixes" {
	invoke_cli disable
	[ "$status" -eq 0 ]
	invoke_cli client add server-a
	[ "$status" -eq 0 ]
	for hook_name in services-start services-stop post-mount unmount firewall-start; do
		hook_path=$NUTMERLIN_JFFS_ROOT/scripts/$hook_name
		printf 'unrelated-%s\n' "$hook_name" >"$BATS_TEST_TMPDIR/$hook_name.prefix"
		cp "$BATS_TEST_TMPDIR/$hook_name.prefix" "$BATS_TEST_TMPDIR/$hook_name.combined"
		printf '\n' >>"$BATS_TEST_TMPDIR/$hook_name.combined"
		cat "$hook_path" >>"$BATS_TEST_TMPDIR/$hook_name.combined"
		mv "$BATS_TEST_TMPDIR/$hook_name.combined" "$hook_path"
		chmod 755 "$hook_path"
	done
	invoke_platform platform_cru_ensure
	cp "$NUTMERLIN_OPT_ROOT/lib/opkg/status" "$BATS_TEST_TMPDIR/opkg-status.before"
	cp "$NUTMERLIN_OPT_ROOT/bin/opkg" "$BATS_TEST_TMPDIR/opkg.before"
	printf '%s\n' unrelated >"$NUTMERLIN_JFFS_ROOT/unrelated-file"

	invoke_cli uninstall

	[ "$status" -eq 0 ]
	[ "$output" = 'uninstall: ok: NUTMerlin owned artifacts removed; Entware packages retained' ]
	[ ! -e "$code_root" ]
	[ ! -e "$config_root" ]
	[ ! -e "$NUTMERLIN_TMP_ROOT/nutmerlin" ]
	[ ! -e "$NUTMERLIN_TEST_ROOT/platform/cru.tsv" ]
	[ ! -e "$NUTMERLIN_TEST_ROOT/platform/firewall.tsv" ]
	for hook_name in services-start services-stop post-mount unmount firewall-start; do
		cmp "$BATS_TEST_TMPDIR/$hook_name.prefix" \
			"$NUTMERLIN_JFFS_ROOT/scripts/$hook_name"
	done
	[ "$(cat "$NUTMERLIN_JFFS_ROOT/unrelated-file")" = unrelated ]
	cmp "$BATS_TEST_TMPDIR/opkg-status.before" "$NUTMERLIN_OPT_ROOT/lib/opkg/status"
	cmp "$BATS_TEST_TMPDIR/opkg.before" "$NUTMERLIN_OPT_ROOT/bin/opkg"

	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		"$REPOSITORY_ROOT/bin/nutmerlin" uninstall
	[ "$status" -eq 0 ]
	[ "$output" = 'uninstall: ok: NUTMerlin is already uninstalled; no artifacts changed' ]
}

@test "uninstall with missing Entware storage disables and reports residual data" {
	prepare_owned_lan_admission
	offline_config=$BATS_TEST_TMPDIR/offline-uninstall-config
	mv "$config_root" "$offline_config"
	NUTMERLIN_TEST_STORAGE_STATE=missing

	invoke_cli uninstall

	[ "$status" -eq 69 ]
	[[ "$output" == *'uninstall unavailable: attributable /opt state is missing'* ]]
	[[ "$output" == *'residual data may remain at /opt/etc/nutmerlin'* ]]
	[ "$(cat "$code_root/enabled")" = 0 ]
	[ -d "$code_root" ]
	[ -d "$offline_config" ]
	[ ! -e "$NUTMERLIN_TEST_ROOT/platform/firewall.tsv" ]
	[ ! -e "$NUTMERLIN_TEST_ROOT/platform/cru.tsv" ]
	for hook_name in services-start services-stop post-mount unmount firewall-start; do
		[ "$(grep -c '^# BEGIN NUTMerlin managed block:' \
			"$NUTMERLIN_JFFS_ROOT/scripts/$hook_name")" -eq 1 ]
	done
}

@test "uninstall refuses ambiguous owned evidence before any mutation" {
	invoke_platform platform_cru_ensure
	selector_path=$config_root/config/current
	selector_alias=$BATS_TEST_TMPDIR/current-alias
	ln "$selector_path" "$selector_alias"
	cp "$code_root/enabled" "$BATS_TEST_TMPDIR/enabled.before"

	invoke_cli uninstall

	[ "$status" -eq 78 ]
	[[ "$output" == *'uninstall refused: /opt state is ownership_mismatch'* ]]
	cmp "$BATS_TEST_TMPDIR/enabled.before" "$code_root/enabled"
	[ -e "$NUTMERLIN_TEST_ROOT/platform/cru.tsv" ]
	[ -d "$code_root" ]
	[ -d "$config_root" ]
	[ "$(stat -c '%h' "$selector_path")" -eq 2 ]
}

@test "uninstall refuses ambiguous firewall state before changing enabled state" {
	prepare_owned_lan_admission
	printf '%s\n' 'foreign firewall change' >>"$NUTMERLIN_TEST_ROOT/platform/firewall.tsv"
	cp "$code_root/enabled" "$BATS_TEST_TMPDIR/enabled.before"
	cp "$NUTMERLIN_TEST_ROOT/platform/firewall.tsv" "$BATS_TEST_TMPDIR/firewall.before"

	invoke_cli uninstall

	[ "$status" -eq 78 ]
	cmp "$BATS_TEST_TMPDIR/enabled.before" "$code_root/enabled"
	cmp "$BATS_TEST_TMPDIR/firewall.before" "$NUTMERLIN_TEST_ROOT/platform/firewall.tsv"
	[ -d "$code_root" ]
	[ -d "$config_root" ]
}

@test "interrupted uninstall remains disabled and converges on an exact retry" {
	NUTMERLIN_TEST_MANAGEMENT_FAIL_AFTER=hooks

	invoke_cli uninstall

	[ "$status" -eq 75 ]
	[[ "$output" == *'management temporary failure after hooks'* ]]
	[ "$(cat "$code_root/enabled")" = 0 ]
	[ -d "$code_root" ]
	[ -d "$config_root" ]
	for hook_name in services-start services-stop post-mount unmount firewall-start; do
		[ "$(grep -c '^# BEGIN NUTMerlin managed block:' \
			"$NUTMERLIN_JFFS_ROOT/scripts/$hook_name" || :)" -eq 0 ]
	done

	unset NUTMERLIN_TEST_MANAGEMENT_FAIL_AFTER
	invoke_cli uninstall
	[ "$status" -eq 0 ]
	[ ! -e "$code_root" ]
	[ ! -e "$config_root" ]
}

@test "management commands reject traversal arguments before changing owned state" {
	before_id=$(cat "$code_root/installation.id")
	outside_path=$BATS_TEST_TMPDIR/outside
	printf '%s\n' preserve >"$outside_path"
	for management_action in enable disable repair uninstall; do
		invoke_cli "$management_action" ../outside
		[ "$status" -eq 64 ]
		[ "$(cat "$code_root/installation.id")" = "$before_id" ]
		[ "$(cat "$outside_path")" = preserve ]
	done
}

@test "uninstall refuses a symlinked owned-root entry without following it" {
	outside_path=$BATS_TEST_TMPDIR/outside-secret
	printf '%s\n' preserve >"$outside_path"
	ln -s "$outside_path" "$config_root/config/sets/foreign-link"

	invoke_cli uninstall

	[ "$status" -eq 78 ]
	[ "$(cat "$outside_path")" = preserve ]
	[ -L "$config_root/config/sets/foreign-link" ]
	[ -d "$code_root" ]
	[ -d "$config_root" ]
}

@test "uninstall retains and refuses an unexpected volatile-root file" {
	foreign_runtime_path=$NUTMERLIN_TMP_ROOT/nutmerlin/log/foreign.log
	printf '%s\n' preserve >"$foreign_runtime_path"

	invoke_cli uninstall

	[ "$status" -eq 78 ]
	[[ "$output" == *'uninstall refused: no complete owned installation is present'* ]]
	[ "$(cat "$foreign_runtime_path")" = preserve ]
	[ -d "$code_root" ]
	[ -d "$config_root" ]
}

@test "uninstall refuses a regular file masquerading as an owned driver socket" {
	fake_socket=$NUTMERLIN_TMP_ROOT/nutmerlin/state/dummy-ups-dummy
	printf '%s\n' preserve >"$fake_socket"

	invoke_cli uninstall

	[ "$status" -eq 78 ]
	[ "$(cat "$fake_socket")" = preserve ]
	[ -d "$code_root" ]
	[ -d "$config_root" ]
}
