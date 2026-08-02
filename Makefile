.PHONY: bootstrap lint test-unit test test-security docs-check package

bootstrap:
	@tools/project-checks.sh bootstrap

lint:
	@tools/project-checks.sh lint

test-unit:
	@tools/project-checks.sh test-unit

test: lint test-unit test-security docs-check

test-security:
	@tools/project-checks.sh test-security

docs-check:
	@tools/project-checks.sh docs-check

package:
	@tools/project-checks.sh package
