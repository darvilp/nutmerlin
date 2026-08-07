#!/usr/bin/env bats

setup() {
	REPOSITORY_ROOT=$(cd "$BATS_TEST_DIRNAME/../.." && pwd)
	# shellcheck source=test/lib/host-harness.sh
	. "$REPOSITORY_ROOT/test/lib/host-harness.sh"
	host_harness_setup
	# shellcheck source=test/lib/entware-fixture.sh
	. "$REPOSITORY_ROOT/test/lib/entware-fixture.sh"
	entware_fixture_setup
	version=$(cat "$REPOSITORY_ROOT/VERSION")
	archive_name=nutmerlin-core-$version.tar.gz
	archive_path=$REPOSITORY_ROOT/dist/$archive_name
	launcher_path=$REPOSITORY_ROOT/dist/nutmerlin-install-$version.sh
	make --no-print-directory -C "$REPOSITORY_ROOT" release-artifacts >/dev/null
	make_fake_curl
}

teardown() {
	host_harness_teardown
}

make_fake_curl() {
	cat >"$NUTMERLIN_TEST_ROOT/bin/curl" <<'EOF'
#!/bin/sh
set -eu
output=
url=
while [ "$#" -gt 0 ]; do
	case $1 in
		-o)
			shift
			[ "$#" -gt 0 ] || exit 64
			output=$1
			;;
		https://*) url=$1 ;;
	esac
	shift
done
printf '%s\n' "$url" >"$NUTMERLIN_TEST_CURL_LOG"
[ "${NUTMERLIN_TEST_CURL_FAIL:-0}" != 1 ] || exit 22
[ -n "$output" ] && [ -n "$url" ] && [ -f "$NUTMERLIN_TEST_DOWNLOAD_SOURCE" ] || exit 64
cp "$NUTMERLIN_TEST_DOWNLOAD_SOURCE" "$output"
EOF
	chmod 700 "$NUTMERLIN_TEST_ROOT/bin/curl"
	NUTMERLIN_TEST_CURL=$NUTMERLIN_TEST_ROOT/bin/curl
	NUTMERLIN_TEST_CURL_LOG=$NUTMERLIN_TEST_ROOT/curl.log
	export NUTMERLIN_TEST_CURL NUTMERLIN_TEST_CURL_LOG
}

invoke_launcher() {
	launcher=$1
	input=${2-}
	download_source=$3
	shift 3
	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_CURL="$NUTMERLIN_TEST_CURL" \
		NUTMERLIN_TEST_CURL_LOG="$NUTMERLIN_TEST_CURL_LOG" \
		NUTMERLIN_TEST_DOWNLOAD_SOURCE="$download_source" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		NUTMERLIN_TEST_INTERACTIVE=1 \
		"$@" /bin/sh -c 'printf "%s" "$1" | /bin/sh "$2"' sh "$input" "$launcher"
}

assert_bootstrap_clean() {
	[ -z "$(find "$NUTMERLIN_TEST_ROOT/tmp" -mindepth 1 -maxdepth 1 \
		-name 'nutmerlin-bootstrap.*' -print -quit)" ]
}

repack_core() {
	package_root=$1
	output_path=$2
	temporary_tar=$BATS_TEST_TMPDIR/repacked.tar
	(
		cd "$package_root"
		tar --sort=name --mtime=@0 --owner=0 --group=0 --numeric-owner \
			-cf "$temporary_tar" LICENSE MANIFEST.sha256 README.md VERSION \
			bin install.sh lib share
	)
	gzip -n -c "$temporary_tar" >"$output_path"
}

launcher_for_archive() {
	custom_archive=$1
	custom_launcher=$2
	original_digest=$(sha256sum "$archive_path" | awk '{ print $1 }')
	custom_digest=$(sha256sum "$custom_archive" | awk '{ print $1 }')
	sed "s/$original_digest/$custom_digest/g" "$launcher_path" >"$custom_launcher"
	chmod 700 "$custom_launcher"
}

@test "release artifacts are deterministic versioned and pinned to one archive digest" {
	[ -f "$archive_path" ]
	[ -f "$archive_path.sha256" ]
	[ -x "$launcher_path" ]
	cp "$archive_path" "$BATS_TEST_TMPDIR/first.tar.gz"
	cp "$archive_path.sha256" "$BATS_TEST_TMPDIR/first.tar.gz.sha256"
	cp "$launcher_path" "$BATS_TEST_TMPDIR/first-launcher.sh"

	run make --no-print-directory -C "$REPOSITORY_ROOT" release-artifacts
	[ "$status" -eq 0 ]
	cmp "$BATS_TEST_TMPDIR/first.tar.gz" "$archive_path"
	cmp "$BATS_TEST_TMPDIR/first.tar.gz.sha256" "$archive_path.sha256"
	cmp "$BATS_TEST_TMPDIR/first-launcher.sh" "$launcher_path"

	expected_digest=$(sha256sum "$archive_path" | awk '{ print $1 }')
	[ "$(cat "$archive_path.sha256")" = "$expected_digest  $archive_name" ]
	grep -F "https://github.com/darvilp/nutmerlin/releases/download/v$version/$archive_name" \
		"$launcher_path"
	grep -F "$expected_digest" "$launcher_path"
	[ "$(stat -c '%a' "$launcher_path")" = 755 ]
	/bin/sh -n "$launcher_path"
}

@test "production bootstrap requires the explicit router gate before download" {
	run env -u NUTMERLIN_ENABLE_TEST_ADAPTERS -u NUTMERLIN_ALLOW_PRODUCTION_ROUTER \
		/bin/sh "$launcher_path"

	[ "$status" -eq 78 ]
	[[ "$output" == *'bootstrap refused: set NUTMERLIN_ALLOW_PRODUCTION_ROUTER=1'* ]]
}

@test "test curl adapter cannot escape its canonical direct-child path" {
	cp "$NUTMERLIN_TEST_CURL" "$NUTMERLIN_TEST_ROOT/outside-curl"
	chmod 700 "$NUTMERLIN_TEST_ROOT/outside-curl"

	invoke_launcher "$launcher_path" 'q
' "$archive_path" \
		NUTMERLIN_TEST_CURL="$NUTMERLIN_TEST_ROOT/bin/../outside-curl"

	[ "$status" -eq 78 ]
	[[ "$output" == *'bootstrap refused: isolated curl adapter is invalid'* ]]
	[ ! -e "$NUTMERLIN_TEST_CURL_LOG" ]
	assert_bootstrap_clean
}

@test "test curl adapter refuses a symlinked bin parent" {
	mv "$NUTMERLIN_TEST_ROOT/bin" "$NUTMERLIN_TEST_ROOT/real-bin"
	ln -s real-bin "$NUTMERLIN_TEST_ROOT/bin"
	NUTMERLIN_TEST_CURL=$NUTMERLIN_TEST_ROOT/bin/curl
	export NUTMERLIN_TEST_CURL

	invoke_launcher "$launcher_path" 'q
' "$archive_path"

	[ "$status" -eq 78 ]
	[[ "$output" == *'bootstrap refused: isolated curl adapter parent is invalid'* ]]
	[ ! -e "$NUTMERLIN_TEST_CURL_LOG" ]
	assert_bootstrap_clean
}

@test "workspace permission failure still cleans the validated temporary directory" {
	cat >"$NUTMERLIN_TEST_ROOT/bin/chmod" <<'EOF'
#!/bin/sh
case ${2:-} in
	"$NUTMERLIN_TEST_ROOT"/tmp/nutmerlin-bootstrap.*) exit 1 ;;
esac
exec /bin/chmod "$@"
EOF
	/bin/chmod 700 "$NUTMERLIN_TEST_ROOT/bin/chmod"

	invoke_launcher "$launcher_path" 'q
' "$archive_path"

	[ "$status" -eq 75 ]
	[[ "$output" == *'bootstrap unavailable: temporary workspace permissions could not be set'* ]]
	assert_bootstrap_clean
}

@test "valid pinned core reaches the existing menu and quit leaves no state" {
	invoke_launcher "$launcher_path" 'q
' "$archive_path"

	[ "$status" -eq 0 ]
	[[ "$output" == *"NUTMerlin $version"* ]]
	[[ "$output" == *'State: not installed'* ]]
	[[ "$output" == *'i) Install NUTMerlin'* ]]
	[[ "$output" == *'Menu closed; no changes were made'* ]]
	[ "$(cat "$NUTMERLIN_TEST_CURL_LOG")" = \
		"https://github.com/darvilp/nutmerlin/releases/download/v$version/$archive_name" ]
	[ ! -e "$NUTMERLIN_JFFS_ROOT/addons/nutmerlin" ]
	[ ! -e "$NUTMERLIN_OPT_ROOT/etc/nutmerlin" ]
	assert_bootstrap_clean
}

@test "confirmed menu install uses the verified downloaded core" {
	invoke_launcher "$launcher_path" 'i
y
n
q
' "$archive_path"

	[ "$status" -eq 0 ]
	[[ "$output" == *'Install NUTMerlin? [y/N]'* ]]
	[[ "$output" == *'Refresh the six required Entware NUT packages? [y/N]'* ]]
	[[ "$output" == *'NUTMerlin installed: dummy is configured loopback-only'* ]]
	[ -x "$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/bin/nutmerlin" ]
	[ -d "$NUTMERLIN_OPT_ROOT/etc/nutmerlin" ]
	assert_bootstrap_clean
}

@test "download failure is temporary and cleans its private workspace" {
	invoke_launcher "$launcher_path" 'q
' "$archive_path" NUTMERLIN_TEST_CURL_FAIL=1

	[ "$status" -eq 75 ]
	[[ "$output" == *'bootstrap unavailable: pinned core download failed'* ]]
	[[ "$output" != *'NUTMerlin 0.1.0-dev'* ]]
	assert_bootstrap_clean
}

@test "truncated or digest-mismatched core is refused before extraction" {
	printf '%s\n' truncated >"$BATS_TEST_TMPDIR/truncated.tar.gz"
	invoke_launcher "$launcher_path" 'q
' "$BATS_TEST_TMPDIR/truncated.tar.gz"

	[ "$status" -eq 78 ]
	[[ "$output" == *'bootstrap refused: core archive SHA-256 mismatch'* ]]
	[[ "$output" != *'NUTMerlin 0.1.0-dev'* ]]
	assert_bootstrap_clean
}

@test "unsafe archive inventory and modes are refused before extraction" {
	unsafe_root=$BATS_TEST_TMPDIR/unsafe-root
	mkdir "$unsafe_root"
	tar -xzf "$archive_path" -C "$unsafe_root"
	chmod 600 "$unsafe_root/install.sh"
	repack_core "$unsafe_root" "$BATS_TEST_TMPDIR/unsafe.tar.gz"
	launcher_for_archive "$BATS_TEST_TMPDIR/unsafe.tar.gz" \
		"$BATS_TEST_TMPDIR/unsafe-launcher.sh"

	invoke_launcher "$BATS_TEST_TMPDIR/unsafe-launcher.sh" 'q
' "$BATS_TEST_TMPDIR/unsafe.tar.gz"

	[ "$status" -eq 78 ]
	[[ "$output" == *'bootstrap refused: core archive types or modes are unsafe'* ]]
	[[ "$output" != *'NUTMerlin 0.1.0-dev'* ]]
	assert_bootstrap_clean
}

@test "an unsafe archive object type is refused before extraction" {
	unsafe_root=$BATS_TEST_TMPDIR/type-root
	mkdir "$unsafe_root"
	tar -xzf "$archive_path" -C "$unsafe_root"
	rm "$unsafe_root/README.md"
	ln -s LICENSE "$unsafe_root/README.md"
	repack_core "$unsafe_root" "$BATS_TEST_TMPDIR/type.tar.gz"
	launcher_for_archive "$BATS_TEST_TMPDIR/type.tar.gz" \
		"$BATS_TEST_TMPDIR/type-launcher.sh"

	invoke_launcher "$BATS_TEST_TMPDIR/type-launcher.sh" 'q
' "$BATS_TEST_TMPDIR/type.tar.gz"

	[ "$status" -eq 78 ]
	[[ "$output" == *'bootstrap refused: core archive types or modes are unsafe'* ]]
	[[ "$output" != *'NUTMerlin 0.1.0-dev'* ]]
	assert_bootstrap_clean
}

@test "an extra archive object is refused before extraction" {
	unsafe_root=$BATS_TEST_TMPDIR/extra-root
	mkdir "$unsafe_root"
	tar -xzf "$archive_path" -C "$unsafe_root"
	printf '%s\n' unexpected >"$unsafe_root/unexpected"
	temporary_tar=$BATS_TEST_TMPDIR/extra.tar
	(
		cd "$unsafe_root"
		tar --sort=name --mtime=@0 --owner=0 --group=0 --numeric-owner \
			-cf "$temporary_tar" LICENSE MANIFEST.sha256 README.md VERSION \
			bin install.sh lib share unexpected
	)
	gzip -n -c "$temporary_tar" >"$BATS_TEST_TMPDIR/extra.tar.gz"
	launcher_for_archive "$BATS_TEST_TMPDIR/extra.tar.gz" \
		"$BATS_TEST_TMPDIR/extra-launcher.sh"

	invoke_launcher "$BATS_TEST_TMPDIR/extra-launcher.sh" 'q
' "$BATS_TEST_TMPDIR/extra.tar.gz"

	[ "$status" -eq 78 ]
	[[ "$output" == *'bootstrap refused: core archive inventory is unsafe'* ]]
	[[ "$output" != *'NUTMerlin 0.1.0-dev'* ]]
	assert_bootstrap_clean
}

@test "a corrupt internal manifest is refused before the menu" {
	corrupt_root=$BATS_TEST_TMPDIR/corrupt-root
	mkdir "$corrupt_root"
	tar -xzf "$archive_path" -C "$corrupt_root"
	printf '%s\n' tampered >>"$corrupt_root/README.md"
	repack_core "$corrupt_root" "$BATS_TEST_TMPDIR/corrupt.tar.gz"
	launcher_for_archive "$BATS_TEST_TMPDIR/corrupt.tar.gz" \
		"$BATS_TEST_TMPDIR/corrupt-launcher.sh"

	invoke_launcher "$BATS_TEST_TMPDIR/corrupt-launcher.sh" 'q
' "$BATS_TEST_TMPDIR/corrupt.tar.gz"

	[ "$status" -eq 78 ]
	[[ "$output" == *'bootstrap refused: extracted core manifest verification failed'* ]]
	[[ "$output" != *'NUTMerlin 0.1.0-dev'* ]]
	assert_bootstrap_clean
}

@test "foreign installed state remains inert through the downloaded menu" {
	foreign_code_root=$NUTMERLIN_JFFS_ROOT/addons/nutmerlin
	foreign_marker=$BATS_TEST_TMPDIR/foreign-cli-ran
	mkdir -p "$foreign_code_root/bin"
	printf '%s\n' '#!/bin/sh' "printf '%s\\n' ran >'$foreign_marker'" \
		>"$foreign_code_root/bin/nutmerlin"
	chmod 700 "$foreign_code_root/bin/nutmerlin"

	invoke_launcher "$launcher_path" 'i
q
' "$archive_path"

	[ "$status" -eq 0 ]
	[[ "$output" == *'State: unavailable; installed ownership could not be verified'* ]]
	[[ "$output" != *'i) Install NUTMerlin'* ]]
	[ ! -e "$foreign_marker" ]
	assert_bootstrap_clean
}

@test "end of input is inert and cleans the downloaded core" {
	invoke_launcher "$launcher_path" '' "$archive_path"

	[ "$status" -eq 0 ]
	[[ "$output" == *'Menu closed; no changes were made'* ]]
	[ ! -e "$NUTMERLIN_JFFS_ROOT/addons/nutmerlin" ]
	[ ! -e "$NUTMERLIN_OPT_ROOT/etc/nutmerlin" ]
	assert_bootstrap_clean
}
