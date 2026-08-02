# ADR 0077: Pin SSH identity with current Entware OpenSSH

- Status: Accepted
- Date: 2026-08-02

## Context

ADRs 0032 and 0033 constrain target authority and key scope, but do not choose the router client, enrollment trust, algorithms, host-key rotation, or client configuration isolation. Firmware SSH clients differ across Merlin generations, and trust-on-first-use during unattended onboarding can permanently pin an attacker's key.

## Decision

P1 SSH uses the current qualified Entware OpenSSH client and explicit per-binding identity material.

- `openssh-client`, `openssh-client-utils`, and `openssh-keygen` form an optional dependency cohort installed only when SSH capability is requested and qualified under ADR 0014. Firmware Dropbear or another ambient client is not a transparent fallback.
- NUTMerlin-generated Ed25519 user keys are the default. RSA keys of at least 3072 bits with RSA-SHA2 signatures are an explicit compatibility profile. DSA and SHA-1 `ssh-rsa` signatures are unsupported.
- Every binding owns its private key, public key, exact host-key record, endpoint identity, restricted account, and forced-wrapper protocol version. No global administrator `known_hosts`, SSH config, key, or agent state is read.
- Enrollment may scan or receive a candidate host key, but never trusts it automatically. The administrator must verify the SHA-256 fingerprint through an independent trusted path and record explicit confirmation before harmless binding tests can establish activation evidence.
- `StrictHostKeyChecking` is effectively `yes`; `accept-new`, trust-on-first-use, trust-all, and silent changed-key replacement are unsupported.
- A changed or additional host key closes the binding immediately. Rotation is an explicit replacement transaction that shows old and new fingerprints, independently verifies the new key, reruns harmless and forbidden-operation tests, and creates new activation evidence before retiring the old record.
- Client execution selects only the binding's identity and host-key store, disables password and interactive authentication, agent use, PTY, X11, tunneling, forwarding, multiplexing, roaming configuration, and automatic host-key updates, and runs noninteractively.
- Target authorization restricts the key to the forced wrapper and the exact router management source address when the target mechanism supports source constraints. A target that cannot enforce the operation restriction in ADR 0032 remains unqualified; absence of an optional source-address constraint is recorded as residual evidence rather than replaced by a shared key.
- Endpoint hostname resolution and effective address are validated before dispatch. Router-local administration endpoints, multicast, broadcast, and unspecified addresses are prohibited; an explicitly configured non-LAN target receives the same host-key and egress checks and no weaker profile.
- Harmless onboarding exercises one fixed allowed operation and one syntactically forbidden operation through the target wrapper. It never invokes a real shutdown.
- State-changing SSH operations use the retry and commit rules of their typed operation. A disconnect after dispatch never proves target state or authorizes a retry.

## Consequences

- SSH adds a small current Entware package cohort but has consistent behavior across supported Merlin families.
- Onboarding requires an out-of-band fingerprint check rather than one-click TOFU.
- Key and host rotation are binding-specific and can invalidate active policy evidence without affecting other targets.
- Tests must cover package and architecture qualification, Ed25519 and RSA-SHA2 profiles, candidate-key substitution, changed and additional keys, independent known-host stores, ignored ambient config and agent, forbidden authentication and forwarding, DNS/address changes, forced-wrapper negatives, and firmware-client nonfallback.

## Rejected alternative

Using the firmware Dropbear client with a first-seen pinned host key would reduce package dependencies and setup friction, but would vary algorithms and option behavior by router firmware and would authenticate the first network response rather than an independently established target identity.
