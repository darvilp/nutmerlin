#!/bin/sh

hooks_names='services-start services-stop post-mount unmount firewall-start'

hooks_render_block() {
	hook_name=$1
	hook_installation_id=$2
	hook_code_root=$3
	printf '# BEGIN NUTMerlin managed block: %s %s\n' "$hook_installation_id" "$hook_name"
	printf 'if [ -x "%s/bin/nutmerlin" ]; then\n' "$hook_code_root"
	printf '\t"%s/bin/nutmerlin" hook %s "$@" >/dev/null 2>&1 || :\n' "$hook_code_root" "$hook_name"
	printf '%s\n' 'fi'
	printf '# END NUTMerlin managed block: %s %s\n' "$hook_installation_id" "$hook_name"
}

hooks_write_metadata() {
	hook_metadata_root=$1
	hook_installation_id=$2
	hook_code_root=$3
	hook_metadata_path=$hook_metadata_root/hooks.tsv
	hook_scratch=$(mktemp "$NUTMERLIN_TMP_ROOT/.nutmerlin-hook.XXXXXX") || return 75
	: >"$hook_metadata_path"
	for hook_name in $hooks_names; do
		hooks_render_block "$hook_name" "$hook_installation_id" "$hook_code_root" >"$hook_scratch"
		hook_digest=$(sha256sum "$hook_scratch" | awk '{ print $1 }')
		printf '%s\t%s\n' "$hook_name" "$hook_digest" >>"$hook_metadata_path"
	done
	rm -f -- "$hook_scratch"
	chmod 600 "$hook_metadata_path"
}

hooks_metadata_digest() {
	hook_code_root=$1
	hook_name=$2
	awk -F '\t' -v hook_name="$hook_name" '
		$1 == hook_name && length($2) == 64 && $2 !~ /[^0-9a-f]/ { print $2; found++ }
		END { if (found != 1) exit 1 }
	' "$hook_code_root/hooks.tsv"
}

hooks_verify_one() {
	verified_hook_root=$1
	verified_hook_name=$2
	verified_hook_id=$3
	verified_code_root=$4
	verified_hook_path=$verified_hook_root/$verified_hook_name
	[ -f "$verified_hook_path" ] && [ ! -L "$verified_hook_path" ] || return 1
	[ "$(stat -c '%h' "$verified_hook_path")" = 1 ] || return 1
	[ "$(stat -c '%u' "$verified_hook_path")" = "$(id -u)" ] || return 1
	verified_hook_scratch=$(mktemp "$NUTMERLIN_TMP_ROOT/.nutmerlin-hook-check.XXXXXX") || return 1
	hooks_render_block "$verified_hook_name" "$verified_hook_id" "$verified_code_root" >"$verified_hook_scratch"
	verified_hook_digest=$(sha256sum "$verified_hook_scratch" | awk '{ print $1 }')
	expected_hook_digest=$(hooks_metadata_digest "$verified_code_root" "$verified_hook_name") || {
		rm -f -- "$verified_hook_scratch"
		return 1
	}
	[ "$verified_hook_digest" = "$expected_hook_digest" ] || {
		rm -f -- "$verified_hook_scratch"
		return 1
	}
	verified_hook_size=$(wc -c <"$verified_hook_scratch")
	verified_file_size=$(wc -c <"$verified_hook_path")
	if [ "$verified_file_size" -lt "$verified_hook_size" ] ||
		! tail -c "$verified_hook_size" "$verified_hook_path" | cmp -s - "$verified_hook_scratch"; then
		rm -f -- "$verified_hook_scratch"
		return 1
	fi
	[ "$(grep -c '^# BEGIN NUTMerlin managed block:' "$verified_hook_path")" -eq 1 ] || {
		rm -f -- "$verified_hook_scratch"
		return 1
	}
	[ "$(grep -c '^# END NUTMerlin managed block:' "$verified_hook_path")" -eq 1 ] || {
		rm -f -- "$verified_hook_scratch"
		return 1
	}
	rm -f -- "$verified_hook_scratch"
}

hooks_verify_all() {
	verified_code_root=$1
	verified_hook_root=$NUTMERLIN_JFFS_ROOT/scripts
	[ -d "$verified_hook_root" ] && [ ! -L "$verified_hook_root" ] || return 1
	verified_hook_id=$(cat "$verified_code_root/installation.id")
	metadata_inventory=$(awk -F '\t' '{ print $1 }' "$verified_code_root/hooks.tsv")
	[ "$metadata_inventory" = 'services-start
services-stop
post-mount
unmount
firewall-start' ] || return 1
	for verified_hook_name in $hooks_names; do
		hooks_verify_one "$verified_hook_root" "$verified_hook_name" "$verified_hook_id" \
			"$verified_code_root" || return 1
	done
}

hooks_classify_one() {
	classified_hook_root=$1
	classified_hook_name=$2
	classified_hook_id=$3
	classified_code_root=$4
	classified_hook_path=$classified_hook_root/$classified_hook_name
	HOOKS_STATE=missing
	if [ ! -e "$classified_hook_path" ] && [ ! -L "$classified_hook_path" ]; then
		export HOOKS_STATE
		return 0
	fi
	[ -f "$classified_hook_path" ] && [ ! -L "$classified_hook_path" ] || return 78
	[ "$(stat -c '%h' "$classified_hook_path")" = 1 ] || return 78
	[ "$(stat -c '%u' "$classified_hook_path")" = "$(id -u)" ] || return 78
	classified_hook_mode=$(stat -c '%a' "$classified_hook_path")
	case $classified_hook_mode in
		[1357][0145][0145]) ;;
		*) return 78 ;;
	esac
	if hooks_verify_one "$classified_hook_root" "$classified_hook_name" \
		"$classified_hook_id" "$classified_code_root"; then
		HOOKS_STATE=exact
		export HOOKS_STATE
		return 0
	fi
	if grep -E '(^|[^[:alnum:]_-])(upsd|upsdrvctl|dummy-ups|usbhid-ups|NUT_CONFPATH)([^[:alnum:]_-]|$)' \
		"$classified_hook_path" >/dev/null 2>&1 ||
		grep -F 'NUTMerlin managed block:' "$classified_hook_path" >/dev/null 2>&1; then
		return 78
	fi
	export HOOKS_STATE
}

hooks_repairable_all() {
	repairable_hook_code_root=$1
	repairable_hook_root=$NUTMERLIN_JFFS_ROOT/scripts
	if [ ! -e "$repairable_hook_root" ] && [ ! -L "$repairable_hook_root" ]; then
		return 0
	fi
	[ -d "$repairable_hook_root" ] && [ ! -L "$repairable_hook_root" ] || return 78
	repairable_hook_id=$(cat "$repairable_hook_code_root/installation.id")
	ownership_id_is_valid "$repairable_hook_id" || return 78
	for repairable_hook_name in $hooks_names; do
		hooks_classify_one "$repairable_hook_root" "$repairable_hook_name" \
			"$repairable_hook_id" "$repairable_hook_code_root" || return 78
	done
}

hooks_repair_all() (
	repair_hook_code_root=$1
	repair_hook_root=$NUTMERLIN_JFFS_ROOT/scripts
	repair_hook_id=$(cat "$repair_hook_code_root/installation.id")
	hooks_repairable_all "$repair_hook_code_root" || return $?
	if [ ! -e "$repair_hook_root" ]; then
		ownership_layout_parent_is_safe "$NUTMERLIN_JFFS_ROOT" || return 78
		mkdir -m 755 "$repair_hook_root" || return 75
	fi
	repair_hook_scratch=$(mktemp -d "$NUTMERLIN_TMP_ROOT/.nutmerlin-hook-repair.XXXXXX") || return 75
	repair_hook_candidate=
	trap 'rm -rf -- "$repair_hook_scratch"; [ -z "$repair_hook_candidate" ] || rm -f -- "$repair_hook_candidate"' \
		EXIT HUP INT TERM
	for repair_hook_name in $hooks_names; do
		hooks_classify_one "$repair_hook_root" "$repair_hook_name" "$repair_hook_id" \
			"$repair_hook_code_root" || return 78
		[ "$HOOKS_STATE" = missing ] || continue
		repair_hook_path=$repair_hook_root/$repair_hook_name
		repair_hook_candidate=$repair_hook_root/.nutmerlin-repair-$repair_hook_name-$repair_hook_id
		[ ! -e "$repair_hook_candidate" ] && [ ! -L "$repair_hook_candidate" ] || return 78
		if [ -e "$repair_hook_path" ]; then
			repair_hook_mode=$(stat -c '%a' "$repair_hook_path")
			cp "$repair_hook_path" "$repair_hook_scratch/$repair_hook_name.original" || return 75
			cp "$repair_hook_path" "$repair_hook_candidate" || return 75
			[ ! -s "$repair_hook_candidate" ] || printf '\n' >>"$repair_hook_candidate"
		else
			repair_hook_mode=755
			: >"$repair_hook_candidate"
		fi
		hooks_render_block "$repair_hook_name" "$repair_hook_id" "$repair_hook_code_root" \
			>>"$repair_hook_candidate"
		chmod "$repair_hook_mode" "$repair_hook_candidate" || return 75
		if [ -e "$repair_hook_path" ]; then
			hooks_file_matches_snapshot "$repair_hook_path" \
				"$repair_hook_scratch/$repair_hook_name.original" "$repair_hook_mode" || return 78
		elif [ -e "$repair_hook_path" ] || [ -L "$repair_hook_path" ]; then
			return 78
		fi
		mv "$repair_hook_candidate" "$repair_hook_path" || return 75
		repair_hook_candidate=
		hooks_verify_one "$repair_hook_root" "$repair_hook_name" "$repair_hook_id" \
			"$repair_hook_code_root" || return 78
	done
	hooks_verify_all "$repair_hook_code_root"
)

hooks_remove_all() (
	remove_hook_code_root=$1
	remove_hook_root=$NUTMERLIN_JFFS_ROOT/scripts
	remove_hook_id=$(cat "$remove_hook_code_root/installation.id")
	hooks_repairable_all "$remove_hook_code_root" || return $?
	remove_hook_scratch=$(mktemp -d "$NUTMERLIN_TMP_ROOT/.nutmerlin-hook-remove.XXXXXX") || return 75
	remove_hook_candidate=
	trap 'rm -rf -- "$remove_hook_scratch"; [ -z "$remove_hook_candidate" ] || rm -f -- "$remove_hook_candidate"' \
		EXIT HUP INT TERM
	for remove_hook_name in $hooks_names; do
		hooks_classify_one "$remove_hook_root" "$remove_hook_name" "$remove_hook_id" \
			"$remove_hook_code_root" || return 78
		[ "$HOOKS_STATE" = exact ] || continue
		remove_hook_path=$remove_hook_root/$remove_hook_name
		remove_hook_mode=$(stat -c '%a' "$remove_hook_path")
		remove_hook_snapshot=$remove_hook_scratch/$remove_hook_name.original
		remove_hook_block=$remove_hook_scratch/$remove_hook_name.block
		cp "$remove_hook_path" "$remove_hook_snapshot" || return 75
		hooks_render_block "$remove_hook_name" "$remove_hook_id" "$remove_hook_code_root" \
			>"$remove_hook_block"
		remove_hook_size=$(wc -c <"$remove_hook_path")
		remove_block_size=$(wc -c <"$remove_hook_block")
		[ "$remove_hook_size" -ge "$remove_block_size" ] || return 78
		remove_prefix_size=$((remove_hook_size - remove_block_size))
		remove_original_size=$remove_prefix_size
		if [ "$remove_prefix_size" -gt 0 ]; then
			remove_original_size=$((remove_prefix_size - 1))
		fi
		remove_hook_candidate=$remove_hook_root/.nutmerlin-remove-$remove_hook_name-$remove_hook_id
		[ ! -e "$remove_hook_candidate" ] && [ ! -L "$remove_hook_candidate" ] || return 78
		if [ "$remove_original_size" -eq 0 ]; then
			: >"$remove_hook_candidate"
		else
			dd if="$remove_hook_path" of="$remove_hook_candidate" bs=1 \
				count="$remove_original_size" 2>/dev/null || return 75
		fi
		chmod "$remove_hook_mode" "$remove_hook_candidate" || return 75
		hooks_file_matches_snapshot "$remove_hook_path" "$remove_hook_snapshot" \
			"$remove_hook_mode" || return 78
		mv "$remove_hook_candidate" "$remove_hook_path" || return 75
		remove_hook_candidate=
		hooks_classify_one "$remove_hook_root" "$remove_hook_name" "$remove_hook_id" \
			"$remove_hook_code_root" || return 78
		[ "$HOOKS_STATE" = missing ] || return 78
	done
)

hooks_file_matches_snapshot() {
	hooks_live_path=$1
	hooks_snapshot_path=$2
	hooks_expected_mode=$3
	[ -f "$hooks_live_path" ] && [ ! -L "$hooks_live_path" ] || return 1
	[ "$(stat -c '%h' "$hooks_live_path")" = 1 ] || return 1
	[ "$(stat -c '%u' "$hooks_live_path")" = "$(id -u)" ] || return 1
	[ "$(stat -c '%a' "$hooks_live_path")" = "$hooks_expected_mode" ] || return 1
	cmp -s "$hooks_live_path" "$hooks_snapshot_path"
}

hooks_install_all() {
	hook_install_id=$1
	hook_install_code_root=$2
	installed_hook_root=$NUTMERLIN_JFFS_ROOT/scripts
	NUTMERLIN_HOOK_BACKUP_ROOT=$NUTMERLIN_TMP_ROOT/.nutmerlin-hook-backup-$hook_install_id
	NUTMERLIN_HOOK_ROOT_CREATED=0
	NUTMERLIN_HOOK_INSTALL_ACTIVE=0
	export NUTMERLIN_HOOK_BACKUP_ROOT NUTMERLIN_HOOK_ROOT_CREATED NUTMERLIN_HOOK_INSTALL_ACTIVE
	[ ! -e "$NUTMERLIN_HOOK_BACKUP_ROOT" ] && [ ! -L "$NUTMERLIN_HOOK_BACKUP_ROOT" ] || return 78
	mkdir -m 700 "$NUTMERLIN_HOOK_BACKUP_ROOT" || return 75
	NUTMERLIN_HOOK_INSTALL_ACTIVE=1
	export NUTMERLIN_HOOK_INSTALL_ACTIVE
	if [ -e "$installed_hook_root" ] || [ -L "$installed_hook_root" ]; then
		[ -d "$installed_hook_root" ] && [ ! -L "$installed_hook_root" ] || return 78
	else
		mkdir -m 755 "$installed_hook_root" || return 75
		NUTMERLIN_HOOK_ROOT_CREATED=1
		export NUTMERLIN_HOOK_ROOT_CREATED
	fi

	for installed_hook_name in $hooks_names; do
		installed_hook_path=$installed_hook_root/$installed_hook_name
		installed_hook_candidate=$installed_hook_root/.nutmerlin-$installed_hook_name-$hook_install_id
		[ ! -e "$installed_hook_candidate" ] && [ ! -L "$installed_hook_candidate" ] || return 78
		if [ -e "$installed_hook_path" ] || [ -L "$installed_hook_path" ]; then
			[ -f "$installed_hook_path" ] && [ ! -L "$installed_hook_path" ] || return 78
			[ "$(stat -c '%h' "$installed_hook_path")" = 1 ] || return 78
			[ "$(stat -c '%u' "$installed_hook_path")" = "$(id -u)" ] || return 78
			installed_hook_mode=$(stat -c '%a' "$installed_hook_path")
			case $installed_hook_mode in
				[1357][0145][0145]) ;;
				*) return 78 ;;
			esac
			cp "$installed_hook_path" "$NUTMERLIN_HOOK_BACKUP_ROOT/$installed_hook_name"
			printf '%s\n' "$installed_hook_mode" >"$NUTMERLIN_HOOK_BACKUP_ROOT/$installed_hook_name.mode"
			cp "$installed_hook_path" "$installed_hook_candidate"
			[ ! -s "$installed_hook_candidate" ] || printf '\n' >>"$installed_hook_candidate"
		else
			: >"$NUTMERLIN_HOOK_BACKUP_ROOT/$installed_hook_name.absent"
			: >"$installed_hook_candidate"
			installed_hook_mode=755
		fi
		hooks_render_block "$installed_hook_name" "$hook_install_id" "$hook_install_code_root" \
			>>"$installed_hook_candidate"
		chmod "$installed_hook_mode" "$installed_hook_candidate"
		installed_hook_snapshot=$NUTMERLIN_HOOK_BACKUP_ROOT/$installed_hook_name.installed
		[ ! -e "$installed_hook_snapshot" ] && [ ! -L "$installed_hook_snapshot" ] || return 78
		cp "$installed_hook_candidate" "$installed_hook_snapshot"
		chmod "$installed_hook_mode" "$installed_hook_snapshot"
		hooks_file_matches_snapshot "$installed_hook_candidate" "$installed_hook_snapshot" \
			"$installed_hook_mode" || return 78
		if [ -f "$NUTMERLIN_HOOK_BACKUP_ROOT/$installed_hook_name.absent" ]; then
			if [ -e "$installed_hook_path" ] || [ -L "$installed_hook_path" ]; then
				rm -f -- "$installed_hook_candidate"
				return 78
			fi
		else
			hooks_file_matches_snapshot "$installed_hook_path" \
				"$NUTMERLIN_HOOK_BACKUP_ROOT/$installed_hook_name" "$installed_hook_mode" || {
				rm -f -- "$installed_hook_candidate"
				return 78
			}
		fi
		mv "$installed_hook_candidate" "$installed_hook_path" || {
			rm -f -- "$installed_hook_candidate"
			return 75
		}
		if [ "${NUTMERLIN_ENABLE_TEST_ADAPTERS:-0}" = 1 ] &&
			command -v hooks_test_after_publish >/dev/null 2>&1; then
			hooks_test_after_publish "$installed_hook_path" "$installed_hook_name"
		fi
		hooks_file_matches_snapshot "$installed_hook_path" "$installed_hook_snapshot" \
			"$installed_hook_mode" || return 78
		if [ "${NUTMERLIN_ENABLE_TEST_ADAPTERS:-0}" = 1 ] &&
			[ "${NUTMERLIN_TEST_HOOK_INSTALL_FAIL_AFTER:-}" = "$installed_hook_name" ]; then
			return 75
		fi
	done
}

hooks_rollback_install() {
	[ "${NUTMERLIN_HOOK_INSTALL_ACTIVE:-0}" = 1 ] || return 0
	installed_hook_root=$NUTMERLIN_JFFS_ROOT/scripts
	rollback_status=0
	for rollback_hook_name in $hooks_names; do
		rollback_hook_path=$installed_hook_root/$rollback_hook_name
		rollback_installed_snapshot=$NUTMERLIN_HOOK_BACKUP_ROOT/$rollback_hook_name.installed
		[ -f "$rollback_installed_snapshot" ] || continue
		rollback_installed_mode=$(stat -c '%a' "$rollback_installed_snapshot")
		if [ -f "$NUTMERLIN_HOOK_BACKUP_ROOT/$rollback_hook_name.absent" ] &&
			[ ! -e "$rollback_hook_path" ] && [ ! -L "$rollback_hook_path" ]; then
			continue
		fi
		if [ -f "$NUTMERLIN_HOOK_BACKUP_ROOT/$rollback_hook_name" ]; then
			rollback_original_mode=$(cat "$NUTMERLIN_HOOK_BACKUP_ROOT/$rollback_hook_name.mode")
			if hooks_file_matches_snapshot "$rollback_hook_path" \
				"$NUTMERLIN_HOOK_BACKUP_ROOT/$rollback_hook_name" "$rollback_original_mode"; then
				continue
			fi
		fi
		if ! hooks_file_matches_snapshot "$rollback_hook_path" "$rollback_installed_snapshot" \
			"$rollback_installed_mode"; then
			printf 'NUTMerlin hook rollback refused concurrent change: %s\n' \
				"$rollback_hook_path" >&2
			rollback_status=78
			continue
		fi
		if [ -f "$NUTMERLIN_HOOK_BACKUP_ROOT/$rollback_hook_name.absent" ]; then
			rm -f -- "$rollback_hook_path"
		elif [ -f "$NUTMERLIN_HOOK_BACKUP_ROOT/$rollback_hook_name" ]; then
			rollback_candidate=$installed_hook_root/.nutmerlin-rollback-$rollback_hook_name
			if [ -e "$rollback_candidate" ] || [ -L "$rollback_candidate" ]; then
				rollback_status=78
				continue
			fi
			cp "$NUTMERLIN_HOOK_BACKUP_ROOT/$rollback_hook_name" "$rollback_candidate" || {
				rollback_status=75
				continue
			}
			chmod "$rollback_original_mode" "$rollback_candidate" || {
				rm -f -- "$rollback_candidate"
				rollback_status=75
				continue
			}
			hooks_file_matches_snapshot "$rollback_candidate" \
				"$NUTMERLIN_HOOK_BACKUP_ROOT/$rollback_hook_name" "$rollback_original_mode" || {
				rm -f -- "$rollback_candidate"
				rollback_status=78
				continue
			}
			hooks_file_matches_snapshot "$rollback_hook_path" "$rollback_installed_snapshot" \
				"$rollback_installed_mode" || {
				rm -f -- "$rollback_candidate"
				printf 'NUTMerlin hook rollback refused concurrent change: %s\n' \
					"$rollback_hook_path" >&2
				rollback_status=78
				continue
			}
			mv "$rollback_candidate" "$rollback_hook_path" || {
				rm -f -- "$rollback_candidate"
				rollback_status=75
			}
		fi
	done
	if [ "$rollback_status" -eq 0 ]; then
		rm -rf -- "$NUTMERLIN_HOOK_BACKUP_ROOT"
	else
		printf 'NUTMerlin hook rollback evidence retained: %s\n' \
			"$NUTMERLIN_HOOK_BACKUP_ROOT" >&2
	fi
	if [ "${NUTMERLIN_HOOK_ROOT_CREATED:-0}" = 1 ]; then
		rmdir "$installed_hook_root" 2>/dev/null || :
	fi
	NUTMERLIN_HOOK_INSTALL_ACTIVE=0
	export NUTMERLIN_HOOK_INSTALL_ACTIVE
	return "$rollback_status"
}

hooks_commit_install() {
	rm -rf -- "$NUTMERLIN_HOOK_BACKUP_ROOT"
	NUTMERLIN_HOOK_INSTALL_ACTIVE=0
	export NUTMERLIN_HOOK_INSTALL_ACTIVE
}
