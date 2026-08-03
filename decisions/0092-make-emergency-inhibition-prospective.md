# ADR 0092: Make emergency inhibition prospective

- Status: Deferred research - non-authoritative for v0.1
- Date: 2026-08-02

## Context

An administrator needs a rapid way to stop additional router-side automation after noticing a bad policy or target condition. Killing executors or deleting a policy cannot recall network bytes already accepted, and stopping a committed shutdown sequence can strand targets between graceful shutdown and later lifecycle steps. Client-local NUT policies are also independent of the router policy engine.

## Decision

NUTMerlin provides durable policy deactivation and a global prospective automation inhibit; neither is represented as cancellation of remote effects.

- Deactivating one policy version prevents it from creating new episodes and durably cancels its undispatched reversible timers and actions.
- Global automation inhibit immediately and durably prevents every policy from creating new episodes or crossing a new dispatch or commit boundary, and cancels all undispatched reversible work.
- An action definitively not transmitted may be canceled. If request transmission may have begun, the action follows its existing accepted or unknown evidence and retry rules; inhibit never rewrites it as canceled or not dispatched.
- Already committed sequences and dispatched nonrepeatable operations retain their captured meaning under ADRs 0003 and 0024. NUTMerlin does not promise a stop button for them and does not terminate their executor merely to create the appearance of cancellation.
- The inhibit leaves read-only UPS collection, bounded local history, CLI status, installed-WebUI status, listener/firewall protection, and ordinary NUT server service running. It does not disable or reconfigure independent secondary clients, whose local shutdown policies may still act.
- The CLI and any installed WebUI state exactly which pending work was canceled, which accepted or unknown work may continue, which committed sequence will continue, and that client-local policies are outside the inhibit.
- Global inhibit survives service and router restart through the safety journal and JFFS anchor. Missing durable confirmation leaves it in force.
- Clearing inhibit requires authenticated explicit administration, current state reconciliation, and valid policy/runtime gates. It does not replay canceled notifications or actions and does not resume the inhibited outage episode.
- After clear, policies remain armed only for a new episode following confirmed recovery and a new qualifying onset. If the source is still in the old outage condition, NUTMerlin monitors it without creating a replacement episode.
- Full addon disable and uninstall remain separate lifecycle operations with their own service, listener, client, and storage effects.

## Consequences

- The emergency control is honest about physical and distributed irreversibility.
- An administrator can stop a bad uncommitted fan-out without removing NUT status from independent clients.
- Clearing during a continuing outage cannot unexpectedly fire all overdue actions at once.
- Tests must cover every point before and after commit and request transmission, concurrent actions, policy-specific versus global inhibit, process and router restart, failed durable write, client-local independence, continuing outage on clear, recovery/new onset, and exact UI evidence wording.

## Rejected alternative

Immediately killing all executor and policy processes would appear to stop more work, but a killed connection may already have delivered its request, committed sequences may require remaining steps for safety, and restart could no longer determine whether an action should repeat.
