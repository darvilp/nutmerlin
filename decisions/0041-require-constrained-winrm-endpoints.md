# ADR 0041: Require constrained WinRM endpoints

- Status: Accepted
- Date: 2026-08-02

## Context

Client-side fixed PowerShell text does not constrain a copied WinRM credential. Default PowerShell remoting endpoints commonly expose broad command capability to administrators, while Just Enough Administration provides target-side delegated endpoints that restrict visible commands and parameters.

The primary community profile is likely to include workgroup Windows hosts where Kerberos server identity is unavailable.

## Decision

A supported WinRM binding requires a NUTMerlin-specific JEA or equivalently constrained target-side endpoint.

- A dedicated non-administrator identity is admitted only to that constrained endpoint.
- The endpoint exposes only versioned harmless test, bounded status, and graceful-shutdown operations with fixed parameter schemas.
- The normal workgroup profile uses HTTPS and verifies the target certificate and identity.
- Basic authentication, CredSSP or delegated reusable credentials, `TrustedHosts` as a server-verification substitute, default unrestricted PowerShell endpoints, and local or domain administrator credentials are unsupported.
- A future domain/Kerberos profile requires separate qualification and must preserve constrained endpoint and least-privilege identity requirements.
- If the Windows target cannot provide the constrained endpoint, NUTMerlin directs users to client-local NUT or another qualified binding rather than weakening WinRM.
- Command acceptance and observed host power state remain distinct execution and verification results.

## Consequences

- WinRM remains a P2 option rather than the default Windows path.
- Some Windows editions or administration policies may not support the required setup.
- Onboarding must include endpoint installation, certificate trust, ACL, forbidden-command, and graceful-shutdown tests.

## Rejected alternative

Using a dedicated local administrator over verified HTTPS with fixed client-side command templates would support more ordinary Windows installations, but would store a reusable administrator credential on the router and expose a general remoting endpoint if that credential leaked.
