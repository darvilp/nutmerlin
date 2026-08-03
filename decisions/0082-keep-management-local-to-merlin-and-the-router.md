# ADR 0082: Keep management local to Merlin and the router

- Status: Deferred research - non-authoritative for v0.1
- Date: 2026-08-02

## Context

CLI and web parity could be implemented through a new local or LAN API, but that would add a privileged listener, authentication scheme, session lifecycle, CSRF boundary, and remote attack surface. Merlin already provides an authenticated administrator UI and a documented service-event path, while router shell access already has its own administrative boundary.

## Decision

NUTMerlin exposes no standalone management web server, REST API, RPC listener, or remotely callable CLI in P0 through P2.

- When the optional WebUI component from ADR 0097 is installed, its page is mounted only through the Merlin Addons API and remains inside the firmware's authenticated administrator origin and session.
- State-changing browser requests use the firmware's documented form and service-event protections plus a NUTMerlin one-time operation nonce bound to installation ID, operation ID, candidate hash, and UI schema version.
- A web operation nonce expires after 5 minutes, is consumed on first attempted dispatch regardless of result, lives only in protected transient storage, and cannot be reused to authorize a different candidate or operation.
- The UI submits only fixed versioned management-operation identifiers and validated fields. User input never becomes a service-event name, shell token, path, command, or executable argument.
- The service-event dispatcher revalidates authentication context available from Merlin, nonce, schema, candidate hash, current state, authorization, and operation-specific confirmation server-side. Browser-side validation is advisory only.
- The UI reads only sanitized bounded status artifacts served through the authenticated Merlin surface. No secret, broker IPC, safety-journal raw content, arbitrary file, or privileged command result is exposed as a status asset.
- Read-only native NUT protocol access remains the separately scoped data plane from ADRs 0018 and 0019 and conveys no addon management authority.
- The complete CLI calls the same local management-operation controller without an HTTP hop. State-changing CLI operations require local effective router-administrator privilege and operation-specific confirmation; sanitized read-only status may be available to a qualified lower-privilege identity.
- CLI JSON output is an automation result format, not a network protocol. NUTMerlin supplies no listener or remote wrapper that executes it.
- If Merlin UI mounting, nonce storage, firmware session integration, or service-event dispatch is unavailable or cannot be verified, the web management surface remains absent or closes and reports recovery guidance where possible; the core and authoritative local CLI remain available.
- UI code uses fixed-origin resources, output encoding, strict field bounds, and no third-party scripts, remote fonts, analytics, inline secret values, or browser-side credential persistence.

## Consequences

- There is one fewer privileged listener and no second router-login implementation to secure.
- Browser operations can expire or require a fresh preview after five minutes, while CLI recovery remains available when the UI breaks.
- External automation cannot remotely reconfigure or trigger NUTMerlin through an undocumented API; outbound webhook and MQTT remain publish-only.
- Tests must cover nonce binding, exact expiry and single use, replay after success and failure, candidate substitution, fixed operation allowlists, forged service events, stale UI schema, CSRF behavior, output encoding, status-file traversal, direct broker denial, CLI privilege, and UI-failure recovery. Exact firmware session/CSRF behavior remains part of real-router qualification.

## Rejected alternative

A localhost JSON API proxied by the Merlin page would provide a clean client/server abstraction and make UI/CLI sharing straightforward, but would still introduce a privileged listener, local request authentication, proxy trust, lifecycle ordering, and another input parser on the router.
