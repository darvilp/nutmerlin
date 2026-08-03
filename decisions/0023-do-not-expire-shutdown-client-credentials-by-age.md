# ADR 0023: Do not expire shutdown-client credentials by age

- Status: Superseded by ADR 0098
- Date: 2026-08-02

## Context

Shutdown-client credentials are consumed by unattended protection services. Fixed expiry limits the lifetime of a disclosed credential, but a missed rotation can silently leave a host unable to react to a critical UPS event. Credential age alone is not evidence of compromise, and independent per-client credentials can be revoked without affecting other clients.

## Decision

Shutdown-client credentials do not expire automatically according to age.

- A credential remains valid until the administrator explicitly replaces it or removes the client.
- Replacement is required after suspected disclosure, loss of trust in an admitted network, client retirement, or transfer of installation ownership.
- The CLI and any installed WebUI report credential creation and last-replacement timestamps without presenting an expiry deadline.
- Authentication failures produce health diagnostics but never claim that a successful login proves the client's local shutdown command will work.
- NUTMerlin does not silently rotate a shutdown-client credential because doing so would require an unavailable out-of-band secret-delivery channel to that client.
- Rotation cutover and emergency revocation follow ADR 0093.

## Consequences

- An unused or forgotten credential can remain valid until the administrator removes it.
- Client inventory and explicit retirement controls are important compensating controls.
- Tests must prove that calendar passage alone cannot invalidate a working shutdown client.

## Rejected alternative

Expiring each credential after 365 days with a 30-day warning would bound its lifetime, but could silently defeat shutdown protection when the administrator misses the rotation window.
