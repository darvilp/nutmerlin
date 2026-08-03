# ADR 0084: Require manual authentication of first install

- Status: Deferred research - non-authoritative for v0.1
- Date: 2026-08-02

## Context

After installation, NUTMerlin can pin its release trust root and verify updates. Before installation, however, a downloaded bootstrap script, keyring, checksum, and documentation all arrive without local project state. Executing a network response directly would grant router root authority before any project signature had been authenticated.

## Decision

First installation is a two-stage, manually authenticated bundle workflow.

- The administrator obtains a versioned release manifest, detached OpenPGP signature, project verification keyring, installer, and referenced artifacts as ordinary files in a new local staging directory.
- Before executing project code, the administrator confirms the complete primary-key fingerprint through the independent project-controlled channels required by ADR 0066 and confirms that the supplied keyring contains that root.
- Verification uses the current Entware `gpgv2` installed through the already trusted Entware prerequisite, with an explicitly selected project keyring rather than an ambient user keyring or downloaded keyserver result.
- The authenticated signed manifest is verified first. Artifact hashes, byte sizes, names, release version, platform constraints, and installer version are then checked exactly against it before the installer may execute.
- The installer runs from the verified local file. NUTMerlin documentation never instructs users to pipe `curl`, `wget`, or another network stream into a shell, source a remote script, or execute a moving branch URL.
- HTTPS remains required for normal retrieval but is defense in depth, not release authenticity. Redirects and unexpected content types or filenames fail the documented workflow.
- The same complete bundle and verification steps support offline transfer; offline media does not waive fingerprint or signature checks.
- Successful install records the verified release trust root and manifest in ownership/update state so subsequent user-initiated updates use the pinned path from ADRs 0017 and 0066.
- If `gpgv2`, an independently confirmed fingerprint, or the complete signed bundle is unavailable, installation stops. A checksum printed next to an archive, a short key ID, a Git commit hash from the same retrieval channel, or a browser padlock is not a substitute.
- Public release remains blocked until the concrete independent fingerprint channels and emergency replacement instructions are documented and tested; this ADR does not invent those unresolved channel owners.

## Consequences

- First install is less convenient than a one-line command but does not execute unauthenticated project bytes as router root.
- Entware and `gpgv2` are explicit prerequisites to the authenticated bootstrap path.
- Release packaging must be deterministic and complete enough to verify offline.
- Tests need substituted keyrings, same-channel fake fingerprints, wrong and short key IDs, manifest/artifact mismatch, filename confusion, truncation, redirect, offline bundle, already-installed root mismatch, and proof that installer execution occurs only after all verification succeeds.

## Rejected alternative

A pinned HTTPS URL with `curl | sh` and a checksum fetched from the same site would provide the simplest community onboarding, but compromise of that origin, DNS, TLS termination, or the moving script would yield immediate privileged execution and could replace the checksum at the same time.
