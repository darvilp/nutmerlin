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
