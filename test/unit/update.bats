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
	make --no-print-directory -C "$REPOSITORY_ROOT" package >/dev/null
	code_root=$NUTMERLIN_JFFS_ROOT/addons/nutmerlin
	config_root=$NUTMERLIN_OPT_ROOT/etc/nutmerlin
	installed_cli=$code_root/bin/nutmerlin
	package_path=$BATS_TEST_TMPDIR/nutmerlin-core-test.tar.gz
	cp "$REPOSITORY_ROOT/dist/nutmerlin-core-dev.tar.gz" "$package_path"
}

teardown() {
	host_harness_teardown
}

invoke_cli() {
	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		NUTMERLIN_TEST_UPDATE_FAIL_AFTER="${NUTMERLIN_TEST_UPDATE_FAIL_AFTER:-}" \
		NUTMERLIN_TEST_UPDATE_SIGNAL_AFTER="${NUTMERLIN_TEST_UPDATE_SIGNAL_AFTER:-}" \
		NUTMERLIN_TEST_UPDATE_RECOVERY_CLEANUP_FAIL="${NUTMERLIN_TEST_UPDATE_RECOVERY_CLEANUP_FAIL:-0}" \
		NUTMERLIN_TEST_JFFS_AVAILABLE_KB="${NUTMERLIN_TEST_JFFS_AVAILABLE_KB:-}" \
		"$installed_cli" "$@"
}

code_snapshot() {
	(
		cd "$code_root"
		find . -type f -print | sort | while IFS= read -r snapshot_path; do
			sha256sum "$snapshot_path"
		done
	)
}

tree_snapshot() {
	snapshot_root=$1
	(
		cd "$snapshot_root"
		find . -type f -print | sort | while IFS= read -r snapshot_path; do
			printf '%s  ' "$snapshot_path"
			sha256sum "$snapshot_path" | awk '{ print $1 }'
		done
	)
}

write_sidecar() {
	update_digest=$(sha256sum "$package_path" | awk '{ print $1 }')
	printf '%s  %s\n' "$update_digest" "${package_path##*/}" >"$package_path.sha256"
}

rebuild_package_from_root() {
	package_root=$1
	shift
	package_tar=$BATS_TEST_TMPDIR/package.tar
	(
		cd "$package_root"
		tar --sort=name --mtime=@0 --owner=0 --group=0 --numeric-owner \
			-cf "$package_tar" LICENSE MANIFEST.sha256 README.md VERSION \
			bin install.sh lib share "$@"
	)
	gzip -n -c "$package_tar" >"$package_path"
	write_sidecar
}

rewrite_internal_manifest() {
	manifest_root=$1
	(
		cd "$manifest_root"
		sha256sum LICENSE README.md VERSION bin/nutmerlin install.sh \
			lib/nutmerlin/*.sh share/dummy/cyberpower.dev >MANIFEST.sha256
	)
}

@test "update requires an exact adjacent archive sidecar before owned mutation" {
	code_snapshot >"$BATS_TEST_TMPDIR/code.before"

	invoke_cli update "$package_path"

	[ "$status" -eq 78 ]
	[[ "$output" == *'update refused: adjacent SHA-256 sidecar is missing or unsafe'* ]]
	code_snapshot >"$BATS_TEST_TMPDIR/code.after"
	cmp "$BATS_TEST_TMPDIR/code.before" "$BATS_TEST_TMPDIR/code.after"

	printf '%064d  %s\n' 0 "${package_path##*/}" >"$package_path.sha256"
	invoke_cli update "$package_path"
	[ "$status" -eq 78 ]
	[[ "$output" == *'update refused: archive SHA-256 does not match its sidecar'* ]]
	code_snapshot >"$BATS_TEST_TMPDIR/code.after"
	cmp "$BATS_TEST_TMPDIR/code.before" "$BATS_TEST_TMPDIR/code.after"
}

@test "update rejects an extra archive object before owned mutation" {
	package_root=$BATS_TEST_TMPDIR/package-root
	mkdir "$package_root"
	tar -xzf "$package_path" -C "$package_root"
	printf '%s\n' unexpected >"$package_root/extra-file"
	rebuild_package_from_root "$package_root" extra-file
	code_snapshot >"$BATS_TEST_TMPDIR/code.before"

	invoke_cli update "$package_path"

	[ "$status" -eq 78 ]
	[[ "$output" == *'update refused: archive inventory is not the fixed core inventory'* ]]
	code_snapshot >"$BATS_TEST_TMPDIR/code.after"
	cmp "$BATS_TEST_TMPDIR/code.before" "$BATS_TEST_TMPDIR/code.after"
}

@test "update rejects duplicate traversal and absolute archive names before extraction" {
	duplicate_root=$BATS_TEST_TMPDIR/duplicate-root
	mkdir "$duplicate_root"
	tar -xzf "$package_path" -C "$duplicate_root"
	rebuild_package_from_root "$duplicate_root" LICENSE

	invoke_cli update "$package_path"

	[ "$status" -eq 78 ]
	[[ "$output" == *'update refused: archive inventory is not the fixed core inventory'* ]]

	traversal_root=$BATS_TEST_TMPDIR/traversal-root
	mkdir "$traversal_root"
	cp "$REPOSITORY_ROOT/dist/nutmerlin-core-dev.tar.gz" "$package_path"
	tar -xzf "$package_path" -C "$traversal_root"
	printf '%s\n' escape >"$traversal_root/escape"
	package_tar=$BATS_TEST_TMPDIR/traversal.tar
	(
		cd "$traversal_root"
		tar --sort=name --mtime=@0 --owner=0 --group=0 --numeric-owner \
			--transform='s|^escape$|../escape|' -cf "$package_tar" \
			LICENSE MANIFEST.sha256 README.md VERSION bin install.sh lib share escape
	)
	gzip -n -c "$package_tar" >"$package_path"
	write_sidecar

	invoke_cli update "$package_path"

	[ "$status" -eq 78 ]
	[[ "$output" == *'update refused: archive inventory is not the fixed core inventory'* ]]
	[ ! -e "$NUTMERLIN_JFFS_ROOT/addons/escape" ]

	absolute_root=$BATS_TEST_TMPDIR/absolute-root
	absolute_target=$BATS_TEST_TMPDIR/absolute-escape
	mkdir "$absolute_root"
	cp "$REPOSITORY_ROOT/dist/nutmerlin-core-dev.tar.gz" "$package_path"
	tar -xzf "$package_path" -C "$absolute_root"
	printf '%s\n' escape >"$absolute_root/escape"
	package_tar=$BATS_TEST_TMPDIR/absolute.tar
	(
		cd "$absolute_root"
		tar -P --sort=name --mtime=@0 --owner=0 --group=0 --numeric-owner \
			--transform="s|^escape$|$absolute_target|" -cf "$package_tar" \
			LICENSE MANIFEST.sha256 README.md VERSION bin install.sh lib share escape
	)
	gzip -n -c "$package_tar" >"$package_path"
	write_sidecar
	invoke_cli update "$package_path"
	[ "$status" -eq 78 ]
	[[ "$output" == *'update refused: archive inventory is not the fixed core inventory'* ]]
	[ ! -e "$absolute_target" ]
}

@test "update rejects unsafe archive types and modes before extraction" {
	code_snapshot >"$BATS_TEST_TMPDIR/code.before"
	unsafe_mode_root=$BATS_TEST_TMPDIR/unsafe-mode-root
	mkdir "$unsafe_mode_root"
	tar -xzf "$package_path" -C "$unsafe_mode_root"
	chmod 777 "$unsafe_mode_root/lib/nutmerlin/status.sh"
	rebuild_package_from_root "$unsafe_mode_root"

	invoke_cli update "$package_path"

	[ "$status" -eq 78 ]
	[[ "$output" == *'update refused: archive types or modes are unsafe'* ]]

	unsafe_link_root=$BATS_TEST_TMPDIR/unsafe-link-root
	mkdir "$unsafe_link_root"
	cp "$REPOSITORY_ROOT/dist/nutmerlin-core-dev.tar.gz" "$package_path"
	tar -xzf "$package_path" -C "$unsafe_link_root"
	rm "$unsafe_link_root/lib/nutmerlin/status.sh"
	ln -s ../../LICENSE "$unsafe_link_root/lib/nutmerlin/status.sh"
	rewrite_internal_manifest "$unsafe_link_root"
	rebuild_package_from_root "$unsafe_link_root"

	invoke_cli update "$package_path"

	[ "$status" -eq 78 ]
	[[ "$output" == *'update refused: archive types or modes are unsafe'* ]]
	code_snapshot >"$BATS_TEST_TMPDIR/code.after"
	cmp "$BATS_TEST_TMPDIR/code.before" "$BATS_TEST_TMPDIR/code.after"
}

@test "update verifies the internal fixed manifest before replacing owned code" {
	package_root=$BATS_TEST_TMPDIR/bad-manifest-root
	mkdir "$package_root"
	tar -xzf "$package_path" -C "$package_root"
	sed '1s/^[0-9a-f][0-9a-f]*/0000000000000000000000000000000000000000000000000000000000000000/' \
		"$package_root/MANIFEST.sha256" >"$package_root/MANIFEST.sha256.new"
	mv "$package_root/MANIFEST.sha256.new" "$package_root/MANIFEST.sha256"
	chmod 644 "$package_root/MANIFEST.sha256"
	rebuild_package_from_root "$package_root"
	code_snapshot >"$BATS_TEST_TMPDIR/code.before"

	invoke_cli update "$package_path"

	[ "$status" -eq 78 ]
	[[ "$output" == *'update refused: extracted core manifest verification failed'* ]]
	code_snapshot >"$BATS_TEST_TMPDIR/code.after"
	cmp "$BATS_TEST_TMPDIR/code.before" "$BATS_TEST_TMPDIR/code.after"
	[ -z "$(find "$NUTMERLIN_JFFS_ROOT/addons" -mindepth 1 -maxdepth 1 \
		-name '.nutmerlin-update-*' -print -quit)" ]
}

@test "update refuses before staging when JFFS cannot hold the candidate" {
	write_sidecar
	code_snapshot >"$BATS_TEST_TMPDIR/code.before"
	NUTMERLIN_TEST_JFFS_AVAILABLE_KB=1

	invoke_cli update "$package_path"

	[ "$status" -eq 69 ]
	[[ "$output" == *'update unavailable: JFFS does not have enough free space'* ]]
	code_snapshot >"$BATS_TEST_TMPDIR/code.after"
	cmp "$BATS_TEST_TMPDIR/code.before" "$BATS_TEST_TMPDIR/code.after"
	[ -z "$(find "$NUTMERLIN_JFFS_ROOT/addons" -mindepth 1 -maxdepth 1 \
		-name '.nutmerlin-update-*' -print -quit)" ]
}

@test "a valid local update atomically replaces code and preserves disabled configuration" {
	invoke_cli disable
	[ "$status" -eq 0 ]
	invoke_cli client add server-a
	[ "$status" -eq 0 ]
	installation_id=$(cat "$code_root/installation.id")
	tree_snapshot "$config_root" >"$BATS_TEST_TMPDIR/config.before"
	update_root=$BATS_TEST_TMPDIR/update-root
	mkdir "$update_root"
	tar -xzf "$package_path" -C "$update_root"
	printf '%s\n' '0.1.1-test' >"$update_root/VERSION"
	rewrite_internal_manifest "$update_root"
	rebuild_package_from_root "$update_root"

	invoke_cli update "$package_path"

	[ "$status" -eq 0 ]
	[ "$output" = 'update: ok: NUTMerlin updated to 0.1.1-test; service remains disabled' ]
	[ "$(cat "$code_root/VERSION")" = '0.1.1-test' ]
	[ "$(cat "$code_root/installation.id")" = "$installation_id" ]
	[ "$(cat "$code_root/enabled")" = 0 ]
	tree_snapshot "$config_root" >"$BATS_TEST_TMPDIR/config.after"
	cmp "$BATS_TEST_TMPDIR/config.before" "$BATS_TEST_TMPDIR/config.after"
	[ -z "$(find "$NUTMERLIN_JFFS_ROOT/addons" -mindepth 1 -maxdepth 1 \
		\( -name '.nutmerlin-update-*' -o -name '.nutmerlin-backup-*' \) \
		-print -quit)" ]
	[ ! -s "$NUTMERLIN_EXTERNAL_CALL_LOG" ]
}

@test "activation failure restores one backup and an exact retry succeeds" {
	invoke_cli disable
	[ "$status" -eq 0 ]
	prior_version=$(cat "$code_root/VERSION")
	prior_id=$(cat "$code_root/installation.id")
	tree_snapshot "$config_root" >"$BATS_TEST_TMPDIR/config.before"
	update_root=$BATS_TEST_TMPDIR/recovery-update-root
	mkdir "$update_root"
	tar -xzf "$package_path" -C "$update_root"
	printf '%s\n' '0.1.2-test' >"$update_root/VERSION"
	rewrite_internal_manifest "$update_root"
	rebuild_package_from_root "$update_root"
	NUTMERLIN_TEST_UPDATE_FAIL_AFTER=activation

	invoke_cli update "$package_path"

	[ "$status" -eq 75 ]
	[[ "$output" == *'update temporary failure after activation'* ]]
	[[ "$output" == *'update activation failed; the previous code was restored'* ]]
	[ "$(cat "$code_root/VERSION")" = "$prior_version" ]
	[ "$(cat "$code_root/installation.id")" = "$prior_id" ]
	[ "$(cat "$code_root/enabled")" = 0 ]
	tree_snapshot "$config_root" >"$BATS_TEST_TMPDIR/config.after"
	cmp "$BATS_TEST_TMPDIR/config.before" "$BATS_TEST_TMPDIR/config.after"
	[ -z "$(find "$NUTMERLIN_JFFS_ROOT/addons" -mindepth 1 -maxdepth 1 \
		\( -name '.nutmerlin-update-*' -o -name '.nutmerlin-backup-*' \) \
		-print -quit)" ]

	unset NUTMERLIN_TEST_UPDATE_FAIL_AFTER
	invoke_cli update "$package_path"
	[ "$status" -eq 0 ]
	[ "$(cat "$code_root/VERSION")" = '0.1.2-test' ]
}

@test "rollback restores the old root disabled even when cleanup reports failure" {
	prior_version=$(cat "$code_root/VERSION")
	write_sidecar
	NUTMERLIN_TEST_UPDATE_FAIL_AFTER=activation
	NUTMERLIN_TEST_UPDATE_RECOVERY_CLEANUP_FAIL=1

	invoke_cli update "$package_path"

	[ "$status" -eq 75 ]
	[[ "$output" == *'update recovery incomplete; the previous code was restored disabled and requires repair'* ]]
	[ "$(cat "$code_root/VERSION")" = "$prior_version" ]
	[ "$(cat "$code_root/enabled")" = 0 ]
	[ -z "$(find "$NUTMERLIN_JFFS_ROOT/addons" -mindepth 1 -maxdepth 1 \
		\( -name '.nutmerlin-update-*' -o -name '.nutmerlin-backup-*' \) \
		-print -quit)" ]
}

assert_signal_restores_callable_old_root() {
	signal_checkpoint=$1
	invoke_cli disable
	[ "$status" -eq 0 ]
	prior_version=$(cat "$code_root/VERSION")
	write_sidecar
	NUTMERLIN_TEST_UPDATE_SIGNAL_AFTER=$signal_checkpoint

	invoke_cli update "$package_path"

	[ "$status" -eq 143 ] || {
		printf 'checkpoint=%s status=%s output=%s\n' \
			"$signal_checkpoint" "$status" "$output" >&2
		false
	}
	[ "$(cat "$code_root/VERSION")" = "$prior_version" ]
	[ "$(cat "$code_root/enabled")" = 0 ] || {
		printf 'checkpoint=%s enabled=%s output=%s\n' "$signal_checkpoint" \
			"$(cat "$code_root/enabled")" "$output" >&2
		false
	}
	[ -x "$installed_cli" ]
	[ -z "$(find "$NUTMERLIN_JFFS_ROOT/addons" -mindepth 1 -maxdepth 1 \
		\( -name '.nutmerlin-update-*' -o -name '.nutmerlin-backup-*' \) \
		-print -quit)" ]
	unset NUTMERLIN_TEST_UPDATE_SIGNAL_AFTER
}

@test "a signal after close restores one callable old root" {
	assert_signal_restores_callable_old_root closing
}

@test "a signal with only the backup present restores one callable old root" {
	assert_signal_restores_callable_old_root backup
}

@test "a signal after candidate activation restores one callable old root" {
	assert_signal_restores_callable_old_root activation
}

@test "candidate service code must pass smoke or the old core is restored" {
	invoke_cli disable
	[ "$status" -eq 0 ]
	prior_version=$(cat "$code_root/VERSION")
	broken_root=$BATS_TEST_TMPDIR/broken-service-root
	mkdir "$broken_root"
	tar -xzf "$package_path" -C "$broken_root"
	printf '%s\n' '' 'service_validate_active_source() {' \
		"  printf '%s\\n' 'candidate service smoke failed' >&2" \
		'  return 75' '}' >>"$broken_root/lib/nutmerlin/service.sh"
	printf '%s\n' '0.1.3-test' >"$broken_root/VERSION"
	rewrite_internal_manifest "$broken_root"
	rebuild_package_from_root "$broken_root"

	invoke_cli update "$package_path"

	[ "$status" -eq 75 ]
	[[ "$output" == *'candidate service smoke failed'* ]] || {
		printf 'status=%s output=%s\n' "$status" "$output" >&2
		false
	}
	[[ "$output" == *'update activation failed; the previous code was restored'* ]]
	[ "$(cat "$code_root/VERSION")" = "$prior_version" ]
	[ "$(cat "$code_root/enabled")" = 0 ]
	[ -z "$(find "$NUTMERLIN_JFFS_ROOT/addons" -mindepth 1 -maxdepth 1 \
		\( -name '.nutmerlin-update-*' -o -name '.nutmerlin-backup-*' \) \
		-print -quit)" ]
}

@test "the packaged installer survives update repair and owned uninstall in an isolated root" {
	invoke_cli uninstall
	[ "$status" -eq 0 ]
	package_install_root=$BATS_TEST_TMPDIR/package-install
	mkdir "$package_install_root"
	tar -xzf "$REPOSITORY_ROOT/dist/nutmerlin-core-dev.tar.gz" \
		-C "$package_install_root"

	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		"$package_install_root/install.sh"
	[ "$status" -eq 0 ]
	installed_cli=$code_root/bin/nutmerlin
	invoke_cli disable
	[ "$status" -eq 0 ]
	invoke_cli update "$REPOSITORY_ROOT/dist/nutmerlin-core-dev.tar.gz"
	[ "$status" -eq 0 ]
	invoke_cli repair
	[ "$status" -eq 0 ]
	invoke_cli uninstall
	[ "$status" -eq 0 ]
	[ ! -e "$code_root" ]
	[ ! -e "$config_root" ]
	[ -f "$NUTMERLIN_OPT_ROOT/lib/opkg/status" ]
}

@test "update rejects remote grammar and ambiguous live state without staging" {
	invoke_cli update https://example.invalid/nutmerlin.tar.gz
	[ "$status" -eq 78 ]
	[[ "$output" == *'update refused: archive must be a local path'* ]]
	invoke_cli update "$package_path" extra
	[ "$status" -eq 64 ]

	write_sidecar
	mkdir -m 700 "$NUTMERLIN_TEST_ROOT/platform"
	printf '%s\n' 'foreign schedule' >"$NUTMERLIN_TEST_ROOT/platform/cru.tsv"
	chmod 600 "$NUTMERLIN_TEST_ROOT/platform/cru.tsv"
	code_snapshot >"$BATS_TEST_TMPDIR/code.before"
	invoke_cli update "$package_path"
	[ "$status" -eq 78 ]
	[[ "$output" == *'management refused: periodic job state is foreign or ambiguous'* ]]
	code_snapshot >"$BATS_TEST_TMPDIR/code.after"
	cmp "$BATS_TEST_TMPDIR/code.before" "$BATS_TEST_TMPDIR/code.after"
	[ -z "$(find "$NUTMERLIN_JFFS_ROOT/addons" -mindepth 1 -maxdepth 1 \
		-name '.nutmerlin-update-*' -print -quit)" ]
}
