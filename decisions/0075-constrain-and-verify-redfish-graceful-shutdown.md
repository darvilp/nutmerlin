# ADR 0075: Constrain and verify Redfish graceful shutdown

- Status: Accepted
- Date: 2026-08-02

## Context

ADR 0040 limits P2 Redfish to graceful shutdown and observation, but does not define endpoint identity, authentication, latent credential authority, dispatch evidence, or verification timing. Redfish services may expose multiple systems, broad reset privileges, self-signed certificates, asynchronous task responses, and stale or unavailable power state.

## Decision

P2 Redfish is a manually configured, verified-HTTPS, graceful-only binding to one exact ComputerSystem resource.

- NUTMerlin performs no LAN-wide Redfish discovery. The administrator supplies a base endpoint; NUTMerlin validates the service root and requires explicit selection when more than one ComputerSystem is exposed.
- The binding pins the exact service identity and ComputerSystem resource. Redirects, effective-address changes, a different system identity, or ambiguous resource discovery invalidate activation evidence.
- TLS 1.2 or newer with verified server identity is required. Private services use an explicitly installed CA or certificate pin; trust-all mode, plaintext HTTP, and TLS downgrade are unsupported.
- Authentication uses a dedicated per-binding BMC account and a Redfish session when the qualified service supports it. Session tokens remain transient and redacted; the stored credential follows ADR 0055.
- The BMC role must be the narrowest target-enforced role that can read the selected system and request `GracefulShutdown`, without BMC administration, account management, firmware update, virtual media, console, or unrelated-system access.
- A binding whose available account necessarily grants `ForceOff`, reset, power-on, or broader server-control authority is not qualified for P2. Client-side omission alone is not treated as least privilege.
- Required target-side denial is established only through non-actuating role metadata, configuration evidence, or qualified vendor behavior. NUTMerlin never probes denial by attempting an abrupt or output-changing operation; inability to establish the restriction harmlessly leaves the binding unavailable.
- Harmless activation testing proves service identity, selected-system identity, TLS trust, session lifecycle, readable power state, advertised `GracefulShutdown` capability, and the available non-actuating credential-scope evidence without issuing a reset action.
- Before dispatch, NUTMerlin obtains a fresh selected-system state and revalidates that `GracefulShutdown` remains advertised. An already `Off` system returns `already_satisfied`; unavailable, ambiguous, or contradictory state inhibits dispatch.
- `host.graceful_shutdown` maps only to `ComputerSystem.Reset` with `ResetType` equal to `GracefulShutdown`. It is nonrepeatable and receives one dispatch attempt with no post-dispatch retry.
- HTTP or asynchronous-task acceptance establishes dispatch acceptance only. Verification follows any same-origin task reference and then polls the selected ComputerSystem for `Off`.
- The Redfish verification default is 300 seconds with a 5-second poll interval, within ADR 0048's global bounds. `Off` is verified after two consecutive fresh matching observations. Timeout, task failure, identity drift, or lost response ends failed or unknown and never escalates.
- Redfish observation may verify another binding's graceful action only when the policy explicitly references this same logical target and exact selected-system identity.

## Consequences

- Many BMCs whose roles combine graceful and abrupt power control will be unavailable rather than advertised as safely supported.
- A successful Redfish POST is not mislabeled as a powered-off host.
- The executor needs mock coverage for service discovery, multi-system selection, sessions, task monitors, certificate and identity changes, advertised capabilities, forbidden privilege probes, stale state, duplicate `Off`, timeout, and unknown outcomes.
- Exact BMC model, firmware, schema behavior, TLS profile, and role definition become separately qualified capability evidence; they do not follow from router or UPS qualification.

## Rejected alternative

Using any dedicated BMC operator account over verified HTTPS while relying on NUTMerlin never to send `ForceOff` would support more hardware, but theft or misuse of the stored credential could bypass the client-side operation registry and invoke the broader server-control authority directly.
