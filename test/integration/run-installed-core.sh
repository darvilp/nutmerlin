#!/bin/sh

set -eu

repository_root=$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)
nut_root=${NUTMERLIN_NUT_ROOT:-}
test_scenario=${1:-}
installed_root=

case $test_scenario in
	service | rollback) ;;
	*)
		printf '%s\n' 'usage: run-installed-core.sh service|rollback' >&2
		exit 64
		;;
esac

resolve_test_binary() {
	test_binary_name=$1
	if [ -n "$nut_root" ]; then
		for test_binary_candidate in \
			"$nut_root/lib/nut/$test_binary_name" \
			"$nut_root/usr/lib/nut/$test_binary_name" \
			"$nut_root/sbin/$test_binary_name" \
			"$nut_root/usr/sbin/$test_binary_name" \
			"$nut_root/bin/$test_binary_name" \
			"$nut_root/usr/bin/$test_binary_name"; do
			[ ! -x "$test_binary_candidate" ] || {
				printf '%s\n' "$test_binary_candidate"
				return 0
			}
		done
		return 1
	fi
	for test_binary_candidate in \
		"/lib/nut/$test_binary_name" \
		"/usr/lib/nut/$test_binary_name" \
		"/usr/sbin/$test_binary_name" \
		"/usr/bin/$test_binary_name"; do
		[ ! -x "$test_binary_candidate" ] || {
			printf '%s\n' "$test_binary_candidate"
			return 0
		}
	done
	return 1
}

cleanup_installed_root() {
	if [ -n "$installed_root" ] && [ -d "$installed_root" ]; then
		if [ "${NUTMERLIN_TEST_DEBUG:-0}" = 1 ]; then
			for debug_log in "$installed_root"/tmp/nutmerlin/log/* "$installed_root"/tmp/nutmerlin/run/*.err; do
				[ ! -f "$debug_log" ] || {
					printf '%s\n' "--- $debug_log" >&2
					sed -n '1,160p' "$debug_log" >&2
				}
			done
		fi
		installed_cli=$installed_root/jffs/addons/nutmerlin/bin/nutmerlin
		if [ -x "$installed_cli" ]; then
			env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
				NUTMERLIN_TEST_ROOT="$installed_root" \
				NUTMERLIN_TEST_RUN_USER="$(id -un)" \
				"$installed_cli" service stop >/dev/null 2>&1 || :
		fi
		case $installed_root in
			/tmp/nutmerlin-installed.*) rm -rf -- "$installed_root" ;;
		esac
	fi
}

dummy_ups_source=$(resolve_test_binary dummy-ups) || exit 69
upsd_source=$(resolve_test_binary upsd) || exit 69
upsc_source=$(resolve_test_binary upsc) || exit 69
usbhid_ups_source=$(resolve_test_binary usbhid-ups) || exit 69

if [ -n "${NUTMERLIN_NUT_LIBDIRS:-}" ]; then
	LD_LIBRARY_PATH=$NUTMERLIN_NUT_LIBDIRS${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}
	export LD_LIBRARY_PATH
fi

installed_root=$(mktemp -d /tmp/nutmerlin-installed.XXXXXX)
trap cleanup_installed_root EXIT HUP INT TERM
printf '%s\n' 'nutmerlin-test-root-v1' >"$installed_root/.nutmerlin-test-root"
chmod 600 "$installed_root/.nutmerlin-test-root"
mkdir -p \
	"$installed_root/jffs" \
	"$installed_root/opt/bin" \
	"$installed_root/opt/lib/nut" \
	"$installed_root/opt/lib/opkg" \
	"$installed_root/tmp"
cp "$dummy_ups_source" "$installed_root/opt/lib/nut/dummy-ups"
cp "$upsd_source" "$installed_root/opt/lib/nut/upsd"
cp "$usbhid_ups_source" "$installed_root/opt/lib/nut/usbhid-ups"
cp "$upsc_source" "$installed_root/opt/bin/upsc"
printf '%s\n' '#!/bin/sh' 'exit 99' >"$installed_root/opt/bin/opkg"
chmod 700 "$installed_root/opt/bin/opkg" "$installed_root/opt/bin/upsc" \
	"$installed_root/opt/lib/nut/dummy-ups" "$installed_root/opt/lib/nut/upsd" \
	"$installed_root/opt/lib/nut/usbhid-ups"

: >"$installed_root/opt/lib/opkg/status"
for package_name in nut nut-common nut-server nut-upsc nut-driver-dummy-ups nut-driver-usbhid-ups; do
	{
		printf 'Package: %s\n' "$package_name"
		printf '%s\n' 'Version: 2.8.1-test' 'Architecture: host-test' 'Status: install user installed' ''
	} >>"$installed_root/opt/lib/opkg/status"
done

NUTMERLIN_TEST_RUN_USER=$(id -un)
export NUTMERLIN_TEST_RUN_USER
make --no-print-directory -C "$repository_root" install DESTDIR="$installed_root" \
	>"$installed_root/install.log"
installed_cli=$installed_root/jffs/addons/nutmerlin/bin/nutmerlin
env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
	NUTMERLIN_TEST_ROOT="$installed_root" \
	NUTMERLIN_TEST_RUN_USER="$NUTMERLIN_TEST_RUN_USER" \
	"$installed_cli" service start >"$installed_root/start.log"

active_set_id=$(cat "$installed_root/opt/etc/nutmerlin/config/current")
active_config=$installed_root/opt/etc/nutmerlin/config/sets/$active_set_id
for service_pid_file in dummy-ups.pid upsd.pid; do
	service_pid=$(cut -f1 "$installed_root/tmp/nutmerlin/run/$service_pid_file")
	tr '\000' '\n' <"/proc/$service_pid/environ" | grep -Fx "NUT_CONFPATH=$active_config" >/dev/null
done

upsc_observation=$("$installed_root/opt/bin/upsc" dummy@127.0.0.1 2>"$installed_root/upsc.err")
printf '%s\n' "$upsc_observation" | grep -q '^ups.status: OL$'

repeat_install_output=$(make --no-print-directory -C "$repository_root" install DESTDIR="$installed_root")
[ "$repeat_install_output" = 'NUTMerlin already installed: owned state is complete' ]

if [ "$test_scenario" = rollback ]; then
	config_root=$installed_root/opt/etc/nutmerlin/config
	initial_set_id=$(cat "$config_root/current")
	server_pid_file=$installed_root/tmp/nutmerlin/run/upsd.pid
	driver_pid_file=$installed_root/tmp/nutmerlin/run/dummy-ups.pid
	original_server_record=$(cat "$server_pid_file")
	server_pid=$(printf '%s\n' "$original_server_record" | cut -f1)
	driver_pid=$(cut -f1 "$driver_pid_file")
	printf '%s\n' "$original_server_record" | awk -F '\t' -v OFS='\t' '{$5 = "00000000000000000000000000000000"; print}' >"$server_pid_file"
	chmod 600 "$server_pid_file"
	set +e
	env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$installed_root" \
		NUTMERLIN_TEST_RUN_USER="$NUTMERLIN_TEST_RUN_USER" \
		"$installed_cli" service stop >"$installed_root/foreign-stop.log" 2>&1
	foreign_stop_status=$?
	set -e
	[ "$foreign_stop_status" -eq 78 ]
	kill -0 "$server_pid"
	kill -0 "$driver_pid"
	printf '%s\n' "$original_server_record" >"$server_pid_file"
	chmod 600 "$server_pid_file"
	mkdir "$installed_root/tmp/nutmerlin/lock/lifecycle"
	set +e
	env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$installed_root" \
		NUTMERLIN_TEST_RUN_USER="$NUTMERLIN_TEST_RUN_USER" \
		"$installed_cli" source use-dummy >"$installed_root/concurrent-activation.log" 2>&1
	concurrent_status=$?
	set -e
	[ "$concurrent_status" -eq 75 ]
	[ "$(cat "$config_root/current")" = "$initial_set_id" ]
	rmdir "$installed_root/tmp/nutmerlin/lock/lifecycle"
	set +e
	env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$installed_root" \
		NUTMERLIN_TEST_RUN_USER="$NUTMERLIN_TEST_RUN_USER" \
		NUTMERLIN_TEST_ACTIVATION_FAIL=1 \
		"$installed_cli" source use-dummy >"$installed_root/failed-activation.log" 2>&1
	activation_status=$?
	set -e
	[ "$activation_status" -eq 75 ]
	[ "$(cat "$config_root/current")" = "$initial_set_id" ]
	[ ! -e "$config_root/last-good" ]
	[ "$(find "$config_root/sets" -mindepth 1 -maxdepth 1 -type d | wc -l)" -eq 1 ]
	"$installed_root/opt/bin/upsc" dummy@127.0.0.1 ups.status 2>/dev/null | grep -qx OL

	env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$installed_root" \
		NUTMERLIN_TEST_RUN_USER="$NUTMERLIN_TEST_RUN_USER" \
		"$installed_cli" source use-dummy >"$installed_root/successful-activation.log"
	new_set_id=$(cat "$config_root/current")
	[ "$new_set_id" != "$initial_set_id" ]
	[ "$(cat "$config_root/last-good")" = "$initial_set_id" ]
	[ "$(find "$config_root/sets" -mindepth 1 -maxdepth 1 -type d | wc -l)" -eq 2 ]
	"$installed_root/opt/bin/upsc" dummy@127.0.0.1 ups.status 2>/dev/null | grep -qx OL
fi

chmod 500 "$installed_root/opt"
env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
	NUTMERLIN_TEST_ROOT="$installed_root" \
	NUTMERLIN_TEST_RUN_USER="$NUTMERLIN_TEST_RUN_USER" \
	"$installed_cli" service stop >"$installed_root/stop.log"
chmod 700 "$installed_root/opt"
if ss -ltn | awk 'NR > 1 { print $4 }' | grep -Eq '(^|:)3493$'; then
	exit 1
fi

if [ "$test_scenario" = rollback ]; then
	printf '%s\n' 'activation rollback: preserved; retained sets: 2'
else
	printf '%s\n' 'installed dummy status: OL'
fi
