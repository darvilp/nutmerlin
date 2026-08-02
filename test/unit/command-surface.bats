#!/usr/bin/env bats

setup() {
	REPOSITORY_ROOT=$(cd "$BATS_TEST_DIRNAME/../.." && pwd)
}

@test "stable host-safe project commands are available" {
	for target in bootstrap lint test-unit test test-security docs-check package; do
		run make --no-print-directory -n -C "$REPOSITORY_ROOT" "$target"
		[ "$status" -eq 0 ]
	done
}
