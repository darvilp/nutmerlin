# ADR 0080: Use fixed authenticated webhook profiles

- Status: Accepted
- Date: 2026-08-02

## Context

ADRs 0034 and 0035 establish transport and delivery boundaries, but the P1 design still permits optional signing, redacted headers, response policy, and generic payloads without choosing exact profiles. Arbitrary secret headers and templates would make it difficult to prove where credentials appear, what is signed, how replay is bounded, or whether DNS and redirects can move a request to a protected endpoint.

## Decision

P1 webhook publication uses a fixed UTF-8 JSON POST and one of three closed authentication profiles:

1. `lan_anonymous` — credential-free HTTP or HTTPS, limited to `notification.publish` and the confirmed trusted-LAN destination rules in ADR 0034.
2. `https_bearer` — verified HTTPS with exactly one per-binding bearer token in the `Authorization` header.
3. `https_hmac_v1` — verified HTTPS with exactly one per-binding HMAC-SHA-256 key and fixed signature headers.

All profiles follow these rules:

- Method is `POST`; content type is `application/json`; the body is the versioned normalized notification envelope from ADR 0072. Policies cannot choose a method, header name, body template, query secret, or arbitrary payload fragment.
- Bearer and HMAC credentials are mutually exclusive, binding-scoped, stored under ADR 0055, redacted everywhere, and replaced through an explicit transaction that invalidates activation evidence.
- `https_hmac_v1` signs the exact byte sequence `nutmerlin-webhook-v1\n`, decimal Unix timestamp, newline, publication ID, newline, decimal body length, newline, then the exact body bytes. The receiver gets fixed timestamp, publication-ID, and `v1=<lowercase-hex-hmac>` headers.
- Signed dispatch requires a trusted wall-clock state. Receiver guidance uses a default maximum timestamp skew of 300 seconds plus publication-ID deduplication; if router clock trust is unavailable, the signed binding is inhibited rather than sent with a misleading timestamp.
- TLS 1.2 or newer and verified server identity are required for secret-bearing or non-LAN bindings. Installed CA or certificate-pin material is explicit; trust-all, plaintext fallback, and automatic TLS downgrade are unsupported.
- Redirects are always disabled. A 3xx result is not followed, even within the same origin.
- Before each connection, every resolved address is checked. Unspecified, loopback, link-local, multicast, broadcast, router-owned, and router-administration destinations are rejected; `lan_anonymous` additionally requires every effective address to remain inside its one confirmed trusted subnet.
- The connected peer address is checked against the validated set while the original hostname remains the TLS identity. Resolution or peer changes that cross scope fail closed and invalidate current harmless evidence where persistent.
- Any HTTP `2xx` is delivery acceptance. Other status classes, connection loss, or timeout are failure or unknown according to whether request bytes may have been accepted; the response body is never action evidence and is captured only as a bounded redacted diagnostic.
- Generic webhook notification is nonrepeatable after body dispatch because the receiver has no required deduplication contract. A conclusive failure before dispatch may retry only inside ADR 0048's budget; an unknown outcome does not retry.

## Consequences

- Common bearer and signed receivers are supported without allowing secret placement or payload semantics to become arbitrary.
- HMAC consumers have a deterministic cross-language signing input and bounded replay guidance, but require synchronized clocks.
- Receiver-specific JSON layouts need an external adapter rather than a NUTMerlin template language.
- Tests must use exact signature vectors, body-byte and length changes, 300-second boundary guidance, untrusted clock, secret replacement, all response classes, body truncation/redaction, resolution races, mixed allowed/denied address sets, peer mismatch, router endpoints, redirects, TLS failures, and absence of post-dispatch retry.

## Rejected alternative

Allowing arbitrary secret headers, query parameters, methods, and JSON templates would integrate more webhook receivers directly, but would turn the binding into an open-ended HTTP request builder whose credential exposure, SSRF behavior, signature semantics, and result meaning could not be exhaustively tested.
