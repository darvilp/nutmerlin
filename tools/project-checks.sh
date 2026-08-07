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
		-type f -name '*.sh' -print
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
	for document in AGENTS.md CONTEXT.md README.md requirements.md architecture.md security.md testing.md hardware.md development.md plan.md; do
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
	mv -- "$temporary_package" "$repository_root/dist/nutmerlin-core-dev.tar.gz"
	package_digest=$(sha256sum "$repository_root/dist/nutmerlin-core-dev.tar.gz" |
		awk '{ print $1 }')
	printf '%s  %s\n' "$package_digest" nutmerlin-core-dev.tar.gz \
		>"$repository_root/dist/nutmerlin-core-dev.tar.gz.sha256"
	rm -f -- "$temporary_archive" "$comparison_archive" "$comparison_package"
	rm -rf -- "$package_stage"
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
	*)
		printf '%s\n' 'usage: project-checks.sh bootstrap|lint|test-unit|test-nut|test-security|docs-check|package' >&2
		exit 64
		;;
esac
