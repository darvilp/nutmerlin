# NUTMerlin repository and release policy

## 1. Confirmed repository

- GitHub repository: darvilp/nutmerlin
- Visibility: public
- License: GPL-3.0-or-later
- CI: GitHub Actions
- Default branch: main
- Development workflow: feature branch → draft pull request → review → merge

The repository already exists. Documentation and automation shall not contain the superseded danielarvilpayne owner.

## 2. Branch protection

main should require:

- pull request before ordinary merge;
- required host CI checks;
- branch up to date before merge where practical;
- no force pushes;
- no branch deletion.

A solo maintainer may retain an emergency bypass, but normal project and Codex work uses reviewed branches and preserves unrelated worktree changes.

## 3. CI and hardware separation

Ordinary pull requests run hardware-free checks for:

- lint and POSIX shell conformance;
- host platform/mock tests;
- configuration generation;
- policy/action state;
- NUT dummy-ups integration;
- security and input validation;
- documentation links/consistency;
- package/release artifact construction.

Current Entware AArch64 package/ABI execution is required release evidence even when it is not part of every pull request.

Exact-router, storage, physical-UPS, Windows shutdown, WinRM, and Redfish tests are manually triggered evidence workflows. They do not become ordinary PR gates.

## 4. Issue and pull-request boundaries

Priority and area labels may describe accepted capability scope, but a milestone label does not grant safety authority or replace evidence.

Useful label families include:

- priority:P0, priority:P1, priority:P2;
- area:platform, area:nut, area:ui, area:policy, area:executor, area:security, area:testing;
- hardware:required, hardware:legacy, hardware:production-reference;
- blocked and good first issue.

Tickets generated from a later specification should retain explicit blocking relationships. Raw incoming community reports are triaged separately from already agent-ready project tickets.

## 5. Authenticated release artifacts

An installable release publishes separate:

- source archive;
- required installable core archive;
- optional exact-version WebUI archive;
- canonical release manifest;
- detached OpenPGP signature;
- plain SHA-256 diagnostic checksums;
- dependency/package provenance;
- supported-platform and exact-hardware evidence;
- migration and rollback notes;
- known incompatibilities and absent conditional capabilities.

The signed manifest covers the version-locked core and WebUI artifacts, artifact names, byte sizes, SHA-256 hashes, compatibility metadata, component dependencies, and installer requirement. Plain hashes are diagnostic and never substitute for authentication. The WebUI has no separate release identity or update channel.

CI produces deterministic artifacts and the completed canonical manifest. A maintainer signs that exact manifest outside CI with the accepted release-signing subkey after required evidence passes.

Release publication and first install remain blocked until two independent project-controlled fingerprint channels and the emergency signing-root replacement procedure are selected and tested.

## 6. Update and catalog policy

NUTMerlin updates are administrator-initiated. There is no automatic install/update channel.

An AMTM or other catalog entry is Later and requires a separate accepted model for:

- pinned release trust;
- artifact ownership;
- maintainer identity;
- update initiation;
- safe activation and rollback;
- signing-root rotation/revocation;
- emergency response.

Catalog convenience cannot bypass the authenticated bundle, signed manifest, safe update window, or rollback quarantine.

## 7. Milestones

Repository milestones follow plan.md:

- P0 safe NUT core;
- P1 common graceful orchestration;
- P2 independently qualified native graceful adapters;
- Later separately governed broad/high-risk scope.

There is no separate final hardening milestone. Security, recovery, documentation, negative testing, and support evidence are exit gates for every capability.
