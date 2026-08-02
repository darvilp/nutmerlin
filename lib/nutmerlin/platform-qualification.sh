#!/bin/sh

platform_qualification_load() {
	qualified_3004_stable=none qualified_3006_stable=none known_incompatibility_scope=none

	if [ "${platform_evidence_layer:-}" = host_simulation ] &&
		[ "${NUTMERLIN_ENABLE_TEST_ADAPTERS:-0}" = 1 ] && roots_are_isolated; then
		qualified_3004_stable=$(platform_token_or_unknown "${NUTMERLIN_TEST_QUALIFIED_3004:-none}")
		qualified_3006_stable=$(platform_token_or_unknown "${NUTMERLIN_TEST_QUALIFIED_3006:-none}")
		case ${NUTMERLIN_TEST_INCOMPATIBILITY_SCOPE:-none} in
			none | core | webui | wall_clock_security | local_script)
				known_incompatibility_scope=$NUTMERLIN_TEST_INCOMPATIBILITY_SCOPE
				;;
			*) known_incompatibility_scope=core ;;
		esac
	fi
}

platform_version_matches_family() {
	case $1:$2 in
		3004.388.x:3004.388.*) release=${2#3004.388.} ;;
		3006.102.x:3006.102.*) release=${2#3006.102.} ;;
		386.x:386.*) release=${2#386.} ;;
		*) return 1 ;;
	esac
	case $release in
		'' | *[!0-9_]* | _* | *_ | *_*_*) return 1 ;;
		*) return 0 ;;
	esac
}

platform_qualified_stable() {
	case $1 in
		3004.388.x)
			platform_version_matches_family "$1" "$qualified_3004_stable" && printf '%s' "$qualified_3004_stable" || printf '%s' none
			;;
		3006.102.x)
			platform_version_matches_family "$1" "$qualified_3006_stable" && printf '%s' "$qualified_3006_stable" || printf '%s' none
			;;
		*) printf '%s' none ;;
	esac
}

platform_known_incompatibility_scope() {
	printf '%s' "$known_incompatibility_scope"
}
