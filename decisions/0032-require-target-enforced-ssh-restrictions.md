# ADR 0032: Require target-enforced restrictions for SSH bindings

- Status: Deferred research - non-authoritative for v0.1
- Date: 2026-08-02

## Context

Client-side command templates prevent policy input from becoming arbitrary shell text, but they do not constrain a copied or stolen private key. If the target account accepts an ordinary shell, compromise of router-held SSH material grants more authority than the typed operation requires.

Target platforms provide different restriction mechanisms, including OpenSSH forced commands, restricted shells or subsystems, and purpose-built wrappers.

## Decision

A supported SSH executor binding requires a target-enforced operation restriction.

- The target uses an `authorized_keys` forced command, restricted subsystem, or equivalent server-side mechanism that admits only the binding's declared typed operations.
- The target-side wrapper accepts a small versioned protocol of fixed operation tokens and strictly structured parameters; it rejects arbitrary original commands and unknown arguments.
- The bound account provides no interactive shell, PTY, agent forwarding, port forwarding, X11 forwarding, or unrelated privilege.
- Any elevation on the target is limited to the exact wrapper or operation required, not a reusable administrator role.
- Binding registration tests at least one harmless allowed operation and an unknown or forbidden operation before enablement.
- NUTMerlin never imports or accepts a general-purpose SSH account or unrestricted key as an equivalent binding.
- Platforms unable to enforce the restriction may remain supported for the core NUT server but are not qualified for the SSH executor.
- Linux, BSD, NAS, and optional Windows OpenSSH templates may use different mechanisms only if they preserve this contract.

## Consequences

- SSH onboarding requires target-side setup instead of only entering an address and key.
- Some appliances with inflexible SSH account management cannot use this executor.
- Wrapper protocol, setup templates, and negative tests become versioned compatibility surfaces.

## Rejected alternative

Allowing a dedicated ordinary account with a narrowly configured `sudoers` shutdown command would support more targets, but a stolen key could still run unrelated unprivileged commands and explore the host beyond NUTMerlin's operation contract.
