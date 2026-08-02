#!/bin/sh

host_harness_setup() {
	NUTMERLIN_TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/nutmerlin-host-test.XXXXXX")
	chmod 700 "$NUTMERLIN_TEST_ROOT"
	export NUTMERLIN_TEST_ROOT
	NUTMERLIN_ISOLATION_ROOT=$NUTMERLIN_TEST_ROOT
	export NUTMERLIN_ISOLATION_ROOT

	mkdir -p \
		"$NUTMERLIN_TEST_ROOT/bin" \
		"$NUTMERLIN_TEST_ROOT/jffs" \
		"$NUTMERLIN_TEST_ROOT/opt" \
		"$NUTMERLIN_TEST_ROOT/status" \
		"$NUTMERLIN_TEST_ROOT/web"

	NUTMERLIN_ROUTER_ROOT=$NUTMERLIN_TEST_ROOT/jffs
	NUTMERLIN_ENTWARE_ROOT=$NUTMERLIN_TEST_ROOT/opt
	NUTMERLIN_STATUS_ROOT=$NUTMERLIN_TEST_ROOT/status
	NUTMERLIN_WEB_ROOT=$NUTMERLIN_TEST_ROOT/web
	NUTMERLIN_EXTERNAL_CALL_LOG=$NUTMERLIN_TEST_ROOT/external-calls
	export NUTMERLIN_ROUTER_ROOT NUTMERLIN_ENTWARE_ROOT
	export NUTMERLIN_STATUS_ROOT NUTMERLIN_WEB_ROOT
	export NUTMERLIN_EXTERNAL_CALL_LOG

	for command_name in nvram iptables ip6tables service opkg; do
		# The generated stub must expand these values when it runs, not now.
		# shellcheck disable=SC2016
		printf '%s\n' '#!/bin/sh' \
			'printf "%s\n" "$0 $*" >>"$NUTMERLIN_EXTERNAL_CALL_LOG"' \
			'exit 99' >"$NUTMERLIN_TEST_ROOT/bin/$command_name"
		chmod 700 "$NUTMERLIN_TEST_ROOT/bin/$command_name"
	done

	PATH=$NUTMERLIN_TEST_ROOT/bin:$PATH
	export PATH
}

host_harness_teardown() {
	if [ -n "${NUTMERLIN_TEST_ROOT:-}" ] && [ -d "$NUTMERLIN_TEST_ROOT" ]; then
		rm -rf -- "$NUTMERLIN_TEST_ROOT"
	fi
}
