# ADR 0021: Permit native NUT credentials on the trusted LAN

- Status: Accepted
- Date: 2026-08-02

## Context

Native NUT sessions provide transport encryption only when the packaged server and client were built with compatible TLS support and both ends are configured to require it. Requiring that interoperability for every client would bring certificate issuance, trust distribution, renewal, and client-specific TLS behavior into P0. Sending an `upsmon` password without TLS exposes it to interception by a hostile host able to observe or redirect trusted-LAN traffic.

NUTMerlin already confines native NUT access to one explicitly confirmed trusted LAN scope by default, and every shutdown client has a unique role-limited credential.

## Decision

P0 permits a shutdown client's unique `upsmon secondary` credential to traverse the native non-TLS NUT protocol only within the explicitly confirmed trusted LAN scope.

- Onboarding states plainly that a native non-TLS NUT session does not provide credential confidentiality.
- Shutdown-client credentials are never reused for another client, role, installation, or service.
- Credentialed NUT access is never admitted from WAN, guest, or other untrusted networks.
- Extending access to another subnet requires separately classifying and confirming that subnet as trusted; it is not inferred from private addressing.
- Traffic crossing an untrusted network requires an independently secured tunnel or qualified NUT TLS before it reaches the admitted listener.
- NUT TLS remains optional, qualification-dependent hardening rather than a P0 release gate.
- When NUT TLS is enabled, NUTMerlin requires server-certificate verification and forced encryption. Unsupported TLS, trust failure, or certificate mismatch fails closed without falling back to plaintext.
- Qualification records the packaged server's TLS capability and representative client interoperability separately from basic native-NUT support.

## Consequences

- Standard NUT shutdown clients can participate in P0 without universal TLS compatibility.
- The administrator's trusted-LAN classification is an explicit acceptance of credential-interception risk on that segment.
- Compromise of one intercepted credential is limited to one client's secondary role, but still requires revocation and replacement.
- TLS enablement needs certificate lifecycle, downgrade, and compatibility tests before it can be advertised for a platform/client combination.

## Rejected alternative

Requiring verified TLS or a secure tunnel for every shutdown client would provide transport confidentiality by default, but would make client and Entware TLS interoperability a P0 gate and exclude otherwise standard clients that cannot meet it.
