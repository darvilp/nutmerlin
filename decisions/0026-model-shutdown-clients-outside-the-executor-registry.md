# ADR 0026: Model shutdown clients outside the executor registry

- Status: Accepted
- Date: 2026-08-02

## Context

The initial architecture lists `nut_client` as an executor and uses it as an action in a sample router policy. In the default client-local pattern, however, NUTMerlin provides server access and onboarding while independent client software owns the policy and invokes its local shutdown command. The router neither dispatches that command nor verifies its result.

## Decision

A shutdown client is a P0 NUT-access and onboarding resource, not an executor or router-policy target.

- Remove `nut_client` from the executor registry and from router-side action schemas.
- NUTMerlin may manage the client's identity, secondary-role credential, connection instructions, and explicitly supported observations without reporting an execution result.
- Client-local policy, timer, commit boundary, and shutdown command remain owned by the client.
- Client connection or authentication does not prove that the local action is configured or that the host can power down.
- Client-local validation results are reported separately from router-dispatched executor results.
- The local-script adapter is the first actual P0 executor.
- `nut_fsd` remains an executor because NUTMerlin actively sends a committed FSD request and records its outcome.

## Consequences

- Milestone 1 owns shutdown-client onboarding, while Milestone 3 begins router-side execution with the local-script executor.
- The UI cannot present one superficially uniform action list for client-local and centrally dispatched shutdown patterns.
- Audit records distinguish observations and onboarding state from attempted remote side effects.

## Rejected alternative

Keeping a declarative `nut_client` executor whose result meant only that a client was expected to respond would simplify the UI model, but would conflate expectation with dispatch and could imply a shutdown was attempted or verified when it was not.
