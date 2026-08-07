#!/bin/sh

set -eu

repository_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
command_name=${1:-}

require_commands() {
	missing=0
	for required_command in make shellcheck shfmt bats cmp jq rg tar gzip ss; do
		if ! command -v "$required_command" >/dev/null 2>&1; then
			printf 'missing required host command: %s\n' "$required_command" >&2
			missing=1
		fi
	done
	[ "$missing" -eq 0 ]
}

nut_binary_is_available() {
	nut_binary_name=$1
	if [ -n "${NUTMERLIN_NUT_ROOT:-}" ]; then
		for nut_binary_candidate in \
			"$NUTMERLIN_NUT_ROOT/lib/nut/$nut_binary_name" \
			"$NUTMERLIN_NUT_ROOT/usr/lib/nut/$nut_binary_name" \
			"$NUTMERLIN_NUT_ROOT/sbin/$nut_binary_name" \
			"$NUTMERLIN_NUT_ROOT/usr/sbin/$nut_binary_name" \
			"$NUTMERLIN_NUT_ROOT/bin/$nut_binary_name" \
			"$NUTMERLIN_NUT_ROOT/usr/bin/$nut_binary_name"; do
			[ -x "$nut_binary_candidate" ] && return 0
		done
		return 1
	fi

	for nut_binary_candidate in \
		"/lib/nut/$nut_binary_name" \
		"/usr/lib/nut/$nut_binary_name" \
		"/usr/sbin/$nut_binary_name" \
		"/usr/bin/$nut_binary_name"; do
		[ -x "$nut_binary_candidate" ] && return 0
	done
	command -v "$nut_binary_name" >/dev/null 2>&1
}

require_nut_binaries() {
	missing=0
	for required_nut_binary in dummy-ups upsd upsc usbhid-ups; do
		if ! nut_binary_is_available "$required_nut_binary"; then
			printf 'missing required host NUT binary: %s\n' "$required_nut_binary" >&2
			missing=1
		fi
	done
	[ "$missing" -eq 0 ]
}

shell_files() {
	printf '%s\n' "$repository_root/install.sh"
	find "$repository_root/bin" "$repository_root/lib" "$repository_root/test" "$repository_root/tools" \
		-type f \( -name '*.sh' -o -name '*.sh.in' \) -print
	find "$repository_root/bin" -type f -print
}

run_lint() {
	require_commands
	shell_files | while IFS= read -r shell_file; do
		sh -n "$shell_file"
		shellcheck -s sh "$shell_file"
		shfmt -d -i 0 -ci "$shell_file"
	done
}

run_docs_check() {
	require_commands
	for document in AGENTS.md CONTEXT.md INSTALL.md README.md requirements.md architecture.md security.md testing.md hardware.md development.md plan.md; do
		test -s "$repository_root/$document"
	done
	test ! -e "$repository_root/docs/adr"

	find "$repository_root" -path "$repository_root/.git" -prune -o -name '*.md' -type f -print |
		while IFS= read -r markdown_file; do
			{ rg -o --no-filename '\[[^]]+\]\([^)]+\)' "$markdown_file" || [ "$?" -eq 1 ]; } |
				while IFS= read -r markdown_link; do
					link_target=$(printf '%s\n' "$markdown_link" | sed 's/^[^(]*(//; s/)$//; s/#.*$//')
					case $link_target in
						'' | http://* | https://* | mailto:*) continue ;;
					esac
					test -e "$(dirname -- "$markdown_file")/$link_target"
				done
		done

	{ rg -o --no-filename 'ADR [0-9][0-9][0-9][0-9]' \
		"$repository_root"/*.md || [ "$?" -eq 1 ]; } | sort -u |
		while IFS=' ' read -r _ adr_number; do
			find "$repository_root/decisions" -name "$adr_number-*.md" -print -quit | grep -q .
		done
}

run_package() {
	package_basename=${1:-nutmerlin-core-dev.tar.gz}
	case $package_basename in
		nutmerlin-core-*.tar.gz) ;;
		*)
			printf '%s\n' 'package output basename is invalid' >&2
			return 64
			;;
	esac
	require_commands
	mkdir -p "$repository_root/dist"
	package_stage=$(mktemp -d "${TMPDIR:-/tmp}/nutmerlin-core-stage.XXXXXX")
	temporary_archive=$(mktemp "${TMPDIR:-/tmp}/nutmerlin-core-tar.XXXXXX")
	temporary_package=$(mktemp "${TMPDIR:-/tmp}/nutmerlin-core.XXXXXX")
	comparison_archive=$(mktemp "${TMPDIR:-/tmp}/nutmerlin-core-compare-tar.XXXXXX")
	comparison_package=$(mktemp "${TMPDIR:-/tmp}/nutmerlin-core-compare.XXXXXX")
	trap 'rm -rf -- "$package_stage"; rm -f -- "$temporary_archive" "$temporary_package" "$comparison_archive" "$comparison_package"' EXIT HUP INT TERM

	mkdir -m 755 "$package_stage/bin" "$package_stage/lib" \
		"$package_stage/lib/nutmerlin" "$package_stage/share" "$package_stage/share/dummy"
	cp "$repository_root/LICENSE" "$repository_root/README.md" "$repository_root/VERSION" \
		"$repository_root/install.sh" "$package_stage/"
	cp "$repository_root/bin/nutmerlin" "$package_stage/bin/nutmerlin"
	cp "$repository_root/lib/nutmerlin/"*.sh "$package_stage/lib/nutmerlin/"
	cp "$repository_root/share/dummy/cyberpower.dev" \
		"$package_stage/share/dummy/cyberpower.dev"
	chmod 644 "$package_stage/LICENSE" "$package_stage/README.md" "$package_stage/VERSION" \
		"$package_stage/lib/nutmerlin/"*.sh "$package_stage/share/dummy/cyberpower.dev"
	chmod 755 "$package_stage/install.sh" "$package_stage/bin/nutmerlin"
	(
		cd "$package_stage"
		sha256sum LICENSE README.md VERSION bin/nutmerlin install.sh \
			lib/nutmerlin/*.sh share/dummy/cyberpower.dev >MANIFEST.sha256
	)
	chmod 644 "$package_stage/MANIFEST.sha256"

	build_package() {
		build_archive=$1
		build_output=$2
		(
			cd "$package_stage"
			tar --sort=name --mtime=@0 --owner=0 --group=0 --numeric-owner \
				-cf "$build_archive" LICENSE MANIFEST.sha256 README.md VERSION \
				bin install.sh lib share
		)
		gzip -n -c "$build_archive" >"$build_output"
	}

	build_package "$temporary_archive" "$temporary_package"
	test -x "$package_stage/install.sh"
	test -x "$package_stage/bin/nutmerlin"
	test -s "$package_stage/lib/nutmerlin/update.sh"
	test -s "$package_stage/share/dummy/cyberpower.dev"
	package_listing=$(tar -tzf "$temporary_package")
	test "$package_listing" = 'LICENSE
MANIFEST.sha256
README.md
VERSION
bin/
bin/nutmerlin
install.sh
lib/
lib/nutmerlin/
lib/nutmerlin/client.sh
lib/nutmerlin/configuration.sh
lib/nutmerlin/entware.sh
lib/nutmerlin/hooks.sh
lib/nutmerlin/lifecycle.sh
lib/nutmerlin/management.sh
lib/nutmerlin/menu.sh
lib/nutmerlin/ownership.sh
lib/nutmerlin/paths.sh
lib/nutmerlin/platform.sh
lib/nutmerlin/result.sh
lib/nutmerlin/service.sh
lib/nutmerlin/status.sh
lib/nutmerlin/update.sh
share/
share/dummy/
share/dummy/cyberpower.dev'
	build_package "$comparison_archive" "$comparison_package"
	if ! cmp -s "$temporary_package" "$comparison_package"; then
		printf '%s\n' 'package build is not byte-deterministic' >&2
		return 1
	fi
	mv -- "$temporary_package" "$repository_root/dist/$package_basename"
	package_digest=$(sha256sum "$repository_root/dist/$package_basename" |
		awk '{ print $1 }')
	printf '%s  %s\n' "$package_digest" "$package_basename" \
		>"$repository_root/dist/$package_basename.sha256"
	rm -f -- "$temporary_archive" "$comparison_archive" "$comparison_package"
	rm -rf -- "$package_stage"
	trap - EXIT HUP INT TERM
}

run_release_artifacts() {
	require_commands
	if [ ! -f "$repository_root/VERSION" ] || [ -L "$repository_root/VERSION" ]; then
		printf '%s\n' 'release artifact build refused: VERSION is missing or unsafe' >&2
		return 78
	fi
	[ "$(wc -l <"$repository_root/VERSION")" -eq 1 ] || {
		printf '%s\n' 'release artifact build refused: VERSION must contain one line' >&2
		return 78
	}
	release_version=$(cat "$repository_root/VERSION")
	if [ "${#release_version}" -gt 64 ] ||
		! printf '%s\n' "$release_version" |
		grep -Eq '^[0-9]+[.][0-9]+[.][0-9]+(-[A-Za-z0-9.]+)?$'; then
		printf '%s\n' 'release artifact build refused: VERSION is invalid' >&2
		return 78
	fi
	release_archive=nutmerlin-core-$release_version.tar.gz
	release_launcher=nutmerlin-install-$release_version.sh
	release_url=https://github.com/darvilp/nutmerlin/releases/download/v$release_version/$release_archive
	run_package "$release_archive"
	release_digest=$(sha256sum "$repository_root/dist/$release_archive" | awk '{ print $1 }')
	release_launcher_path=$repository_root/dist/$release_launcher
	release_launcher_comparison=$(mktemp "${TMPDIR:-/tmp}/nutmerlin-launcher-compare.XXXXXX")
	trap 'rm -f -- "$release_launcher_comparison"' EXIT HUP INT TERM

	render_release_launcher() {
		render_output=$1
		sed -e "s|@NUTMERLIN_VERSION@|$release_version|g" \
			-e "s|@NUTMERLIN_ARCHIVE@|$release_archive|g" \
			-e "s|@NUTMERLIN_DIGEST@|$release_digest|g" \
			-e "s|@NUTMERLIN_URL@|$release_url|g" \
			"$repository_root/tools/nutmerlin-install.sh.in" >"$render_output"
		chmod 755 "$render_output"
	}

	render_release_launcher "$release_launcher_path"
	render_release_launcher "$release_launcher_comparison"
	cmp -s "$release_launcher_path" "$release_launcher_comparison" || {
		printf '%s\n' 'release launcher build is not byte-deterministic' >&2
		return 1
	}
	/bin/sh -n "$release_launcher_path"
	shellcheck -s sh "$release_launcher_path"
	shfmt -d -i 0 -ci "$release_launcher_path"
	rm -f -- "$release_launcher_comparison"
	trap - EXIT HUP INT TERM
}

case $command_name in
	bootstrap)
		require_commands
		require_nut_binaries
		printf '%s\n' 'host prerequisites are available; no system or package state changed'
		;;
	lint)
		run_lint
		;;
	test-unit)
		require_commands
		bats "$repository_root/test/unit"
		;;
	test-nut)
		require_commands
		require_nut_binaries
		for integration_suite in "$repository_root"/test/integration/*.bats; do
			bats "$integration_suite"
		done
		;;
	test-security)
		require_commands
		bats "$repository_root/test/security"
		;;
	docs-check)
		run_docs_check
		;;
	package)
		run_package
		;;
	release-artifacts)
		run_release_artifacts
		;;
	*)
		printf '%s\n' 'usage: project-checks.sh bootstrap|lint|test-unit|test-nut|test-security|docs-check|package|release-artifacts' >&2
		exit 64
		;;
esac
