#!/usr/bin/env bats

setup() {
	REPOSITORY_ROOT=$(cd "$BATS_TEST_DIRNAME/../.." && pwd)
	# shellcheck source=test/lib/host-harness.sh
	. "$REPOSITORY_ROOT/test/lib/host-harness.sh"
	host_harness_setup
	# shellcheck source=test/lib/entware-fixture.sh
	. "$REPOSITORY_ROOT/test/lib/entware-fixture.sh"
	entware_fixture_setup
	make --no-print-directory -C "$REPOSITORY_ROOT" install DESTDIR="$NUTMERLIN_TEST_ROOT" >/dev/null
	installed_cli=$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/bin/nutmerlin
}

teardown() {
	host_harness_teardown
}

@test "source show reports the active dummy profile" {
	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		"$installed_cli" source show

	[ "$status" -eq 0 ]
	[ "$output" = 'source: ok: active source is dummy; identity=simulation' ]
}

@test "configure-usbhid refuses regex syntax as a serial identity" {
	current_before=$(cat "$NUTMERLIN_OPT_ROOT/etc/nutmerlin/config/current")

	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		"$installed_cli" source configure-usbhid \
		--vendor-id 0764 --product-id 0501 --serial 'SER.*'

	[ "$status" -eq 78 ]
	[ "$output" = 'source refused: serial must be a 1-64 character literal identifier' ]
	[ "$(cat "$NUTMERLIN_OPT_ROOT/etc/nutmerlin/config/current")" = "$current_before" ]
}

@test "configure-usbhid does not accept logical selectors or arbitrary driver options" {
	current_before=$(cat "$NUTMERLIN_OPT_ROOT/etc/nutmerlin/config/current")
	for forbidden_option in --bus --device --allow-duplicates --driver-option; do
		run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
			NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
			NUTMERLIN_TEST_RUN_USER="$(id -un)" \
			"$installed_cli" source configure-usbhid \
			--vendor-id 0764 --product-id 0501 --serial CPS123456 \
			"$forbidden_option" unsafe

		[ "$status" -eq 64 ]
		[[ "$output" == usage:* ]]
	done
	[ "$(cat "$NUTMERLIN_OPT_ROOT/etc/nutmerlin/config/current")" = "$current_before" ]
}

@test "configure-usbhid selects one matching serial profile while disabled" {
	config_root=$NUTMERLIN_OPT_ROOT/etc/nutmerlin/config
	previous_set_id=$(cat "$config_root/current")
	printf '%s\n' 0 >"$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/enabled"
	mkdir -m 700 "$NUTMERLIN_TEST_ROOT/platform"
	printf 'usb-a\t0764\t0501\tCPS123456\t003\t001\t009\n' \
		>"$NUTMERLIN_TEST_ROOT/platform/usb-devices.tsv"
	chmod 600 "$NUTMERLIN_TEST_ROOT/platform/usb-devices.tsv"

	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		"$installed_cli" source configure-usbhid \
		--vendor-id 0764 --product-id 0501 --serial CPS123456

	[ "$status" -eq 0 ]
	[ "$output" = 'source: ok: usbhid source selected while service is disabled; identity=serial' ]
	current_set_id=$(cat "$config_root/current")
	[ "$current_set_id" != "$previous_set_id" ]
	[ ! -e "$config_root/last-good" ]
	[ ! -e "$config_root/sets/$previous_set_id" ]
	[ "$(find "$config_root/sets" -mindepth 1 -maxdepth 1 -type d | wc -l)" -eq 1 ]
	set_root=$config_root/sets/$current_set_id
	[ "$(stat -c '%a' "$set_root")" = 700 ]
	[ "$(cat "$set_root/model.tsv")" = $'schema\tnutmerlin.model.v1\nsource\tups\nset_id\t'"$current_set_id"$'\nvendor_id\t0764\nproduct_id\t0501\nidentity\tserial\nidentity_value\tCPS123456' ]
	[ "$(cat "$set_root/ups.conf")" = $'statepath = '"$NUTMERLIN_TMP_ROOT"$'/nutmerlin/state\n\n[ups]\n\tdriver = usbhid-ups\n\tport = auto\n\tvendorid = ^0764$\n\tproductid = ^0501$\n\tserial = ^CPS123456$' ]
	[ "$(cat "$set_root/upsd.conf")" = $'STATEPATH '"$NUTMERLIN_TMP_ROOT"$'/nutmerlin/state\nLISTEN 127.0.0.1 3493' ]
	[ ! -s "$set_root/upsd.users" ]
	(cd "$set_root" && sha256sum -c SHA256SUMS)
	run rg -n 'allow_duplicates|allowfrom|actions|instcmds|FSD|SHUTDOWNCMD|load[.]off|outlet|SET' \
		"$set_root"
	[ "$status" -eq 1 ]

	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		"$installed_cli" source show

	[ "$status" -eq 0 ]
	[ "$output" = 'source: ok: active source is ups; vendor_id=0764 product_id=0501 identity=serial value=redacted' ]
	[[ "$output" != *CPS123456* ]]
}

@test "configure-usbhid renders punctuation in a serial as a literal match" {
	printf '%s\n' 0 >"$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/enabled"
	mkdir -m 700 "$NUTMERLIN_TEST_ROOT/platform"
	printf 'usb-a\t0764\t0501\tCPS.12+3\t003\t001\t009\n' \
		>"$NUTMERLIN_TEST_ROOT/platform/usb-devices.tsv"
	chmod 600 "$NUTMERLIN_TEST_ROOT/platform/usb-devices.tsv"

	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		"$installed_cli" source configure-usbhid \
		--vendor-id 0764 --product-id 0501 --serial 'CPS.12+3'

	[ "$status" -eq 0 ]
	set_id=$(cat "$NUTMERLIN_OPT_ROOT/etc/nutmerlin/config/current")
	grep -Fx $'\tserial = ^CPS\\.12\\+3$' \
		"$NUTMERLIN_OPT_ROOT/etc/nutmerlin/config/sets/$set_id/ups.conf"
}

@test "configure-usbhid derives a physical busport from an isolated sysfs tree" {
	printf '%s\n' 0 >"$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/enabled"
	usb_sysfs_root=$NUTMERLIN_TEST_ROOT/platform/sysfs-usb
	mkdir -p "$usb_sysfs_root/1-3"
	printf '%s\n' 0764 >"$usb_sysfs_root/1-3/idVendor"
	printf '%s\n' 0501 >"$usb_sysfs_root/1-3/idProduct"
	printf '%s\n' 3 >"$usb_sysfs_root/1-3/devpath"
	printf '%s\n' 001 >"$usb_sysfs_root/1-3/busnum"
	printf '%s\n' 014 >"$usb_sysfs_root/1-3/devnum"

	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_USB_SYSFS_ROOT="$usb_sysfs_root" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		"$installed_cli" source configure-usbhid \
		--vendor-id 0764 --product-id 0501 --busport 3

	[ "$status" -eq 0 ]
	[ "$output" = 'source: ok: usbhid source selected while service is disabled; identity=busport' ]
	set_id=$(cat "$NUTMERLIN_OPT_ROOT/etc/nutmerlin/config/current")
	set_root=$NUTMERLIN_OPT_ROOT/etc/nutmerlin/config/sets/$set_id
	grep -Fx $'identity_value\t003' "$set_root/model.tsv"
	grep -Fx $'\tbusport = ^003$' "$set_root/ups.conf"

	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_USB_SYSFS_ROOT="$usb_sysfs_root" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		"$installed_cli" source show

	[ "$status" -eq 0 ]
	[ "$output" = 'source: ok: active source is ups; vendor_id=0764 product_id=0501 identity=busport value=003' ]
}

@test "configure-usbhid leaves a changed serial unavailable without changing current" {
	config_root=$NUTMERLIN_OPT_ROOT/etc/nutmerlin/config
	current_before=$(cat "$config_root/current")
	mkdir -m 700 "$NUTMERLIN_TEST_ROOT/platform"
	printf 'usb-a\t0764\t0501\tCHANGED999\t003\t001\t010\n' \
		>"$NUTMERLIN_TEST_ROOT/platform/usb-devices.tsv"
	chmod 600 "$NUTMERLIN_TEST_ROOT/platform/usb-devices.tsv"

	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		"$installed_cli" source configure-usbhid \
		--vendor-id 0764 --product-id 0501 --serial CPS123456

	[ "$status" -eq 69 ]
	[ "$output" = 'source unavailable: configured serial identity did not match' ]
	[ "$(cat "$config_root/current")" = "$current_before" ]
}

@test "configure-usbhid reports an incomplete matching serial identity" {
	mkdir -m 700 "$NUTMERLIN_TEST_ROOT/platform"
	printf 'usb-a\t0764\t0501\t-\t003\t001\t010\n' \
		>"$NUTMERLIN_TEST_ROOT/platform/usb-devices.tsv"
	chmod 600 "$NUTMERLIN_TEST_ROOT/platform/usb-devices.tsv"

	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		"$installed_cli" source configure-usbhid \
		--vendor-id 0764 --product-id 0501 --serial CPS123456

	[ "$status" -eq 69 ]
	[ "$output" = 'source unavailable: matching USB device has no stable serial identity' ]
}

@test "configure-usbhid refuses duplicate exact identities" {
	mkdir -m 700 "$NUTMERLIN_TEST_ROOT/platform"
	{
		printf 'usb-a\t0764\t0501\tCPS123456\t003\t001\t010\n'
		printf 'usb-b\t0764\t0501\tCPS123456\t004\t001\t011\n'
	} >"$NUTMERLIN_TEST_ROOT/platform/usb-devices.tsv"
	chmod 600 "$NUTMERLIN_TEST_ROOT/platform/usb-devices.tsv"

	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		"$installed_cli" source configure-usbhid \
		--vendor-id 0764 --product-id 0501 --serial CPS123456

	[ "$status" -eq 78 ]
	[ "$output" = 'source refused: configured serial identity matches multiple USB devices' ]
}

@test "stable serial selection ignores logical enumeration changes and other serials" {
	printf '%s\n' 0 >"$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/enabled"
	mkdir -m 700 "$NUTMERLIN_TEST_ROOT/platform"
	usb_inventory=$NUTMERLIN_TEST_ROOT/platform/usb-devices.tsv
	{
		printf 'usb-a\t0764\t0501\tCPS123456\t003\t001\t010\n'
		printf 'usb-b\t0764\t0501\tOTHER999\t004\t001\t011\n'
	} >"$usb_inventory"
	chmod 600 "$usb_inventory"

	env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		"$installed_cli" source configure-usbhid \
		--vendor-id 0764 --product-id 0501 --serial CPS123456 >/dev/null
	first_set_id=$(cat "$NUTMERLIN_OPT_ROOT/etc/nutmerlin/config/current")
	{
		printf 'usb-a\t0764\t0501\tCPS123456\t003\t009\t099\n'
		printf 'usb-b\t0764\t0501\tOTHER999\t004\t007\t088\n'
	} >"$usb_inventory"
	chmod 600 "$usb_inventory"

	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		"$installed_cli" source configure-usbhid \
		--vendor-id 0764 --product-id 0501 --serial CPS123456

	[ "$status" -eq 0 ]
	second_set_id=$(cat "$NUTMERLIN_OPT_ROOT/etc/nutmerlin/config/current")
	[ "$second_set_id" != "$first_set_id" ]
	grep -Fx $'identity_value\tCPS123456' \
		"$NUTMERLIN_OPT_ROOT/etc/nutmerlin/config/sets/$second_set_id/model.tsv"
}

@test "status reports an unavailable real source without exposing its serial" {
	printf '%s\n' 0 >"$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/enabled"
	mkdir -m 700 "$NUTMERLIN_TEST_ROOT/platform"
	usb_inventory=$NUTMERLIN_TEST_ROOT/platform/usb-devices.tsv
	printf 'usb-a\t0764\t0501\tCPS123456\t003\t001\t010\n' >"$usb_inventory"
	chmod 600 "$usb_inventory"
	env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		"$installed_cli" source configure-usbhid \
		--vendor-id 0764 --product-id 0501 --serial CPS123456 >/dev/null
	: >"$usb_inventory"
	chmod 600 "$usb_inventory"

	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		"$installed_cli" status --json

	[ "$status" -eq 69 ]
	[ "$(printf '%s\n' "$output" | jq -r '.details.source')" = ups ]
	[ "$(printf '%s\n' "$output" | jq -r '.details.driver')" = stopped ]
	[[ "$output" != *CPS123456* ]]
}

@test "status gives stable source diagnostics for physical identity failures" {
	printf '%s\n' 0 >"$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/enabled"
	mkdir -m 700 "$NUTMERLIN_TEST_ROOT/platform"
	usb_inventory=$NUTMERLIN_TEST_ROOT/platform/usb-devices.tsv
	printf 'usb-a\t0764\t0501\tCPS123456\t003\t001\t010\n' >"$usb_inventory"
	chmod 600 "$usb_inventory"
	env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		"$installed_cli" source configure-usbhid \
		--vendor-id 0764 --product-id 0501 --serial CPS123456 >/dev/null

	for source_case in absent changed incomplete duplicate; do
		case $source_case in
			absent)
				: >"$usb_inventory"
				expected_status=69
				expected_message='source unavailable: no USB device matches the configured vendor/product'
				;;
			changed)
				printf 'usb-a\t0764\t0501\tCHANGED999\t003\t001\t010\n' >"$usb_inventory"
				expected_status=69
				expected_message='source unavailable: configured serial identity did not match'
				;;
			incomplete)
				printf 'usb-a\t0764\t0501\t-\t003\t001\t010\n' >"$usb_inventory"
				expected_status=69
				expected_message='source unavailable: matching USB device has no stable serial identity'
				;;
			duplicate)
				{
					printf 'usb-a\t0764\t0501\tCPS123456\t003\t001\t010\n'
					printf 'usb-b\t0764\t0501\tCPS123456\t004\t001\t011\n'
				} >"$usb_inventory"
				expected_status=78
				expected_message='source refused: configured serial identity matches multiple USB devices'
				;;
		esac
		chmod 600 "$usb_inventory"

		run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
			NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
			NUTMERLIN_TEST_RUN_USER="$(id -un)" \
			"$installed_cli" diagnostics --json

		[ "$status" -eq "$expected_status" ]
		[ "$(printf '%s\n' "$output" | jq -r '.message')" = "$expected_message" ]
		[ "$(printf '%s\n' "$output" | jq -r '.details.failed_layer')" = source ]
		[ "$(printf '%s\n' "$output" | jq -r '.details.remediation')" = \
			'reconnect the configured UPS or correct its stable identity' ]
		[[ "$output" != *CPS123456* ]]
	done
}

@test "failed real-source activation stays unavailable and never restores dummy" {
	config_root=$NUTMERLIN_OPT_ROOT/etc/nutmerlin/config
	initial_set_id=$(cat "$config_root/current")
	mkdir -m 700 "$NUTMERLIN_TEST_ROOT/platform"
	printf 'usb-a\t0764\t0501\tCPS123456\t003\t001\t010\n' \
		>"$NUTMERLIN_TEST_ROOT/platform/usb-devices.tsv"
	chmod 600 "$NUTMERLIN_TEST_ROOT/platform/usb-devices.tsv"

	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		"$installed_cli" source configure-usbhid \
		--vendor-id 0764 --product-id 0501 --serial CPS123456

	[ "$status" -eq 75 ]
	[[ "$output" == *'configuration activation failed: ups remains selected and unavailable'* ]]
	current_set_id=$(cat "$config_root/current")
	[ "$current_set_id" != "$initial_set_id" ]
	grep -Fx $'source\tups' "$config_root/sets/$current_set_id/model.tsv"
	[ ! -e "$config_root/last-good" ]
	[ "$(find "$config_root/sets" -mindepth 1 -maxdepth 1 -type d | wc -l)" -eq 1 ]
	[ ! -e "$NUTMERLIN_TMP_ROOT/nutmerlin/run/dummy-ups.pid" ]
}

@test "real-source activation refuses success when obsolete-set cleanup fails" {
	printf '%s\n' 0 >"$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/enabled"
	config_root=$NUTMERLIN_OPT_ROOT/etc/nutmerlin/config
	initial_set_id=$(cat "$config_root/current")
	mkdir -m 700 "$NUTMERLIN_TEST_ROOT/platform"
	printf 'usb-a\t0764\t0501\tCPS123456\t003\t001\t010\n' \
		>"$NUTMERLIN_TEST_ROOT/platform/usb-devices.tsv"
	chmod 600 "$NUTMERLIN_TEST_ROOT/platform/usb-devices.tsv"

	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		NUTMERLIN_TEST_REMOVE_SET_FAIL_ID="$initial_set_id" \
		"$installed_cli" source configure-usbhid \
		--vendor-id 0764 --product-id 0501 --serial CPS123456

	[ "$status" -eq 75 ]
	[ "$output" = 'configuration activation failed: ups selected but obsolete-set cleanup failed' ]
	current_set_id=$(cat "$config_root/current")
	[ "$current_set_id" != "$initial_set_id" ]
	grep -Fx $'source\tups' "$config_root/sets/$current_set_id/model.tsv"
	[ -d "$config_root/sets/$initial_set_id" ]
	[ ! -e "$config_root/last-good" ]
	[ ! -e "$NUTMERLIN_TMP_ROOT/nutmerlin/run/dummy-ups.pid" ]
}

@test "lifecycle health revalidates a disconnect and stable reconnect" {
	printf '%s\n' 0 >"$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/enabled"
	mkdir -m 700 "$NUTMERLIN_TEST_ROOT/platform"
	usb_inventory=$NUTMERLIN_TEST_ROOT/platform/usb-devices.tsv
	printf 'usb-a\t0764\t0501\tCPS123456\t003\t001\t010\n' >"$usb_inventory"
	chmod 600 "$usb_inventory"
	env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		"$installed_cli" source configure-usbhid \
		--vendor-id 0764 --product-id 0501 --serial CPS123456 >/dev/null
	: >"$usb_inventory"
	chmod 600 "$usb_inventory"

	run env REPOSITORY_ROOT="$REPOSITORY_ROOT" \
		NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" /bin/sh -c '
		for library in paths entware configuration platform service lifecycle; do
			. "$REPOSITORY_ROOT/lib/nutmerlin/$library.sh"
		done
		paths_initialize
		service_pid_pair_is_owned_current() { return 0; }
		service_query_active() { return 0; }
		service_network_is_expected() { return 0; }
		lifecycle_service_is_healthy
	'
	[ "$status" -eq 1 ]

	printf 'usb-a\t0764\t0501\tCPS123456\t003\t009\t099\n' >"$usb_inventory"
	chmod 600 "$usb_inventory"
	run env REPOSITORY_ROOT="$REPOSITORY_ROOT" \
		NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" /bin/sh -c '
		for library in paths entware configuration platform service lifecycle; do
			. "$REPOSITORY_ROOT/lib/nutmerlin/$library.sh"
		done
		paths_initialize
		service_pid_pair_is_owned_current() { return 0; }
		service_query_active() { return 0; }
		service_network_is_expected() { return 0; }
		lifecycle_service_is_healthy
	'
	[ "$status" -eq 0 ]
}

@test "service start revalidates a configured serial before launching NUT" {
	code_root=$NUTMERLIN_JFFS_ROOT/addons/nutmerlin
	printf '%s\n' 0 >"$code_root/enabled"
	mkdir -m 700 "$NUTMERLIN_TEST_ROOT/platform"
	usb_inventory=$NUTMERLIN_TEST_ROOT/platform/usb-devices.tsv
	printf 'usb-a\t0764\t0501\tCPS123456\t003\t001\t010\n' >"$usb_inventory"
	chmod 600 "$usb_inventory"
	env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		"$installed_cli" source configure-usbhid \
		--vendor-id 0764 --product-id 0501 --serial CPS123456 >/dev/null
	: >"$usb_inventory"
	chmod 600 "$usb_inventory"
	printf '%s\n' 1 >"$code_root/enabled"

	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		"$installed_cli" service start

	[ "$status" -eq 69 ]
	[ "$output" = 'source unavailable: no USB device matches the configured vendor/product' ]
	[ ! -e "$NUTMERLIN_TMP_ROOT/nutmerlin/run/usbhid-ups.pid" ]
	[ ! -e "$NUTMERLIN_TMP_ROOT/nutmerlin/run/upsd.pid" ]
	current_set_id=$(cat "$NUTMERLIN_OPT_ROOT/etc/nutmerlin/config/current")
	grep -Fx $'source\tups' \
		"$NUTMERLIN_OPT_ROOT/etc/nutmerlin/config/sets/$current_set_id/model.tsv"

	printf 'usb-a\t0764\t0501\tCPS123456\t003\t009\t099\n' >"$usb_inventory"
	chmod 600 "$usb_inventory"
	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		"$installed_cli" service start

	[ "$status" -eq 75 ]
	[ "$output" = 'service temporary failure: usbhid did not start' ]
	grep -Fx $'source\tups' \
		"$NUTMERLIN_OPT_ROOT/etc/nutmerlin/config/sets/$current_set_id/model.tsv"
}
