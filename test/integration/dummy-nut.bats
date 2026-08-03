#!/usr/bin/env bats

setup() {
	repository_root=$(CDPATH='' cd -- "$BATS_TEST_DIRNAME/../.." && pwd)
}

@test "real dummy-ups, upsd, and upsc survive stop and restart" {
	run "$repository_root/test/integration/run-dummy-nut.sh" smoke

	[ "$status" -eq 0 ]
	[ "$output" = 'battery.charge: 100
device.mfr: CPS
device.model: CP1500PFCLCD
ups.status: OL' ]
}

@test "unsafe listener configuration is rejected before processes start" {
	caller_tmp=$BATS_TEST_TMPDIR/caller-controlled-tmp
	mkdir "$caller_tmp"
	chmod 500 "$caller_tmp"
	run env TMPDIR="$caller_tmp" "$repository_root/test/integration/run-dummy-nut.sh" invalid
	chmod 700 "$caller_tmp"

	[ "$status" -eq 78 ]
	[ "$output" = 'nut-integration: unsafe-listener: LISTEN must be exactly 127.0.0.1 3493' ]
}
