#!/bin/sh

configuration_random_id() {
	random_id=$(dd if=/dev/urandom bs=16 count=1 2>/dev/null | od -An -tx1 | tr -d ' \n')
	case $random_id in
		????????????????????????????????) printf '%s\n' "$random_id" ;;
		*) return 70 ;;
	esac
}

configuration_render_dummy() {
	candidate_root=$1
	set_id=$2
	code_root=$3
	runtime_root=$4

	printf 'schema\tnutmerlin.model.v1\nsource\tdummy\nset_id\t%s\n' "$set_id" >"$candidate_root/model.tsv"
	{
		printf 'statepath = %s/state\n\n' "$runtime_root"
		printf '%s\n' '[dummy]'
		printf '\tdriver = dummy-ups\n'
		printf '\tport = %s/share/dummy/cyberpower.dev\n' "$code_root"
		printf '\tmode = dummy-once\n'
	} >"$candidate_root/ups.conf"
	{
		printf 'STATEPATH %s/state\n' "$runtime_root"
		printf '%s\n' 'LISTEN 127.0.0.1 3493'
	} >"$candidate_root/upsd.conf"
	: >"$candidate_root/upsd.users"
	chmod 600 "$candidate_root/model.tsv" "$candidate_root/ups.conf" \
		"$candidate_root/upsd.conf" "$candidate_root/upsd.users"
	(
		cd "$candidate_root" || exit
		sha256sum model.tsv ups.conf upsd.conf upsd.users >SHA256SUMS
	)
	chmod 600 "$candidate_root/SHA256SUMS"
}

configuration_validate_set() {
	validated_set_root=$1
	validated_set_uid=$(id -u)
	[ -d "$validated_set_root" ] && [ ! -L "$validated_set_root" ] || return 1
	[ "$(stat -c '%a' "$validated_set_root")" = 700 ] || return 1
	[ "$(stat -c '%u' "$validated_set_root")" = "$validated_set_uid" ] || return 1
	[ "$(find "$validated_set_root" -mindepth 1 -maxdepth 1 | wc -l)" -eq 5 ] || return 1
	for set_file in model.tsv ups.conf upsd.conf upsd.users SHA256SUMS; do
		[ -f "$validated_set_root/$set_file" ] && [ ! -L "$validated_set_root/$set_file" ] || return 1
		[ "$(stat -c '%a' "$validated_set_root/$set_file")" = 600 ] || return 1
		[ "$(stat -c '%h' "$validated_set_root/$set_file")" = 1 ] || return 1
		[ "$(stat -c '%u' "$validated_set_root/$set_file")" = "$validated_set_uid" ] || return 1
	done
	validated_set_id=${validated_set_root##*/}
	case $validated_set_id in
		.candidate-*) validated_set_id=${validated_set_id#.candidate-} ;;
	esac
	case $validated_set_id in
		????????????????????????????????) ;;
		*) return 1 ;;
	esac
	case $validated_set_id in
		*[!0-9a-f]*) return 1 ;;
	esac
	(
		umask 077
		validation_scratch=$(mktemp -d "$NUTMERLIN_TMP_ROOT/.nutmerlin-config-check.XXXXXX") || exit 1
		trap 'rm -rf -- "$validation_scratch"' EXIT HUP INT TERM
		configuration_render_dummy "$validation_scratch" "$validated_set_id" \
			"$NUTMERLIN_JFFS_ROOT/addons/nutmerlin" "$NUTMERLIN_TMP_ROOT/nutmerlin"
		for validated_file in model.tsv ups.conf upsd.conf upsd.users SHA256SUMS; do
			cmp -s "$validation_scratch/$validated_file" "$validated_set_root/$validated_file" || exit 1
		done
	)
}

configuration_create_initial() {
	config_candidate=$1
	code_root=$2
	runtime_root=$3
	set_id=$(configuration_random_id)
	sets_root=$config_candidate/config/sets
	candidate_root=$sets_root/.candidate-$set_id
	set_root=$sets_root/$set_id

	mkdir -p "$sets_root"
	chmod 700 "$config_candidate/config" "$sets_root"
	mkdir -m 700 "$candidate_root"
	configuration_render_dummy "$candidate_root" "$set_id" "$code_root" "$runtime_root"
	configuration_validate_set "$candidate_root" || return 70
	mv "$candidate_root" "$set_root"
	printf '%s\n' "$set_id" >"$config_candidate/config/current.new"
	chmod 600 "$config_candidate/config/current.new"
	mv "$config_candidate/config/current.new" "$config_candidate/config/current"
}

configuration_select_set() {
	selector_root=$1
	selector_name=$2
	selected_set_id=$3
	configuration_random_id_is_valid=$selected_set_id
	case $configuration_random_id_is_valid in
		????????????????????????????????) ;;
		*) return 78 ;;
	esac
	case $configuration_random_id_is_valid in
		*[!0-9a-f]*) return 78 ;;
	esac
	selector_candidate=$selector_root/$selector_name.new
	if [ -e "$selector_candidate" ] || [ -L "$selector_candidate" ]; then
		return 78
	fi
	(umask 077 && printf '%s\n' "$selected_set_id" >"$selector_candidate")
	chmod 600 "$selector_candidate"
	mv "$selector_candidate" "$selector_root/$selector_name"
}

configuration_remove_set() {
	remove_sets_root=$1
	remove_set_id=$2
	case $remove_set_id in
		????????????????????????????????) ;;
		*) return 78 ;;
	esac
	case $remove_set_id in
		*[!0-9a-f]*) return 78 ;;
	esac
	remove_set_root=$remove_sets_root/$remove_set_id
	[ ! -e "$remove_set_root" ] || rm -rf -- "$remove_set_root"
}

configuration_activate_dummy() {
	activation_config_root=$NUTMERLIN_OPT_ROOT/etc/nutmerlin/config
	activation_sets_root=$activation_config_root/sets
	activation_code_root=$NUTMERLIN_JFFS_ROOT/addons/nutmerlin
	activation_runtime_root=$NUTMERLIN_TMP_ROOT/nutmerlin
	activation_previous_id=$(cat "$activation_config_root/current")
	activation_old_last_good=
	if [ -f "$activation_config_root/last-good" ]; then
		activation_old_last_good=$(cat "$activation_config_root/last-good")
	fi
	activation_new_id=$(configuration_random_id)
	activation_candidate_root=$activation_sets_root/.candidate-$activation_new_id
	activation_new_root=$activation_sets_root/$activation_new_id

	mkdir -m 700 "$activation_candidate_root"
	configuration_render_dummy "$activation_candidate_root" "$activation_new_id" \
		"$activation_code_root" "$activation_runtime_root"
	configuration_validate_set "$activation_candidate_root" || {
		rm -rf -- "$activation_candidate_root"
		return 70
	}
	mv "$activation_candidate_root" "$activation_new_root"
	if ! configuration_select_set "$activation_config_root" current "$activation_new_id"; then
		configuration_remove_set "$activation_sets_root" "$activation_new_id"
		return 78
	fi

	if ! service_restart; then
		configuration_select_set "$activation_config_root" current "$activation_previous_id"
		configuration_remove_set "$activation_sets_root" "$activation_new_id"
		unset NUTMERLIN_TEST_ACTIVATION_FAIL
		service_start || :
		printf '%s\n' 'configuration activation failed: previous set restored once' >&2
		return 75
	fi

	if ! configuration_select_set "$activation_config_root" last-good "$activation_previous_id"; then
		configuration_select_set "$activation_config_root" current "$activation_previous_id" || :
		service_restart || :
		configuration_remove_set "$activation_sets_root" "$activation_new_id"
		printf '%s\n' 'configuration activation failed: last-good selector was not replaced' >&2
		return 75
	fi
	if [ -n "$activation_old_last_good" ] &&
		[ "$activation_old_last_good" != "$activation_previous_id" ] &&
		[ "$activation_old_last_good" != "$activation_new_id" ]; then
		configuration_remove_set "$activation_sets_root" "$activation_old_last_good"
	fi
	SOURCE_MESSAGE='dummy configuration activated on loopback'
	export SOURCE_MESSAGE
}
