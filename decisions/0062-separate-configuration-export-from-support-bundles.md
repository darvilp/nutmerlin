# ADR 0062: Separate configuration export from support bundles

- Status: Deferred research - non-authoritative for v0.1
- Date: 2026-08-02

## Context

A replacement-media export needs enough topology and policy detail to reconstruct an installation. A file suitable for a public support forum must omit or transform LAN addresses, target names, usernames, device serials, and operational patterns even when none is an authentication secret. One generic regex-redacted archive cannot serve both purposes safely.

## Decision

NUTMerlin provides separate configuration-export and support-bundle contracts.

Configuration export:

- Uses a versioned schema and includes supported non-secret source, listener, target, binding metadata, policy definitions, display settings, and compatibility facts required for reconstruction.
- Contains no credential values, private keys, secret headers, trust private material, safety-journal records, or raw generated files.
- Imports secret references as unresolved binding requirements rather than dangling or guessed credentials.
- Every imported or restored policy remains inactive under ADR 0042 until current validation, harmless tests, and explicit activation.
- Is administrator-sensitive and is not labeled safe for public sharing merely because it contains no secrets.

Support bundles:

- A public support bundle is built from an explicit allowlist, removes device serials and usernames, generalizes LAN addresses and prefixes, pseudonymizes target IDs and labels using a bundle-local non-reusable salt, and omits policy payload details not needed for diagnosis.
- It includes at most the latest 24 hours or 1,000 operational-history records, whichever limit is reached first.
- An explicitly selected private support bundle may retain addresses, labels, and fuller non-secret configuration for administrator-controlled troubleshooting, but still excludes every secret class and private key.
- Both variants include addon, firmware, architecture, Entware/NUT, capability, service-health, storage, listener-scope, redaction-schema, and bundle-format versions as applicable.
- The CLI and any installed WebUI show the proposed sections, privacy class, time range, and redaction summary before generation.
- Bundles are generated into mode `0600` temporary files, automatically expire after 10 minutes, and are deleted after confirmed handoff where the surface supports it.
- NUTMerlin never uploads a support bundle automatically or embeds an upload destination.

## Consequences

- Replacement-media recovery remains useful without making that artifact suitable for public posting.
- Community reports can carry compatibility evidence with materially reduced network and identity exposure.
- Redaction is schema-driven and must fail closed on unknown secret-bearing fields or future schema versions.
- Tests need seeded secrets in every supported location, address and label pseudonymization, linkability checks across bundles, record/time caps, file modes, expiry, import inhibition, and unknown-field refusal.

## Rejected alternative

One diagnostic archive with field-name and regex redaction would be easier to build, but could retain sensitive topology and would either omit configuration needed for recovery or expose too much for public support.
