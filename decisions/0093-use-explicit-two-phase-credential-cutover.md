# ADR 0093: Use explicit two-phase credential cutover

- Status: Accepted
- Date: 2026-08-02

## Context

Credentials do not expire by age, but compromise, target changes, and ordinary maintenance still require replacement. Immediate replacement can silently disconnect a shutdown client or executor before its peer is updated; indefinite dual validity doubles attack surface. Rollback generations can also resurrect a credential the administrator believed revoked unless revocation is independent from old configuration bytes.

## Decision

Credential replacement uses an explicit versioned two-phase cutover, while emergency revocation is a separate immediate operation.

- A binding or registered shutdown client has at most one `current` and one `pending` credential version. Credential IDs and versions are non-secret; values remain independently stored under ADR 0055.
- Creating a pending version never disables, overwrites, or automatically promotes the current version. The new secret is delivered once under ADR 0022.
- The pending cutover window defaults to 24 hours and may be configured from 1 through 168 hours. Expiry deletes the unpromoted pending secret and leaves the current credential active; it never silently breaks the working path.
- Promotion requires a current harmless authentication/capability test using the pending version and explicit administrator confirmation. A successful login alone does not auto-promote.
- NUT server-owned secondary credentials use a distinct temporary username/version so current and pending credentials can coexist during the window. Promotion atomically makes the pending version current and removes the old server-side authorization through a new validated configuration generation.
- For externally owned SSH, webhook, MQTT, WinRM, or Redfish credentials, the administrator provisions the new peer-side material first. NUTMerlin tests it, switches the binding explicitly, then provides exact old-credential revocation steps; it does not claim the external credential is revoked until target-side evidence or explicit administrator confirmation supports that statement.
- Promotion invalidates binding and policy activation evidence and requires the exact new version to qualify before state-changing use. In-progress work retains its captured credential reference only when its dispatch has already begun; no new action may select the retiring version.
- Emergency revocation immediately marks the selected version unusable, inhibits the binding and affected policy actions, deletes locally held secret material when recovery evidence permits, and removes server-owned authorization without waiting for a replacement. It warns that externally owned target authorization may remain until separately removed.
- A non-secret durable revocation record identifies every revoked credential version. Configuration, release, and rollback activation reject any generation that would restore its authority; compromised credentials are never re-enabled to make rollback healthier.
- Last-known-good generations are regenerated or made ineligible as needed. If no valid generation remains after urgent server-owned revocation, external access stays closed rather than restoring the revoked credential.
- Rotation and revocation never occur automatically because of calendar age, addon update, reboot, or connectivity loss.

## Consequences

- Routine rotation can preserve a working shutdown path while the client or target is updated, but overlap is bounded to seven days maximum.
- A missed window costs only the new pending secret, not the current protection.
- Emergency revocation favors loss of the affected capability over continued use of suspected material.
- Rollback and last-known-good logic need credential-version and revocation awareness independent of config hashes.
- Tests must cover exact 1-, 24-, and 168-hour boundaries, pending loss, no auto-promotion, both credentials during NUT overlap, target-first external cutover, failed new tests, crash at every promotion step, in-progress references, immediate revocation, external residual authority, LKG regeneration, and attempted rollback resurrection.

## Rejected alternatives

Immediate in-place replacement would minimize dual validity but can remove unattended protection before the peer accepts the new credential. Indefinite overlap would avoid cutover deadlines but permanently expand credential exposure and leave it unclear which version can be retired.
