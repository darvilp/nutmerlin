#!/usr/bin/env bats

setup() {
	REPOSITORY_ROOT=$(cd "$BATS_TEST_DIRNAME/../.." && pwd)
	# shellcheck source=test/lib/host-harness.sh
	. "$REPOSITORY_ROOT/test/lib/host-harness.sh"
	host_harness_setup
	# shellcheck source=test/lib/entware-fixture.sh
	. "$REPOSITORY_ROOT/test/lib/entware-fixture.sh"
	entware_fixture_setup
	make --no-print-directory -C "$REPOSITORY_ROOT" install DESTDIR="$NUTMERLIN_TEST_ROOT" >/dev/null
	installed_cli=$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/bin/nutmerlin
}

teardown() {
	host_harness_teardown
}

configure_real_source() {
	printf '%s\n' 0 >"$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/enabled"
	mkdir -m 700 "$NUTMERLIN_TEST_ROOT/platform"
	printf 'usb-a\t0764\t0501\tCPS123456\t003\t001\t009\n' \
		>"$NUTMERLIN_TEST_ROOT/platform/usb-devices.tsv"
	chmod 600 "$NUTMERLIN_TEST_ROOT/platform/usb-devices.tsv"
	env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		"$installed_cli" source configure-usbhid \
		--vendor-id 0764 --product-id 0501 --serial CPS123456 >/dev/null
}

write_network_fixture() {
	fixture_lan_address=${1:-192.168.50.1}
	fixture_lan_netmask=${2:-255.255.255.0}
	fixture_wan_address=${3:-203.0.113.2}
	{
		printf 'schema\tnutmerlin.network.v1\n'
		printf 'lan_address\t%s\n' "$fixture_lan_address"
		printf 'lan_netmask\t%s\n' "$fixture_lan_netmask"
		printf 'wan_address\t%s\n' "$fixture_wan_address"
	} >"$NUTMERLIN_TEST_ROOT/platform/network.tsv"
	chmod 600 "$NUTMERLIN_TEST_ROOT/platform/network.tsv"
}

invoke_firewall() {
	firewall_action=$1
	shift
	env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		/bin/sh -c '
			for module in paths configuration ownership platform; do
				. "$1/$module.sh"
			done
			shift
			paths_initialize
			"$@"
		' sh "$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/lib" "$firewall_action" "$@"
}

@test "lan configure refuses the loopback-only dummy source" {
	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		"$installed_cli" lan configure --address 192.168.50.1 --cidr 192.168.50.0/24

	[ "$status" -eq 69 ]
	[ "$output" = 'LAN exposure unavailable: active source is dummy' ]
}

@test "lan configure atomically renders loopback and one trusted LAN listener" {
	configure_real_source
	write_network_fixture
	config_root=$NUTMERLIN_OPT_ROOT/etc/nutmerlin/config
	previous_set_id=$(cat "$config_root/current")

	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		"$installed_cli" lan configure \
		--address 192.168.50.1 --cidr 192.168.50.0/24

	[ "$status" -eq 0 ]
	[ "$output" = 'lan: ok: trusted LAN configured while service is disabled; address=192.168.50.1 cidr=192.168.50.0/24' ]
	current_set_id=$(cat "$config_root/current")
	[ "$current_set_id" != "$previous_set_id" ]
	[ -d "$config_root/sets/$previous_set_id" ]
	[ "$(cat "$config_root/last-good")" = "$previous_set_id" ]
	set_root=$config_root/sets/$current_set_id
	grep -Fx $'lan_address\t192.168.50.1' "$set_root/model.tsv"
	grep -Fx $'lan_cidr\t192.168.50.0/24' "$set_root/model.tsv"
	[ "$(cat "$set_root/upsd.conf")" = $'STATEPATH '"$NUTMERLIN_TMP_ROOT"$'/nutmerlin/state\nLISTEN 127.0.0.1 3493\nLISTEN 192.168.50.1 3493' ]
	(cd "$set_root" && sha256sum -c SHA256SUMS)
	[ ! -e "$NUTMERLIN_TEST_ROOT/platform/firewall.tsv" ]
}

@test "lan configure rejects unsafe addresses and scopes without changing current" {
	configure_real_source
	write_network_fixture
	config_root=$NUTMERLIN_OPT_ROOT/etc/nutmerlin/config
	current_before=$(cat "$config_root/current")
	injection_marker=$NUTMERLIN_TEST_ROOT/not-created

	while IFS='|' read -r unsafe_address unsafe_cidr; do
		run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
			NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
			NUTMERLIN_TEST_RUN_USER="$(id -un)" \
			"$installed_cli" lan configure \
			--address "$unsafe_address" --cidr "$unsafe_cidr"
		[ "$status" -eq 78 ]
		[ "$(cat "$config_root/current")" = "$current_before" ]
	done <<EOF
0.0.0.0|192.168.50.0/24
127.0.0.1|192.168.50.0/24
224.0.0.1|192.168.50.0/24
255.255.255.255|192.168.50.0/24
192.168.050.1|192.168.50.0/24
::|192.168.50.0/24
192.168.50.1;touch $injection_marker|192.168.50.0/24
192.168.50.1|0.0.0.0/0
192.168.50.1|0.0.0.0/32
192.168.50.1|127.0.0.0/8
192.168.50.1|224.0.0.0/4
192.168.50.1|192.168.50.255/32
192.168.50.1|192.168.50.1/24
192.168.50.1|192.168.50.0/08
192.168.50.1|::/0
EOF
	[ ! -e "$injection_marker" ]
	[ ! -e "$NUTMERLIN_TEST_ROOT/platform/firewall.tsv" ]
}

@test "lan configure rejects a WAN-equal or broadcast router address" {
	configure_real_source
	config_root=$NUTMERLIN_OPT_ROOT/etc/nutmerlin/config
	current_before=$(cat "$config_root/current")

	write_network_fixture 192.168.50.1 255.255.255.0 192.168.50.1
	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		"$installed_cli" lan configure \
		--address 192.168.50.1 --cidr 192.168.50.0/24
	[ "$status" -eq 78 ]
	[ "$output" = 'LAN exposure refused: address equals a router WAN IPv4 address' ]

	write_network_fixture 192.168.50.255 255.255.255.0 203.0.113.2
	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		"$installed_cli" lan configure \
		--address 192.168.50.255 --cidr 192.168.50.0/24
	[ "$status" -eq 78 ]
	[ "$output" = 'LAN exposure refused: router LAN address is a network or broadcast address' ]
	[ "$(cat "$config_root/current")" = "$current_before" ]
}

@test "lan disable replaces an external configuration with loopback-only state" {
	configure_real_source
	write_network_fixture
	env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		"$installed_cli" lan configure \
		--address 192.168.50.1 --cidr 192.168.50.0/24 >/dev/null
	config_root=$NUTMERLIN_OPT_ROOT/etc/nutmerlin/config
	exposed_set_id=$(cat "$config_root/current")

	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		"$installed_cli" lan disable

	[ "$status" -eq 0 ]
	[ "$output" = 'lan: ok: trusted LAN disabled while service is disabled' ]
	loopback_set_id=$(cat "$config_root/current")
	[ "$loopback_set_id" != "$exposed_set_id" ]
	[ ! -e "$config_root/sets/$exposed_set_id" ]
	[ ! -e "$config_root/last-good" ]
	set_root=$config_root/sets/$loopback_set_id
	[ "$(wc -l <"$set_root/model.tsv")" -eq 7 ]
	[ "$(cat "$set_root/upsd.conf")" = $'STATEPATH '"$NUTMERLIN_TMP_ROOT"$'/nutmerlin/state\nLISTEN 127.0.0.1 3493' ]
}

@test "failed initial LAN activation restores the prior loopback set and closes admission" {
	configure_real_source
	write_network_fixture
	config_root=$NUTMERLIN_OPT_ROOT/etc/nutmerlin/config
	loopback_set_id=$(cat "$config_root/current")
	printf '%s\n' 1 >"$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/enabled"

	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		"$installed_cli" lan configure \
		--address 192.168.50.1 --cidr 192.168.50.0/24

	[ "$status" -eq 75 ]
	[[ "$output" == *'configuration activation failed: previous set restored once'* ]]
	[ "$(cat "$config_root/current")" = "$loopback_set_id" ]
	[ ! -e "$NUTMERLIN_TEST_ROOT/platform/firewall.tsv" ]
	[ ! -e "$NUTMERLIN_TMP_ROOT/nutmerlin/run/upsd.pid" ]
}

@test "failed LAN disable keeps the replacement loopback set and never restores exposure" {
	configure_real_source
	write_network_fixture
	env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		"$installed_cli" lan configure \
		--address 192.168.50.1 --cidr 192.168.50.0/24 >/dev/null
	config_root=$NUTMERLIN_OPT_ROOT/etc/nutmerlin/config
	exposed_set_id=$(cat "$config_root/current")
	printf '%s\n' 1 >"$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/enabled"

	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		"$installed_cli" lan disable

	[ "$status" -eq 75 ]
	[[ "$output" == *'configuration activation failed: safer LAN selection remains active and stopped'* ]]
	loopback_set_id=$(cat "$config_root/current")
	[ "$loopback_set_id" != "$exposed_set_id" ]
	[ ! -e "$config_root/sets/$exposed_set_id" ]
	[ "$(wc -l <"$config_root/sets/$loopback_set_id/model.tsv")" -eq 7 ]
	[ ! -e "$NUTMERLIN_TEST_ROOT/platform/firewall.tsv" ]
	[ ! -e "$NUTMERLIN_TMP_ROOT/nutmerlin/run/upsd.pid" ]
}

@test "service restart revalidates source and router network before opening admission" {
	configure_real_source
	write_network_fixture
	env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		"$installed_cli" lan configure \
		--address 192.168.50.1 --cidr 192.168.50.0/24 >/dev/null

	write_network_fixture 192.168.50.1 255.255.255.0 192.168.50.1
	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		"$installed_cli" service start
	[ "$status" -eq 78 ]
	[ "$output" = 'LAN exposure refused: address equals a router WAN IPv4 address' ]
	[ ! -e "$NUTMERLIN_TEST_ROOT/platform/firewall.tsv" ]
	[ ! -e "$NUTMERLIN_TMP_ROOT/nutmerlin/run/upsd.pid" ]

	write_network_fixture
	: >"$NUTMERLIN_TEST_ROOT/platform/usb-devices.tsv"
	chmod 600 "$NUTMERLIN_TEST_ROOT/platform/usb-devices.tsv"
	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		"$installed_cli" service start
	[ "$status" -eq 69 ]
	[ "$output" = 'source unavailable: no USB device matches the configured vendor/product' ]
	[ ! -e "$NUTMERLIN_TEST_ROOT/platform/firewall.tsv" ]
	[ ! -e "$NUTMERLIN_TMP_ROOT/nutmerlin/run/upsd.pid" ]
}

@test "trusted-LAN firewall adapter is exact idempotent and conservative" {
	configure_real_source
	write_network_fixture
	env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		"$installed_cli" lan configure \
		--address 192.168.50.1 --cidr 192.168.50.0/24 >/dev/null
	printf '%s\n' 'foreign firewall state' >"$NUTMERLIN_TEST_ROOT/platform/unrelated-firewall.txt"
	unrelated_before=$(sha256sum "$NUTMERLIN_TEST_ROOT/platform/unrelated-firewall.txt")

	run invoke_firewall platform_firewall_ensure 192.168.50.1 192.168.50.0/24
	[ "$status" -eq 0 ]
	firewall_path=$NUTMERLIN_TEST_ROOT/platform/firewall.tsv
	[ "$(stat -c '%a' "$firewall_path")" = 600 ]
	installation_id=$(cat "$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/installation.id")
	[ "$(cat "$firewall_path")" = $'schema\tnutmerlin.firewall.v1\ninstallation_id\t'"$installation_id"$'\nchain\tNUTMERLIN\njump\tINPUT\t1\ttcp\t192.168.50.1\t3493\tNUTMERLIN\tnutmerlin:'"$installation_id"$'\nallow\t192.168.50.0/24\t192.168.50.1\ttcp\t3493\tnutmerlin:'"$installation_id"$'\ndeny\t0.0.0.0/0\t192.168.50.1\ttcp\t3493\tnutmerlin:'"$installation_id" ]
	firewall_before=$(sha256sum "$firewall_path")

	run invoke_firewall platform_firewall_ensure 192.168.50.1 192.168.50.0/24
	[ "$status" -eq 0 ]
	[ "$(sha256sum "$firewall_path")" = "$firewall_before" ]
	[ "$(sha256sum "$NUTMERLIN_TEST_ROOT/platform/unrelated-firewall.txt")" = "$unrelated_before" ]
	[ ! -s "$NUTMERLIN_EXTERNAL_CALL_LOG" ]

	run invoke_firewall platform_firewall_close 192.168.50.1 192.168.50.0/24
	[ "$status" -eq 0 ]
	[ ! -e "$firewall_path" ]
	[ "$(sha256sum "$NUTMERLIN_TEST_ROOT/platform/unrelated-firewall.txt")" = "$unrelated_before" ]
}

@test "stale or broad firewall state refuses mutation and remains attributable" {
	configure_real_source
	write_network_fixture
	firewall_path=$NUTMERLIN_TEST_ROOT/platform/firewall.tsv
	installation_id=$(cat "$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/installation.id")
	{
		printf 'schema\tnutmerlin.firewall.v1\n'
		printf 'installation_id\t%s\n' "$installation_id"
		printf 'chain\tNUTMERLIN\n'
		printf 'allow\t0.0.0.0/0\t192.168.50.1\ttcp\t3493\tnutmerlin:%s\n' "$installation_id"
	} >"$firewall_path"
	chmod 600 "$firewall_path"
	stale_before=$(sha256sum "$firewall_path")

	run invoke_firewall platform_firewall_ensure 192.168.50.1 192.168.50.0/24
	[ "$status" -eq 78 ]
	[ "$(sha256sum "$firewall_path")" = "$stale_before" ]

	run invoke_firewall platform_firewall_close 192.168.50.1 192.168.50.0/24
	[ "$status" -eq 78 ]
	[ "$(sha256sum "$firewall_path")" = "$stale_before" ]
}

@test "production iptables branch inserts verifies refuses conflicts and removes exact rules" {
	configure_real_source
	iptables_state=$NUTMERLIN_TEST_ROOT/platform/iptables-state
	mkdir -m 700 "$iptables_state"
	printf '%s\n' untouched >"$iptables_state/unrelated"
	unrelated_before=$(sha256sum "$iptables_state/unrelated")
	installed_library=$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/lib

	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" /bin/sh -c '
		for module in paths configuration ownership platform; do . "$1/$module.sh"; done
		paths_initialize
		NUTMERLIN_ENABLE_TEST_ADAPTERS=0
		export NUTMERLIN_ENABLE_TEST_ADAPTERS
		iptables_state=$NUTMERLIN_TEST_ROOT/platform/iptables-state
		iptables() {
			printf "%s\n" "$*" >>"$iptables_state/commands.log"
			iptables_target=
			for iptables_argument do iptables_target=$iptables_argument; done
			case $1 in
				-S)
					if [ "$#" -eq 1 ]; then
						printf "%s\n" "-P INPUT ACCEPT"
						[ ! -f "$iptables_state/chain" ] || printf "%s\n" "-N NUTMERLIN"
						[ ! -f "$iptables_state/jump" ] || printf "%s\n" "-A INPUT -p tcp -d 192.168.50.1/32 -m tcp --dport 3493 -m comment --comment $marker -j NUTMERLIN"
						[ ! -f "$iptables_state/extra" ] || printf "%s\n" "-A FORWARD -g NUTMERLIN"
						[ ! -f "$iptables_state/allow" ] || printf "%s\n" "-A NUTMERLIN -s 192.168.50.0/24 -d 192.168.50.1/32 -p tcp -m tcp --dport 3493 -m comment --comment $marker -j ACCEPT"
						[ ! -f "$iptables_state/deny" ] || printf "%s\n" "-A NUTMERLIN -d 192.168.50.1/32 -p tcp -m tcp --dport 3493 -m comment --comment $marker -j DROP"
					elif [ "$2" = INPUT ]; then
						printf "%s\n" "-P INPUT ACCEPT"
						[ ! -f "$iptables_state/jump" ] || printf "%s\n" "-A INPUT -p tcp -d 192.168.50.1/32 -m tcp --dport 3493 -m comment --comment $marker -j NUTMERLIN"
					elif [ "$2" = NUTMERLIN ] && [ -f "$iptables_state/chain" ]; then
						printf "%s\n" "-N NUTMERLIN"
						[ ! -f "$iptables_state/allow" ] || printf "%s\n" "-A NUTMERLIN -s 192.168.50.0/24 -d 192.168.50.1/32 -p tcp -m tcp --dport 3493 -m comment --comment $marker -j ACCEPT"
						[ ! -f "$iptables_state/deny" ] || printf "%s\n" "-A NUTMERLIN -d 192.168.50.1/32 -p tcp -m tcp --dport 3493 -m comment --comment $marker -j DROP"
					else
						return 1
					fi
					;;
				-N) : >"$iptables_state/chain" ;;
				-A)
					case $iptables_target in
						ACCEPT) : >"$iptables_state/allow" ;;
						DROP) : >"$iptables_state/deny" ;;
						*) return 1 ;;
					esac
					;;
				-I) : >"$iptables_state/jump" ;;
				-C)
					case $iptables_target in
						ACCEPT) [ -f "$iptables_state/allow" ] ;;
						DROP) [ -f "$iptables_state/deny" ] ;;
						NUTMERLIN) [ -f "$iptables_state/jump" ] ;;
						*) return 1 ;;
					esac
					;;
				-D)
					case $iptables_target in
						ACCEPT) rm -f -- "$iptables_state/allow" ;;
						DROP) rm -f -- "$iptables_state/deny" ;;
						NUTMERLIN) rm -f -- "$iptables_state/jump" ;;
						*) return 1 ;;
					esac
					;;
				-X)
					[ ! -f "$iptables_state/allow" ] && [ ! -f "$iptables_state/deny" ] &&
						[ ! -f "$iptables_state/jump" ] || return 1
					rm -f -- "$iptables_state/chain"
					;;
				*) return 1 ;;
			esac
		}
		marker=$(platform_firewall_marker)
		platform_firewall_ensure 192.168.50.1 192.168.50.0/24
		platform_firewall_state 192.168.50.1 192.168.50.0/24
		: >"$iptables_state/extra"
		if platform_firewall_state 192.168.50.1 192.168.50.0/24; then
			exit 1
		else
			[ "$?" -eq 78 ] || exit 1
		fi
		rm -f -- "$iptables_state/extra"
		platform_firewall_ensure 192.168.50.1 192.168.50.0/24
		platform_firewall_close 192.168.50.1 192.168.50.0/24
		platform_firewall_is_absent
		printf "%s|%s|%s|%s|%s|%s\n" \
			"$(grep -c "^-N NUTMERLIN$" "$iptables_state/commands.log")" \
			"$(grep -c "^-A NUTMERLIN .* -s 192.168.50.0/24 .* -j ACCEPT$" "$iptables_state/commands.log")" \
			"$(grep -c "^-A NUTMERLIN .* -j DROP$" "$iptables_state/commands.log")" \
			"$(grep -c "^-I INPUT 1 .* -j NUTMERLIN$" "$iptables_state/commands.log")" \
			"$(grep -c "^-D INPUT .* -j NUTMERLIN$" "$iptables_state/commands.log")" \
			"$(grep -c "^-X NUTMERLIN$" "$iptables_state/commands.log")"
	' sh "$installed_library"

	[ "$status" -eq 0 ]
	[ "$output" = '1|1|1|1|1|1' ]
	[ "$(sha256sum "$iptables_state/unrelated")" = "$unrelated_before" ]
}

@test "service network boundary recreates exact firewall state and rejects extra listeners" {
	configure_real_source
	write_network_fixture
	env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		"$installed_cli" lan configure \
		--address 192.168.50.1 --cidr 192.168.50.0/24 >/dev/null
	installed_library=$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/lib

	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" /bin/sh -c '
		for module in paths configuration ownership platform service; do . "$1/$module.sh"; done
		paths_initialize
		service_resolve_current
		service_load_active_profile
		service_network_prepare
		service_firewall_is_expected
		rm -f -- "$NUTMERLIN_TEST_ROOT/platform/firewall.tsv"
		service_network_prepare
		service_firewall_is_expected
	' sh "$installed_library"
	[ "$status" -eq 0 ]
	[ -f "$NUTMERLIN_TEST_ROOT/platform/firewall.tsv" ]

	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" /bin/sh -c '
		for module in paths configuration ownership platform service; do . "$1/$module.sh"; done
		paths_initialize
		service_resolve_current
		service_load_active_profile
		platform_listener_snapshot() {
			printf "%s\n" "State Recv-Q Send-Q Local Address:Port Peer Address:Port"
			printf "%s\n" "LISTEN 0 16 127.0.0.1:3493 0.0.0.0:*"
			printf "%s\n" "LISTEN 0 16 192.168.50.1:3493 0.0.0.0:*"
			printf "%s\n" "LISTEN 0 16 0.0.0.0:3493 0.0.0.0:*"
		}
		service_listener_is_expected
	' sh "$installed_library"
	[ "$status" -eq 1 ]
}

@test "status reports trusted-LAN health only when listener and firewall both match" {
	configure_real_source
	write_network_fixture
	env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		"$installed_cli" lan configure \
		--address 192.168.50.1 --cidr 192.168.50.0/24 >/dev/null
	invoke_firewall platform_firewall_ensure 192.168.50.1 192.168.50.0/24
	printf '%s\n' 1 >"$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/enabled"
	installed_library=$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/lib

	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" /bin/sh -c '
		for module in paths entware configuration hooks ownership service platform lifecycle status; do
			. "$1/$module.sh"
		done
		paths_initialize
		status_process_value() { printf "%s\n" running; }
		service_query_active() { return 0; }
		platform_listener_snapshot() {
			printf "%s\n" "State Recv-Q Send-Q Local Address:Port Peer Address:Port"
			printf "%s\n" "LISTEN 0 16 127.0.0.1:3493 0.0.0.0:*"
			printf "%s\n" "LISTEN 0 16 192.168.50.1:3493 0.0.0.0:*"
		}
		status_collect
		printf "%s|%s|%s|%s|%s\n" "$STATUS_STATE" "$STATUS_LISTENER" \
			"$STATUS_FIREWALL" "$STATUS_FAILED_LAYER" "$STATUS_MESSAGE"
	' sh "$installed_library"
	[ "$status" -eq 0 ]
	[ "$output" = 'ok|trusted_lan|trusted_lan|none|ups service is healthy for trusted LAN 192.168.50.0/24' ]

	printf '%s\n' 'stale broad state' >"$NUTMERLIN_TEST_ROOT/platform/firewall.tsv"
	chmod 600 "$NUTMERLIN_TEST_ROOT/platform/firewall.tsv"
	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" /bin/sh -c '
		for module in paths entware configuration hooks ownership service platform lifecycle status; do
			. "$1/$module.sh"
		done
		paths_initialize
		status_process_value() { printf "%s\n" running; }
		service_query_active() { return 0; }
		platform_listener_snapshot() {
			printf "%s\n" "State Recv-Q Send-Q Local Address:Port Peer Address:Port"
			printf "%s\n" "LISTEN 0 16 127.0.0.1:3493 0.0.0.0:*"
			printf "%s\n" "LISTEN 0 16 192.168.50.1:3493 0.0.0.0:*"
		}
		status_collect
		printf "%s|%s|%s|%s\n" "$STATUS_STATE" "$STATUS_FIREWALL" \
			"$STATUS_FAILED_LAYER" "$STATUS_EXIT"
	' sh "$installed_library"
	[ "$status" -eq 0 ]
	[ "$output" = 'refused|ambiguous|firewall|78' ]

	rm -f -- "$NUTMERLIN_TEST_ROOT/platform/firewall.tsv"
	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" /bin/sh -c '
		for module in paths entware configuration hooks ownership service platform lifecycle status; do
			. "$1/$module.sh"
		done
		paths_initialize
		status_process_value() { printf "%s\n" running; }
		service_query_active() { return 0; }
		platform_listener_snapshot() {
			printf "%s\n" "State Recv-Q Send-Q Local Address:Port Peer Address:Port"
			printf "%s\n" "LISTEN 0 16 127.0.0.1:3493 0.0.0.0:*"
			printf "%s\n" "LISTEN 0 16 192.168.50.1:3493 0.0.0.0:*"
		}
		status_collect
		printf "%s|%s|%s|%s\n" "$STATUS_STATE" "$STATUS_FIREWALL" \
			"$STATUS_FAILED_LAYER" "$STATUS_EXIT"
	' sh "$installed_library"
	[ "$status" -eq 0 ]
	[ "$output" = 'unavailable|closed|firewall|69' ]
}

@test "firewall-start lifecycle reconciliation recreates a missing owned chain" {
	configure_real_source
	write_network_fixture
	env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		"$installed_cli" lan configure \
		--address 192.168.50.1 --cidr 192.168.50.0/24 >/dev/null
	printf '%s\n' 1 >"$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/enabled"
	installed_library=$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/lib

	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" /bin/sh -c '
		for module in paths entware configuration hooks ownership service platform lifecycle; do
			. "$1/$module.sh"
		done
		paths_initialize
		service_restart() {
			service_resolve_current
			service_load_active_profile
			service_validate_active_network
			service_network_prepare
		}
		lifecycle_hook firewall-start
		printf "%s\n" "$LIFECYCLE_MESSAGE"
	' sh "$installed_library"
	[ "$status" -eq 0 ]
	[ "$output" = 'service recovered successfully' ]
	[ -f "$NUTMERLIN_TEST_ROOT/platform/firewall.tsv" ]
}

@test "firewall-start and periodic reconcile close unhealthy admission during recovery pause" {
	configure_real_source
	write_network_fixture
	env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" \
		"$installed_cli" lan configure \
		--address 192.168.50.1 --cidr 192.168.50.0/24 >/dev/null
	printf '%s\n' 1 >"$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/enabled"
	recovery_path=$NUTMERLIN_TMP_ROOT/nutmerlin/run/recovery.tsv
	printf 'schema\tnutmerlin.recovery.v1\nfailures\t3\npause\t3\n' >"$recovery_path"
	chmod 600 "$recovery_path"
	installed_library=$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/lib

	run env NUTMERLIN_ENABLE_TEST_ADAPTERS=1 \
		NUTMERLIN_TEST_ROOT="$NUTMERLIN_TEST_ROOT" \
		NUTMERLIN_TEST_RUN_USER="$(id -un)" /bin/sh -c '
		for module in paths entware configuration hooks ownership service platform lifecycle; do
			. "$1/$module.sh"
		done
		paths_initialize
		lifecycle_service_is_healthy() { return 1; }
		service_stop() {
			: >"$NUTMERLIN_TEST_ROOT/platform/service-stopped"
			return 0
		}
		lifecycle_hook firewall-start
		firewall_status=$?
		lifecycle_recovery_write 3 3
		rm -f -- "$NUTMERLIN_TEST_ROOT/platform/service-stopped"
		lifecycle_hook reconcile
		reconcile_status=$?
		paused_value=$(sed -n "3p" "$NUTMERLIN_TMP_ROOT/nutmerlin/run/recovery.tsv" | cut -f2)
		lifecycle_recovery_write 3 3
		rm -f -- "$NUTMERLIN_TEST_ROOT/platform/service-stopped"
		lifecycle_service_is_healthy() { return 0; }
		lifecycle_hook reconcile
		healthy_status=$?
		[ ! -e "$NUTMERLIN_TMP_ROOT/nutmerlin/run/recovery.tsv" ]
		[ ! -e "$NUTMERLIN_TEST_ROOT/platform/service-stopped" ]
		printf "%s|%s|%s|%s\n" "$firewall_status" "$reconcile_status" \
			"$healthy_status" "$paused_value"
		[ "$firewall_status" -eq 75 ]
		[ "$reconcile_status" -eq 75 ]
		[ "$healthy_status" -eq 0 ]
	' sh "$installed_library"

	[ "$status" -eq 0 ]
	[ "$output" = '75|75|0|2' ]
}
