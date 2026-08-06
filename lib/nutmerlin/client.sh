#!/bin/sh

# shellcheck disable=SC2034 # module result variables are consumed by the sourcing CLI

client_random_secret() {
	unset client_secret
	client_secret=$(dd if=/dev/urandom bs=24 count=1 2>/dev/null | od -An -tx1 | tr -d ' \n')
	configuration_client_secret_is_valid "$client_secret" || return 70
	printf '%s\n' "$client_secret"
}

client_secret_is_unique() {
	unique_set_root=$1
	unset unique_secret
	unique_secret=$2
	if [ ! -d "$unique_set_root/clients" ]; then
		return 0
	fi
	for unique_client_path in "$unique_set_root"/clients/*; do
		unique_client_id=${unique_client_path##*/}
		configuration_read_client "$unique_client_path" "$unique_client_id" || return 78
		[ "$CONFIGURATION_CLIENT_SECRET" != "$unique_secret" ] || return 1
	done
}

client_discard_candidate() {
	discard_candidate_root=$1
	discard_sets_root=$2
	case $discard_candidate_root in
		"$discard_sets_root"/.candidate-????????????????????????????????) ;;
		*) return 78 ;;
	esac
	[ ! -e "$discard_candidate_root" ] || rm -rf -- "$discard_candidate_root"
}

client_add() {
	client_label=$1
	configuration_client_label_is_valid "$client_label" || {
		printf '%s\n' 'client refused: name must be 1-64 safe display characters without edge spaces' >&2
		return 78
	}
	client_config_root=$NUTMERLIN_OPT_ROOT/etc/nutmerlin/config
	client_sets_root=$client_config_root/sets
	client_previous_id=$(cat "$client_config_root/current")
	configuration_client_id_is_valid "$client_previous_id" || return 78
	client_previous_root=$client_sets_root/$client_previous_id
	configuration_validate_set "$client_previous_root" || return 78
	client_existing_count=$(platform_client_count "$client_previous_root") || return $?
	[ "$client_existing_count" -lt 64 ] || {
		printf '%s\n' 'client refused: the 64-client limit has been reached' >&2
		return 78
	}

	client_attempt=0
	CLIENT_ID=
	while [ "$client_attempt" -lt 8 ]; do
		client_attempt=$((client_attempt + 1))
		client_candidate_id=$(configuration_random_id) || return $?
		if [ ! -e "$client_previous_root/clients/$client_candidate_id" ] &&
			[ ! -L "$client_previous_root/clients/$client_candidate_id" ]; then
			CLIENT_ID=$client_candidate_id
			break
		fi
	done
	[ -n "$CLIENT_ID" ] || return 70
	CLIENT_USERNAME=nm_$CLIENT_ID
	client_attempt=0
	unset CLIENT_SECRET client_candidate_secret
	CLIENT_SECRET=
	while [ "$client_attempt" -lt 8 ]; do
		client_attempt=$((client_attempt + 1))
		client_candidate_secret=$(client_random_secret) || return $?
		if client_secret_is_unique "$client_previous_root" "$client_candidate_secret"; then
			CLIENT_SECRET=$client_candidate_secret
			break
		fi
	done
	[ -n "$CLIENT_SECRET" ] || return 70

	client_new_set_id=$(configuration_random_id) || return $?
	client_candidate_root=$client_sets_root/.candidate-$client_new_set_id
	mkdir -m 700 "$client_candidate_root" || return 75
	configuration_render_current_profile "$client_candidate_root" "$client_new_set_id" \
		"$client_previous_root" || {
		client_discard_candidate "$client_candidate_root" "$client_sets_root" || return $?
		return 70
	}
	if [ ! -d "$client_candidate_root/clients" ]; then
		mkdir -m 700 "$client_candidate_root/clients" || {
			client_discard_candidate "$client_candidate_root" "$client_sets_root" || return $?
			return 75
		}
	fi
	configuration_write_client_record "$client_candidate_root/clients" "$CLIENT_ID" \
		"$client_label" "$CLIENT_USERNAME" "$CLIENT_SECRET" || {
		client_discard_candidate "$client_candidate_root" "$client_sets_root" || return $?
		return 70
	}
	configuration_render_upsd_users "$client_candidate_root" || {
		client_discard_candidate "$client_candidate_root" "$client_sets_root" || return $?
		return 70
	}
	chmod 600 "$client_candidate_root/upsd.users"
	configuration_write_manifest "$client_candidate_root" || {
		client_discard_candidate "$client_candidate_root" "$client_sets_root" || return $?
		return 70
	}
	configuration_activate_candidate "$client_candidate_root" "$client_new_set_id" || return $?
	CLIENT_MESSAGE='secondary client created; save the secret now because it cannot be shown again'
}

client_revoke() {
	revoked_client_id=$1
	configuration_client_id_is_valid "$revoked_client_id" || {
		printf '%s\n' 'client refused: client ID must be exactly 32 lowercase hexadecimal characters' >&2
		return 78
	}
	revoke_config_root=$NUTMERLIN_OPT_ROOT/etc/nutmerlin/config
	revoke_sets_root=$revoke_config_root/sets
	revoke_previous_id=$(cat "$revoke_config_root/current")
	configuration_client_id_is_valid "$revoke_previous_id" || return 78
	revoke_previous_root=$revoke_sets_root/$revoke_previous_id
	configuration_validate_set "$revoke_previous_root" || return 78
	revoke_previous_client=$revoke_previous_root/clients/$revoked_client_id
	if [ ! -f "$revoke_previous_client" ] || [ -L "$revoke_previous_client" ]; then
		printf 'client unavailable: no active client has ID %s\n' "$revoked_client_id" >&2
		return 69
	fi
	configuration_read_client "$revoke_previous_client" "$revoked_client_id" || return 78

	revoke_new_set_id=$(configuration_random_id) || return $?
	revoke_candidate_root=$revoke_sets_root/.candidate-$revoke_new_set_id
	mkdir -m 700 "$revoke_candidate_root" || return 75
	configuration_render_current_profile "$revoke_candidate_root" "$revoke_new_set_id" \
		"$revoke_previous_root" || {
		client_discard_candidate "$revoke_candidate_root" "$revoke_sets_root" || return $?
		return 70
	}
	rm -f -- "$revoke_candidate_root/clients/$revoked_client_id"
	if [ "$(find "$revoke_candidate_root/clients" -mindepth 1 -maxdepth 1 | wc -l)" -eq 0 ]; then
		rmdir "$revoke_candidate_root/clients" || {
			client_discard_candidate "$revoke_candidate_root" "$revoke_sets_root" || return $?
			return 75
		}
	fi
	configuration_render_upsd_users "$revoke_candidate_root" || {
		client_discard_candidate "$revoke_candidate_root" "$revoke_sets_root" || return $?
		return 70
	}
	chmod 600 "$revoke_candidate_root/upsd.users"
	configuration_write_manifest "$revoke_candidate_root" || {
		client_discard_candidate "$revoke_candidate_root" "$revoke_sets_root" || return $?
		return 70
	}
	configuration_activate_candidate "$revoke_candidate_root" "$revoke_new_set_id" || return $?
	CLIENT_MESSAGE="secondary client revoked; client_id=$revoked_client_id"
}
