#!/bin/sh

platform_process_snapshot() {
	ps 2>/dev/null
}

platform_listener_snapshot() {
	command -v ss >/dev/null 2>&1 || return 69
	ss -ltn 2>/dev/null
}

platform_process_is_alive() {
	kill -0 "$1" 2>/dev/null
}

platform_process_signal() {
	kill "$1"
}

platform_process_executable() {
	readlink "/proc/$1/exe" 2>/dev/null
}

platform_process_uid() {
	awk '/^Uid:/ { print $2; exit }' "/proc/$1/status" 2>/dev/null
}

platform_process_has_environment() {
	platform_environment_pid=$1
	platform_environment_value=$2
	tr '\000' '\n' <"/proc/$platform_environment_pid/environ" 2>/dev/null |
		grep -Fx "$platform_environment_value" >/dev/null
}

platform_usb_snapshot() {
	if [ "${NUTMERLIN_ENABLE_TEST_ADAPTERS:-0}" = 1 ]; then
		platform_usb_fixture=$NUTMERLIN_TEST_ROOT/platform/usb-devices.tsv
		if [ -e "$platform_usb_fixture" ] || [ -L "$platform_usb_fixture" ]; then
			[ -f "$platform_usb_fixture" ] && [ ! -L "$platform_usb_fixture" ] || return 78
			[ "$(stat -c '%a' "$platform_usb_fixture")" = 600 ] || return 78
			[ "$(stat -c '%h' "$platform_usb_fixture")" = 1 ] || return 78
			[ "$(stat -c '%u' "$platform_usb_fixture")" = "$(id -u)" ] || return 78
			cat "$platform_usb_fixture"
			return 0
		fi
		platform_usb_root=${NUTMERLIN_TEST_USB_SYSFS_ROOT:-}
		[ -n "$platform_usb_root" ] || return 0
		platform_usb_canonical_root=$(readlink -f "$platform_usb_root" 2>/dev/null || :)
		case $platform_usb_canonical_root in
			"$NUTMERLIN_TEST_ROOT"/platform/*) ;;
			*) return 78 ;;
		esac
	else
		platform_usb_root=/sys/bus/usb/devices
		platform_usb_canonical_root=$(readlink -f "$platform_usb_root" 2>/dev/null || :)
		[ "$platform_usb_canonical_root" = /sys/bus/usb/devices ] || return 69
	fi
	[ -d "$platform_usb_canonical_root" ] && [ ! -L "$platform_usb_canonical_root" ] || return 69
	for platform_usb_visible_path in "$platform_usb_canonical_root"/*; do
		[ -e "$platform_usb_visible_path" ] || [ -L "$platform_usb_visible_path" ] || continue
		platform_usb_device_root=$(readlink -f "$platform_usb_visible_path" 2>/dev/null || :)
		if [ "${NUTMERLIN_ENABLE_TEST_ADAPTERS:-0}" = 1 ]; then
			case $platform_usb_device_root in
				"$platform_usb_canonical_root"/*) ;;
				*) return 78 ;;
			esac
		else
			case $platform_usb_device_root in
				/sys/devices/*) ;;
				*) return 78 ;;
			esac
		fi
		[ -d "$platform_usb_device_root" ] || continue
		platform_usb_vendor_path=$platform_usb_device_root/idVendor
		platform_usb_product_path=$platform_usb_device_root/idProduct
		if [ ! -f "$platform_usb_vendor_path" ] || [ -L "$platform_usb_vendor_path" ]; then
			continue
		fi
		if [ ! -f "$platform_usb_product_path" ] || [ -L "$platform_usb_product_path" ]; then
			continue
		fi
		platform_usb_vendor=$(cat "$platform_usb_vendor_path")
		platform_usb_product=$(cat "$platform_usb_product_path")
		case $platform_usb_vendor:$platform_usb_product in
			????:????) ;;
			*) return 78 ;;
		esac
		case $platform_usb_vendor$platform_usb_product in
			*[!0-9A-Fa-f]*) return 78 ;;
		esac
		platform_usb_vendor=$(printf '%s\n' "$platform_usb_vendor" | tr 'A-F' 'a-f')
		platform_usb_product=$(printf '%s\n' "$platform_usb_product" | tr 'A-F' 'a-f')
		platform_usb_serial=-
		if [ -f "$platform_usb_device_root/serial" ] && [ ! -L "$platform_usb_device_root/serial" ]; then
			platform_usb_serial=$(cat "$platform_usb_device_root/serial")
			[ -n "$platform_usb_serial" ] && [ "${#platform_usb_serial}" -le 64 ] || return 78
			case $platform_usb_serial in
				*[!A-Za-z0-9._:+-]*) return 78 ;;
			esac
		fi
		platform_usb_busport=-
		if [ -f "$platform_usb_device_root/devpath" ] && [ ! -L "$platform_usb_device_root/devpath" ]; then
			platform_usb_devpath=$(cat "$platform_usb_device_root/devpath")
			case $platform_usb_devpath in
				*[!0-9.]* | '') return 78 ;;
			esac
			platform_usb_port_number=${platform_usb_devpath##*.}
			platform_usb_busport=$(awk -v value="$platform_usb_port_number" 'BEGIN {
				number = value + 0
				if (number < 1 || number > 255) exit 1
				printf "%03d", number
			}' 2>/dev/null || printf '%s' -)
		fi
		platform_usb_bus=-
		platform_usb_device=-
		if [ -f "$platform_usb_device_root/busnum" ] && [ ! -L "$platform_usb_device_root/busnum" ]; then
			platform_usb_bus_value=$(cat "$platform_usb_device_root/busnum")
			case $platform_usb_bus_value in
				*[!0-9]* | '') return 78 ;;
			esac
			platform_usb_bus=$(awk -v value="$platform_usb_bus_value" 'BEGIN {
				number = value + 0
				if (number < 0 || number > 999) exit 1
				printf "%03d", number
			}' 2>/dev/null || printf '%s' -)
		fi
		if [ -f "$platform_usb_device_root/devnum" ] && [ ! -L "$platform_usb_device_root/devnum" ]; then
			platform_usb_device_value=$(cat "$platform_usb_device_root/devnum")
			case $platform_usb_device_value in
				*[!0-9]* | '') return 78 ;;
			esac
			platform_usb_device=$(awk -v value="$platform_usb_device_value" 'BEGIN {
				number = value + 0
				if (number < 0 || number > 999) exit 1
				printf "%03d", number
			}' 2>/dev/null || printf '%s' -)
		fi
		platform_usb_device_id=${platform_usb_visible_path##*/}
		case $platform_usb_device_id in
			'' | *[!A-Za-z0-9._:-]*) return 78 ;;
		esac
		printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$platform_usb_device_id" \
			"$platform_usb_vendor" "$platform_usb_product" "$platform_usb_serial" \
			"$platform_usb_busport" "$platform_usb_bus" "$platform_usb_device"
	done
}

platform_network_snapshot() {
	if [ "${NUTMERLIN_ENABLE_TEST_ADAPTERS:-0}" = 1 ]; then
		platform_network_fixture=$NUTMERLIN_TEST_ROOT/platform/network.tsv
		[ -f "$platform_network_fixture" ] && [ ! -L "$platform_network_fixture" ] || return 69
		[ "$(stat -c '%a' "$platform_network_fixture")" = 600 ] || return 78
		[ "$(stat -c '%h' "$platform_network_fixture")" = 1 ] || return 78
		[ "$(stat -c '%u' "$platform_network_fixture")" = "$(id -u)" ] || return 78
		cat "$platform_network_fixture"
		return 0
	fi
	command -v nvram >/dev/null 2>&1 || return 69
	platform_lan_address=$(nvram get lan_ipaddr 2>/dev/null) || return 69
	platform_lan_netmask=$(nvram get lan_netmask 2>/dev/null) || return 69
	printf 'schema\tnutmerlin.network.v1\n'
	printf 'lan_address\t%s\n' "$platform_lan_address"
	printf 'lan_netmask\t%s\n' "$platform_lan_netmask"
	platform_wan_count=0
	for platform_wan_key in wan_ipaddr wan0_ipaddr wan1_ipaddr; do
		platform_wan_address=$(nvram get "$platform_wan_key" 2>/dev/null) || return 69
		case $platform_wan_address in
			'' | 0.0.0.0) continue ;;
		esac
		printf 'wan_address\t%s\n' "$platform_wan_address"
		platform_wan_count=$((platform_wan_count + 1))
	done
	[ "$platform_wan_count" -gt 0 ] || printf 'wan_address\t-\n'
}

platform_validate_lan_scope() (
	requested_address=$(configuration_normalize_ipv4 "$1") || {
		printf '%s\n' 'LAN exposure refused: address must be a canonical IPv4 address' >&2
		return 78
	}
	configuration_ipv4_is_safe_listener "$requested_address" || {
		printf '%s\n' 'LAN exposure refused: address is not a safe unicast listener' >&2
		return 78
	}
	requested_cidr=$(configuration_normalize_cidr "$2") || {
		printf '%s\n' 'LAN exposure refused: CIDR must be a canonical IPv4 network with prefix 1-32' >&2
		return 78
	}
	configuration_cidr_is_safe_source "$requested_cidr" || {
		printf '%s\n' 'LAN exposure refused: CIDR overlaps a reserved or unsafe scope' >&2
		return 78
	}
	network_snapshot=$(mktemp "$NUTMERLIN_TMP_ROOT/.nutmerlin-network.XXXXXX") || return 75
	trap 'rm -f -- "$network_snapshot"' EXIT HUP INT TERM
	platform_network_snapshot >"$network_snapshot" || {
		network_status=$?
		printf '%s\n' 'LAN exposure unavailable: router network state could not be verified' >&2
		return "$network_status"
	}
	network_line_count=$(wc -l <"$network_snapshot")
	if [ "$network_line_count" -lt 4 ] || [ "$network_line_count" -gt 6 ]; then
		printf '%s\n' 'LAN exposure refused: router network state is malformed' >&2
		return 78
	fi
	[ "$(sed -n '1p' "$network_snapshot")" = "$(printf 'schema\tnutmerlin.network.v1')" ] || {
		printf '%s\n' 'LAN exposure refused: router network state is malformed' >&2
		return 78
	}
	network_tab=$(printf '\t')
	observed_lan_address=$(awk -F "$network_tab" '$1 == "lan_address" && NF == 2 { print $2; count++ } END { if (count != 1) exit 1 }' "$network_snapshot") || return 78
	observed_lan_netmask=$(awk -F "$network_tab" '$1 == "lan_netmask" && NF == 2 { print $2; count++ } END { if (count != 1) exit 1 }' "$network_snapshot") || return 78
	[ "$(awk -F "$network_tab" 'NR > 1 && $1 !~ /^(lan_address|lan_netmask|wan_address)$/ { count++ } END { print count + 0 }' "$network_snapshot")" -eq 0 ] || return 78
	[ "$(configuration_normalize_ipv4 "$observed_lan_address" 2>/dev/null || :)" = "$observed_lan_address" ] || return 78
	[ "$requested_address" = "$observed_lan_address" ] || {
		printf '%s\n' 'LAN exposure refused: address does not equal the router LAN IPv4 address' >&2
		return 78
	}
	lan_prefix=$(configuration_netmask_prefix "$observed_lan_netmask") || return 78
	physical_cidr=$(configuration_network_cidr "$observed_lan_address" "$lan_prefix") || return 78
	physical_start=$(configuration_ipv4_to_uint "${physical_cidr%/*}") || return 78
	physical_size=$(awk -v prefix="$lan_prefix" 'BEGIN { printf "%.0f\n", 2 ^ (32 - prefix) }')
	physical_end=$(awk -v start="$physical_start" -v size="$physical_size" 'BEGIN { printf "%.0f\n", start + size - 1 }')
	requested_uint=$(configuration_ipv4_to_uint "$requested_address") || return 78
	if [ "$lan_prefix" -lt 32 ] &&
		{ [ "$requested_uint" = "$physical_start" ] || [ "$requested_uint" = "$physical_end" ]; }; then
		printf '%s\n' 'LAN exposure refused: router LAN address is a network or broadcast address' >&2
		return 78
	fi
	requested_cidr_prefix=${requested_cidr##*/}
	requested_cidr_start=$(configuration_ipv4_to_uint "${requested_cidr%/*}") || return 78
	if [ "$requested_cidr_prefix" -eq 32 ] && [ "$lan_prefix" -lt 32 ] &&
		[ "$requested_cidr_start" = "$physical_end" ]; then
		printf '%s\n' 'LAN exposure refused: CIDR selects the router LAN broadcast address' >&2
		return 78
	fi
	wan_count=0
	while IFS="$network_tab" read -r network_key network_value network_extra; do
		[ "$network_key" = wan_address ] || continue
		[ -z "$network_extra" ] || return 78
		wan_count=$((wan_count + 1))
		[ "$network_value" = - ] || {
			[ "$(configuration_normalize_ipv4 "$network_value" 2>/dev/null || :)" = "$network_value" ] || return 78
			[ "$requested_address" != "$network_value" ] || {
				printf '%s\n' 'LAN exposure refused: address equals a router WAN IPv4 address' >&2
				return 78
			}
		}
	done <"$network_snapshot"
	[ "$wan_count" -ge 1 ] || return 78
)

platform_storage_state() {
	case ${NUTMERLIN_TEST_STORAGE_STATE:-} in
		missing | read_only | replaced | ownership_mismatch | unknown)
			printf '%s\n' "$NUTMERLIN_TEST_STORAGE_STATE"
			return 0
			;;
		'' | available) ;;
		*) return 78 ;;
	esac
	if [ ! -e "$NUTMERLIN_OPT_ROOT" ] && [ ! -L "$NUTMERLIN_OPT_ROOT" ]; then
		printf '%s\n' missing
		return 0
	fi
	if [ ! -d "$NUTMERLIN_OPT_ROOT" ] || [ -L "$NUTMERLIN_OPT_ROOT" ]; then
		printf '%s\n' replaced
		return 0
	fi
	if [ "${NUTMERLIN_ENABLE_TEST_ADAPTERS:-0}" = 1 ]; then
		if [ ! -w "$NUTMERLIN_OPT_ROOT" ]; then
			printf '%s\n' read_only
			return 0
		fi
	else
		storage_device=$(df -P "$NUTMERLIN_OPT_ROOT" 2>/dev/null | awk 'NR == 2 { print $1 }')
		[ -n "$storage_device" ] || {
			printf '%s\n' unknown
			return 0
		}
		storage_options=$(awk -v device="$storage_device" '$1 == device { print $4; exit }' /proc/mounts 2>/dev/null)
		[ -n "$storage_options" ] || {
			printf '%s\n' unknown
			return 0
		}
		case ,$storage_options, in
			*,ro,*)
				printf '%s\n' read_only
				return 0
				;;
		esac
	fi
	platform_config_root=$NUTMERLIN_OPT_ROOT/etc/nutmerlin
	if [ ! -d "$platform_config_root" ] || [ -L "$platform_config_root" ]; then
		printf '%s\n' replaced
		return 0
	fi
	platform_code_id=$(cat "$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/installation.id" 2>/dev/null || :)
	platform_config_id=$(cat "$platform_config_root/installation.id" 2>/dev/null || :)
	if [ -z "$platform_code_id" ] || [ "$platform_code_id" != "$platform_config_id" ]; then
		printf '%s\n' replaced
		return 0
	fi
	if ! ownership_verify_config_root "$platform_config_root"; then
		printf '%s\n' ownership_mismatch
		return 0
	fi
	printf '%s\n' available
}

platform_cru_command() {
	platform_schedule_id=$(cat "$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/installation.id" 2>/dev/null || :)
	ownership_id_is_valid "$platform_schedule_id" || return 78
	printf '%s/bin/nutmerlin hook reconcile %s\n' \
		"$NUTMERLIN_JFFS_ROOT/addons/nutmerlin" "$platform_schedule_id"
}

platform_cru_expected_record() {
	periodic_command=$(platform_cru_command) || return $?
	printf 'NUTMerlin\t*/5 * * * *\t%s\n' "$periodic_command"
}

platform_cru_adapter_state() {
	platform_cru_path=$NUTMERLIN_TEST_ROOT/platform/cru.tsv
	if [ ! -e "$platform_cru_path" ] && [ ! -L "$platform_cru_path" ]; then
		return 1
	fi
	[ -f "$platform_cru_path" ] && [ ! -L "$platform_cru_path" ] || return 78
	[ "$(stat -c '%a' "$platform_cru_path")" = 600 ] || return 78
	[ "$(stat -c '%h' "$platform_cru_path")" = 1 ] || return 78
	[ "$(stat -c '%u' "$platform_cru_path")" = "$(id -u)" ] || return 78
	platform_expected_record=$(platform_cru_expected_record) || return $?
	[ "$(wc -l <"$platform_cru_path")" -eq 1 ] || return 78
	[ "$(cat "$platform_cru_path")" = "$platform_expected_record" ] || return 78
}

platform_cru_listing_state() {
	platform_listing=$1
	periodic_command=$(platform_cru_command) || return $?
	platform_expected_line="*/5 * * * * $periodic_command #NUTMerlin#"
	platform_named_count=$(printf '%s\n' "$platform_listing" | grep -Fc '#NUTMerlin#' || :)
	platform_command_count=$(printf '%s\n' "$platform_listing" | grep -Fc "$periodic_command" || :)
	if [ "$platform_named_count" -eq 0 ] && [ "$platform_command_count" -eq 0 ]; then
		return 1
	fi
	[ "$platform_named_count" -eq 1 ] && [ "$platform_command_count" -eq 1 ] || return 78
	printf '%s\n' "$platform_listing" | grep -Fx "$platform_expected_line" >/dev/null || return 78
}

platform_cru_ensure() {
	periodic_command=$(platform_cru_command) || return $?
	if [ "${NUTMERLIN_ENABLE_TEST_ADAPTERS:-0}" = 1 ]; then
		platform_state_root=$NUTMERLIN_TEST_ROOT/platform
		if [ -e "$platform_state_root" ] || [ -L "$platform_state_root" ]; then
			[ -d "$platform_state_root" ] && [ ! -L "$platform_state_root" ] || return 78
			[ "$(stat -c '%a' "$platform_state_root")" = 700 ] || return 78
			[ "$(stat -c '%u' "$platform_state_root")" = "$(id -u)" ] || return 78
		else
			mkdir -m 700 "$platform_state_root" || return 75
		fi
		if platform_cru_adapter_state; then
			return 0
		else
			platform_cru_state=$?
			[ "$platform_cru_state" -eq 1 ] || return "$platform_cru_state"
		fi
		platform_cru_candidate=$platform_state_root/cru.tsv.new
		[ ! -e "$platform_cru_candidate" ] && [ ! -L "$platform_cru_candidate" ] || return 78
		(umask 077 && set -C && platform_cru_expected_record >"$platform_cru_candidate") || {
			rm -f -- "$platform_cru_candidate"
			return 75
		}
		if ! ln "$platform_cru_candidate" "$platform_state_root/cru.tsv" 2>/dev/null; then
			rm -f -- "$platform_cru_candidate"
			return 78
		fi
		rm -f -- "$platform_cru_candidate"
		platform_cru_adapter_state
		return $?
	fi
	command -v cru >/dev/null 2>&1 || return 69
	cru_listing=$(cru l 2>/dev/null) || return 75
	if platform_cru_listing_state "$cru_listing"; then
		return 0
	else
		platform_cru_state=$?
		[ "$platform_cru_state" -eq 1 ] || return "$platform_cru_state"
	fi
	cru a NUTMerlin "*/5 * * * * $periodic_command" || return 75
	cru_listing=$(cru l 2>/dev/null) || return 75
	platform_cru_listing_state "$cru_listing" || return 75
}

platform_cru_remove() {
	if [ "${NUTMERLIN_ENABLE_TEST_ADAPTERS:-0}" = 1 ]; then
		platform_cru_path=$NUTMERLIN_TEST_ROOT/platform/cru.tsv
		if platform_cru_adapter_state; then
			:
		else
			platform_cru_state=$?
			[ "$platform_cru_state" -eq 1 ] && return 0
			return "$platform_cru_state"
		fi
		rm -f -- "$platform_cru_path"
		return 0
	fi
	command -v cru >/dev/null 2>&1 || return 69
	cru_listing=$(cru l 2>/dev/null) || return 75
	if platform_cru_listing_state "$cru_listing"; then
		cru d NUTMerlin >/dev/null 2>&1 || return 75
		cru_listing=$(cru l 2>/dev/null) || return 75
		if platform_cru_listing_state "$cru_listing"; then
			return 75
		else
			platform_cru_state=$?
			[ "$platform_cru_state" -eq 1 ] || return "$platform_cru_state"
		fi
		return 0
	else
		platform_cru_state=$?
		[ "$platform_cru_state" -eq 1 ] && return 0
		return "$platform_cru_state"
	fi
}

platform_firewall_chain=NUTMERLIN

platform_firewall_marker() {
	platform_firewall_installation_id=$(cat \
		"$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/installation.id" 2>/dev/null || :)
	ownership_id_is_valid "$platform_firewall_installation_id" || return 78
	printf 'nutmerlin:%s\n' "$platform_firewall_installation_id"
}

platform_firewall_expected_record() {
	platform_firewall_address=$1
	platform_firewall_cidr=$2
	platform_firewall_marker=$(platform_firewall_marker) || return $?
	platform_firewall_installation_id=${platform_firewall_marker#nutmerlin:}
	printf 'schema\tnutmerlin.firewall.v1\n'
	printf 'installation_id\t%s\n' "$platform_firewall_installation_id"
	printf 'chain\t%s\n' "$platform_firewall_chain"
	printf 'jump\tINPUT\t1\ttcp\t%s\t3493\t%s\t%s\n' \
		"$platform_firewall_address" "$platform_firewall_chain" "$platform_firewall_marker"
	printf 'allow\t%s\t%s\ttcp\t3493\t%s\n' \
		"$platform_firewall_cidr" "$platform_firewall_address" "$platform_firewall_marker"
	printf 'deny\t0.0.0.0/0\t%s\ttcp\t3493\t%s\n' \
		"$platform_firewall_address" "$platform_firewall_marker"
}

platform_firewall_adapter_state() {
	platform_firewall_address=$1
	platform_firewall_cidr=$2
	platform_firewall_path=$NUTMERLIN_TEST_ROOT/platform/firewall.tsv
	if [ ! -e "$platform_firewall_path" ] && [ ! -L "$platform_firewall_path" ]; then
		return 1
	fi
	[ -f "$platform_firewall_path" ] && [ ! -L "$platform_firewall_path" ] || return 78
	[ "$(stat -c '%a' "$platform_firewall_path")" = 600 ] || return 78
	[ "$(stat -c '%h' "$platform_firewall_path")" = 1 ] || return 78
	[ "$(stat -c '%u' "$platform_firewall_path")" = "$(id -u)" ] || return 78
	platform_firewall_expected=$(platform_firewall_expected_record \
		"$platform_firewall_address" "$platform_firewall_cidr") || return $?
	[ "$(cat "$platform_firewall_path")" = "$platform_firewall_expected" ] || return 78
}

platform_firewall_reference_count() {
	awk -v chain="$platform_firewall_chain" '
		{
			for (field = 1; field < NF; field++) {
				if (($field == "-j" || $field == "-g") && $(field + 1) == chain) count++
			}
		}
		END { print count + 0 }
	'
}

platform_firewall_iptables_state() {
	platform_firewall_address=$1
	platform_firewall_cidr=$2
	command -v iptables >/dev/null 2>&1 || return 69
	platform_firewall_marker=$(platform_firewall_marker) || return $?
	platform_firewall_all_rules=$(iptables -S 2>/dev/null) || return 69
	if ! platform_firewall_chain_rules=$(iptables -S "$platform_firewall_chain" 2>/dev/null); then
		if printf '%s\n' "$platform_firewall_all_rules" |
			grep -Fx -- "-N $platform_firewall_chain" >/dev/null; then
			return 69
		fi
		return 1
	fi
	platform_firewall_input_rules=$(iptables -S INPUT 2>/dev/null) || return 69
	[ "$(printf '%s\n' "$platform_firewall_all_rules" | platform_firewall_reference_count)" -eq 1 ] || return 78
	[ "$(printf '%s\n' "$platform_firewall_chain_rules" | wc -l)" -eq 3 ] || return 78
	[ "$(printf '%s\n' "$platform_firewall_chain_rules" | grep -Fc -- "--comment $platform_firewall_marker")" -eq 2 ] || return 78
	platform_firewall_allow_rule=$(printf '%s\n' "$platform_firewall_chain_rules" | sed -n '2p')
	platform_firewall_deny_rule=$(printf '%s\n' "$platform_firewall_chain_rules" | sed -n '3p')
	case $platform_firewall_allow_rule in
		*"-s $platform_firewall_cidr"*"--comment $platform_firewall_marker"*"-j ACCEPT") ;;
		*) return 78 ;;
	esac
	case $platform_firewall_deny_rule in
		*"--comment $platform_firewall_marker"*"-j DROP") ;;
		*) return 78 ;;
	esac
	case $platform_firewall_deny_rule in
		*' -s '*) return 78 ;;
	esac
	iptables -C "$platform_firewall_chain" -p tcp -s "$platform_firewall_cidr" \
		-d "$platform_firewall_address" --dport 3493 -m comment \
		--comment "$platform_firewall_marker" -j ACCEPT >/dev/null 2>&1 || return 78
	iptables -C "$platform_firewall_chain" -p tcp -d "$platform_firewall_address" \
		--dport 3493 -m comment --comment "$platform_firewall_marker" \
		-j DROP >/dev/null 2>&1 || return 78
	iptables -C INPUT -p tcp -d "$platform_firewall_address" --dport 3493 \
		-m comment --comment "$platform_firewall_marker" -j "$platform_firewall_chain" \
		>/dev/null 2>&1 || return 78
	platform_firewall_first_input=$(printf '%s\n' "$platform_firewall_input_rules" |
		awk '$1 == "-A" && $2 == "INPUT" { print; exit }')
	case $platform_firewall_first_input in
		*"--comment $platform_firewall_marker"*"-j $platform_firewall_chain"*) ;;
		*) return 78 ;;
	esac
}

platform_firewall_state() {
	if [ "${NUTMERLIN_ENABLE_TEST_ADAPTERS:-0}" = 1 ]; then
		platform_firewall_adapter_state "$1" "$2"
	else
		platform_firewall_iptables_state "$1" "$2"
	fi
}

platform_firewall_delete_expected_rules() {
	platform_firewall_address=$1
	platform_firewall_cidr=$2
	platform_firewall_marker=$3
	platform_firewall_delete_status=0
	iptables -D INPUT -p tcp -d "$platform_firewall_address" --dport 3493 \
		-m comment --comment "$platform_firewall_marker" \
		-j "$platform_firewall_chain" >/dev/null 2>&1 || platform_firewall_delete_status=75
	iptables -D "$platform_firewall_chain" -p tcp -s "$platform_firewall_cidr" \
		-d "$platform_firewall_address" --dport 3493 -m comment \
		--comment "$platform_firewall_marker" -j ACCEPT \
		>/dev/null 2>&1 || platform_firewall_delete_status=75
	iptables -D "$platform_firewall_chain" -p tcp -d "$platform_firewall_address" \
		--dport 3493 -m comment --comment "$platform_firewall_marker" \
		-j DROP >/dev/null 2>&1 || platform_firewall_delete_status=75
	return "$platform_firewall_delete_status"
}

platform_firewall_ensure() {
	platform_firewall_address=$1
	platform_firewall_cidr=$2
	if platform_firewall_state "$platform_firewall_address" "$platform_firewall_cidr"; then
		return 0
	else
		platform_firewall_observed=$?
		[ "$platform_firewall_observed" -eq 1 ] || return "$platform_firewall_observed"
	fi
	if [ "${NUTMERLIN_ENABLE_TEST_ADAPTERS:-0}" = 1 ]; then
		platform_firewall_root=$NUTMERLIN_TEST_ROOT/platform
		[ -d "$platform_firewall_root" ] && [ ! -L "$platform_firewall_root" ] || return 78
		[ "$(stat -c '%a' "$platform_firewall_root")" = 700 ] || return 78
		platform_firewall_candidate=$platform_firewall_root/firewall.tsv.new
		[ ! -e "$platform_firewall_candidate" ] && [ ! -L "$platform_firewall_candidate" ] || return 78
		(umask 077 && set -C && platform_firewall_expected_record \
			"$platform_firewall_address" "$platform_firewall_cidr" \
			>"$platform_firewall_candidate") || {
			rm -f -- "$platform_firewall_candidate"
			return 75
		}
		if ! ln "$platform_firewall_candidate" "$platform_firewall_root/firewall.tsv" 2>/dev/null; then
			rm -f -- "$platform_firewall_candidate"
			return 78
		fi
		rm -f -- "$platform_firewall_candidate"
		platform_firewall_adapter_state "$platform_firewall_address" "$platform_firewall_cidr"
		return $?
	fi
	platform_firewall_marker=$(platform_firewall_marker) || return $?
	platform_firewall_all_rules=$(iptables -S 2>/dev/null) || return 69
	if [ "$(printf '%s\n' "$platform_firewall_all_rules" | platform_firewall_reference_count)" -ne 0 ]; then
		return 78
	fi
	iptables -N "$platform_firewall_chain" || return 75
	platform_firewall_created=1
	iptables -A "$platform_firewall_chain" -p tcp -s "$platform_firewall_cidr" \
		-d "$platform_firewall_address" --dport 3493 -m comment \
		--comment "$platform_firewall_marker" -j ACCEPT || platform_firewall_created=0
	if [ "$platform_firewall_created" -eq 1 ]; then
		iptables -A "$platform_firewall_chain" -p tcp -d "$platform_firewall_address" \
			--dport 3493 -m comment --comment "$platform_firewall_marker" \
			-j DROP || platform_firewall_created=0
	fi
	if [ "$platform_firewall_created" -eq 1 ]; then
		iptables -I INPUT 1 -p tcp -d "$platform_firewall_address" --dport 3493 \
			-m comment --comment "$platform_firewall_marker" \
			-j "$platform_firewall_chain" || platform_firewall_created=0
	fi
	if [ "$platform_firewall_created" -ne 1 ]; then
		platform_firewall_delete_expected_rules "$platform_firewall_address" \
			"$platform_firewall_cidr" "$platform_firewall_marker" || :
		iptables -X "$platform_firewall_chain" >/dev/null 2>&1 || :
		return 75
	fi
	if ! platform_firewall_iptables_state "$platform_firewall_address" "$platform_firewall_cidr"; then
		platform_firewall_delete_expected_rules "$platform_firewall_address" \
			"$platform_firewall_cidr" "$platform_firewall_marker" || :
		iptables -X "$platform_firewall_chain" >/dev/null 2>&1 || :
		return 75
	fi
}

platform_firewall_close() {
	platform_firewall_address=$1
	platform_firewall_cidr=$2
	if platform_firewall_state "$platform_firewall_address" "$platform_firewall_cidr"; then
		:
	else
		platform_firewall_observed=$?
		[ "$platform_firewall_observed" -eq 1 ] && return 0
		return "$platform_firewall_observed"
	fi
	if [ "${NUTMERLIN_ENABLE_TEST_ADAPTERS:-0}" = 1 ]; then
		rm -f -- "$NUTMERLIN_TEST_ROOT/platform/firewall.tsv"
		return 0
	fi
	platform_firewall_marker=$(platform_firewall_marker) || return $?
	platform_firewall_delete_expected_rules "$platform_firewall_address" \
		"$platform_firewall_cidr" "$platform_firewall_marker" || return $?
	iptables -X "$platform_firewall_chain" || return 75
	if iptables -S "$platform_firewall_chain" >/dev/null 2>&1; then
		return 75
	fi
}

platform_firewall_is_absent() {
	if [ "${NUTMERLIN_ENABLE_TEST_ADAPTERS:-0}" = 1 ]; then
		[ ! -e "$NUTMERLIN_TEST_ROOT/platform/firewall.tsv" ] &&
			[ ! -L "$NUTMERLIN_TEST_ROOT/platform/firewall.tsv" ]
		return $?
	fi
	command -v iptables >/dev/null 2>&1 || return 69
	platform_firewall_all_rules=$(iptables -S 2>/dev/null) || return 69
	! printf '%s\n' "$platform_firewall_all_rules" |
		grep -Fx -- "-N $platform_firewall_chain" >/dev/null
}

platform_client_count() {
	client_set_root=$1
	client_root=$client_set_root/clients
	if [ ! -e "$client_root" ] && [ ! -L "$client_root" ]; then
		printf '%s\n' 0
		return 0
	fi
	[ -d "$client_root" ] && [ ! -L "$client_root" ] || return 78
	find "$client_root" -mindepth 1 -maxdepth 1 -type f | wc -l
}

platform_unmount_is_relevant() {
	unmount_candidate=${1:-}
	if [ -z "$unmount_candidate" ]; then
		return 0
	fi
	[ "${#unmount_candidate}" -le 256 ] || return 1
	case $unmount_candidate in
		/*) ;;
		*) return 1 ;;
	esac
	[ "$unmount_candidate" = "$NUTMERLIN_OPT_ROOT" ] && return 0
	resolved_opt_root=$(readlink -f "$NUTMERLIN_OPT_ROOT" 2>/dev/null || :)
	case $resolved_opt_root in
		"$unmount_candidate" | "$unmount_candidate"/*) return 0 ;;
		*) return 1 ;;
	esac
}
