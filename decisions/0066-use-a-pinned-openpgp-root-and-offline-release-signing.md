# ADR 0066: Use a pinned OpenPGP root and offline release signing

- Status: Accepted
- Date: 2026-08-02

## Context

ADR 0017 requires pinned-key signatures but leaves the format, verifier, bootstrap, custody, rotation, and revocation open. Current supported AArch64 and legacy ARMv7 Entware feeds provide `gpgv2`, allowing verification with a maintained package rather than a project-written cryptographic implementation. NUTMerlin must also support offline installation and cannot require an identity provider or transparency-log query at install time.

## Decision

NUTMerlin uses detached OpenPGP signatures made by an Ed25519 release-signing subkey and verified by `gpgv2` against a pinned project keyring.

- The release trust root is identified by the full fingerprint of a dedicated offline primary certification key.
- The primary private key never enters CI, a router, or an ordinary development workstation and is used only for subkey certification, planned root transition, and revocation material.
- A dedicated release-signing subkey has a maximum validity of 12 months and is held outside CI, preferably on a hardware token; encrypted offline custody is the documented fallback.
- CI produces deterministic release artifacts, their hashes and sizes, compatibility metadata, and the canonical manifest. A maintainer signs that exact completed manifest only after required CI evidence passes.
- The detached signature, manifest, archive, and plain diagnostic hashes are separate files. Verification trusts only manifest fields covered by an accepted signature and then verifies every artifact against the signed manifest.
- `gpgv2` and its exact package provenance are part of the minimal update/install verifier dependency and the AArch64 package/ABI release gate.
- Planned signing-subkey rotation is certified by the existing root before expiry.
- Planned root rotation requires a transition statement signed by both old and new roots, with both trust roots published for at least 90 days and two public releases, whichever takes longer, before the old root is retired.
- Suspected root or signing-key compromise stops release publication and update guidance. A new root is never accepted automatically solely because the old, possibly compromised key signed it; administrators must perform a documented manual trust bootstrap.
- The primary-key revocation certificate is generated at key creation, stored independently offline, and published through every established trust channel when applicable.
- First installation never executes a network stream. The administrator downloads a versioned bootstrap artifact and detached signature, obtains the pinned keyring/fingerprint through established channels, verifies, inspects the candidate version, and then executes locally.
- Public release is blocked until at least two independent project-controlled fingerprint publication channels and an emergency replacement procedure are documented and tested. Selecting those concrete channels remains release research rather than an assumed repository fact.

## Consequences

- Online and offline releases share one verification path and do not depend on the release host remaining trustworthy.
- Signing is intentionally outside CI, adding a maintainer release ceremony.
- Key compromise recovery is manual and visible rather than an unsafe automatic transition.
- Tests need valid, altered, truncated, wrong-key, expired-subkey, revoked-key, planned-transition, compromise-bootstrap, missing-verifier, and offline-package cases.

## Rejected alternatives

Sigstore keyless signing would reduce long-lived signing-key custody but add online identity, transparency-log, time, and verifier dependencies to router installation. Shipping a custom minimal signature verifier would reduce package dependencies but create a new cryptographic implementation and update burden.
