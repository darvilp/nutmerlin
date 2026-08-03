# ADR 0053: Recover current state without replaying network work

- Status: Superseded by ADR 0098
- Date: 2026-08-02

## Context

LAN, WAN, DNS, a broker, or an individual target may be unreachable during an outage. Persistently replaying missed notifications or actions after connectivity returns can present obsolete events as current and can dispatch shutdown after utility recovery. Silently discarding all evidence makes delivery gaps invisible.

## Decision

Network recovery restores current state and reports delivery gaps; it does not generically replay missed work.

- Remote action attempts and retries occur only inside the original action budget, policy stage deadline, event conditions, and retry classification.
- Network restoration does not authorize an expired, canceled, failed, or unknown action and does not create a new event episode.
- Webhook and MQTT event publications have no persistent offline replay outbox.
- A publication failure is retained in bounded local event/audit history with its original event ID and redacted diagnostic result.
- MQTT reconnection publishes current availability and a current retained state snapshot under ADR 0037; missed transition events are not republished on the normal event topic.
- A policy may emit a new recovery or delivery-gap summary containing the gap interval, count, and current state, clearly distinguished from the missed events.
- Generic webhooks receive no automatic catch-up request; a new recovery notification requires an explicitly enabled policy.
- Already committed action intent follows ADRs 0024 and 0025. An eligible retry that remains inside its original durable action budget is not considered offline replay.
- Target reconnection alone never proves completion or resolves an unknown result.

## Consequences

- Subscribers and external automations do not receive stale transitions as new outage triggers.
- Local history, not an outbound queue, is the authoritative record of missed publication attempts.
- Integrations needing durable event streaming must provide and qualify a separate freshness-aware protocol in a later phase.
- Tests must cover DNS, route, broker, and target outages; recovery during reversible and committed states; MQTT session behavior; gap summaries; and absence of stale webhook requests.

## Rejected alternative

A bounded persistent outbox with expirations and stable event IDs would improve eventual delivery, but could still cause consumers that ignore timestamps to act after recovery and would add write load during the very failures the addon must tolerate.
