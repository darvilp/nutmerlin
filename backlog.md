# NUTMerlin future roadmap

This file is non-authoritative. Items here have no accepted interface, architecture, milestone, or dependency on v0.1. A future item receives a new issue and architecture review only after the v0.1 server tracer is proven and a concrete user need exists.

## Candidate post-v0.1 usability

- Optional curated Merlin WebUI over the established local CLI behavior.
- Small redacted diagnostic/support export.
- Explicit configuration backup/import after the configuration model stabilizes.
- Additional exact router, UPS, storage, and NUT-driver evidence.
- Optional NUT TLS interoperability where actual clients qualify.

## Candidate notifications

- Outbound notification-only webhook.
- Outbound publish-only MQTT.

These must not become inbound control or imply verified remote action.

## Separate future architecture

Centralized policies, SSH/WinRM/Redfish actions, scheduling, dependencies, conflicts, budgets, FSD, output control, restoration, PDU/SNMP, multi-source authority, and operational history require a new threat model and architecture review. If concurrent orchestration is justified, consider a small compiled controller rather than extending the v0.1 shell lifecycle code.

## Later release engineering

- Independent publisher-authentication root and fingerprint channels.
- Emergency root replacement.
- Stronger provenance or attestations.
- AMTM or other catalog publication.
- Broad support matrices.

The historical ADRs and research remain available as ideas and evidence, but are non-authoritative unless explicitly reconsidered.
