#!/bin/sh

path_is_safe_test_root() {
	path_to_check=$1
	[ -d "$path_to_check" ] && [ ! -L "$path_to_check" ] || return 1
	canonical_test_root=$(CDPATH='' cd -P -- "$path_to_check" 2>/dev/null && pwd -P) || return 1
	case $canonical_test_root in
		/ | /jffs | /opt | /tmp) return 1 ;;
	esac
	[ "$canonical_test_root" = "$path_to_check" ] || return 1
	[ "$(stat -c '%a' "$path_to_check")" = 700 ] || return 1
	[ "$(stat -c '%u' "$path_to_check")" = "$(id -u)" ] || return 1
	test_root_marker=$path_to_check/.nutmerlin-test-root
	[ -f "$test_root_marker" ] && [ ! -L "$test_root_marker" ] || return 1
	[ "$(stat -c '%a' "$test_root_marker")" = 600 ] || return 1
	[ "$(stat -c '%h' "$test_root_marker")" = 1 ] || return 1
	[ "$(stat -c '%u' "$test_root_marker")" = "$(id -u)" ] || return 1
	[ "$(cat "$test_root_marker")" = nutmerlin-test-root-v1 ]
}

path_is_safe_test_child() {
	child_path=$1
	private_root=$2
	[ -d "$child_path" ] && [ ! -L "$child_path" ] || return 1
	canonical_child=$(CDPATH='' cd -P -- "$child_path" 2>/dev/null && pwd -P) || return 1
	case $canonical_child in
		"$private_root"/*) ;;
		*) return 1 ;;
	esac
}

paths_initialize() {
	if [ "${NUTMERLIN_ENABLE_TEST_ADAPTERS:-0}" = 1 ]; then
		case ${NUTMERLIN_TEST_ROOT:-} in
			/*) ;;
			*)
				printf '%s\n' 'test root must be an absolute path' >&2
				return 78
				;;
		esac
		path_is_safe_test_root "$NUTMERLIN_TEST_ROOT" || {
			printf '%s\n' 'test root must carry private harness ownership evidence' >&2
			return 78
		}
		NUTMERLIN_JFFS_ROOT=$NUTMERLIN_TEST_ROOT/jffs
		NUTMERLIN_OPT_ROOT=$NUTMERLIN_TEST_ROOT/opt
		NUTMERLIN_TMP_ROOT=$NUTMERLIN_TEST_ROOT/tmp
		for private_child_root in "$NUTMERLIN_JFFS_ROOT" "$NUTMERLIN_OPT_ROOT" "$NUTMERLIN_TMP_ROOT"; do
			path_is_safe_test_child "$private_child_root" "$canonical_test_root" || {
				printf '%s\n' 'test roots must be canonical directories beneath the private test root' >&2
				return 78
			}
		done
	else
		NUTMERLIN_JFFS_ROOT=/jffs
		NUTMERLIN_OPT_ROOT=/opt
		NUTMERLIN_TMP_ROOT=/tmp
	fi

	export NUTMERLIN_JFFS_ROOT NUTMERLIN_OPT_ROOT NUTMERLIN_TMP_ROOT
}
