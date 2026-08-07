#!/usr/bin/env bats

setup() {
	repository_root=$(CDPATH='' cd -- "$BATS_TEST_DIRNAME/../.." && pwd)
}

@test "installed CLI lifecycle rejects foreign identity and rolls back activation once" {
	run "$repository_root/test/integration/run-installed-core.sh" rollback

	[ "$status" -eq 0 ]
	[ "$output" = 'activation rollback: preserved; retained sets: 2' ]
}

@test "real upsmon accepts one restricted client and rejects wrong or revoked credentials" {
	run "$repository_root/test/integration/run-installed-core.sh" client

	[ "$status" -eq 0 ]
	[ "$output" = 'standard secondary authentication: correct=accepted wrong=rejected revoked=rejected' ]
}

@test "real NUT survives disable enable repair and update before conservative uninstall" {
	run "$repository_root/test/integration/run-installed-core.sh" management

	[ "$status" -eq 0 ]
	[ "$output" = 'management lifecycle: disable=closed enable=running repair=running update=running uninstall=owned-only' ]
}
