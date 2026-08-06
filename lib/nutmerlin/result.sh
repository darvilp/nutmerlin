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

result_emit_client_add() {
	result_format=$1
	result_message=$2
	result_client_id=$3
	result_username=$4
	unset result_secret result_value
	result_secret=$5
	for result_value in "$result_message" "$result_client_id" "$result_username" "$result_secret"; do
		result_value_is_safe "$result_value" || return 70
	done
	case $result_client_id:$result_secret in
		????????????????????????????????:????????????????????????????????????????????????) ;;
		*) return 70 ;;
	esac
	case $result_client_id$result_secret in
		*[!0-9a-f]*) return 70 ;;
	esac
	[ "$result_username" = "nm_$result_client_id" ] || return 70
	case $result_format in
		human)
			printf '%s\n' "client.add: ok: $result_message" \
				"client_id=$result_client_id" "username=$result_username" "secret=$result_secret"
			;;
		json)
			printf '{"schema_version":"nutmerlin.result.v1","command":"client.add","status":"ok","exit_class":"success","message":"%s","details":{"client_id":"%s","username":"%s","secret":"%s"}}\n' \
				"$(result_json_escape "$result_message")" "$result_client_id" \
				"$result_username" "$result_secret"
			;;
		*) return 70 ;;
	esac
}

result_emit_status() {
	result_command=$1
	result_format=$2
	result_status=$3
	result_exit_class=$4
	result_message=$5
	shift 5
	for result_value in "$result_command" "$result_status" "$result_exit_class" "$result_message" "$@"; do
		result_value_is_safe "$result_value" || {
			printf '%s\n' 'result: internal: unsafe result value' >&2
			return 70
		}
	done
	result_installation=$1
	result_enabled=$2
	result_storage=$3
	result_source=$4
	result_driver=$5
	result_upsd=$6
	result_upsc=$7
	result_listener=$8
	result_firewall=$9
	shift 9
	result_client_count=$1
	result_recovery=$2
	result_failed_layer=$3
	result_remediation=$4
	case $result_client_count in
		'' | *[!0-9]*) return 70 ;;
	esac
	case $result_format in
		human)
			printf '%s: %s: %s; installation=%s enabled=%s storage=%s source=%s driver=%s upsd=%s upsc=%s listener=%s firewall=%s clients=%s recovery=%s failed_layer=%s remediation=%s\n' \
				"$result_command" "$result_status" "$result_message" "$result_installation" "$result_enabled" \
				"$result_storage" "$result_source" "$result_driver" "$result_upsd" "$result_upsc" \
				"$result_listener" "$result_firewall" "$result_client_count" "$result_recovery" \
				"$result_failed_layer" "$result_remediation"
			;;
		json)
			printf '{"schema_version":"nutmerlin.result.v1","command":"%s","status":"%s","exit_class":"%s","message":"%s","details":{"installation":"%s","enabled":"%s","storage":"%s","source":"%s","driver":"%s","upsd":"%s","upsc":"%s","listener":"%s","firewall":"%s","client_count":%s,"recovery":"%s","failed_layer":"%s","remediation":"%s"}}\n' \
				"$(result_json_escape "$result_command")" "$(result_json_escape "$result_status")" \
				"$(result_json_escape "$result_exit_class")" "$(result_json_escape "$result_message")" \
				"$(result_json_escape "$result_installation")" "$(result_json_escape "$result_enabled")" \
				"$(result_json_escape "$result_storage")" "$(result_json_escape "$result_source")" \
				"$(result_json_escape "$result_driver")" "$(result_json_escape "$result_upsd")" \
				"$(result_json_escape "$result_upsc")" "$(result_json_escape "$result_listener")" \
				"$(result_json_escape "$result_firewall")" "$result_client_count" \
				"$(result_json_escape "$result_recovery")" "$(result_json_escape "$result_failed_layer")" \
				"$(result_json_escape "$result_remediation")"
			;;
		*) return 70 ;;
	esac
}
