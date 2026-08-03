# ADR 0027: Model targets as logical destinations with executor bindings

- Status: Deferred research - non-authoritative for v0.1
- Date: 2026-08-02

## Context

One managed server can expose an operating-system path such as SSH or WinRM and a separate out-of-band path such as Redfish. Treating each endpoint as an unrelated target simplifies storage, but makes grouping, deduplication, verification, escalation, and destructive-action authorization depend on manually correlating records.

Other destinations such as a webhook receiver, MQTT publication destination, or local script normally have only one execution path but still need stable policy identity.

## Decision

A target represents one logical destination and contains one or more executor bindings.

- The target owns a stable non-secret ID, display label, group membership, exclusions, and target-level destructive-action gates.
- Each executor binding owns one executor type, its validated endpoint and transport settings, credential references, and discovered or configured capabilities.
- Credential values are stored separately from both target and binding configuration and are referenced by opaque secret IDs.
- An action addresses a logical target and selects or requires an eligible binding according to its typed operation and policy configuration.
- Cross-protocol verification or escalation must resolve to bindings on the same logical target.
- A binding on one target can never satisfy an action, verification, or escalation for another target merely because an address or label is similar.
- P0 may permit one binding per target while preserving the model; multi-binding fallback is not implied or automatically enabled.
- Webhook, MQTT, and local-script destinations may each be represented as a logical target with one binding.

## Consequences

- Target identity remains stable if a protocol endpoint or credential changes.
- Multi-protocol sequencing can enforce that graceful shutdown and later verification or escalation concern the same asset.
- Configuration validation needs an additional binding concept and must reject duplicate IDs, invalid cross-target references, and capability mismatches.

## Rejected alternative

Making each executor endpoint a separate target, such as `server-ssh` and `server-redfish`, would reduce the number of concepts but would leave cross-protocol identity and safety correlation to policy authors.
