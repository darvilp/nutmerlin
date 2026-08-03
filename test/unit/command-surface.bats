#!/usr/bin/env bats

setup() {
	REPOSITORY_ROOT=$(cd "$BATS_TEST_DIRNAME/../.." && pwd)
}

@test "stable host-safe project commands are available" {
	for target in bootstrap lint test-unit test test-nut test-security docs-check package; do
		run make --no-print-directory -n -C "$REPOSITORY_ROOT" "$target"
		[ "$status" -eq 0 ]
	done
}

@test "superseded qualification commands are absent" {
	for old_command in self-check platform-eligibility dependency-plan storage-preflight storage-readiness; do
		run "$REPOSITORY_ROOT/bin/nutmerlin" "$old_command"
		[ "$status" -eq 64 ]
	done
}

@test "bootstrap requires a complete real NUT binary set" {
	private_nut_root=$BATS_TEST_TMPDIR/nut-root
	mkdir -p "$private_nut_root/lib/nut" "$private_nut_root/bin"
	for binary_name in dummy-ups upsd usbhid-ups; do
		printf '%s\n' '#!/bin/sh' 'exit 0' >"$private_nut_root/lib/nut/$binary_name"
		chmod 700 "$private_nut_root/lib/nut/$binary_name"
	done
	printf '%s\n' '#!/bin/sh' 'exit 0' >"$private_nut_root/bin/upsc"
	chmod 700 "$private_nut_root/bin/upsc"

	run env NUTMERLIN_NUT_ROOT="$private_nut_root" "$REPOSITORY_ROOT/tools/project-checks.sh" bootstrap
	[ "$status" -eq 0 ]

	rm "$private_nut_root/bin/upsc"
	run env NUTMERLIN_NUT_ROOT="$private_nut_root" "$REPOSITORY_ROOT/tools/project-checks.sh" bootstrap
	[ "$status" -eq 1 ]
	[[ "$output" == *'missing required host NUT binary: upsc'* ]]
}
