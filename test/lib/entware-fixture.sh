#!/bin/sh

entware_fixture_setup() {
	mkdir -p \
		"$NUTMERLIN_OPT_ROOT/bin" \
		"$NUTMERLIN_OPT_ROOT/lib/nut" \
		"$NUTMERLIN_OPT_ROOT/lib/opkg"

	: >"$NUTMERLIN_OPT_ROOT/lib/opkg/status"
	for package_name in nut nut-common nut-server nut-upsc nut-driver-dummy-ups nut-driver-usbhid-ups; do
		[ "$package_name" != "${NUTMERLIN_FIXTURE_OMIT_PACKAGE:-}" ] || continue
		{
			printf 'Package: %s\n' "$package_name"
			printf '%s\n' 'Version: 2.8.2-1' 'Architecture: aarch64-3.10' 'Status: install user installed' ''
		} >>"$NUTMERLIN_OPT_ROOT/lib/opkg/status"
	done

	printf '%s\n' '#!/bin/sh' 'exit 99' >"$NUTMERLIN_OPT_ROOT/bin/opkg"
	printf '%s\n' '#!/bin/sh' "printf '%s\\n' 'usage: upsc UPS[@HOST]'" >"$NUTMERLIN_OPT_ROOT/bin/upsc"
	if [ "${NUTMERLIN_FIXTURE_BAD_DUMMY_HELP:-0}" = 1 ]; then
		printf '%s\n' '#!/bin/sh' "printf '%s\\n' 'usage: dummy-ups -a ID'" >"$NUTMERLIN_OPT_ROOT/lib/nut/dummy-ups"
	else
		printf '%s\n' '#!/bin/sh' "printf '%s\\n' 'usage: dummy-ups -a ID -F'" >"$NUTMERLIN_OPT_ROOT/lib/nut/dummy-ups"
	fi
	printf '%s\n' '#!/bin/sh' "printf '%s\\n' 'usage: upsd -F -u USER'" >"$NUTMERLIN_OPT_ROOT/lib/nut/upsd"
	printf '%s\n' '#!/bin/sh' "printf '%s\\n' 'usage: usbhid-ups -a ID -F -x OPTION'" >"$NUTMERLIN_OPT_ROOT/lib/nut/usbhid-ups"
	chmod 700 \
		"$NUTMERLIN_OPT_ROOT/bin/opkg" \
		"$NUTMERLIN_OPT_ROOT/bin/upsc" \
		"$NUTMERLIN_OPT_ROOT/lib/nut/dummy-ups" \
		"$NUTMERLIN_OPT_ROOT/lib/nut/upsd" \
		"$NUTMERLIN_OPT_ROOT/lib/nut/usbhid-ups"
}
