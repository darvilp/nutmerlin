#!/bin/sh

set -eu

repository_root=$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)
scenario=${1:-}
nut_root=${NUTMERLIN_NUT_ROOT:-}
work_root=
driver_pid=
server_pid=

diagnostic() {
	diagnostic_code=$1
	shift
	printf 'nut-integration: %s: %s\n' "$diagnostic_code" "$*" >&2
}

fail() {
	diagnostic "$@"
	exit 1
}

resolve_binary() {
	binary_name=$1

	if [ -n "$nut_root" ]; then
		for binary_candidate in \
			"$nut_root/lib/nut/$binary_name" \
			"$nut_root/usr/lib/nut/$binary_name" \
			"$nut_root/sbin/$binary_name" \
			"$nut_root/usr/sbin/$binary_name" \
			"$nut_root/bin/$binary_name" \
			"$nut_root/usr/bin/$binary_name"; do
			if [ -x "$binary_candidate" ]; then
				printf '%s\n' "$binary_candidate"
				return 0
			fi
		done
		return 1
	fi

	for binary_candidate in \
		"/lib/nut/$binary_name" \
		"/usr/lib/nut/$binary_name" \
		"/usr/sbin/$binary_name" \
		"/usr/bin/$binary_name"; do
		if [ -x "$binary_candidate" ]; then
			printf '%s\n' "$binary_candidate"
			return 0
		fi
	done

	command -v "$binary_name" 2>/dev/null || return 1
}

stop_processes() {
	if [ -n "$server_pid" ] && kill -0 "$server_pid" 2>/dev/null; then
		kill "$server_pid"
		wait "$server_pid" 2>/dev/null || :
	fi
	server_pid=

	if [ -n "$driver_pid" ] && kill -0 "$driver_pid" 2>/dev/null; then
		kill "$driver_pid"
		wait "$driver_pid" 2>/dev/null || :
	fi
	driver_pid=
}

cleanup() {
	stop_processes
	if [ -n "$work_root" ] && [ -d "$work_root" ]; then
		case $work_root in
			/tmp/nutmerlin-nut.*) rm -rf -- "$work_root" ;;
			*) diagnostic cleanup-refused "unexpected temporary path: $work_root" ;;
		esac
	fi
}

write_configuration() {
	configuration_kind=$1
	listener_address=127.0.0.1
	if [ "$configuration_kind" = unsafe-listener ]; then
		listener_address=0.0.0.0
	fi

	printf '%s\n' 'MODE=standalone' >"$work_root/etc/nut.conf"
	{
		printf 'statepath = %s\n\n' "$work_root/state"
		printf '%s\n' '[dummy]'
		printf '\tdriver = dummy-ups\n'
		printf '\tport = %s\n' "$work_root/dummy.dev"
		printf '\tmode = dummy-once\n'
	} >"$work_root/etc/ups.conf"
	{
		printf 'STATEPATH %s\n' "$work_root/state"
		printf 'LISTEN %s 3493\n' "$listener_address"
	} >"$work_root/etc/upsd.conf"
	printf '%s\n' '# No authenticated users are needed for this loopback-only probe.' \
		>"$work_root/etc/upsd.users"
	chmod 600 "$work_root/etc/nut.conf" "$work_root/etc/ups.conf" \
		"$work_root/etc/upsd.conf" "$work_root/etc/upsd.users"
}

configuration_is_safe() {
	[ "$(sed -n 's/^LISTEN \([^ ]*\) 3493$/\1/p' "$work_root/etc/upsd.conf")" = 127.0.0.1 ]
}

listener_is_clear() {
	! ss -ltn | awk 'NR > 1 { print $4 }' | grep -Eq '(^|:)3493$'
}

listener_is_loopback_only() {
	listener_addresses=$(ss -ltn | awk 'NR > 1 && $4 ~ /:3493$/ { print $4 }')
	[ "$listener_addresses" = '127.0.0.1:3493' ]
}

wait_for_file() {
	wait_path=$1
	wait_attempt=0
	while [ "$wait_attempt" -lt 10 ]; do
		[ -e "$wait_path" ] && return 0
		wait_attempt=$((wait_attempt + 1))
		sleep 1
	done
	return 1
}

query_status() {
	query_attempt=0
	while [ "$query_attempt" -lt 10 ]; do
		if "$upsc_bin" dummy@127.0.0.1 >"$work_root/upsc.out" 2>"$work_root/upsc.err"; then
			fixture_observation=$(grep -E '^(battery[.]charge|device[.]mfr|device[.]model|ups[.]status):' "$work_root/upsc.out")
			[ "$fixture_observation" = 'battery.charge: 100
device.mfr: CPS
device.model: CP1500PFCLCD
ups.status: OL' ] || return 1
			return 0
		fi
		query_attempt=$((query_attempt + 1))
		sleep 1
	done
	return 1
}

start_processes() {
	"$dummy_ups_bin" -a dummy -F -u "$run_user" \
		>"$work_root/dummy-ups.log" 2>&1 &
	driver_pid=$!
	wait_for_file "$work_root/state/dummy-ups-dummy" || {
		diagnostic driver-start-failed "dummy-ups did not create its state socket"
		return 1
	}
	kill -0 "$driver_pid" 2>/dev/null || {
		diagnostic driver-start-failed "dummy-ups exited before upsd started"
		return 1
	}

	"$upsd_bin" -F -u "$run_user" >"$work_root/upsd.log" 2>&1 &
	server_pid=$!
	query_status || {
		diagnostic server-start-failed "upsc could not read the expected dummy status"
		return 1
	}
	listener_is_loopback_only || {
		diagnostic unsafe-listener "upsd did not bind only to 127.0.0.1:3493"
		return 1
	}
}

assert_stopped() {
	[ -z "$driver_pid" ] || ! kill -0 "$driver_pid" 2>/dev/null
	[ -z "$server_pid" ] || ! kill -0 "$server_pid" 2>/dev/null
	listener_is_clear
}

case $scenario in
	smoke | invalid) ;;
	*)
		printf '%s\n' 'usage: run-dummy-nut.sh smoke|invalid' >&2
		exit 64
		;;
esac

dummy_ups_bin=$(resolve_binary dummy-ups) || fail missing-binary 'dummy-ups is required'
upsd_bin=$(resolve_binary upsd) || fail missing-binary 'upsd is required'
upsc_bin=$(resolve_binary upsc) || fail missing-binary 'upsc is required'
command -v ss >/dev/null 2>&1 || fail missing-binary 'ss is required'
run_user=$(id -un)

if [ -n "${NUTMERLIN_NUT_LIBDIRS:-}" ]; then
	LD_LIBRARY_PATH=$NUTMERLIN_NUT_LIBDIRS${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
	export LD_LIBRARY_PATH
fi

work_root=$(mktemp -d /tmp/nutmerlin-nut.XXXXXX)
trap cleanup EXIT HUP INT TERM
mkdir -m 700 "$work_root/etc" "$work_root/state"
cp "$repository_root/share/dummy/cyberpower.dev" "$work_root/dummy.dev"
chmod 600 "$work_root/dummy.dev"
NUT_CONFPATH=$work_root/etc
NUT_STATEPATH=$work_root/state
export NUT_CONFPATH NUT_STATEPATH

listener_is_clear || fail listener-in-use 'TCP port 3493 is already occupied'

if [ "$scenario" = invalid ]; then
	write_configuration unsafe-listener
	if configuration_is_safe; then
		fail validation-error 'unsafe listener configuration was accepted'
	fi
	assert_stopped || fail cleanup-error 'invalid configuration left a process or listener behind'
	diagnostic unsafe-listener 'LISTEN must be exactly 127.0.0.1 3493'
	exit 78
fi

write_configuration safe
configuration_is_safe || fail validation-error 'generated configuration is not loopback-only'

start_processes || exit 1
first_observation=$(grep -E '^(battery[.]charge|device[.]mfr|device[.]model|ups[.]status):' "$work_root/upsc.out")
stop_processes
assert_stopped || fail cleanup-error 'stop left a process or listener behind'

start_processes || exit 1
second_observation=$(grep -E '^(battery[.]charge|device[.]mfr|device[.]model|ups[.]status):' "$work_root/upsc.out")
stop_processes
assert_stopped || fail cleanup-error 'restart cleanup left a process or listener behind'

[ "$first_observation" = "$second_observation" ] || fail restart-error 'status changed after restart'
printf '%s\n' "$second_observation"
