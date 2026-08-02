# ADR 0010: Refuse foreign or ambiguously owned NUT deployments

- Status: Accepted
- Date: 2026-08-01

## Context

An existing Entware NUT deployment may contain administrator-owned configuration, credentials, service conventions, or integrations that NUTMerlin cannot safely reproduce. In-place adoption would require a broad parser and migration surface before the core ownership and rollback model is proven.

## Decision

The MVP does not adopt existing foreign NUT deployments.

- Preflight classifies the deployment as absent, NUTMerlin-owned, foreign, or ambiguous.
- Foreign and ambiguous deployments cause installation to stop before mutation.
- Refusal mode is read-only and reports the files, processes, hooks, listeners, or ownership evidence that caused the classification.
- NUTMerlin does not stop, rename, back up, import, or modify foreign or ambiguously owned artifacts.
- The administrator must resolve ownership outside the installer before retrying.
- Installed NUT packages alone do not establish deployment ownership; package provenance is tracked separately.
- Constrained import or adoption is outside the MVP and requires a later explicit decision.

## Consequences

- Existing Entware NUT users must migrate manually before installing the MVP.
- Install, repair, upgrade, rollback, and uninstall can operate against a narrow project-owned artifact set.
- Detection and refusal remain P0; adoption leaves the P0 backlog.
- False foreign classifications are inconvenient but fail safely, while false ownership classifications could destroy administrator state and therefore must be prevented.

## Rejected alternative

A guided MVP adoption workflow could parse recognized directives, preview a diff, back up the deployment, and establish new ownership. It was rejected because unknown directives, secret handling, rollback, and partial adoption materially expand the initial safety surface.
