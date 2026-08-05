#!/bin/sh

configuration_random_id() {
	random_id=$(dd if=/dev/urandom bs=16 count=1 2>/dev/null | od -An -tx1 | tr -d ' \n')
	case $random_id in
		????????????????????????????????) printf '%s\n' "$random_id" ;;
		*) return 70 ;;
	esac
}

configuration_normalize_usb_id() {
	usb_id=$1
	[ "${#usb_id}" -eq 4 ] || return 1
	case $usb_id in
		*[!0-9A-Fa-f]*) return 1 ;;
	esac
	printf '%s\n' "$usb_id" | tr 'A-F' 'a-f'
}

configuration_serial_is_valid() {
	usb_serial=$1
	[ -n "$usb_serial" ] && [ "${#usb_serial}" -le 64 ] || return 1
	case $usb_serial in
		*[!A-Za-z0-9._:+-]*) return 1 ;;
	esac
}

configuration_normalize_busport() {
	usb_busport=$1
	[ -n "$usb_busport" ] && [ "${#usb_busport}" -le 3 ] || return 1
	case $usb_busport in
		*[!0-9]*) return 1 ;;
	esac
	awk -v value="$usb_busport" 'BEGIN {
		number = value + 0
		if (number < 1 || number > 255) exit 1
		printf "%03d\n", number
	}'
}

configuration_normalize_ipv4() {
	ipv4_value=$1
	case $ipv4_value in
		'' | *[!0-9.]*) return 1 ;;
	esac
	awk -F . 'NF == 4 {
		for (i = 1; i <= 4; i++) {
			if ($i == "" || $i !~ /^[0-9]+$/ || $i + 0 > 255 || $i != ($i + 0) "") exit 1
		}
		printf "%d.%d.%d.%d\n", $1, $2, $3, $4
		exit 0
	}
	{ exit 1 }' <<EOF
$ipv4_value
EOF
}

configuration_ipv4_to_uint() {
	configuration_normalize_ipv4 "$1" >/dev/null || return 1
	awk -F . '{ printf "%.0f\n", (($1 * 256 + $2) * 256 + $3) * 256 + $4 }' <<EOF
$1
EOF
}

configuration_uint_to_ipv4() {
	uint_value=$1
	awk -v value="$uint_value" 'BEGIN {
		if (value < 0 || value > 4294967295 || value != int(value)) exit 1
		a = int(value / 16777216)
		value -= a * 16777216
		b = int(value / 65536)
		value -= b * 65536
		c = int(value / 256)
		d = value - c * 256
		printf "%d.%d.%d.%d\n", a, b, c, d
	}'
}

configuration_normalize_cidr() {
	cidr_value=$1
	case $cidr_value in
		*/*) ;;
		*) return 1 ;;
	esac
	cidr_address=${cidr_value%/*}
	cidr_prefix=${cidr_value##*/}
	[ -n "$cidr_prefix" ] || return 1
	case $cidr_prefix in
		*[!0-9]*) return 1 ;;
	esac
	normalized_prefix=$(awk -v value="$cidr_prefix" 'BEGIN {
		if (value !~ /^[0-9]+$/) exit 1
		printf "%d\n", value + 0
	}') || return 1
	[ "$cidr_prefix" = "$normalized_prefix" ] || return 1
	[ "$cidr_prefix" -ge 1 ] && [ "$cidr_prefix" -le 32 ] || return 1
	cidr_address=$(configuration_normalize_ipv4 "$cidr_address") || return 1
	cidr_uint=$(configuration_ipv4_to_uint "$cidr_address") || return 1
	cidr_block=$(awk -v prefix="$cidr_prefix" 'BEGIN { printf "%.0f\n", 2 ^ (32 - prefix) }')
	cidr_network=$(awk -v value="$cidr_uint" -v block="$cidr_block" \
		'BEGIN { printf "%.0f\n", int(value / block) * block }')
	[ "$cidr_uint" = "$cidr_network" ] || return 1
	printf '%s/%s\n' "$cidr_address" "$cidr_prefix"
}

configuration_ipv4_is_safe_listener() {
	listener_address=$(configuration_normalize_ipv4 "$1") || return 1
	listener_uint=$(configuration_ipv4_to_uint "$listener_address") || return 1
	[ "$listener_uint" -ne 0 ] &&
		{ [ "$listener_uint" -lt 2130706432 ] || [ "$listener_uint" -gt 2147483647 ]; } &&
		[ "$listener_uint" -lt 3758096384 ] && [ "$listener_uint" -ne 4294967295 ]
}

configuration_cidr_is_safe_source() {
	trusted_cidr=$(configuration_normalize_cidr "$1") || return 1
	trusted_network=${trusted_cidr%/*}
	trusted_prefix=${trusted_cidr##*/}
	trusted_start=$(configuration_ipv4_to_uint "$trusted_network") || return 1
	trusted_size=$(awk -v prefix="$trusted_prefix" 'BEGIN { printf "%.0f\n", 2 ^ (32 - prefix) }')
	trusted_end=$(awk -v start="$trusted_start" -v size="$trusted_size" \
		'BEGIN { printf "%.0f\n", start + size - 1 }')
	# Reject scopes that overlap unspecified, loopback, multicast, or limited broadcast space.
	[ "$trusted_start" -gt 16777215 ] || return 1
	[ "$trusted_end" -lt 2130706432 ] || [ "$trusted_start" -gt 2147483647 ] || return 1
	[ "$trusted_end" -lt 3758096384 ] || return 1
}

configuration_netmask_prefix() {
	netmask_value=$(configuration_normalize_ipv4 "$1") || return 1
	awk -F . 'BEGIN {
		bits[255] = 8; bits[254] = 7; bits[252] = 6; bits[248] = 5; bits[240] = 4
		bits[224] = 3; bits[192] = 2; bits[128] = 1; bits[0] = 0
	}
	{
		prefix = 0; partial = 0
		for (i = 1; i <= 4; i++) {
			if (!(($i + 0) in bits)) exit 1
			if (partial && $i != 0) exit 1
			prefix += bits[$i + 0]
			if ($i != 255) partial = 1
		}
		if (prefix < 1 || prefix > 32) exit 1
		print prefix
	}' <<EOF
$netmask_value
EOF
}

configuration_network_cidr() {
	network_address=$(configuration_normalize_ipv4 "$1") || return 1
	network_prefix=$2
	case $network_prefix in
		'' | *[!0-9]*) return 1 ;;
	esac
	[ "$network_prefix" -ge 1 ] && [ "$network_prefix" -le 32 ] || return 1
	network_uint=$(configuration_ipv4_to_uint "$network_address") || return 1
	network_block=$(awk -v prefix="$network_prefix" 'BEGIN { printf "%.0f\n", 2 ^ (32 - prefix) }')
	network_start=$(awk -v value="$network_uint" -v block="$network_block" \
		'BEGIN { printf "%.0f\n", int(value / block) * block }')
	printf '%s/%s\n' "$(configuration_uint_to_ipv4 "$network_start")" "$network_prefix"
}

configuration_render_dummy() {
	candidate_root=$1
	set_id=$2
	code_root=$3
	runtime_root=$4

	printf 'schema\tnutmerlin.model.v1\nsource\tdummy\nset_id\t%s\n' "$set_id" >"$candidate_root/model.tsv"
	{
		printf 'statepath = %s/state\n\n' "$runtime_root"
		printf '%s\n' '[dummy]'
		printf '\tdriver = dummy-ups\n'
		printf '\tport = %s/share/dummy/cyberpower.dev\n' "$code_root"
		printf '\tmode = dummy-once\n'
	} >"$candidate_root/ups.conf"
	{
		printf 'STATEPATH %s/state\n' "$runtime_root"
		printf '%s\n' 'LISTEN 127.0.0.1 3493'
	} >"$candidate_root/upsd.conf"
	: >"$candidate_root/upsd.users"
	chmod 600 "$candidate_root/model.tsv" "$candidate_root/ups.conf" \
		"$candidate_root/upsd.conf" "$candidate_root/upsd.users"
	(
		cd "$candidate_root" || exit
		sha256sum model.tsv ups.conf upsd.conf upsd.users >SHA256SUMS
	)
	chmod 600 "$candidate_root/SHA256SUMS"
}

configuration_render_usbhid() {
	candidate_root=$1
	set_id=$2
	runtime_root=$3
	vendor_id=$4
	product_id=$5
	identity_kind=$6
	identity_value=$7
	lan_address=${8:--}
	lan_cidr=${9:--}

	printf 'schema\tnutmerlin.model.v1\nsource\tups\nset_id\t%s\nvendor_id\t%s\nproduct_id\t%s\nidentity\t%s\nidentity_value\t%s\n' \
		"$set_id" "$vendor_id" "$product_id" "$identity_kind" "$identity_value" \
		>"$candidate_root/model.tsv"
	if [ "$lan_address" != - ] || [ "$lan_cidr" != - ]; then
		[ "$lan_address" != - ] && [ "$lan_cidr" != - ] || return 78
		printf 'lan_address\t%s\nlan_cidr\t%s\n' "$lan_address" "$lan_cidr" \
			>>"$candidate_root/model.tsv"
	fi
	{
		printf 'statepath = %s/state\n\n' "$runtime_root"
		printf '%s\n' '[ups]'
		printf '\tdriver = usbhid-ups\n\tport = auto\n'
		printf '\tvendorid = ^%s$\n' "$vendor_id"
		printf '\tproductid = ^%s$\n' "$product_id"
		case $identity_kind in
			serial)
				identity_pattern=$(printf '%s\n' "$identity_value" | sed 's/[.+]/\\&/g')
				printf '\tserial = ^%s$\n' "$identity_pattern"
				;;
			busport) printf '\tbusport = ^%s$\n' "$identity_value" ;;
			*) return 78 ;;
		esac
	} >"$candidate_root/ups.conf"
	{
		printf 'STATEPATH %s/state\n' "$runtime_root"
		printf '%s\n' 'LISTEN 127.0.0.1 3493'
		[ "$lan_address" = - ] || printf 'LISTEN %s 3493\n' "$lan_address"
	} >"$candidate_root/upsd.conf"
	: >"$candidate_root/upsd.users"
	chmod 600 "$candidate_root/model.tsv" "$candidate_root/ups.conf" \
		"$candidate_root/upsd.conf" "$candidate_root/upsd.users"
	(
		cd "$candidate_root" || exit
		sha256sum model.tsv ups.conf upsd.conf upsd.users >SHA256SUMS
	)
	chmod 600 "$candidate_root/SHA256SUMS"
}

configuration_model_value() {
	model_path=$1
	model_line=$2
	model_key=$3
	awk -F '\t' -v expected_line="$model_line" -v expected_key="$model_key" '
		NR == expected_line && NF == 2 && $1 == expected_key { print $2; found++ }
		END { if (found != 1) exit 1 }
	' "$model_path"
}

configuration_read_model() {
	model_set_root=$1
	model_expected_set_id=$2
	model_path=$model_set_root/model.tsv
	[ "$(configuration_model_value "$model_path" 1 schema)" = nutmerlin.model.v1 ] || return 1
	CONFIGURATION_SOURCE=$(configuration_model_value "$model_path" 2 source) || return 1
	CONFIGURATION_SET_ID=$(configuration_model_value "$model_path" 3 set_id) || return 1
	[ "$CONFIGURATION_SET_ID" = "$model_expected_set_id" ] || return 1
	case $CONFIGURATION_SOURCE in
		dummy)
			[ "$(wc -l <"$model_path")" -eq 3 ] || return 1
			CONFIGURATION_VENDOR_ID=
			CONFIGURATION_PRODUCT_ID=
			CONFIGURATION_IDENTITY_KIND=simulation
			CONFIGURATION_IDENTITY_VALUE=
			;;
		ups)
			model_line_count=$(wc -l <"$model_path")
			case $model_line_count in
				7)
					CONFIGURATION_LAN_ADDRESS=-
					CONFIGURATION_LAN_CIDR=-
					;;
				9)
					CONFIGURATION_LAN_ADDRESS=$(configuration_model_value "$model_path" 8 lan_address) || return 1
					CONFIGURATION_LAN_CIDR=$(configuration_model_value "$model_path" 9 lan_cidr) || return 1
					[ "$(configuration_normalize_ipv4 "$CONFIGURATION_LAN_ADDRESS" 2>/dev/null || :)" = \
						"$CONFIGURATION_LAN_ADDRESS" ] || return 1
					configuration_ipv4_is_safe_listener "$CONFIGURATION_LAN_ADDRESS" || return 1
					[ "$(configuration_normalize_cidr "$CONFIGURATION_LAN_CIDR" 2>/dev/null || :)" = \
						"$CONFIGURATION_LAN_CIDR" ] || return 1
					configuration_cidr_is_safe_source "$CONFIGURATION_LAN_CIDR" || return 1
					;;
				*) return 1 ;;
			esac
			CONFIGURATION_VENDOR_ID=$(configuration_model_value "$model_path" 4 vendor_id) || return 1
			CONFIGURATION_PRODUCT_ID=$(configuration_model_value "$model_path" 5 product_id) || return 1
			CONFIGURATION_IDENTITY_KIND=$(configuration_model_value "$model_path" 6 identity) || return 1
			CONFIGURATION_IDENTITY_VALUE=$(configuration_model_value "$model_path" 7 identity_value) || return 1
			[ "$(configuration_normalize_usb_id "$CONFIGURATION_VENDOR_ID" 2>/dev/null || :)" = \
				"$CONFIGURATION_VENDOR_ID" ] || return 1
			[ "$(configuration_normalize_usb_id "$CONFIGURATION_PRODUCT_ID" 2>/dev/null || :)" = \
				"$CONFIGURATION_PRODUCT_ID" ] || return 1
			case $CONFIGURATION_IDENTITY_KIND in
				serial) configuration_serial_is_valid "$CONFIGURATION_IDENTITY_VALUE" || return 1 ;;
				busport)
					[ "$(configuration_normalize_busport "$CONFIGURATION_IDENTITY_VALUE" 2>/dev/null || :)" = \
						"$CONFIGURATION_IDENTITY_VALUE" ] || return 1
					;;
				*) return 1 ;;
			esac
			;;
		*) return 1 ;;
	esac
	if [ "$CONFIGURATION_SOURCE" = dummy ]; then
		CONFIGURATION_LAN_ADDRESS=-
		CONFIGURATION_LAN_CIDR=-
	fi
	export CONFIGURATION_SOURCE CONFIGURATION_SET_ID CONFIGURATION_VENDOR_ID
	export CONFIGURATION_PRODUCT_ID CONFIGURATION_IDENTITY_KIND CONFIGURATION_IDENTITY_VALUE
	export CONFIGURATION_LAN_ADDRESS CONFIGURATION_LAN_CIDR
}

configuration_validate_set() {
	validated_set_root=$1
	validated_set_uid=$(id -u)
	[ -d "$validated_set_root" ] && [ ! -L "$validated_set_root" ] || return 1
	[ "$(stat -c '%a' "$validated_set_root")" = 700 ] || return 1
	[ "$(stat -c '%u' "$validated_set_root")" = "$validated_set_uid" ] || return 1
	[ "$(find "$validated_set_root" -mindepth 1 -maxdepth 1 | wc -l)" -eq 5 ] || return 1
	for set_file in model.tsv ups.conf upsd.conf upsd.users SHA256SUMS; do
		[ -f "$validated_set_root/$set_file" ] && [ ! -L "$validated_set_root/$set_file" ] || return 1
		[ "$(stat -c '%a' "$validated_set_root/$set_file")" = 600 ] || return 1
		[ "$(stat -c '%h' "$validated_set_root/$set_file")" = 1 ] || return 1
		[ "$(stat -c '%u' "$validated_set_root/$set_file")" = "$validated_set_uid" ] || return 1
	done
	validated_set_id=${validated_set_root##*/}
	case $validated_set_id in
		.candidate-*) validated_set_id=${validated_set_id#.candidate-} ;;
	esac
	case $validated_set_id in
		????????????????????????????????) ;;
		*) return 1 ;;
	esac
	case $validated_set_id in
		*[!0-9a-f]*) return 1 ;;
	esac
	configuration_read_model "$validated_set_root" "$validated_set_id" || return 1
	validated_source=$CONFIGURATION_SOURCE
	validated_vendor_id=$CONFIGURATION_VENDOR_ID
	validated_product_id=$CONFIGURATION_PRODUCT_ID
	validated_identity_kind=$CONFIGURATION_IDENTITY_KIND
	validated_identity_value=$CONFIGURATION_IDENTITY_VALUE
	validated_lan_address=$CONFIGURATION_LAN_ADDRESS
	validated_lan_cidr=$CONFIGURATION_LAN_CIDR
	(
		umask 077
		validation_scratch=$(mktemp -d "$NUTMERLIN_TMP_ROOT/.nutmerlin-config-check.XXXXXX") || exit 1
		trap 'rm -rf -- "$validation_scratch"' EXIT HUP INT TERM
		case $validated_source in
			dummy)
				configuration_render_dummy "$validation_scratch" "$validated_set_id" \
					"$NUTMERLIN_JFFS_ROOT/addons/nutmerlin" "$NUTMERLIN_TMP_ROOT/nutmerlin"
				;;
			ups)
				configuration_render_usbhid "$validation_scratch" "$validated_set_id" \
					"$NUTMERLIN_TMP_ROOT/nutmerlin" "$validated_vendor_id" "$validated_product_id" \
					"$validated_identity_kind" "$validated_identity_value" \
					"$validated_lan_address" "$validated_lan_cidr"
				;;
			*) exit 1 ;;
		esac
		for validated_file in model.tsv ups.conf upsd.conf upsd.users SHA256SUMS; do
			cmp -s "$validation_scratch/$validated_file" "$validated_set_root/$validated_file" || exit 1
		done
	)
}

configuration_create_initial() {
	config_candidate=$1
	code_root=$2
	runtime_root=$3
	set_id=$(configuration_random_id)
	sets_root=$config_candidate/config/sets
	candidate_root=$sets_root/.candidate-$set_id
	set_root=$sets_root/$set_id

	mkdir -p "$sets_root"
	chmod 700 "$config_candidate/config" "$sets_root"
	mkdir -m 700 "$candidate_root"
	configuration_render_dummy "$candidate_root" "$set_id" "$code_root" "$runtime_root"
	configuration_validate_set "$candidate_root" || return 70
	mv "$candidate_root" "$set_root"
	printf '%s\n' "$set_id" >"$config_candidate/config/current.new"
	chmod 600 "$config_candidate/config/current.new"
	mv "$config_candidate/config/current.new" "$config_candidate/config/current"
}

configuration_describe_current_source() {
	description_config_root=$NUTMERLIN_OPT_ROOT/etc/nutmerlin/config
	description_current_path=$description_config_root/current
	if [ ! -f "$description_current_path" ] || [ -L "$description_current_path" ]; then
		printf '%s\n' 'source unavailable: current configuration selector is missing' >&2
		return 69
	fi
	description_set_id=$(cat "$description_current_path" 2>/dev/null || :)
	service_id_is_valid "$description_set_id" || {
		printf '%s\n' 'source refused: current configuration selector is invalid' >&2
		return 78
	}
	description_set_root=$description_config_root/sets/$description_set_id
	configuration_validate_set "$description_set_root" || {
		printf '%s\n' 'source refused: current configuration set is invalid' >&2
		return 78
	}
	configuration_read_model "$description_set_root" "$description_set_id" || {
		printf '%s\n' 'source refused: current source model is invalid' >&2
		return 78
	}
	case $CONFIGURATION_SOURCE in
		dummy) SOURCE_MESSAGE='active source is dummy; identity=simulation' ;;
		ups)
			if [ "$CONFIGURATION_IDENTITY_KIND" = serial ]; then
				description_identity_value=redacted
			else
				description_identity_value=$CONFIGURATION_IDENTITY_VALUE
			fi
			SOURCE_MESSAGE="active source is ups; vendor_id=$CONFIGURATION_VENDOR_ID product_id=$CONFIGURATION_PRODUCT_ID identity=$CONFIGURATION_IDENTITY_KIND value=$description_identity_value"
			;;
		*) return 78 ;;
	esac
	export SOURCE_MESSAGE
}

configuration_usb_record_is_valid() {
	usb_record_id=$1
	usb_record_vendor=$2
	usb_record_product=$3
	usb_record_serial=$4
	usb_record_busport=$5
	usb_record_bus=$6
	usb_record_device=$7
	[ -n "$usb_record_id" ] && [ "${#usb_record_id}" -le 64 ] || return 1
	case $usb_record_id in
		*[!A-Za-z0-9._:-]*) return 1 ;;
	esac
	[ "$(configuration_normalize_usb_id "$usb_record_vendor" 2>/dev/null || :)" = \
		"$usb_record_vendor" ] || return 1
	[ "$(configuration_normalize_usb_id "$usb_record_product" 2>/dev/null || :)" = \
		"$usb_record_product" ] || return 1
	if [ "$usb_record_serial" != - ]; then
		configuration_serial_is_valid "$usb_record_serial" || return 1
	fi
	if [ "$usb_record_busport" != - ]; then
		[ "$(configuration_normalize_busport "$usb_record_busport" 2>/dev/null || :)" = \
			"$usb_record_busport" ] || return 1
	fi
	for usb_logical_value in "$usb_record_bus" "$usb_record_device"; do
		[ "$usb_logical_value" = - ] && continue
		[ "${#usb_logical_value}" -eq 3 ] || return 1
		case $usb_logical_value in
			*[!0-9]*) return 1 ;;
		esac
	done
}

configuration_resolve_usb_identity() (
	resolve_vendor_id=$1
	resolve_product_id=$2
	resolve_identity_kind=$3
	resolve_identity_value=$4
	resolve_snapshot=$(mktemp "$NUTMERLIN_TMP_ROOT/.nutmerlin-usb-snapshot.XXXXXX") || return 75
	trap 'rm -f -- "$resolve_snapshot"' EXIT HUP INT TERM
	platform_usb_snapshot >"$resolve_snapshot" || {
		resolve_status=$?
		printf '%s\n' 'source unavailable: USB discovery could not be read safely' >&2
		rm -f -- "$resolve_snapshot"
		trap - EXIT HUP INT TERM
		return "$resolve_status"
	}
	resolve_count=0
	resolve_compatible_count=0
	resolve_match_count=0
	resolve_incomplete_count=0
	resolve_result=0
	resolve_tab=$(printf '\t')
	while IFS=$resolve_tab read -r resolve_device_id resolve_vendor resolve_product \
		resolve_serial resolve_busport resolve_bus resolve_device resolve_extra; do
		[ -n "$resolve_device_id" ] || continue
		resolve_count=$((resolve_count + 1))
		if [ "$resolve_count" -gt 64 ]; then
			printf '%s\n' 'source refused: USB discovery inventory exceeds 64 devices' >&2
			resolve_result=78
			break
		fi
		if [ -n "$resolve_extra" ] || ! configuration_usb_record_is_valid "$resolve_device_id" \
			"$resolve_vendor" "$resolve_product" "$resolve_serial" "$resolve_busport" \
			"$resolve_bus" "$resolve_device"; then
			printf '%s\n' 'source refused: USB discovery returned an invalid record' >&2
			resolve_result=78
			break
		fi
		if [ "$resolve_vendor" != "$resolve_vendor_id" ] ||
			[ "$resolve_product" != "$resolve_product_id" ]; then
			continue
		fi
		resolve_compatible_count=$((resolve_compatible_count + 1))
		if [ "$resolve_identity_kind" = serial ]; then
			resolve_observed_identity=$resolve_serial
		else
			resolve_observed_identity=$resolve_busport
		fi
		if [ "$resolve_observed_identity" = - ]; then
			resolve_incomplete_count=$((resolve_incomplete_count + 1))
		elif [ "$resolve_observed_identity" = "$resolve_identity_value" ]; then
			resolve_match_count=$((resolve_match_count + 1))
		fi
	done <"$resolve_snapshot"
	rm -f -- "$resolve_snapshot"
	trap - EXIT HUP INT TERM
	[ "$resolve_result" -eq 0 ] || return "$resolve_result"
	if [ "$resolve_match_count" -eq 1 ]; then
		return 0
	fi
	if [ "$resolve_match_count" -gt 1 ]; then
		printf 'source refused: configured %s identity matches multiple USB devices\n' \
			"$resolve_identity_kind" >&2
		return 78
	fi
	if [ "$resolve_compatible_count" -eq 0 ]; then
		printf '%s\n' 'source unavailable: no USB device matches the configured vendor/product' >&2
	elif [ "$resolve_incomplete_count" -gt 0 ]; then
		printf 'source unavailable: matching USB device has no stable %s identity\n' \
			"$resolve_identity_kind" >&2
	else
		printf 'source unavailable: configured %s identity did not match\n' \
			"$resolve_identity_kind" >&2
	fi
	return 69
)

configuration_select_set() {
	selector_root=$1
	selector_name=$2
	selected_set_id=$3
	configuration_random_id_is_valid=$selected_set_id
	case $configuration_random_id_is_valid in
		????????????????????????????????) ;;
		*) return 78 ;;
	esac
	case $configuration_random_id_is_valid in
		*[!0-9a-f]*) return 78 ;;
	esac
	selector_candidate=$selector_root/$selector_name.new
	if [ -e "$selector_candidate" ] || [ -L "$selector_candidate" ]; then
		return 78
	fi
	(umask 077 && printf '%s\n' "$selected_set_id" >"$selector_candidate")
	chmod 600 "$selector_candidate"
	mv "$selector_candidate" "$selector_root/$selector_name"
}

configuration_remove_set() {
	remove_sets_root=$1
	remove_set_id=$2
	case $remove_set_id in
		????????????????????????????????) ;;
		*) return 78 ;;
	esac
	case $remove_set_id in
		*[!0-9a-f]*) return 78 ;;
	esac
	if [ "${NUTMERLIN_ENABLE_TEST_ADAPTERS:-0}" = 1 ] &&
		[ "${NUTMERLIN_TEST_REMOVE_SET_FAIL_ID:-}" = "$remove_set_id" ]; then
		return 75
	fi
	remove_set_root=$remove_sets_root/$remove_set_id
	[ ! -e "$remove_set_root" ] || rm -rf -- "$remove_set_root"
}

configuration_remove_selector() {
	remove_selector_root=$1
	remove_selector_name=$2
	case $remove_selector_name in
		last-good) ;;
		*) return 78 ;;
	esac
	remove_selector_path=$remove_selector_root/$remove_selector_name
	if [ ! -e "$remove_selector_path" ] && [ ! -L "$remove_selector_path" ]; then
		return 0
	fi
	[ -f "$remove_selector_path" ] && [ ! -L "$remove_selector_path" ] || return 78
	[ "$(stat -c '%a' "$remove_selector_path")" = 600 ] || return 78
	[ "$(stat -c '%h' "$remove_selector_path")" = 1 ] || return 78
	[ "$(stat -c '%u' "$remove_selector_path")" = "$(id -u)" ] || return 78
	rm -f -- "$remove_selector_path"
}

configuration_finalize_real_over_dummy() {
	finalize_config_root=$1
	finalize_sets_root=$2
	finalize_previous_id=$3
	finalize_old_last_good=$4
	configuration_remove_selector "$finalize_config_root" last-good || return $?
	configuration_remove_set "$finalize_sets_root" "$finalize_previous_id" || return $?
	if [ -n "$finalize_old_last_good" ] &&
		[ "$finalize_old_last_good" != "$finalize_previous_id" ]; then
		configuration_remove_set "$finalize_sets_root" "$finalize_old_last_good" || return $?
	fi
}

configuration_activate_profile() {
	activation_profile=$1
	activation_vendor_id=${2:-}
	activation_product_id=${3:-}
	activation_identity_kind=${4:-}
	activation_identity_value=${5:-}
	activation_lan_address=${6:--}
	activation_lan_cidr=${7:--}
	activation_fallback=allow
	activation_config_root=$NUTMERLIN_OPT_ROOT/etc/nutmerlin/config
	activation_sets_root=$activation_config_root/sets
	activation_code_root=$NUTMERLIN_JFFS_ROOT/addons/nutmerlin
	activation_runtime_root=$NUTMERLIN_TMP_ROOT/nutmerlin
	activation_previous_id=$(cat "$activation_config_root/current")
	configuration_read_model "$activation_sets_root/$activation_previous_id" \
		"$activation_previous_id" || return 78
	activation_previous_source=$CONFIGURATION_SOURCE
	activation_previous_lan_address=$CONFIGURATION_LAN_ADDRESS
	activation_previous_lan_cidr=$CONFIGURATION_LAN_CIDR
	if [ "$activation_previous_lan_address" != - ]; then
		if [ "$activation_lan_address" = - ] ||
			[ "$activation_lan_address" != "$activation_previous_lan_address" ] ||
			[ "$activation_lan_cidr" != "$activation_previous_lan_cidr" ]; then
			activation_fallback=discard
		fi
	fi
	activation_old_last_good=
	if [ -f "$activation_config_root/last-good" ]; then
		activation_old_last_good=$(cat "$activation_config_root/last-good")
	fi
	activation_new_id=$(configuration_random_id)
	activation_candidate_root=$activation_sets_root/.candidate-$activation_new_id
	activation_new_root=$activation_sets_root/$activation_new_id

	mkdir -m 700 "$activation_candidate_root"
	case $activation_profile in
		dummy)
			configuration_render_dummy "$activation_candidate_root" "$activation_new_id" \
				"$activation_code_root" "$activation_runtime_root"
			;;
		ups)
			configuration_render_usbhid "$activation_candidate_root" "$activation_new_id" \
				"$activation_runtime_root" "$activation_vendor_id" "$activation_product_id" \
				"$activation_identity_kind" "$activation_identity_value" \
				"$activation_lan_address" "$activation_lan_cidr"
			;;
		*) return 78 ;;
	esac
	configuration_validate_set "$activation_candidate_root" || {
		rm -rf -- "$activation_candidate_root"
		return 70
	}
	mv "$activation_candidate_root" "$activation_new_root"
	activation_enabled=$(cat "$activation_code_root/enabled" 2>/dev/null || :)
	if ! service_stop; then
		configuration_remove_set "$activation_sets_root" "$activation_new_id" || {
			printf '%s\n' 'configuration activation failed: candidate cleanup failed' >&2
			return 75
		}
		printf '%s\n' 'configuration activation failed: existing service could not be stopped safely' >&2
		return 75
	fi
	if ! configuration_select_set "$activation_config_root" current "$activation_new_id"; then
		configuration_remove_set "$activation_sets_root" "$activation_new_id" || {
			printf '%s\n' 'configuration activation failed: candidate cleanup failed' >&2
			return 75
		}
		[ "$activation_enabled" != 1 ] || service_start || :
		return 78
	fi

	if [ "$activation_enabled" = 1 ]; then
		if ! service_start; then
			unset NUTMERLIN_TEST_ACTIVATION_FAIL
			if [ "$activation_fallback" = discard ]; then
				configuration_remove_selector "$activation_config_root" last-good || return $?
				configuration_remove_set "$activation_sets_root" "$activation_previous_id" || return $?
				if [ -n "$activation_old_last_good" ] &&
					[ "$activation_old_last_good" != "$activation_previous_id" ]; then
					configuration_remove_set "$activation_sets_root" "$activation_old_last_good" || return $?
				fi
				printf '%s\n' \
					'configuration activation failed: safer LAN selection remains active and stopped' >&2
				return 75
			fi
			if [ "$activation_profile" = ups ] && [ "$activation_previous_source" = dummy ]; then
				configuration_finalize_real_over_dummy "$activation_config_root" \
					"$activation_sets_root" "$activation_previous_id" \
					"$activation_old_last_good" || {
					printf '%s\n' \
						'configuration activation failed: ups selected but obsolete-set cleanup failed' >&2
					return 75
				}
				printf '%s\n' \
					'configuration activation failed: ups remains selected and unavailable' >&2
				return 75
			fi
			configuration_select_set "$activation_config_root" current "$activation_previous_id"
			configuration_remove_set "$activation_sets_root" "$activation_new_id" || {
				printf '%s\n' 'configuration activation failed: candidate cleanup failed' >&2
				return 75
			}
			service_start || :
			printf '%s\n' 'configuration activation failed: previous set restored once' >&2
			return 75
		fi
	fi

	if [ "$activation_fallback" = discard ]; then
		configuration_remove_selector "$activation_config_root" last-good || return $?
		configuration_remove_set "$activation_sets_root" "$activation_previous_id" || return $?
		if [ -n "$activation_old_last_good" ] &&
			[ "$activation_old_last_good" != "$activation_previous_id" ]; then
			configuration_remove_set "$activation_sets_root" "$activation_old_last_good" || return $?
		fi
	elif [ "$activation_profile" = ups ] && [ "$activation_previous_source" = dummy ]; then
		if ! configuration_finalize_real_over_dummy "$activation_config_root" \
			"$activation_sets_root" "$activation_previous_id" "$activation_old_last_good"; then
			service_stop || :
			printf '%s\n' \
				'configuration activation failed: ups selected but obsolete-set cleanup failed' >&2
			return 75
		fi
	elif ! configuration_select_set "$activation_config_root" last-good "$activation_previous_id"; then
		configuration_select_set "$activation_config_root" current "$activation_previous_id" || :
		if [ "$activation_enabled" = 1 ]; then
			service_restart || :
		else
			service_stop || :
		fi
		configuration_remove_set "$activation_sets_root" "$activation_new_id" || {
			service_stop || :
			printf '%s\n' 'configuration activation failed: candidate cleanup failed' >&2
			return 75
		}
		printf '%s\n' 'configuration activation failed: last-good selector was not replaced' >&2
		return 75
	fi
	if [ -n "$activation_old_last_good" ] &&
		[ "$activation_old_last_good" != "$activation_previous_id" ] &&
		[ "$activation_old_last_good" != "$activation_new_id" ]; then
		configuration_remove_set "$activation_sets_root" "$activation_old_last_good" || {
			[ "$activation_enabled" != 1 ] || service_stop || :
			printf '%s\n' 'configuration activation failed: obsolete-set cleanup failed' >&2
			return 75
		}
	fi
	case $activation_profile:$activation_enabled in
		dummy:1) SOURCE_MESSAGE='dummy configuration activated on loopback' ;;
		dummy:*) SOURCE_MESSAGE='dummy source selected while service is disabled' ;;
		ups:1) SOURCE_MESSAGE="usbhid source activated on loopback; identity=$activation_identity_kind" ;;
		ups:*) SOURCE_MESSAGE="usbhid source selected while service is disabled; identity=$activation_identity_kind" ;;
	esac
	export SOURCE_MESSAGE
}

configuration_activate_dummy() {
	configuration_activate_profile dummy
}

configuration_activate_usbhid() {
	configuration_resolve_usb_identity "$1" "$2" "$3" "$4" || return $?
	configuration_activate_profile ups "$1" "$2" "$3" "$4"
}

configuration_activate_lan() {
	lan_activation_action=$1
	lan_activation_address=${2:--}
	lan_activation_cidr=${3:--}
	service_resolve_current || return $?
	service_load_active_profile || return $?
	[ "$SERVICE_SOURCE" = ups ] || return 69
	case $lan_activation_action in
		configure)
			platform_validate_lan_scope "$lan_activation_address" "$lan_activation_cidr" || return $?
			configuration_resolve_usb_identity "$CONFIGURATION_VENDOR_ID" \
				"$CONFIGURATION_PRODUCT_ID" "$CONFIGURATION_IDENTITY_KIND" \
				"$CONFIGURATION_IDENTITY_VALUE" || return $?
			;;
		disable)
			lan_activation_address=-
			lan_activation_cidr=-
			;;
		*) return 64 ;;
	esac
	configuration_activate_profile ups "$CONFIGURATION_VENDOR_ID" "$CONFIGURATION_PRODUCT_ID" \
		"$CONFIGURATION_IDENTITY_KIND" "$CONFIGURATION_IDENTITY_VALUE" \
		"$lan_activation_address" "$lan_activation_cidr" || return $?
	activation_enabled=$(cat "$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/enabled" 2>/dev/null || :)
	case $lan_activation_action:$activation_enabled in
		configure:1)
			LAN_MESSAGE="trusted LAN active; address=$lan_activation_address cidr=$lan_activation_cidr"
			;;
		configure:*)
			LAN_MESSAGE="trusted LAN configured while service is disabled; address=$lan_activation_address cidr=$lan_activation_cidr"
			;;
		disable:1) LAN_MESSAGE='trusted LAN disabled; service is loopback-only' ;;
		disable:*) LAN_MESSAGE='trusted LAN disabled while service is disabled' ;;
	esac
	export LAN_MESSAGE
}
