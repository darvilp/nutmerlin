#!/usr/bin/env bats

setup() {
	REPOSITORY_ROOT=$(cd "$BATS_TEST_DIRNAME/../.." && pwd)
}

@test "service health refuses independently owned processes from different epochs" {
	run env REPOSITORY_ROOT="$REPOSITORY_ROOT" /bin/sh -c '
		. "$REPOSITORY_ROOT/lib/nutmerlin/service.sh"
		service_pid_is_owned() { return 0; }
		service_pid_record_read() {
			recorded_set_id=11111111111111111111111111111111
			case $1 in
				*upsd.pid) recorded_epoch=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa ;;
				*) recorded_epoch=bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb ;;
			esac
		}
		service_current_set_id() { printf "%s\n" 11111111111111111111111111111111; }
		service_pid_pair_is_owned_current /tmp/upsd.pid /tmp/dummy-ups.pid
	'

	[ "$status" -eq 1 ]
}

@test "service health accepts one owned pair from the selected set and epoch" {
	run env REPOSITORY_ROOT="$REPOSITORY_ROOT" /bin/sh -c '
		. "$REPOSITORY_ROOT/lib/nutmerlin/service.sh"
		service_pid_is_owned() { return 0; }
		service_pid_record_read() {
			recorded_set_id=11111111111111111111111111111111
			recorded_epoch=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
		}
		service_current_set_id() { printf "%s\n" 11111111111111111111111111111111; }
		service_pid_pair_is_owned_current /tmp/upsd.pid /tmp/dummy-ups.pid
	'

	[ "$status" -eq 0 ]
}
