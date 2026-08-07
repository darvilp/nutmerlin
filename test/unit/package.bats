#!/usr/bin/env bats

setup() {
	REPOSITORY_ROOT=$(cd "$BATS_TEST_DIRNAME/../.." && pwd)
	package_path=$REPOSITORY_ROOT/dist/nutmerlin-core-dev.tar.gz
	sidecar_path=$package_path.sha256
}

@test "two core packages are identical and carry independently verifiable fixed manifests" {
	run make --no-print-directory -C "$REPOSITORY_ROOT" package
	[ "$status" -eq 0 ]
	[ -f "$package_path" ]
	[ -f "$sidecar_path" ]
	cp "$package_path" "$BATS_TEST_TMPDIR/first.tar.gz"
	cp "$sidecar_path" "$BATS_TEST_TMPDIR/first.tar.gz.sha256"

	run make --no-print-directory -C "$REPOSITORY_ROOT" package
	[ "$status" -eq 0 ]
	cmp "$BATS_TEST_TMPDIR/first.tar.gz" "$package_path"
	cmp "$BATS_TEST_TMPDIR/first.tar.gz.sha256" "$sidecar_path"

	expected_digest=$(sha256sum "$package_path" | awk '{ print $1 }')
	[ "$(cat "$sidecar_path")" = "$expected_digest  nutmerlin-core-dev.tar.gz" ]
	[ "$(tar -tzf "$package_path")" = 'LICENSE
MANIFEST.sha256
README.md
VERSION
bin/
bin/nutmerlin
install.sh
lib/
lib/nutmerlin/
lib/nutmerlin/client.sh
lib/nutmerlin/configuration.sh
lib/nutmerlin/entware.sh
lib/nutmerlin/hooks.sh
lib/nutmerlin/lifecycle.sh
lib/nutmerlin/management.sh
lib/nutmerlin/ownership.sh
lib/nutmerlin/paths.sh
lib/nutmerlin/platform.sh
lib/nutmerlin/result.sh
lib/nutmerlin/service.sh
lib/nutmerlin/status.sh
lib/nutmerlin/update.sh
share/
share/dummy/
share/dummy/cyberpower.dev' ]

	extract_root=$BATS_TEST_TMPDIR/extracted
	mkdir "$extract_root"
	tar -xzf "$package_path" -C "$extract_root"
	(
		cd "$extract_root"
		sha256sum -c MANIFEST.sha256
	)
	[ "$(awk '{ print $2 }' "$extract_root/MANIFEST.sha256")" = 'LICENSE
README.md
VERSION
bin/nutmerlin
install.sh
lib/nutmerlin/client.sh
lib/nutmerlin/configuration.sh
lib/nutmerlin/entware.sh
lib/nutmerlin/hooks.sh
lib/nutmerlin/lifecycle.sh
lib/nutmerlin/management.sh
lib/nutmerlin/ownership.sh
lib/nutmerlin/paths.sh
lib/nutmerlin/platform.sh
lib/nutmerlin/result.sh
lib/nutmerlin/service.sh
lib/nutmerlin/status.sh
lib/nutmerlin/update.sh
share/dummy/cyberpower.dev' ]
	unsafe_metadata=$(TZ=UTC tar --numeric-owner -tvzf "$package_path" |
		awk '$2 != "0/0" || $4 != "1970-01-01" || $5 != "00:00" { print }')
	[ -z "$unsafe_metadata" ]
	[ "$(TZ=UTC tar --numeric-owner -tvzf "$package_path" |
		awk '{ print $1, $NF }')" = '-rw-r--r-- LICENSE
-rw-r--r-- MANIFEST.sha256
-rw-r--r-- README.md
-rw-r--r-- VERSION
drwxr-xr-x bin/
-rwxr-xr-x bin/nutmerlin
-rwxr-xr-x install.sh
drwxr-xr-x lib/
drwxr-xr-x lib/nutmerlin/
-rw-r--r-- lib/nutmerlin/client.sh
-rw-r--r-- lib/nutmerlin/configuration.sh
-rw-r--r-- lib/nutmerlin/entware.sh
-rw-r--r-- lib/nutmerlin/hooks.sh
-rw-r--r-- lib/nutmerlin/lifecycle.sh
-rw-r--r-- lib/nutmerlin/management.sh
-rw-r--r-- lib/nutmerlin/ownership.sh
-rw-r--r-- lib/nutmerlin/paths.sh
-rw-r--r-- lib/nutmerlin/platform.sh
-rw-r--r-- lib/nutmerlin/result.sh
-rw-r--r-- lib/nutmerlin/service.sh
-rw-r--r-- lib/nutmerlin/status.sh
-rw-r--r-- lib/nutmerlin/update.sh
drwxr-xr-x share/
drwxr-xr-x share/dummy/
-rw-r--r-- share/dummy/cyberpower.dev' ]
}
