#!/usr/bin/env bats

setup() {
	REPOSITORY_ROOT=$(cd "$BATS_TEST_DIRNAME/../.." && pwd)
}

@test "result renderer refuses control bytes instead of emitting invalid JSON" {
	run sh -c '. "$1/lib/nutmerlin/result.sh"; result_emit status json unavailable unavailable "line1
line2"' sh "$REPOSITORY_ROOT"

	[ "$status" -eq 70 ]
	[ "$output" = 'result: internal: unsafe result value' ]
}
