#!/bin/sh

entware_required_packages='nut nut-common nut-server nut-upsc nut-driver-dummy-ups nut-driver-usbhid-ups'

entware_missing_guidance() {
	missing_packages=${1:-$entware_required_packages}
	printf 'Review and run separately: opkg install %s\n' "$missing_packages" >&2
}

entware_refresh_guidance() {
	printf '%s\n' 'Recovery: rerun ./install.sh --install-dependencies' >&2
	printf 'Bounded package operation: /opt/bin/opkg update; /opt/bin/opkg install %s\n' \
		"$entware_required_packages" >&2
}

entware_refresh_failure_guidance() {
	printf '%s\n' \
		'Recovery: resolve the Entware error, then rerun ./install.sh --install-dependencies' >&2
	printf 'Bounded package operation: /opt/bin/opkg update; /opt/bin/opkg install %s\n' \
		"$entware_required_packages" >&2
}

entware_check_foundation() {
	NUTMERLIN_ENTWARE_FOUNDATION_OK=0
	if [ ! -d "$NUTMERLIN_OPT_ROOT" ] || [ -L "$NUTMERLIN_OPT_ROOT" ] ||
		[ ! -w "$NUTMERLIN_OPT_ROOT" ]; then
		printf 'Entware requirements unavailable: storage is not writable: %s\n' "$NUTMERLIN_OPT_ROOT" >&2
		return 69
	fi
	entware_available_kb=$(df -Pk "$NUTMERLIN_OPT_ROOT" 2>/dev/null | awk 'NR == 2 { print $4 }')
	case $entware_available_kb in
		'' | *[!0-9]*)
			printf '%s\n' 'Entware requirements unavailable: storage free space could not be read' >&2
			return 69
			;;
	esac
	if [ "$entware_available_kb" -lt 1024 ]; then
		printf '%s\n' 'Entware requirements unavailable: at least 1 MiB of free storage is required' >&2
		return 69
	fi

	entware_status=$NUTMERLIN_OPT_ROOT/lib/opkg/status
	if [ ! -f "$entware_status" ] || [ -L "$entware_status" ] || [ ! -r "$entware_status" ]; then
		printf 'Entware requirements unavailable: missing package metadata: %s\n' "$entware_status" >&2
		entware_missing_guidance
		return 69
	fi
	opkg_bin=$NUTMERLIN_OPT_ROOT/bin/opkg
	if [ ! -f "$opkg_bin" ] || [ -L "$opkg_bin" ] || [ ! -x "$opkg_bin" ]; then
		printf 'Entware requirements unavailable: missing package manager: %s\n' "$opkg_bin" >&2
		return 69
	fi
	opkg_uid=$(stat -c '%u' "$opkg_bin" 2>/dev/null || :)
	opkg_links=$(stat -c '%h' "$opkg_bin" 2>/dev/null || :)
	opkg_mode=$(stat -c '%a' "$opkg_bin" 2>/dev/null || :)
	case $opkg_mode in
		[1357][0145][0145]) ;;
		*) opkg_mode=unsafe ;;
	esac
	if [ "$opkg_uid" != "$(id -u)" ] || [ "$opkg_links" != 1 ] || [ "$opkg_mode" = unsafe ]; then
		printf '%s\n' \
			'Entware requirements incompatible: package manager has unsafe ownership, links, or mode' >&2
		return 78
	fi
	if [ "${NUTMERLIN_ENABLE_TEST_ADAPTERS:-0}" = 1 ]; then
		entware_run_user=${NUTMERLIN_TEST_RUN_USER:-$(id -un)}
	else
		entware_run_user=nobody
	fi
	case $entware_run_user in
		'' | *[!A-Za-z0-9_-]*)
			printf '%s\n' 'Entware requirements incompatible: unprivileged NUT user is invalid' >&2
			return 78
			;;
	esac
	id "$entware_run_user" >/dev/null 2>&1 || {
		printf 'Entware requirements incompatible: unprivileged NUT user is unavailable: %s\n' "$entware_run_user" >&2
		return 78
	}
	NUTMERLIN_ENTWARE_FOUNDATION_OK=1
}

entware_input_is_interactive() {
	[ -t 0 ] || {
		[ "${NUTMERLIN_ENABLE_TEST_ADAPTERS:-0}" = 1 ] &&
			[ "${NUTMERLIN_TEST_INTERACTIVE:-0}" = 1 ]
	}
}

entware_plan_dependency_refresh() {
	dependency_install_authorized=$1
	NUTMERLIN_ENTWARE_REFRESH_AUTHORIZED=0
	initial_entware_status=0
	if entware_check; then
		:
	else
		initial_entware_status=$?
	fi
	NUTMERLIN_ENTWARE_PRE_REFRESH_RECORD=${NUTMERLIN_ENTWARE_RECORD:-unavailable}
	# An unhealthy Entware installation is not repairable through the bounded
	# NUT package operation, even when the dependency flag is present.
	if [ "${NUTMERLIN_ENTWARE_FOUNDATION_OK:-0}" != 1 ]; then
		return "$initial_entware_status"
	fi

	if [ "$dependency_install_authorized" -eq 1 ]; then
		NUTMERLIN_ENTWARE_REFRESH_AUTHORIZED=1
	elif entware_input_is_interactive; then
		printf '%s' 'Refresh the six required Entware NUT packages? [y/N] ' >&2
		dependency_answer=
		IFS= read -r dependency_answer || :
		case $dependency_answer in
			y | Y | yes | YES | Yes) NUTMERLIN_ENTWARE_REFRESH_AUTHORIZED=1 ;;
		esac
	fi

	if [ "$NUTMERLIN_ENTWARE_REFRESH_AUTHORIZED" -eq 1 ]; then
		return 0
	fi
	[ "$initial_entware_status" -eq 0 ] || entware_refresh_guidance
	return "$initial_entware_status"
}

entware_execute_dependency_refresh() {
	printf 'Entware NUT package refresh authorized for: %s\n' "$entware_required_packages"
	printf 'Entware NUT package evidence before refresh:\n%s\n' \
		"$NUTMERLIN_ENTWARE_PRE_REFRESH_RECORD"
	refresh_command_status=0
	if ! "$opkg_bin" update; then
		refresh_command_status=75
	fi
	if [ "$refresh_command_status" -eq 0 ]; then
		# shellcheck disable=SC2086 # fixed internal package roots become six arguments
		if ! "$opkg_bin" install $entware_required_packages; then
			refresh_command_status=75
		fi
	fi
	NUTMERLIN_ENTWARE_RECORD=unavailable
	post_refresh_status=0
	if entware_check; then
		:
	else
		post_refresh_status=$?
	fi
	[ -n "$NUTMERLIN_ENTWARE_RECORD" ] || NUTMERLIN_ENTWARE_RECORD=unavailable
	printf 'Entware NUT package evidence after refresh:\n%s\n' "$NUTMERLIN_ENTWARE_RECORD"
	if [ "$refresh_command_status" -ne 0 ]; then
		printf '%s\n' 'Entware package refresh failed; NUTMerlin remains disabled and stopped' >&2
		entware_refresh_failure_guidance
		return "$refresh_command_status"
	fi
	if [ "$post_refresh_status" -ne 0 ]; then
		printf '%s\n' 'Entware post-refresh compatibility failed; NUTMerlin remains disabled and stopped' >&2
		entware_refresh_failure_guidance
		return "$post_refresh_status"
	fi
	printf '%s\n' 'Entware NUT package refresh completed and compatibility was re-verified'
}

entware_package_field() {
	package_name=$1
	field_name=$2
	awk -v package_name="$package_name" -v field_name="$field_name" '
		BEGIN { RS = ""; FS = "\n" }
		{
			matched = 0
			value = ""
			for (line_number = 1; line_number <= NF; line_number++) {
				if ($line_number == "Package: " package_name) matched = 1
				if (index($line_number, field_name ": ") == 1) {
					value = substr($line_number, length(field_name) + 3)
				}
			}
			if (matched && value != "") {
				print value
				exit 0
			}
		}
		END { if (value == "") exit 1 }
	' "$entware_status"
}

entware_binary_help_contains() {
	binary_path=$1
	shift
	binary_help=$("$binary_path" -h 2>&1 || :)
	for required_help_text in "$@"; do
		printf '%s\n' "$binary_help" | grep -F -- "$required_help_text" >/dev/null || return 1
	done
}

entware_resolve_binary() {
	for binary_candidate in "$@"; do
		if [ -f "$binary_candidate" ] && [ ! -L "$binary_candidate" ] && [ -x "$binary_candidate" ]; then
			printf '%s\n' "$binary_candidate"
			return 0
		fi
	done
	return 1
}

entware_check() {
	entware_check_foundation || return $?

	missing_packages=
	package_architecture=
	NUTMERLIN_ENTWARE_RECORD=
	for required_package in $entware_required_packages; do
		package_status=$(entware_package_field "$required_package" Status 2>/dev/null || :)
		if [ "$package_status" != 'install user installed' ]; then
			missing_packages=${missing_packages:+$missing_packages }$required_package
			continue
		fi
		observed_architecture=$(entware_package_field "$required_package" Architecture 2>/dev/null || :)
		observed_version=$(entware_package_field "$required_package" Version 2>/dev/null || :)
		if [ -z "$observed_architecture" ] || [ -z "$observed_version" ]; then
			printf 'Entware requirements incompatible: package %s has no architecture metadata\n' "$required_package" >&2
			return 78
		fi
		case $observed_architecture:$observed_version in
			*[!A-Za-z0-9._:+~-]*)
				printf 'Entware requirements incompatible: package %s has unsafe version or architecture metadata\n' "$required_package" >&2
				return 78
				;;
		esac
		if [ "${#observed_architecture}" -gt 64 ] || [ "${#observed_version}" -gt 64 ]; then
			printf 'Entware requirements incompatible: package %s metadata is oversized\n' "$required_package" >&2
			return 78
		fi
		if [ -z "$package_architecture" ]; then
			package_architecture=$observed_architecture
		elif [ "$package_architecture" != "$observed_architecture" ]; then
			printf '%s\n' 'Entware requirements incompatible: required packages have mixed architectures' >&2
			return 78
		fi
		entware_record_line=$(printf '%s\t%s\t%s' "$required_package" "$observed_version" "$observed_architecture")
		if [ -z "$NUTMERLIN_ENTWARE_RECORD" ]; then
			NUTMERLIN_ENTWARE_RECORD=$entware_record_line
		else
			NUTMERLIN_ENTWARE_RECORD=$NUTMERLIN_ENTWARE_RECORD'
'$entware_record_line
		fi
	done
	if [ -n "$missing_packages" ]; then
		printf 'Entware requirements unavailable: missing installed packages: %s\n' "$missing_packages" >&2
		entware_missing_guidance "$missing_packages"
		return 69
	fi

	NUTMERLIN_DUMMY_UPS_BIN=$(entware_resolve_binary \
		"$NUTMERLIN_OPT_ROOT/lib/nut/dummy-ups" \
		"$NUTMERLIN_OPT_ROOT/usr/lib/nut/dummy-ups") || {
		printf '%s\n' 'Entware requirements unavailable: missing binary: dummy-ups' >&2
		entware_missing_guidance nut-driver-dummy-ups
		return 69
	}
	NUTMERLIN_UPSD_BIN=$(entware_resolve_binary \
		"$NUTMERLIN_OPT_ROOT/lib/nut/upsd" \
		"$NUTMERLIN_OPT_ROOT/sbin/upsd") || {
		printf '%s\n' 'Entware requirements unavailable: missing binary: upsd' >&2
		entware_missing_guidance nut-server
		return 69
	}
	NUTMERLIN_UPSC_BIN=$(entware_resolve_binary "$NUTMERLIN_OPT_ROOT/bin/upsc") || {
		printf '%s\n' 'Entware requirements unavailable: missing binary: upsc' >&2
		entware_missing_guidance nut-upsc
		return 69
	}
	NUTMERLIN_USBHID_UPS_BIN=$(entware_resolve_binary \
		"$NUTMERLIN_OPT_ROOT/lib/nut/usbhid-ups" \
		"$NUTMERLIN_OPT_ROOT/usr/lib/nut/usbhid-ups") || {
		printf '%s\n' 'Entware requirements unavailable: missing binary: usbhid-ups' >&2
		entware_missing_guidance nut-driver-usbhid-ups
		return 69
	}

	entware_binary_help_contains "$NUTMERLIN_DUMMY_UPS_BIN" '-a' '-F' || {
		printf '%s\n' 'Entware requirements incompatible: dummy-ups lacks required options: -a -F' >&2
		return 78
	}
	entware_binary_help_contains "$NUTMERLIN_UPSD_BIN" '-F' '-u' || {
		printf '%s\n' 'Entware requirements incompatible: upsd lacks required options: -F -u' >&2
		return 78
	}
	entware_binary_help_contains "$NUTMERLIN_UPSC_BIN" 'usage: upsc' || {
		printf '%s\n' 'Entware requirements incompatible: upsc help probe failed' >&2
		return 78
	}
	entware_binary_help_contains "$NUTMERLIN_USBHID_UPS_BIN" '-a' '-F' '-x' || {
		printf '%s\n' 'Entware requirements incompatible: usbhid-ups lacks required options: -a -F -x' >&2
		return 78
	}

	export NUTMERLIN_DUMMY_UPS_BIN NUTMERLIN_UPSD_BIN NUTMERLIN_UPSC_BIN NUTMERLIN_USBHID_UPS_BIN
	export NUTMERLIN_ENTWARE_RECORD
}
