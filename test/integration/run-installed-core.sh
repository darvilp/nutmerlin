#!/bin/sh

set -eu

repository_root=$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)
nut_root=${NUTMERLIN_NUT_ROOT:-}
test_scenario=${1:-}
installed_root=
integration_tab=$(printf '\t')

case $test_scenario in
	service | rollback | lifecycle | client | management) ;;
	*)
		printf '%s\n' 'usage: run-installed-core.sh service|rollback|lifecycle|client|management' >&2
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
	if [ -n "${client_monitor_pid:-}" ] && kill -0 "$client_monitor_pid" 2>/dev/null; then
		kill "$client_monitor_pid" 2>/dev/null || :
		wait "$client_monitor_pid" 2>/dev/null || :
	fi
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
		for cleanup_pid_file in "$installed_root"/tmp/nutmerlin/run/upsd.pid \
			"$installed_root"/tmp/nutmerlin/run/dummy-ups.pid; do
			if [ ! -f "$cleanup_pid_file" ] || [ -L "$cleanup_pid_file" ]; then
				continue
			fi
			cleanup_pid=$(cut -f1 "$cleanup_pid_file")
			case $cleanup_pid in
				'' | *[!0-9]*) continue ;;
			esac
			cleanup_executable=$(readlink "/proc/$cleanup_pid/exe" 2>/dev/null || :)
			case $cleanup_executable in
				"$installed_root"/opt*) kill "$cleanup_pid" 2>/dev/null || : ;;
			esac
		done
		case $installed_root in
			/tmp/nutmerlin-installed.*) rm -rf -- "$installed_root" ;;
		esac
	fi
}

dummy_ups_source=$(resolve_test_binary dummy-ups) || exit 69
upsd_source=$(resolve_test_binary upsd) || exit 69
upsc_source=$(resolve_test_binary upsc) || exit 69
usbhid_ups_source=$(resolve_test_binary usbhid-ups) || exit 69
upsmon_source=$(resolve_test_binary upsmon) || exit 69

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

invoke_cli() {
	env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$installed_root" \
		NUTMERLIN_TEST_RUN_USER="$NUTMERLIN_TEST_RUN_USER" \
		"$installed_cli" "$@"
}

invoke_hook() {
	env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$installed_root" \
		NUTMERLIN_TEST_RUN_USER="$NUTMERLIN_TEST_RUN_USER" \
		"$installed_root/jffs/scripts/$1"
}

write_upsmon_configuration() {
	client_configuration_root=$1
	client_username=$2
	client_password=$3
	mkdir -p "$client_configuration_root"
	chmod 700 "${client_configuration_root%/*}" "$client_configuration_root"
	{
		printf 'MONITOR dummy@127.0.0.1 1 %s %s secondary\n' \
			"$client_username" "$client_password"
		printf '%s\n' \
			'MINSUPPLIES 1' \
			'SHUTDOWNCMD "/bin/false"' \
			"POWERDOWNFLAG $client_configuration_root/powerdown" \
			'POLLFREQ 1' \
			'POLLFREQALERT 1' \
			'HOSTSYNC 15' \
			'DEADTIME 15' \
			'FINALDELAY 5'
	} >"$client_configuration_root/upsmon.conf"
	chmod 600 "$client_configuration_root/upsmon.conf"
}

run_upsmon_until() {
	client_configuration_root=$1
	client_log=$2
	client_expected_pattern=$3
	NUT_CONFPATH=$client_configuration_root
	export NUT_CONFPATH
	"$upsmon_source" -D -F -p >"$client_log" 2>&1 &
	client_monitor_pid=$!
	client_wait=0
	while [ "$client_wait" -lt 10 ]; do
		if grep -F "$client_expected_pattern" "$client_log" >/dev/null 2>&1; then
			kill "$client_monitor_pid" 2>/dev/null || :
			wait "$client_monitor_pid" 2>/dev/null || :
			client_monitor_pid=
			return 0
		fi
		kill -0 "$client_monitor_pid" 2>/dev/null || break
		client_wait=$((client_wait + 1))
		sleep 1
	done
	kill "$client_monitor_pid" 2>/dev/null || :
	wait "$client_monitor_pid" 2>/dev/null || :
	client_monitor_pid=
	return 1
}

if [ "$test_scenario" = lifecycle ]; then
	invoke_hook services-start
else
	invoke_cli service start >"$installed_root/start.log"
fi

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

if [ "$test_scenario" = management ]; then
	cp "$installed_root/opt/lib/opkg/status" "$installed_root/opkg-status.before"
	invoke_cli disable >"$installed_root/disable.log"
	[ "$(cat "$installed_root/jffs/addons/nutmerlin/enabled")" = 0 ]
	[ ! -e "$installed_root/platform/cru.tsv" ]
	[ ! -e "$installed_root/tmp/nutmerlin/run/upsd.pid" ]
	[ ! -e "$installed_root/tmp/nutmerlin/run/dummy-ups.pid" ]
	if ss -ltn | awk 'NR > 1 { print $4 }' | grep -Eq '(^|:)3493$'; then
		exit 1
	fi
	invoke_cli enable >"$installed_root/enable.log"
	"$installed_root/opt/bin/upsc" dummy@127.0.0.1 ups.status 2>/dev/null | grep -qx OL
	management_config_root=$installed_root/opt/etc/nutmerlin/config
	management_set_id=$(cat "$management_config_root/current")
	rm "$management_config_root/current"
	rm "$installed_root/platform/cru.tsv"
	chmod 600 "$installed_root/jffs/addons/nutmerlin/lib/status.sh"
	: >"$installed_root/jffs/scripts/post-mount"
	chmod 755 "$installed_root/jffs/scripts/post-mount"
	invoke_cli repair >"$installed_root/repair.log"
	[ "$(cat "$management_config_root/current")" = "$management_set_id" ]
	[ -f "$installed_root/platform/cru.tsv" ]
	[ "$(stat -c '%a' "$installed_root/jffs/addons/nutmerlin/lib/status.sh")" = 644 ]
	"$installed_root/opt/bin/upsc" dummy@127.0.0.1 ups.status 2>/dev/null | grep -qx OL
	make --no-print-directory -C "$repository_root" package >/dev/null
	invoke_cli update "$repository_root/dist/nutmerlin-core-dev.tar.gz" \
		>"$installed_root/update.log"
	grep -Fx 'update: ok: NUTMerlin updated to 0.1.0-dev; dummy is running on loopback' \
		"$installed_root/update.log" >/dev/null
	"$installed_root/opt/bin/upsc" dummy@127.0.0.1 ups.status 2>/dev/null | grep -qx OL
	invoke_cli uninstall >"$installed_root/uninstall.log"
	[ ! -e "$installed_root/jffs/addons/nutmerlin" ]
	[ ! -e "$installed_root/opt/etc/nutmerlin" ]
	[ ! -e "$installed_root/tmp/nutmerlin" ]
	cmp "$installed_root/opkg-status.before" "$installed_root/opt/lib/opkg/status"
	if ss -ltn | awk 'NR > 1 { print $4 }' | grep -Eq '(^|:)3493$'; then
		exit 1
	fi
	printf '%s\n' 'management lifecycle: disable=closed enable=running repair=running update=running uninstall=owned-only'
	exit 0
fi

if [ "$test_scenario" = lifecycle ]; then
	cru_state=$installed_root/platform/cru.tsv
	[ "$(wc -l <"$cru_state")" -eq 1 ]
	grep -F "NUTMerlin${integration_tab}*/5 * * * *${integration_tab}" "$cru_state" >/dev/null
	initial_server_pid=$(cut -f1 "$installed_root/tmp/nutmerlin/run/upsd.pid")
	initial_driver_pid=$(cut -f1 "$installed_root/tmp/nutmerlin/run/dummy-ups.pid")
	invoke_hook services-start
	[ "$(wc -l <"$cru_state")" -eq 1 ]
	[ "$(cut -f1 "$installed_root/tmp/nutmerlin/run/upsd.pid")" = "$initial_server_pid" ]
	[ "$(cut -f1 "$installed_root/tmp/nutmerlin/run/dummy-ups.pid")" = "$initial_driver_pid" ]
	find "$installed_root/jffs" "$installed_root/opt" -type f -exec sha256sum {} \; | sort >"$installed_root/persistent-before-status.sha256"
	invoke_cli status --json >"$installed_root/healthy-status.json"
	find "$installed_root/jffs" "$installed_root/opt" -type f -exec sha256sum {} \; | sort >"$installed_root/persistent-after-status.sha256"
	cmp "$installed_root/persistent-before-status.sha256" "$installed_root/persistent-after-status.sha256"
	[ "$(jq -r '.status' "$installed_root/healthy-status.json")" = ok ]
	set +e
	env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$installed_root" \
		NUTMERLIN_TEST_RUN_USER="$NUTMERLIN_TEST_RUN_USER" \
		NUTMERLIN_TEST_STORAGE_STATE=missing \
		"$installed_cli" status --json >"$installed_root/live-storage-loss-status.json"
	live_storage_loss_status=$?
	set -e
	[ "$live_storage_loss_status" -eq 69 ]
	[ "$(jq -r '.details.storage' "$installed_root/live-storage-loss-status.json")" = missing ]
	[ "$(jq -r '.details.driver' "$installed_root/live-storage-loss-status.json")" = running ]
	[ "$(jq -r '.details.upsd' "$installed_root/live-storage-loss-status.json")" = running ]

	mkdir "$installed_root/tmp/nutmerlin/lock/lifecycle"
	set +e
	invoke_cli hook reconcile >"$installed_root/concurrent-reconcile.log" 2>&1
	concurrent_reconcile_status=$?
	set -e
	[ "$concurrent_reconcile_status" -eq 75 ]
	rmdir "$installed_root/tmp/nutmerlin/lock/lifecycle"

	kill "$initial_server_pid"
	dead_wait=0
	while kill -0 "$initial_server_pid" 2>/dev/null && [ "$dead_wait" -lt 5 ]; do
		dead_wait=$((dead_wait + 1))
		sleep 1
	done
	if kill -0 "$initial_server_pid" 2>/dev/null; then
		exit 1
	fi
	invoke_cli hook reconcile >/dev/null
	recovered_server_pid=$(cut -f1 "$installed_root/tmp/nutmerlin/run/upsd.pid")
	[ "$recovered_server_pid" != "$initial_server_pid" ]
	"$installed_root/opt/bin/upsc" dummy@127.0.0.1 ups.status 2>/dev/null | grep -qx OL

	invoke_hook services-stop
	[ ! -e "$cru_state" ]
	mv "$installed_root/opt" "$installed_root/opt.delayed"
	invoke_hook services-start
	[ -f "$cru_state" ]
	set +e
	invoke_cli status --json >"$installed_root/missing-status.json"
	missing_status=$?
	set -e
	[ "$missing_status" -eq 69 ]
	[ "$(jq -r '.details.storage' "$installed_root/missing-status.json")" = missing ]
	mv "$installed_root/opt.delayed" "$installed_root/opt"
	invoke_hook post-mount
	"$installed_root/opt/bin/upsc" dummy@127.0.0.1 ups.status 2>/dev/null | grep -qx OL

	chmod 500 "$installed_root/opt"
	invoke_hook firewall-start
	set +e
	invoke_cli status --json >"$installed_root/read-only-status.json"
	read_only_status=$?
	set -e
	[ "$read_only_status" -eq 69 ]
	[ "$(jq -r '.details.storage' "$installed_root/read-only-status.json")" = read_only ]
	chmod 700 "$installed_root/opt"
	invoke_hook post-mount

	config_installation_path=$installed_root/opt/etc/nutmerlin/installation.id
	original_config_installation_id=$(cat "$config_installation_path")
	printf '%s\n' '00000000000000000000000000000000' >"$config_installation_path"
	invoke_cli hook reconcile >/dev/null || :
	set +e
	invoke_cli status --json >"$installed_root/replaced-status.json"
	replaced_status=$?
	set -e
	[ "$replaced_status" -eq 69 ]
	[ "$(jq -r '.details.storage' "$installed_root/replaced-status.json")" = replaced ]
	printf '%s\n' "$original_config_installation_id" >"$config_installation_path"
	chmod 600 "$config_installation_path"
	invoke_hook post-mount
	active_set_root=$installed_root/opt/etc/nutmerlin/config/sets/$(cat "$installed_root/opt/etc/nutmerlin/config/current")
	chmod 644 "$active_set_root/model.tsv"
	invoke_cli hook reconcile >/dev/null 2>&1 || :
	set +e
	invoke_cli status --json >"$installed_root/ownership-status.json"
	ownership_status=$?
	set -e
	[ "$ownership_status" -eq 69 ]
	[ "$(jq -r '.details.storage' "$installed_root/ownership-status.json")" = ownership_mismatch ]
	chmod 600 "$active_set_root/model.tsv"
	invoke_hook post-mount

	invoke_hook services-stop
	failure_attempt=1
	while [ "$failure_attempt" -le 3 ]; do
		env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
			NUTMERLIN_TEST_ROOT="$installed_root" \
			NUTMERLIN_TEST_RUN_USER="$NUTMERLIN_TEST_RUN_USER" \
			NUTMERLIN_TEST_ACTIVATION_FAIL=1 \
			"$installed_root/jffs/scripts/services-start"
		failure_attempt=$((failure_attempt + 1))
	done
	recovery_path=$installed_root/tmp/nutmerlin/run/recovery.tsv
	grep -F "failures${integration_tab}3" "$recovery_path" >/dev/null
	grep -F "pause${integration_tab}3" "$recovery_path" >/dev/null
	pause_check=1
	while [ "$pause_check" -le 3 ]; do
		invoke_cli hook reconcile >/dev/null 2>&1 || :
		[ ! -e "$installed_root/tmp/nutmerlin/run/upsd.pid" ]
		pause_check=$((pause_check + 1))
	done
	grep -F "pause${integration_tab}0" "$recovery_path" >/dev/null
	invoke_cli hook reconcile >/dev/null
	[ ! -e "$recovery_path" ]
	"$installed_root/opt/bin/upsc" dummy@127.0.0.1 ups.status 2>/dev/null | grep -qx OL

	invoke_hook services-stop
	rm -rf -- "$installed_root/tmp/nutmerlin"
	invoke_hook services-start
	"$installed_root/opt/bin/upsc" dummy@127.0.0.1 ups.status 2>/dev/null | grep -qx OL
	pre_unrelated_unmount_pid=$(cut -f1 "$installed_root/tmp/nutmerlin/run/upsd.pid")
	env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$installed_root" \
		NUTMERLIN_TEST_RUN_USER="$NUTMERLIN_TEST_RUN_USER" \
		"$installed_root/jffs/scripts/unmount" /tmp/unrelated-mount
	[ "$(cut -f1 "$installed_root/tmp/nutmerlin/run/upsd.pid")" = "$pre_unrelated_unmount_pid" ]
	invoke_hook unmount
	[ -f "$cru_state" ]
	invoke_hook firewall-start
fi

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

if [ "$test_scenario" = client ]; then
	client_result=$installed_root/client-add.json
	invoke_cli client add integration-secondary --json >"$client_result"
	client_id=$(jq -r '.details.client_id' "$client_result")
	client_username=$(jq -r '.details.username' "$client_result")
	client_secret=$(jq -r '.details.secret' "$client_result")
	for client_service_record in dummy-ups.pid upsd.pid; do
		client_service_pid=$(cut -f1 "$installed_root/tmp/nutmerlin/run/$client_service_record")
		if tr '\000' '\n' <"/proc/$client_service_pid/environ" | grep -F "$client_secret" >/dev/null; then
			exit 1
		fi
	done
	client_root=$installed_root/secondary-client
	write_upsmon_configuration "$client_root/correct" "$client_username" "$client_secret"
	run_upsmon_until "$client_root/correct" "$client_root/correct.log" \
		"Logged into UPS dummy@127.0.0.1" || exit 1

	wrong_secret=000000000000000000000000000000000000000000000000
	[ "$wrong_secret" != "$client_secret" ]
	write_upsmon_configuration "$client_root/wrong" "$client_username" "$wrong_secret"
	run_upsmon_until "$client_root/wrong" "$client_root/wrong.log" \
		"Login on UPS [dummy@127.0.0.1] failed - got [ERR ACCESS-DENIED]" || exit 1

	invoke_cli client revoke "$client_id" >"$installed_root/client-revoke.log"
	run_upsmon_until "$client_root/correct" "$client_root/revoked.log" \
		"Login on UPS [dummy@127.0.0.1] failed - got [ERR ACCESS-DENIED]" || exit 1
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
elif [ "$test_scenario" = lifecycle ]; then
	printf '%s\n' 'Merlin lifecycle: hooks=5 recovery=bounded status=healthy'
elif [ "$test_scenario" = client ]; then
	printf '%s\n' 'standard secondary authentication: correct=accepted wrong=rejected revoked=rejected'
else
	printf '%s\n' 'installed dummy status: OL'
fi
