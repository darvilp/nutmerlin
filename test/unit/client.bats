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

invoke_cli() {
	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		"$installed_cli" "$@"
}

invoke_cli_with_exported_secret_names() {
	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		NUTMERLIN_SECRET_ENV_CAPTURE="$NUTMERLIN_SECRET_ENV_CAPTURE" \
		CLIENT_SECRET=caller-sentinel \
		CONFIGURATION_CLIENT_SECRET=caller-sentinel \
		client_secret=caller-sentinel \
		unique_secret=caller-sentinel \
		client_candidate_secret=caller-sentinel \
		client_record_secret=caller-sentinel \
		result_secret=caller-sentinel \
		result_value=caller-sentinel \
		"$installed_cli" "$@"
}

teardown() {
	host_harness_teardown
}

@test "client add returns one independent restricted credential in a complete selected set" {
	printf '%s\n' 0 >"$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/enabled"
	invoke_cli client add nas-primary --json

	[ "$status" -eq 0 ]
	[ "$(printf '%s\n' "$output" | jq -r '.schema_version')" = nutmerlin.result.v1 ]
	[ "$(printf '%s\n' "$output" | jq -r '.command')" = client.add ]
	client_id=$(printf '%s\n' "$output" | jq -r '.details.client_id')
	username=$(printf '%s\n' "$output" | jq -r '.details.username')
	secret=$(printf '%s\n' "$output" | jq -r '.details.secret')
	[[ "$client_id" =~ ^[0-9a-f]{32}$ ]]
	[ "$username" = "nm_$client_id" ]
	[[ "$secret" =~ ^[0-9a-f]{48}$ ]]

	config_root=$NUTMERLIN_OPT_ROOT/etc/nutmerlin/config
	set_root=$config_root/sets/$(cat "$config_root/current")
	client_root=$set_root/clients
	client_path=$client_root/$client_id
	[ "$(stat -c '%a' "$client_root")" = 700 ]
	[ "$(stat -c '%a' "$client_path")" = 600 ]
	grep -Fx $'schema\tnutmerlin.client.v1' "$client_path"
	grep -Fx $'label\tnas-primary' "$client_path"
	grep -Fx $'username\t'"$username" "$client_path"
	grep -Fx $'secret\t'"$secret" "$client_path"
	expected_users=$(printf '[%s]\npassword = %s\nupsmon secondary\n' "$username" "$secret")
	[ "$(cat "$set_root/upsd.users")" = "$expected_users" ]
	run rg -n 'actions|instcmds|SET|primary|FSD' "$set_root/upsd.users"
	[ "$status" -eq 1 ]
	[ "$(cat "$config_root/current")" != "$(cat "$config_root/last-good")" ]
}

@test "client revoke removes only the selected credential and cannot retain it as last-good" {
	printf '%s\n' 0 >"$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/enabled"
	invoke_cli client add nas-primary --json
	[ "$status" -eq 0 ]
	first_id=$(printf '%s\n' "$output" | jq -r '.details.client_id')
	first_secret=$(printf '%s\n' "$output" | jq -r '.details.secret')

	invoke_cli client add workstation --json
	[ "$status" -eq 0 ]
	second_id=$(printf '%s\n' "$output" | jq -r '.details.client_id')
	second_secret=$(printf '%s\n' "$output" | jq -r '.details.secret')

	invoke_cli client revoke "$first_id"
	[ "$status" -eq 0 ]
	[ "$output" = "client.revoke: ok: secondary client revoked; client_id=$first_id" ]

	config_root=$NUTMERLIN_OPT_ROOT/etc/nutmerlin/config
	set_root=$config_root/sets/$(cat "$config_root/current")
	[ ! -e "$set_root/clients/$first_id" ]
	[ -f "$set_root/clients/$second_id" ]
	! rg -F "$first_secret" "$config_root"
	rg -F "$second_secret" "$set_root/upsd.users"
	[ ! -e "$config_root/last-good" ]
	[ "$(find "$config_root/sets" -mindepth 1 -maxdepth 1 -type d | wc -l)" -eq 1 ]
}

@test "client revoke honors the requested ID when current and last-good contain different clients" {
	printf '%s\n' 0 >"$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/enabled"
	invoke_cli client add nas-primary --json
	[ "$status" -eq 0 ]
	first_id=$(printf '%s\n' "$output" | jq -r '.details.client_id')
	invoke_cli client add workstation --json
	[ "$status" -eq 0 ]
	second_id=$(printf '%s\n' "$output" | jq -r '.details.client_id')

	config_root=$NUTMERLIN_OPT_ROOT/etc/nutmerlin/config
	previous_set=$(cat "$config_root/current")
	invoke_cli client revoke 00000000000000000000000000000000
	[ "$status" -eq 69 ]
	[ "$(cat "$config_root/current")" = "$previous_set" ]

	invoke_cli client revoke "$second_id"
	[ "$status" -eq 0 ]
	set_root=$config_root/sets/$(cat "$config_root/current")
	[ -f "$set_root/clients/$first_id" ]
	[ ! -e "$set_root/clients/$second_id" ]
	[ ! -e "$config_root/last-good" ]
}

@test "failed service activation keeps a revoked credential absent and the service stopped" {
	printf '%s\n' 0 >"$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/enabled"
	invoke_cli client add nas-primary --json
	[ "$status" -eq 0 ]
	first_id=$(printf '%s\n' "$output" | jq -r '.details.client_id')
	first_secret=$(printf '%s\n' "$output" | jq -r '.details.secret')
	invoke_cli client add workstation --json
	[ "$status" -eq 0 ]
	second_id=$(printf '%s\n' "$output" | jq -r '.details.client_id')

	printf '%s\n' 1 >"$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/enabled"
	invoke_cli client revoke "$first_id"
	[ "$status" -eq 75 ]
	[[ "$output" == *'configuration activation failed: revoked credential remains absent and service is stopped'* ]]

	config_root=$NUTMERLIN_OPT_ROOT/etc/nutmerlin/config
	set_root=$config_root/sets/$(cat "$config_root/current")
	[ ! -e "$set_root/clients/$first_id" ]
	[ -f "$set_root/clients/$second_id" ]
	! rg -F "$first_secret" "$config_root"
	[ ! -e "$config_root/last-good" ]
	[ ! -e "$NUTMERLIN_TMP_ROOT/nutmerlin/run/upsd.pid" ]
}

@test "multiple clients stay independent while status and diagnostics redact their secrets" {
	printf '%s\n' 0 >"$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/enabled"
	invoke_cli client add nas-primary --json
	[ "$status" -eq 0 ]
	first_id=$(printf '%s\n' "$output" | jq -r '.details.client_id')
	first_username=$(printf '%s\n' "$output" | jq -r '.details.username')
	first_secret=$(printf '%s\n' "$output" | jq -r '.details.secret')
	invoke_cli client add workstation --json
	[ "$status" -eq 0 ]
	second_id=$(printf '%s\n' "$output" | jq -r '.details.client_id')
	second_username=$(printf '%s\n' "$output" | jq -r '.details.username')
	second_secret=$(printf '%s\n' "$output" | jq -r '.details.secret')
	[ "$first_id" != "$second_id" ]
	[ "$first_username" != "$second_username" ]
	[ "$first_secret" != "$second_secret" ]
	set_root=$NUTMERLIN_OPT_ROOT/etc/nutmerlin/config/sets/$(cat "$NUTMERLIN_OPT_ROOT/etc/nutmerlin/config/current")
	grep -Fx $'label\tnas-primary' "$set_root/clients/$first_id"
	grep -Fx $'label\tworkstation' "$set_root/clients/$second_id"

	invoke_cli status --json
	[ "$status" -eq 69 ]
	[ "$(printf '%s\n' "$output" | jq -r '.details.client_count')" -eq 2 ]
	[[ "$output" != *"$first_secret"* ]]
	[[ "$output" != *"$second_secret"* ]]
	invoke_cli diagnostics --json
	[ "$status" -eq 69 ]
	[[ "$output" != *"$first_secret"* ]]
	[[ "$output" != *"$second_secret"* ]]

	invoke_cli source use-dummy
	[ "$status" -eq 0 ]
	set_root=$NUTMERLIN_OPT_ROOT/etc/nutmerlin/config/sets/$(cat "$NUTMERLIN_OPT_ROOT/etc/nutmerlin/config/current")
	[ -f "$set_root/clients/$first_id" ]
	[ -f "$set_root/clients/$second_id" ]
	rg -F "$first_secret" "$set_root/upsd.users"
	rg -F "$second_secret" "$set_root/upsd.users"
}

@test "client commands reject unsafe names and unknown IDs without changing configuration" {
	config_root=$NUTMERLIN_OPT_ROOT/etc/nutmerlin/config
	initial_set=$(cat "$config_root/current")
	for unsafe_name in ' leading' 'trailing ' 'shell;command' $'line\nbreak'; do
		invoke_cli client add "$unsafe_name"
		[ "$status" -eq 78 ]
		[ "$(cat "$config_root/current")" = "$initial_set" ]
	done
	for unknown_option in --bogus --json; do
		invoke_cli client add "$unknown_option"
		[ "$status" -eq 64 ]
		[ "$(cat "$config_root/current")" = "$initial_set" ]
	done
	invoke_cli client revoke --bogus
	[ "$status" -eq 64 ]
	[ "$(cat "$config_root/current")" = "$initial_set" ]

	invoke_cli client revoke not-a-client-id
	[ "$status" -eq 78 ]
	[ "$(cat "$config_root/current")" = "$initial_set" ]
	invoke_cli client revoke 00000000000000000000000000000000
	[ "$status" -eq 69 ]
	[ "$(cat "$config_root/current")" = "$initial_set" ]
	[ "$(find "$config_root/sets" -mindepth 1 -maxdepth 1 -type d | wc -l)" -eq 1 ]
}

@test "client operations do not preserve inherited secret export attributes" {
	real_sha256sum=$(command -v sha256sum)
	NUTMERLIN_SECRET_ENV_CAPTURE=$NUTMERLIN_TEST_ROOT/secret-environment
	export NUTMERLIN_SECRET_ENV_CAPTURE
	printf '%s\n' '#!/bin/sh' \
		'printf "CLIENT_SECRET=%s\n" "${CLIENT_SECRET-unset}" >>"$NUTMERLIN_SECRET_ENV_CAPTURE"' \
		'printf "CONFIGURATION_CLIENT_SECRET=%s\n" "${CONFIGURATION_CLIENT_SECRET-unset}" >>"$NUTMERLIN_SECRET_ENV_CAPTURE"' \
		'printf "client_secret=%s\n" "${client_secret-unset}" >>"$NUTMERLIN_SECRET_ENV_CAPTURE"' \
		'printf "unique_secret=%s\n" "${unique_secret-unset}" >>"$NUTMERLIN_SECRET_ENV_CAPTURE"' \
		'printf "client_candidate_secret=%s\n" "${client_candidate_secret-unset}" >>"$NUTMERLIN_SECRET_ENV_CAPTURE"' \
		'printf "client_record_secret=%s\n" "${client_record_secret-unset}" >>"$NUTMERLIN_SECRET_ENV_CAPTURE"' \
		'printf "result_secret=%s\n" "${result_secret-unset}" >>"$NUTMERLIN_SECRET_ENV_CAPTURE"' \
		'printf "result_value=%s\n" "${result_value-unset}" >>"$NUTMERLIN_SECRET_ENV_CAPTURE"' \
		"exec $real_sha256sum \"\$@\"" >"$NUTMERLIN_TEST_ROOT/bin/sha256sum"
	chmod 700 "$NUTMERLIN_TEST_ROOT/bin/sha256sum"

	printf '%s\n' 0 >"$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/enabled"
	invoke_cli_with_exported_secret_names client add nas-primary
	[ "$status" -eq 0 ]
	[ -s "$NUTMERLIN_SECRET_ENV_CAPTURE" ]
	! rg -v '^(CLIENT_SECRET|CONFIGURATION_CLIENT_SECRET|client_secret|unique_secret|client_candidate_secret|client_record_secret|result_secret|result_value)=unset$' \
		"$NUTMERLIN_SECRET_ENV_CAPTURE"
}

@test "client operations refuse hidden or foreign entries in the owned client directory" {
	printf '%s\n' 0 >"$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/enabled"
	invoke_cli client add nas-primary --json
	[ "$status" -eq 0 ]
	config_root=$NUTMERLIN_OPT_ROOT/etc/nutmerlin/config
	active_set=$(cat "$config_root/current")
	client_root=$config_root/sets/$active_set/clients
	printf '%s\n' foreign >"$client_root/.unexpected"
	chmod 600 "$client_root/.unexpected"

	invoke_cli client add workstation
	[ "$status" -eq 78 ]
	[ "$(cat "$config_root/current")" = "$active_set" ]
	[ "$(find "$config_root/sets" -mindepth 1 -maxdepth 1 -type d | wc -l)" -eq 2 ]
}
