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

@test "usbhid health rejects an upsc serial that differs from the selected identity" {
	fake_upsc=$BATS_TEST_TMPDIR/upsc
	printf '%s\n' '#!/bin/sh' \
		"printf '%s\\n' 'driver.name: usbhid-ups' 'device.serial: OTHER999' 'ups.status: OL'" \
		>"$fake_upsc"
	chmod 700 "$fake_upsc"
	mkdir -p "$BATS_TEST_TMPDIR/run"

	run env REPOSITORY_ROOT="$REPOSITORY_ROOT" FAKE_UPSC="$fake_upsc" \
		SERVICE_RUNTIME_ROOT="$BATS_TEST_TMPDIR" /bin/sh -c '
		. "$REPOSITORY_ROOT/lib/nutmerlin/service.sh"
		sleep() { return 0; }
		NUTMERLIN_UPSC_BIN=$FAKE_UPSC
		service_runtime_root=$SERVICE_RUNTIME_ROOT
		SERVICE_SOURCE=ups
		CONFIGURATION_IDENTITY_KIND=serial
		CONFIGURATION_IDENTITY_VALUE=CPS123456
		service_query_active
	'

	[ "$status" -eq 1 ]
}

@test "usbhid health accepts only the selected serial or busport identity" {
	fake_upsc=$BATS_TEST_TMPDIR/upsc
	mkdir -p "$BATS_TEST_TMPDIR/run"
	for identity_kind in serial busport; do
		case $identity_kind in
			serial)
				identity_value=CPS123456
				identity_line='device.serial: CPS123456'
				;;
			busport)
				identity_value=003
				identity_line='driver.parameter.busport: ^003$'
				;;
		esac
		printf '%s\n' '#!/bin/sh' \
			"printf '%s\\n' 'driver.name: usbhid-ups' '$identity_line' 'ups.status: OL'" \
			>"$fake_upsc"
		chmod 700 "$fake_upsc"

		run env REPOSITORY_ROOT="$REPOSITORY_ROOT" FAKE_UPSC="$fake_upsc" \
			SERVICE_RUNTIME_ROOT="$BATS_TEST_TMPDIR" IDENTITY_KIND="$identity_kind" \
			IDENTITY_VALUE="$identity_value" /bin/sh -c '
			. "$REPOSITORY_ROOT/lib/nutmerlin/service.sh"
			NUTMERLIN_UPSC_BIN=$FAKE_UPSC
			service_runtime_root=$SERVICE_RUNTIME_ROOT
			SERVICE_SOURCE=ups
			CONFIGURATION_IDENTITY_KIND=$IDENTITY_KIND
			CONFIGURATION_IDENTITY_VALUE=$IDENTITY_VALUE
			service_query_active
		'

		[ "$status" -eq 0 ]
	done
}
