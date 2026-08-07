#!/bin/sh

menu_confirm() {
	menu_confirmation_prompt=$1
	printf '%s' "$menu_confirmation_prompt [y/N] "
	menu_confirmation=
	IFS= read -r menu_confirmation || return 1
	if [ "${#menu_confirmation}" -gt 3 ]; then
		printf '%s\n' 'Confirmation input is invalid; action cancelled' >&2
		return 1
	fi
	case $menu_confirmation in
		*[![:print:]]*)
			printf '%s\n' 'Confirmation input is invalid; action cancelled' >&2
			return 1
			;;
	esac
	case $menu_confirmation in
		y | Y | yes | YES | Yes) return 0 ;;
		*) return 1 ;;
	esac
}

menu_invoke_cli() {
	if "$menu_installed_cli" "$@"; then
		return 0
	else
		menu_cli_status=$?
		printf 'Command did not complete; exit=%s\n' "$menu_cli_status" >&2
		return 0
	fi
}

menu_read_value() {
	menu_value_prompt=$1
	menu_value_maximum=$2
	printf '%s' "$menu_value_prompt: "
	MENU_INPUT=
	if ! IFS= read -r MENU_INPUT; then
		printf '\n%s\n' 'Input ended; action cancelled' >&2
		return 1
	fi
	if [ -z "$MENU_INPUT" ] || [ "${#MENU_INPUT}" -gt "$menu_value_maximum" ]; then
		printf 'Input must contain 1-%s characters\n' "$menu_value_maximum" >&2
		return 1
	fi
	case $MENU_INPUT in
		*[![:print:]]*)
			printf '%s\n' 'Input contains unsupported characters' >&2
			return 1
			;;
	esac
}

menu_detect_installation_state() {
	menu_code_root=$NUTMERLIN_JFFS_ROOT/addons/nutmerlin
	menu_config_root=$NUTMERLIN_OPT_ROOT/etc/nutmerlin
	if [ ! -e "$menu_code_root" ] && [ ! -L "$menu_code_root" ] &&
		[ ! -e "$menu_config_root" ] && [ ! -L "$menu_config_root" ]; then
		MENU_INSTALLATION_STATE=absent
	elif ownership_verify_installed_state; then
		MENU_INSTALLATION_STATE=owned
	else
		MENU_INSTALLATION_STATE=unverified
	fi
}

menu_print_installed_choices() {
	printf '%s\n' \
		'1) Status' \
		'2) Diagnostics' \
		'3) Start service' \
		'4) Stop service' \
		'5) Restart service' \
		'6) Use dummy source' \
		'7) Configure physical UPS source' \
		'8) Configure trusted LAN' \
		'9) Disable trusted LAN' \
		'10) Add secondary client' \
		'11) Revoke secondary client' \
		'12) Enable NUTMerlin' \
		'13) Disable NUTMerlin' \
		'14) Repair owned state' \
		'15) Update from local archive' \
		'16) Refresh required Entware NUT packages' \
		'17) Uninstall' \
		'q) Quit'
}

menu_run() {
	MENU_PACKAGE_ROOT=$1
	MENU_STARTED_INSTALLED=$2
	if [ "${NUTMERLIN_ENABLE_TEST_ADAPTERS:-0}" != 1 ] &&
		{ [ ! -t 0 ] || [ ! -t 1 ]; }; then
		printf '%s\n' 'menu refused: an interactive local terminal is required' >&2
		return 64
	fi
	menu_version=$(cat "$MENU_PACKAGE_ROOT/VERSION" 2>/dev/null || printf '%s' unknown)
	menu_installed_cli=$NUTMERLIN_JFFS_ROOT/addons/nutmerlin/bin/nutmerlin
	while :; do
		printf '\nNUTMerlin %s\n' "$menu_version"
		menu_detect_installation_state
		if [ "$MENU_INSTALLATION_STATE" = owned ]; then
			menu_state_installed=1
			printf '%s\n' 'State: installed'
			printf '%s' 'Current: '
			"$menu_installed_cli" status || :
			menu_print_installed_choices
		elif [ "$MENU_INSTALLATION_STATE" = absent ]; then
			menu_state_installed=0
			printf '%s\n' 'State: not installed'
			if [ "$MENU_STARTED_INSTALLED" -eq 0 ] && [ -x "$MENU_PACKAGE_ROOT/install.sh" ]; then
				printf '%s\n' 'i) Install NUTMerlin'
			fi
			printf '%s\n' 'q) Quit'
		else
			menu_state_installed=0
			printf '%s\n' 'State: unavailable; installed ownership could not be verified'
			printf '%s\n' 'q) Quit'
		fi
		printf '%s' 'Selection: '
		menu_choice=
		if ! IFS= read -r menu_choice; then
			printf '\n%s\n' 'Menu closed; no changes were made'
			return 0
		fi
		if [ -z "$menu_choice" ] || [ "${#menu_choice}" -gt 2 ]; then
			printf '%s\n' 'Invalid selection; choose one listed item' >&2
			continue
		fi
		case $menu_choice in
			*[![:print:]]*)
				printf '%s\n' 'Invalid selection; choose one listed item' >&2
				continue
				;;
		esac
		case $menu_choice in
			q | Q | i | I) ;;
			*)
				if [ "$menu_state_installed" -eq 0 ]; then
					printf '%s\n' 'Invalid selection; choose one listed item' >&2
					continue
				fi
				;;
		esac
		case $menu_choice in
			1)
				[ -x "$menu_installed_cli" ] || {
					printf '%s\n' 'Status is unavailable before installation' >&2
					continue
				}
				menu_invoke_cli status
				;;
			2)
				[ -x "$menu_installed_cli" ] || {
					printf '%s\n' 'Diagnostics are unavailable before installation' >&2
					continue
				}
				menu_invoke_cli diagnostics
				;;
			3) menu_invoke_cli service start ;;
			4) menu_invoke_cli service stop ;;
			5) menu_invoke_cli service restart ;;
			6)
				menu_confirm 'Switch to the loopback-only dummy source?' || {
					printf '%s\n' 'Source change cancelled'
					continue
				}
				menu_invoke_cli source use-dummy
				;;
			7)
				menu_read_value 'USB vendor ID (four hexadecimal digits)' 4 || continue
				menu_vendor_id=$MENU_INPUT
				menu_read_value 'USB product ID (four hexadecimal digits)' 4 || continue
				menu_product_id=$MENU_INPUT
				menu_read_value 'Identity kind (s=serial, p=physical busport)' 1 || continue
				menu_identity_kind=$MENU_INPUT
				case $menu_identity_kind in
					s | S)
						menu_read_value 'Stable USB serial' 64 || continue
						menu_identity_option=--serial
						menu_identity_value=$MENU_INPUT
						;;
					p | P)
						menu_read_value 'Stable physical busport (1-255)' 3 || continue
						menu_identity_option=--busport
						menu_identity_value=$MENU_INPUT
						;;
					*)
						printf '%s\n' 'Identity kind must be s or p' >&2
						continue
						;;
				esac
				unset MENU_INPUT
				menu_confirm 'Configure this physical UPS source?' || {
					printf '%s\n' 'Source change cancelled'
					continue
				}
				menu_invoke_cli source configure-usbhid \
					--vendor-id "$menu_vendor_id" --product-id "$menu_product_id" \
					"$menu_identity_option" "$menu_identity_value"
				;;
			8)
				menu_read_value 'Router LAN IPv4 address' 15 || continue
				menu_lan_address=$MENU_INPUT
				menu_read_value 'Trusted IPv4 CIDR' 18 || continue
				menu_lan_cidr=$MENU_INPUT
				unset MENU_INPUT
				menu_confirm 'Configure this trusted LAN exposure?' || {
					printf '%s\n' 'Trusted LAN change cancelled'
					continue
				}
				menu_invoke_cli lan configure --address "$menu_lan_address" \
					--cidr "$menu_lan_cidr"
				;;
			9)
				menu_confirm 'Disable trusted LAN exposure?' || {
					printf '%s\n' 'Trusted LAN disable cancelled'
					continue
				}
				menu_invoke_cli lan disable
				;;
			10)
				menu_read_value 'Client label' 64 || continue
				menu_invoke_cli client add "$MENU_INPUT"
				unset MENU_INPUT
				;;
			11)
				menu_read_value 'Client ID' 32 || continue
				menu_client_id=$MENU_INPUT
				unset MENU_INPUT
				menu_confirm 'Revoke this client credential?' || {
					printf '%s\n' 'Client revocation cancelled'
					continue
				}
				menu_invoke_cli client revoke "$menu_client_id"
				;;
			12) menu_invoke_cli enable ;;
			13)
				menu_confirm 'Disable NUTMerlin?' || {
					printf '%s\n' 'Disable cancelled; no changes were made'
					continue
				}
				menu_invoke_cli disable
				;;
			14) menu_invoke_cli repair ;;
			15)
				menu_read_value 'Local update archive path' 512 || continue
				menu_update_archive=$MENU_INPUT
				unset MENU_INPUT
				menu_confirm 'Update from this local archive?' || {
					printf '%s\n' 'Update cancelled; no changes were made'
					continue
				}
				menu_invoke_cli update "$menu_update_archive"
				;;
			16) menu_invoke_cli dependencies refresh ;;
			17)
				menu_confirm \
					'Uninstall NUTMerlin and remove all owned configuration and credentials?' || {
					printf '%s\n' 'Uninstall cancelled; no changes were made'
					continue
				}
				menu_invoke_cli uninstall
				;;
			i | I)
				if [ -x "$menu_installed_cli" ] || [ "$MENU_STARTED_INSTALLED" -ne 0 ] ||
					[ ! -x "$MENU_PACKAGE_ROOT/install.sh" ]; then
					printf '%s\n' 'Install is unavailable from this menu state' >&2
					continue
				fi
				if ! menu_confirm 'Install NUTMerlin?'; then
					printf '%s\n' 'Install cancelled; no changes were made'
					continue
				fi
				if "$MENU_PACKAGE_ROOT/install.sh"; then
					:
				else
					menu_install_status=$?
					printf 'Install did not complete; exit=%s\n' "$menu_install_status" >&2
				fi
				;;
			q | Q)
				printf '%s\n' 'Menu closed; no changes were made'
				return 0
				;;
			*) printf '%s\n' 'Invalid selection; choose one listed item' >&2 ;;
		esac
	done
}
