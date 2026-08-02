# ADR 0020: Use independent credentials for shutdown clients

- Status: Accepted
- Date: 2026-08-02

## Context

Standard NUT shutdown clients authenticate to `upsd` with an `upsmon` role. A shared secondary-role credential is simple to document, but removing or rotating one client then disrupts every client and a copied credential cannot be attributed or revoked independently.

## Decision

NUTMerlin issues an independent credential to every explicitly registered shutdown client.

- Each shutdown client has a stable, non-secret client ID and a separate administrator-facing display label.
- Each client receives a separately generated NUT username and password with only the `upsmon secondary` role.
- A credential is never reused across clients, installations, or roles.
- Removing or revoking one shutdown client removes only its server-side credential and atomically regenerates and validates the managed NUT configuration.
- Read-only NUT access remains credential-free and independent of shutdown-client registration.
- Ownership metadata may inventory a credential artifact but must not contain the credential value.
- Settings export excludes credential values, and clean uninstall removes them with other NUTMerlin-owned secrets.
- Generation strength, initial delivery, recovery, rotation, and transport protection remain separate credential-lifecycle decisions.

## Consequences

- One lost or retired client can be revoked without coordinating changes to every other host.
- Configuration and tests must support multiple generated NUT users and reject client-ID or username collisions.
- Onboarding has one secret per shutdown client instead of one household-wide shared value.

## Rejected alternative

One shared `upsmon secondary` credential for all shutdown clients would reduce setup and configuration size, but would couple every client's lifecycle and expand the impact of disclosure.
