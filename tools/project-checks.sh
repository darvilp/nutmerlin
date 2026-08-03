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
	for required_nut_binary in dummy-ups upsd upsc; do
		if ! nut_binary_is_available "$required_nut_binary"; then
			printf 'missing required host NUT binary: %s\n' "$required_nut_binary" >&2
			missing=1
		fi
	done
	[ "$missing" -eq 0 ]
}

shell_files() {
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
	temporary_archive=$(mktemp "${TMPDIR:-/tmp}/nutmerlin-core-tar.XXXXXX")
	temporary_package=$(mktemp "${TMPDIR:-/tmp}/nutmerlin-core.XXXXXX")
	comparison_archive=$(mktemp "${TMPDIR:-/tmp}/nutmerlin-core-compare-tar.XXXXXX")
	comparison_package=$(mktemp "${TMPDIR:-/tmp}/nutmerlin-core-compare.XXXXXX")
	trap 'rm -f -- "$temporary_archive" "$temporary_package" "$comparison_archive" "$comparison_package"' EXIT HUP INT TERM

	build_package() {
		build_archive=$1
		build_output=$2
		(
			cd "$repository_root"
			tar --sort=name --mtime=@0 --owner=0 --group=0 --numeric-owner \
				-cf "$build_archive" LICENSE bin lib share
		)
		gzip -n -c "$build_archive" >"$build_output"
	}

	build_package "$temporary_archive" "$temporary_package"
	test -x "$repository_root/bin/nutmerlin"
	test -x "$repository_root/lib/nutmerlin/result.sh"
	test -s "$repository_root/share/dummy/cyberpower.dev"
	package_listing=$(tar -tzf "$temporary_package")
	test "$package_listing" = 'LICENSE
bin/
bin/nutmerlin
lib/
lib/nutmerlin/
lib/nutmerlin/result.sh
share/
share/dummy/
share/dummy/cyberpower.dev'
	build_package "$comparison_archive" "$comparison_package"
	if ! cmp -s "$temporary_package" "$comparison_package"; then
		printf '%s\n' 'package build is not byte-deterministic' >&2
		return 1
	fi
	mv -- "$temporary_package" "$repository_root/dist/nutmerlin-core-dev.tar.gz"
	rm -f -- "$temporary_archive" "$comparison_archive" "$comparison_package"
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
		bats "$repository_root/test/integration/dummy-nut.bats"
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
