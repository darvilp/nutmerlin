#!/usr/bin/env bats

setup() {
	repository_root=$(CDPATH='' cd -- "$BATS_TEST_DIRNAME/../.." && pwd)
}

@test "Merlin hooks recover real NUT across mount, failure, pause, and reboot scenarios" {
	run "$repository_root/test/integration/run-installed-core.sh" lifecycle

	[ "$status" -eq 0 ]
	[ "$output" = 'Merlin lifecycle: hooks=5 recovery=bounded status=healthy' ]
}
