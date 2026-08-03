#!/bin/sh

# Callers pass only validated command/status identifiers and bounded messages.
result_json_escape() {
	printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

result_value_is_safe() {
	result_value=$1
	[ "${#result_value}" -le 512 ] || return 1
	case $result_value in
		*[![:print:]]*) return 1 ;;
	esac
}

result_emit() {
	for result_value in "$@"; do
		if ! result_value_is_safe "$result_value"; then
			printf '%s\n' 'result: internal: unsafe result value' >&2
			return 70
		fi
	done

	result_command=$1
	result_format=$2
	result_status=$3
	result_exit_class=$4
	result_message=$5

	case $result_format in
		human)
			printf '%s: %s: %s\n' "$result_command" "$result_status" "$result_message"
			;;
		json)
			printf '{"schema_version":"nutmerlin.result.v1","command":"%s","status":"%s","exit_class":"%s","message":"%s"}\n' \
				"$(result_json_escape "$result_command")" \
				"$(result_json_escape "$result_status")" \
				"$(result_json_escape "$result_exit_class")" \
				"$(result_json_escape "$result_message")"
			;;
		*)
			printf '%s\n' 'result: internal: unsupported output format' >&2
			return 70
			;;
	esac
}
