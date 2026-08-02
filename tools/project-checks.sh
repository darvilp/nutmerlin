#!/bin/sh

set -eu

repository_root=$(CDPATH='' cd -- "$(dirname -- "$0")/.." && pwd)
command_name=${1:-}

require_commands() {
	missing=0
	for required_command in make shellcheck shfmt bats jq rg tar gzip python3; do
		if ! command -v "$required_command" >/dev/null 2>&1; then
			printf 'missing required host command: %s\n' "$required_command" >&2
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
	trap 'rm -f -- "$temporary_archive" "$temporary_package"' EXIT HUP INT TERM
	(
		cd "$repository_root"
		tar --sort=name --mtime=@0 --owner=0 --group=0 --numeric-owner \
			-cf "$temporary_archive" LICENSE bin lib
	)
	gzip -n -c "$temporary_archive" >"$temporary_package"
	test -x "$repository_root/bin/nutmerlin"
	test -x "$repository_root/lib/nutmerlin/management-operation.sh"
	package_listing=$(tar -tzf "$temporary_package")
	test "$package_listing" = 'LICENSE
bin/
bin/nutmerlin
lib/
lib/nutmerlin/
lib/nutmerlin/management-operation.sh
lib/nutmerlin/platform-eligibility.sh
lib/nutmerlin/platform-qualification.sh
lib/nutmerlin/storage-preflight.sh
lib/nutmerlin/storage-qualification.sh'
	mv -- "$temporary_package" "$repository_root/dist/nutmerlin-core-dev.tar.gz"
	rm -f -- "$temporary_archive"
	trap - EXIT HUP INT TERM
}

case $command_name in
	bootstrap)
		require_commands
		printf '%s\n' 'host prerequisites are available; no system or package state changed'
		;;
	lint)
		run_lint
		;;
	test-unit)
		require_commands
		bats "$repository_root/test/unit"
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
		printf '%s\n' 'usage: project-checks.sh bootstrap|lint|test-unit|test-security|docs-check|package' >&2
		exit 64
		;;
esac
