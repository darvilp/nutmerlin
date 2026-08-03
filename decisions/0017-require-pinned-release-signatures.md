# ADR 0017: Require pinned-key signatures for every release

- Status: Deferred research - non-authoritative for v0.1
- Date: 2026-08-02

## Context

HTTPS and a checksum retrieved from the same release host detect accidental corruption but do not independently authenticate an archive if the hosting path or release account is compromised. NUTMerlin installs privileged router integration code and may hold credentials capable of controlling other systems.

## Decision

Every installable NUTMerlin release must be authenticated by a digital signature rooted in a pinned public key.

- Sign a release manifest containing the addon version, artifact names, byte sizes, SHA-256 hashes, compatibility metadata, and required installer version.
- Provision the trusted public key independently of the candidate release; never trust a key first encountered beside the release it authenticates.
- Verify the manifest signature before trusting its metadata.
- Verify every archive against the signed size and hash before staging or execution.
- Apply the same verification rules to online and locally supplied offline archives.
- Refuse installation or upgrade when required verification is unavailable or fails.
- Publish plain SHA-256 files for human inspection and corruption diagnosis, but never treat them alone as release authenticity.
- Verifier format, signing-key custody, rotation, and revocation follow ADR 0066; first-install bootstrap follows ADR 0084.

## Consequences

- Compromise of a release host, mirror, DNS, or TLS path is insufficient by itself to create an accepted release.
- Initial installation needs an explicit trust bootstrap that cannot depend on an untrusted downloaded key.
- Release production must protect signing keys and produce deterministic signed manifests.
- Verifier availability on supported Merlin and Entware environments becomes release-blocking.

## Rejected alternative

HTTPS plus published SHA-256 checksums is simpler, but an attacker controlling the release path can replace both the archive and its checksum.
