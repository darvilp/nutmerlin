# ADR 0069: Use ephemeral QoS 1 MQTT publication

- Status: Deferred research - non-authoritative for v0.1
- Date: 2026-08-02

## Context

MQTT publication needs a concrete protocol, acknowledgement, reconnect, and transport contract. A persistent broker session can redeliver queued or unacknowledged work after an outage, while QoS 0 cannot establish even broker acceptance. Automatic protocol or TLS fallback would also make the effective security and recovery behavior depend on connection failure.

## Decision

P1 MQTT bindings use an ephemeral, publish-only QoS 1 session.

- MQTT 5 is the gold-standard and default protocol profile. MQTT 3.1.1 is an explicit compatibility profile when the selected broker is validated for it; protocol negotiation does not fall back automatically.
- MQTT 5 connections set Clean Start to 1 and Session Expiry Interval to 0. MQTT 3.1.1 connections set Clean Session to 1.
- NUTMerlin and its MQTT client do not retain a persistent outbound queue across disconnect or process restart.
- Event, current-state, action-result, availability, and last-will publications use QoS 1. A successful publication result requires the protocol-level acknowledgement within the action's dispatch budget.
- QoS 1 permits duplicate delivery. Every payload therefore carries a stable publication ID, event or snapshot ID as applicable, schema version, creation timestamp, and freshness semantics so consumers can deduplicate.
- Only current state and availability are retained, and reconnect publishes the current availability and state rather than missed events, as required by ADRs 0037 and 0053.
- A binding uses one stable deployment-scoped client ID and a unique credential with a publish-only, topic-prefix ACL. It never requests subscribe or broker-administration permission.
- Plain MQTT transport is permitted only for credential-free, non-sensitive publication to a broker whose effective address is revalidated within the confirmed trusted LAN. It carries a persistent warning.
- Any username, password, client certificate, sensitive payload, or non-trusted-LAN destination requires TLS 1.2 or newer with verified server identity. Private trust uses installed CA or pin material; disabling verification and falling back to plaintext are unsupported.
- NUTMerlin performs no broker auto-discovery. Before each connection, every resolved address and the connected peer are revalidated; unspecified, loopback, link-local, multicast, broadcast, router-owned, and router-administration destinations are rejected, and plaintext requires every effective address to remain in the confirmed trusted subnet.
- Broker acknowledgement remains delivery acceptance, not proof of subscriber receipt, automation, or target state.

## Consequences

- A broker or subscriber can see duplicates but does not receive a NUTMerlin-managed backlog of stale outage events after reconnect.
- A lost acknowledgement can produce an unknown publication outcome; consumers must use the stable application-level ID rather than assume exactly-once delivery.
- Tests must cover both declared protocol profiles, clean-session flags, QoS 1 acknowledgement loss and duplicates, broker restart, client restart, absence of offline replay and subscription, reconnect snapshots, ACL enforcement, TLS verification, address revalidation, and refusal of downgrade.
- MQTT package qualification records the exact Entware client and TLS dependency cohort used by the release.

## Rejected alternative

QoS 0 with clean sessions would minimize broker state and duplicates, but gives no protocol-level acceptance evidence and silently loses more publications. A persistent QoS 1 session would improve eventual delivery, but its reconnect redelivery conflicts with the decision not to replay stale outage work.
