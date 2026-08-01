# NUTMerlin repository setup

## 1. Confirmed defaults

- GitHub owner: `danielarvilpayne`
- Repository: `nutmerlin`
- Visibility: public
- License: GPL-3.0-or-later
- CI: GitHub Actions
- Default branch: `main`
- Development workflow: feature branch -> draft pull request -> review -> merge

The repository should be created only when the local starter packet is ready to become the initial commit.

## 2. Creation from WSL2

Authenticate:

```sh
gh auth status || gh auth login
```

From the repository root:

```sh
git init -b main
git add .
git commit -m "docs: define NUTMerlin architecture and development plan"

gh repo create danielarvilpayne/nutmerlin \
  --public \
  --source=. \
  --remote=origin \
  --push \
  --description "Asuswrt-Merlin addon for Network UPS Tools and safe power-event orchestration"
```

Do not run the command if a repository with that name already exists. Check first:

```sh
gh repo view danielarvilpayne/nutmerlin
```

## 3. Initial repository contents

Before the first push, include:

```text
.github/workflows/ci.yml
.gitignore
.editorconfig
LICENSE
README.md
AGENTS.md
requirements.md
architecture.md
plan.md
testing.md
security.md
hardware.md
development.md
repository.md
backlog.md
references.md
decisions/
test/scenarios/
```

Implementation directories can be created empty or with README placeholders:

```text
src/
lib/
web/
installer/
test/unit/
test/integration/
test/shims/
tools/
packaging/
```

## 4. Initial branch protection

After CI exists, configure `main` to require:

- pull request before merge
- required CI checks
- branch up to date before merge
- no force pushes
- no branch deletion

A solo-maintainer project may allow the owner to bypass protection for emergency recovery, but ordinary Codex work should still use pull requests.

## 5. Initial GitHub Actions jobs

Start with host-only jobs:

```text
lint
unit-platform-mock
unit-config
unit-policy
integration-nut-dummy
security-input-validation
package-artifact
```

Hardware tests are manual workflows and must never be required for a normal pull request.

## 6. Suggested milestones

1. `M0 Repository and test harness`
2. `M1 NUT server MVP`
3. `M2 Merlin UI`
4. `M3 Policy engine`
5. `M4 Common executors`
6. `M5 Community beta`

## 7. Suggested labels

```text
priority:P0
priority:P1
priority:P2
area:platform
area:nut
area:ui
area:policy
area:executor
area:security
area:testing
hardware:required
hardware:ac3100
hardware:ax86u-pro
ups:cp1500pfclcd
good first issue
blocked
```

## 8. Release model

Initial releases should publish:

- source archive
- installable addon archive
- SHA-256 checksums
- generated dependency manifest
- supported/tested hardware report
- upgrade and rollback notes

Do not implement an auto-update channel until update authenticity, rollback, and ownership behavior are tested.
