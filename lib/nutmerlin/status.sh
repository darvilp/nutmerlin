#!/bin/sh

status_recovery_value() {
	if lifecycle_recovery_read; then
		if [ "$RECOVERY_FAILURES" -eq 0 ]; then
			printf '%s\n' ready
		elif [ "$RECOVERY_PAUSE" -gt 0 ]; then
			printf 'paused_%s\n' "$RECOVERY_PAUSE"
		else
			printf 'probe_after_%s_failures\n' "$RECOVERY_FAILURES"
		fi
	else
		printf '%s\n' ambiguous
	fi
}

status_process_value() {
	status_pid_record=$1
	status_process_role=$2
	if service_pid_is_owned "$status_pid_record" "$status_process_role"; then
		printf '%s\n' running
	elif [ ! -e "$status_pid_record" ] && [ ! -L "$status_pid_record" ]; then
		printf '%s\n' stopped
	else
		printf '%s\n' ambiguous
	fi
}

status_driver_without_profile() {
	status_dummy_state=$(status_process_value \
		"$NUTMERLIN_TMP_ROOT/nutmerlin/run/dummy-ups.pid" dummy)
	status_usbhid_state=$(status_process_value \
		"$NUTMERLIN_TMP_ROOT/nutmerlin/run/usbhid-ups.pid" usbhid)
	case $status_dummy_state:$status_usbhid_state in
		running:stopped | stopped:running) printf '%s\n' running ;;
		stopped:stopped) printf '%s\n' stopped ;;
		*) printf '%s\n' ambiguous ;;
	esac
}

status_collect() {
	STATUS_INSTALLATION=ambiguous
	STATUS_ENABLED=unknown
	STATUS_STORAGE=unknown
	STATUS_SOURCE=unavailable
	STATUS_DRIVER=unknown
	STATUS_UPSD=unknown
	STATUS_UPSC=unavailable
	STATUS_LISTENER=unknown
	STATUS_FIREWALL=loopback_only
	STATUS_CLIENT_COUNT=0
	STATUS_RECOVERY=$(status_recovery_value)
	STATUS_FAILED_LAYER=installation
	STATUS_REMEDIATION='run repair after resolving ownership evidence'
	STATUS_EXIT=78
	STATUS_STATE=refused
	STATUS_EXIT_CLASS=configuration_refusal
	STATUS_MESSAGE='installation ownership is ambiguous'
	status_code_root=$NUTMERLIN_JFFS_ROOT/addons/nutmerlin
	if ! ownership_verify_code_root "$status_code_root"; then
		export STATUS_INSTALLATION STATUS_ENABLED STATUS_STORAGE STATUS_SOURCE STATUS_DRIVER STATUS_UPSD
		export STATUS_UPSC STATUS_LISTENER STATUS_FIREWALL STATUS_CLIENT_COUNT STATUS_RECOVERY
		export STATUS_FAILED_LAYER STATUS_REMEDIATION STATUS_EXIT STATUS_STATE STATUS_EXIT_CLASS STATUS_MESSAGE
		return 0
	fi
	STATUS_INSTALLATION=owned
	if [ "$(cat "$status_code_root/enabled" 2>/dev/null || :)" = 1 ]; then
		STATUS_ENABLED=enabled
	else
		STATUS_ENABLED=disabled
	fi
	STATUS_STORAGE=$(platform_storage_state)
	status_server_record=$NUTMERLIN_TMP_ROOT/nutmerlin/run/upsd.pid
	STATUS_UPSD=$(status_process_value "$status_server_record" upsd)
	status_profile_ready=0
	status_source_result=0
	status_source_message=
	if [ "$STATUS_STORAGE" = available ] && service_resolve_current >/dev/null 2>&1 &&
		service_load_active_profile >/dev/null 2>&1; then
		status_profile_ready=1
		STATUS_SOURCE=$SERVICE_SOURCE
		status_driver_record=$NUTMERLIN_TMP_ROOT/nutmerlin/run/$SERVICE_DRIVER_RECORD_NAME
		case $SERVICE_DRIVER_ROLE in
			dummy) status_other_driver_record=$NUTMERLIN_TMP_ROOT/nutmerlin/run/usbhid-ups.pid ;;
			usbhid) status_other_driver_record=$NUTMERLIN_TMP_ROOT/nutmerlin/run/dummy-ups.pid ;;
		esac
		if [ -e "$status_other_driver_record" ] || [ -L "$status_other_driver_record" ]; then
			STATUS_DRIVER=ambiguous
		else
			STATUS_DRIVER=$(status_process_value "$status_driver_record" "$SERVICE_DRIVER_ROLE")
		fi
	else
		STATUS_DRIVER=$(status_driver_without_profile)
	fi
	if [ "$status_profile_ready" -eq 1 ] && [ "$SERVICE_SOURCE" = ups ]; then
		if status_source_message=$(service_validate_active_source 2>&1); then
			status_source_result=0
		else
			status_source_result=$?
		fi
	fi
	if service_listener_is_loopback_only; then
		STATUS_LISTENER=loopback
	elif service_listener_is_clear; then
		STATUS_LISTENER=closed
	else
		STATUS_LISTENER=ambiguous
	fi
	if [ "$STATUS_STORAGE" != available ]; then
		STATUS_FAILED_LAYER=storage
		STATUS_REMEDIATION='restore the attributable Entware storage and wait for reconciliation'
		STATUS_EXIT=69
		STATUS_STATE=unavailable
		STATUS_EXIT_CLASS=unavailable
		STATUS_MESSAGE="storage is unavailable: $STATUS_STORAGE"
	else
		if [ "$status_profile_ready" -eq 1 ]; then
			status_set_root=$NUTMERLIN_ACTIVE_CONFIG
			STATUS_CLIENT_COUNT=$(platform_client_count "$status_set_root" 2>/dev/null || printf '%s\n' 0)
		fi
		service_runtime_root=$NUTMERLIN_TMP_ROOT/nutmerlin
		export service_runtime_root
		if [ "$status_profile_ready" -eq 1 ] && [ "$STATUS_DRIVER" = running ] &&
			[ "$STATUS_UPSD" = running ] && entware_check >/dev/null 2>&1 &&
			[ "$status_source_result" -eq 0 ] && service_query_active; then
			STATUS_UPSC=healthy
		else
			STATUS_UPSC=unavailable
		fi
		if [ "$STATUS_ENABLED" = enabled ] && [ "$STATUS_DRIVER" = running ] &&
			[ "$STATUS_UPSD" = running ] && [ "$STATUS_UPSC" = healthy ] &&
			[ "$STATUS_LISTENER" = loopback ] && [ "$STATUS_RECOVERY" = ready ]; then
			STATUS_FAILED_LAYER=none
			STATUS_REMEDIATION=none
			STATUS_EXIT=0
			STATUS_STATE=ok
			STATUS_EXIT_CLASS=success
			STATUS_MESSAGE="$SERVICE_UPS_NAME service is healthy on loopback"
		elif [ "$status_source_result" -ne 0 ]; then
			STATUS_FAILED_LAYER=source
			STATUS_REMEDIATION='reconnect the configured UPS or correct its stable identity'
			STATUS_MESSAGE=${status_source_message:-source unavailable: stable USB identity could not be verified}
			if [ "$status_source_result" -eq 78 ]; then
				STATUS_EXIT=78
				STATUS_STATE=refused
				STATUS_EXIT_CLASS=configuration_refusal
			else
				STATUS_EXIT=69
				STATUS_STATE=unavailable
				STATUS_EXIT_CLASS=unavailable
			fi
		else
			STATUS_FAILED_LAYER=service
			STATUS_REMEDIATION='run service start or wait for lifecycle reconciliation'
			STATUS_EXIT=69
			STATUS_STATE=unavailable
			STATUS_EXIT_CLASS=unavailable
			STATUS_MESSAGE='installed service is not healthy'
		fi
	fi
	export STATUS_INSTALLATION STATUS_ENABLED STATUS_STORAGE STATUS_SOURCE STATUS_DRIVER STATUS_UPSD
	export STATUS_UPSC STATUS_LISTENER STATUS_FIREWALL STATUS_CLIENT_COUNT STATUS_RECOVERY
	export STATUS_FAILED_LAYER STATUS_REMEDIATION STATUS_EXIT STATUS_STATE STATUS_EXIT_CLASS STATUS_MESSAGE
}
