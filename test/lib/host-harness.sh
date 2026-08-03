#!/bin/sh

host_harness_setup() {
	NUTMERLIN_TEST_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/nutmerlin-host-test.XXXXXX")
	chmod 700 "$NUTMERLIN_TEST_ROOT"
	export NUTMERLIN_TEST_ROOT
	NUTMERLIN_ISOLATION_ROOT=$NUTMERLIN_TEST_ROOT
	export NUTMERLIN_ISOLATION_ROOT
	printf '%s\n' 'nutmerlin-test-root-v1' >"$NUTMERLIN_TEST_ROOT/.nutmerlin-test-root"
	chmod 600 "$NUTMERLIN_TEST_ROOT/.nutmerlin-test-root"

	mkdir -p \
		"$NUTMERLIN_TEST_ROOT/bin" \
		"$NUTMERLIN_TEST_ROOT/jffs" \
		"$NUTMERLIN_TEST_ROOT/opt" \
		"$NUTMERLIN_TEST_ROOT/tmp"

	NUTMERLIN_JFFS_ROOT=$NUTMERLIN_TEST_ROOT/jffs
	NUTMERLIN_OPT_ROOT=$NUTMERLIN_TEST_ROOT/opt
	NUTMERLIN_TMP_ROOT=$NUTMERLIN_TEST_ROOT/tmp
	NUTMERLIN_EXTERNAL_CALL_LOG=$NUTMERLIN_TEST_ROOT/external-calls
	export NUTMERLIN_JFFS_ROOT NUTMERLIN_OPT_ROOT NUTMERLIN_TMP_ROOT
	export NUTMERLIN_EXTERNAL_CALL_LOG

	for command_name in cru iptables mount nvram service; do
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
		case $NUTMERLIN_TEST_ROOT in
			"${TMPDIR:-/tmp}"/nutmerlin-host-test.*) rm -rf -- "$NUTMERLIN_TEST_ROOT" ;;
		esac
	fi
}
