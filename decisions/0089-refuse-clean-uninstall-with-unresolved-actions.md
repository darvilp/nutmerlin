# ADR 0089: Refuse clean uninstall with unresolved actions

- Status: Accepted
- Date: 2026-08-02

## Context

Clean uninstall removes the safety journal, secrets, and recovery state. If a nonrepeatable request is in flight, a sequence is committed, or an outcome is unknown, deleting that evidence could neither cancel the remote effect nor prove whether retry is safe. Missing or read-only `/opt` also prevents proving that all owned data was removed.

## Decision

Clean uninstall is available only from a fully reconciled lifecycle state; broken-storage emergency detach is a distinct incomplete operation.

- Uninstall preflight inhibits new policy eligibility and displays the verified ownership inventory, active and pending state, external credential/revocation checklist, retained packages, remote retained-data caveats, and irreversible local data removal.
- Undispatched reversible timers may be canceled and journaled as part of preflight. No already dispatched, committed, or unknown action is canceled or reclassified for uninstall.
- Clean uninstall refuses while an execution is in flight, a committed sequence remains incomplete, an outcome is unknown, restart or update reconciliation is unresolved, ownership is ambiguous, the safety journal cannot record the transaction, or required owned storage cannot be read and written.
- The administrator must resolve, wait for, or explicitly reconcile those states before clean uninstall. There is no `--force` that discards action evidence or guesses ownership.
- UPS state need not be online when no action state is unresolved, but uninstall during a confirmed outage carries a specific loss-of-monitoring warning and explicit confirmation.
- After preflight, the transaction closes policy and broker dispatch, external NUT listener/firewall scope, and managed services before deleting data. It removes all verified owned local artifacts under ADR 0015 and zero Entware packages under ADR 0013.
- NUTMerlin does not use stored target credentials to delete remote SSH authorizations, JEA endpoints, BMC accounts, webhook receiver state, broker accounts, or subscriber data during uninstall. It produces a non-secret per-binding revocation checklist before destroying local credentials; remote cleanup remains administrator-owned.
- MQTT retained cleanup follows ADR 0037. Failure to reach the broker is reported as unresolved remote data but does not retain local secrets or falsely fail local deletion.
- If `/opt` is missing, read-only, or integrity-failed, an explicit emergency detach may remove only independently verified JFFS hook blocks, UI mount, active pointer, and managed firewall activation needed to stop automatic startup and exposure.
- Emergency detach preserves the minimum verified ownership evidence, detach receipt, release recovery path, and all inaccessible `/opt` data. It is labeled detached/incomplete, not disabled or uninstalled, makes no secret-deletion or secure-erasure claim, and can converge to clean uninstall only when storage and ownership are reconciled.
- An interrupted clean uninstall resumes from its lifecycle journal. It cannot fall back to emergency detach or delete unjournaled artifacts automatically.

## Consequences

- An administrator cannot erase the only record that a remote shutdown may have been accepted.
- Failed media may leave secrets and project data physically present even after router integration is safely detached; the UI/CLI must state that plainly.
- Remote target-side accounts and public-key entries require a visible cleanup checklist rather than risky best-effort automation.
- Tests must cover pending cancellation, every in-flight/commit/unknown state, outage warning, journal and ownership faults, missing/read-only/replaced storage, exact JFFS detach scope, storage return and convergence, interrupted uninstall, MQTT cleanup failure, remote artifacts, and absence of a force-evidence-discard path.

## Rejected alternative

A force-uninstall option that stops processes and deletes every reachable project path would help with badly broken installations, but could erase unknown-action and ownership evidence, leave inaccessible secrets behind while claiming success, or delete artifacts from a replaced/foreign volume.
