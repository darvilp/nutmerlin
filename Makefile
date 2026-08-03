.PHONY: bootstrap install lint test-unit test test-nut test-security docs-check package

bootstrap:
	@tools/project-checks.sh bootstrap

install:
	@test -n "$(DESTDIR)" || { printf '%s\n' 'DESTDIR is required for development install' >&2; exit 64; }
	@NUTMERLIN_ENABLE_TEST_ADAPTERS=1 NUTMERLIN_TEST_ROOT="$(DESTDIR)" ./install.sh

lint:
	@tools/project-checks.sh lint

test-unit:
	@tools/project-checks.sh test-unit

test: lint test-unit test-security docs-check

test-nut:
	@tools/project-checks.sh test-nut

test-security:
	@tools/project-checks.sh test-security

docs-check:
	@tools/project-checks.sh docs-check

package:
	@tools/project-checks.sh package
