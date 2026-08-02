#!/bin/sh

roots_are_isolated() {
	case ${NUTMERLIN_ISOLATION_ROOT:-} in
		'' | / | /jffs | /opt | /tmp)
			return 1
			;;
	esac
	[ ! -L "$NUTMERLIN_ISOLATION_ROOT" ] || return 1
	isolation_path=$(CDPATH='' cd -P -- "$NUTMERLIN_ISOLATION_ROOT" 2>/dev/null && pwd -P) || return 1
	case $isolation_path in
		/ | /jffs | /opt | /tmp)
			return 1
			;;
	esac

	for root_path in \
		"${NUTMERLIN_ROUTER_ROOT:-}" \
		"${NUTMERLIN_ENTWARE_ROOT:-}" \
		"${NUTMERLIN_STATUS_ROOT:-}" \
		"${NUTMERLIN_WEB_ROOT:-}"; do
		[ -d "$root_path" ] && [ ! -L "$root_path" ] || return 1
		canonical_root=$(CDPATH='' cd -P -- "$root_path" 2>/dev/null && pwd -P) || return 1
		case $canonical_root in
			"$isolation_path"/*) ;;
			*)
				return 1
				;;
		esac
	done
}

management_operation_run() {
	operation_id=$1
	output_format=$2

	case $operation_id in
		core.self-check.v1)
			if ! roots_are_isolated; then
				if [ "$output_format" = json ]; then
					printf '%s\n' '{"schema_version":"nutmerlin.management-result.v1","operation":"core.self-check.v1","status":"refused","exit_class":"configuration","health":{"monitoring_only":true,"isolated_roots":false,"external_effects":false}}'
				else
					printf '%s\n' 'self-check refused: host roots are not isolated' >&2
				fi
				return 78
			fi
			;;
		platform.eligibility.v1)
			platform_eligibility_run "$output_format"
			return $?
			;;
		*)
			printf '%s\n' 'unknown management operation' >&2
			return 64
			;;
	esac

	if [ "$output_format" = json ]; then
		printf '%s\n' '{"schema_version":"nutmerlin.management-result.v1","operation":"core.self-check.v1","status":"ok","exit_class":"success","health":{"monitoring_only":true,"isolated_roots":true,"external_effects":false}}'
	else
		printf '%s\n' 'NUTMerlin core self-check: ok (monitoring-only, isolated, no external effects)'
	fi
}
