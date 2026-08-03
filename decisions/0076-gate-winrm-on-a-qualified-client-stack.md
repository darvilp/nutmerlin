# ADR 0076: Gate WinRM on a qualified client stack

- Status: Deferred research - non-authoritative for v0.1
- Date: 2026-08-02

## Context

ADR 0041 defines the target-side WinRM security boundary, but a router-side client and result contract are still unspecified. The current AArch64 Entware feed does not package `openwsman`, `pywinrm`, or `requests-ntlm`. Installing Python modules from a live package index, implementing WS-Man or NTLM locally, or calling a broadly privileged endpoint would conflict with the current-package, minimal-dependency, signed-release, and least-privilege decisions.

## Decision

WinRM remains a P2 candidate, but is not a supported executor until its complete client stack qualifies as a release dependency.

- NUTMerlin does not install WinRM dependencies from PyPI or another mutable language package index during install, update, or executor activation.
- NUTMerlin does not implement its own WS-Man, NTLM, Kerberos, or CredSSP protocol stack.
- A qualifying client path must be reproducibly supplied by the current Entware feed or as reviewed, version-pinned, license-compatible components inside the signed NUTMerlin release, and must pass the package/ABI evidence layer on every supported current architecture.
- If no qualifying path exists for a release, the WinRM capability is absent rather than compatibility-mode installed. Client-local NUT, restricted SSH, or another qualified binding is recommended.
- When present, the normal workgroup profile uses an explicitly configured HTTPS WinRM listener with TLS 1.2 or newer, verified server identity, and the exact constrained endpoint from ADR 0041. `TrustedHosts`, HTTP port 5985, trust-all TLS, Basic, CredSSP, and automatic authentication downgrade remain unsupported.
- A unique dedicated non-administrator credential is stored per binding. JEA endpoint ACL and role-capability evidence must show only fixed harmless test, bounded status, and `host.graceful_shutdown` wrapper operations; wildcards, providers, arbitrary commands, script blocks, and administrator group membership are disqualifying.
- P2 WinRM exposes `host.graceful_shutdown`, not hibernation, restart, arbitrary PowerShell, service administration, or target restoration. Those require separate future operation decisions.
- The shutdown operation is nonrepeatable: one dispatch attempt and no retry after a request could have reached Windows.
- A structured endpoint acknowledgement establishes request acceptance only. Connection loss is never proof of shutdown. Verified `Off` requires a separately qualified observation binding to the same logical target; otherwise the final result remains accepted-but-unverified or unknown according to the evidence obtained.
- The default dispatch and verification budgets remain 30 and 300 seconds under ADR 0048. Failure to verify never authorizes a second shutdown request or an abrupt action.
- Real Windows shutdown testing requires `NUTMERLIN_ALLOW_HOST_SHUTDOWN=1`; ordinary CI uses a mock WS-Man service and harmless JEA wrapper result.

## Consequences

- WinRM may remain absent from P2 releases until a maintainable router client is available; a roadmap label is not treated as dependency evidence.
- Workgroup convenience cannot weaken server identity or endpoint confinement.
- Hibernation remains outside P2, avoiding a Windows-PC-specific branch in the initial community contract.
- Qualification needs dependency SBOM and license review, client parser and authentication tests, mock faults, Windows VM/JEA capability enumeration, certificate rotation, forbidden-command coverage, request-loss outcomes, and manually gated real shutdown.
- Requirements and plan language should describe WinRM as capability-gated rather than unconditionally delivered at P2.

## Rejected alternatives

Runtime installation of `pywinrm` and its transitive dependencies would accelerate development, but would make product behavior depend on an unsigned mutable index and an unrecorded package cohort. Restricting Windows push to OpenSSH forever would be simpler, but would remove the platform-native path rather than preserving it behind honest qualification.
