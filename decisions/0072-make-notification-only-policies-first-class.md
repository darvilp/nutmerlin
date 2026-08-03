# ADR 0072: Make notification-only policies first-class

- Status: Deferred research - non-authoritative for v0.1
- Date: 2026-08-02

## Context

The project promises an alerts-only pattern, but publication is currently scattered across webhook, MQTT, optional email, action-result, and generic external-orchestration language. Without one boundary, notification setup could accidentally require central shutdown authority, a configurable webhook could become an unverified action protocol, or another notifier could expand the P1 secret and transport matrix.

## Decision

P1 supports explicit notification-only policies through the generic webhook and publish-only MQTT bindings.

- A notification-only policy contains only `notify`-class operations and can be activated without enabling any `service_graceful` or higher central-action capability.
- Fresh installation remains monitoring-only under ADR 0042. No publisher, notification template, or policy is active until its binding passes harmless testing and the immutable policy version is explicitly activated.
- P1 exposes one versioned `notification.publish` operation and normalized envelope for selected event transitions, recovery, delivery gaps, health changes, and action-result summaries.
- The envelope has fixed schema and redaction rules, stable event/publication identifiers, source and policy identifiers, timestamps, current freshness, severity, normalized state, and an optional bounded administrator display label. It contains no credentials, raw command output, arbitrary headers, unvalidated payload fragments, or complete raw NUT variable maps.
- Webhook and MQTT adapters encode the same semantic envelope. Protocol-specific topic, endpoint, authentication, acknowledgement, and retained-message behavior stays in the binding.
- P1 generic webhook publication is delivery-only. It does not carry a typed target-action request or claim that an external automation completed an action.
- Notification delivery cannot cross a shutdown commit boundary, authorize a higher safety class, verify target state, or serve as a safety prerequisite for a state-changing action.
- Delivery failure is recorded and handled under ADR 0053 without replay. It does not block independent state-protection work.
- The common action budget and global dispatch-rate ceiling apply. Transition normalization and ADR 0061 health-summary suppression prevent per-poll notification floods.
- Built-in SMTP/email, SMS, push-service, vendor-cloud, and app-specific notification adapters are `Later`. Users may connect them through a webhook receiver or MQTT subscriber outside NUTMerlin.

## Consequences

- A community user can run alert-only automation without provisioning host shutdown credentials or enabling a state-changing executor.
- P1 has two transport implementations but one notification schema and safety meaning.
- Custom message formatting and direct email require an external receiver, reducing router-side dependencies and secrets.
- Tests must prove notification-only activation does not enable higher-class operations; schema parity, redaction, label bounds, duplicate IDs, rate limits, independent action progress, delivery gaps, and absence of arbitrary action payloads.

## Rejected alternative

Adding built-in SMTP and configurable webhook templates in P1 would provide familiar email and receiver-specific payloads, but would introduce another TLS/authentication compatibility surface and make consistent redaction, signing, schema evolution, and delivery semantics harder to enforce on the router.
