# ADR 0034: Limit HTTP webhooks to credential-free LAN notifications

- Status: Deferred research - non-authoritative for v0.1
- Date: 2026-08-02

## Context

Home automation systems commonly expose simple LAN HTTP receivers, while the webhook design also anticipates bearer tokens, secret headers, HMAC signatures, and endpoints beyond the local network. Treating all of these as one transport profile would either exclude common local receivers or expose reusable authorization and replayable requests without transport protection.

## Decision

Plain HTTP is permitted only for a credential-free `notification.publish` webhook whose resolved destination is explicitly confirmed within trusted LAN scope.

- An HTTP binding cannot contain bearer credentials, secret headers, HMAC keys, client credentials, or an operation classified as action-capable or destructive.
- A secret-bearing, sensitive, action-capable, or non-trusted-LAN webhook requires HTTPS with server-certificate verification.
- Private and self-signed HTTPS certificates are trusted only through explicitly installed CA or pin material; disabling verification is not supported.
- HTTPS transport never falls back to HTTP after connection, TLS, certificate, or protocol failure.
- Redirects to HTTP are always rejected, and other redirects are disabled by default unless separately constrained and revalidated.
- Destination resolution and effective address are revalidated against SSRF and trusted-scope rules before dispatch; a hostname cannot retain LAN permission after resolving elsewhere.
- Plain-HTTP configuration carries a persistent warning and any later addition of authentication or action capability requires explicit transport reconfiguration and policy revalidation.

## Consequences

- Simple credential-free Home Assistant, Node-RED, or local collector notifications can work without local certificate administration.
- Authenticated LAN webhooks still require verified HTTPS.
- Binding validation needs both configured-name and effective-address checks, including address changes and redirect behavior.

## Rejected alternative

Requiring verified HTTPS for every webhook would provide a simpler transport invariant, but would make certificate setup mandatory for otherwise low-risk credential-free LAN notification receivers.
