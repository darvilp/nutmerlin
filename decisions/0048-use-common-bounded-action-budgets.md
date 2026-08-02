# ADR 0048: Use common bounded action budgets

- Status: Accepted
- Date: 2026-08-02

## Context

Connection establishment, dispatch acknowledgement, and target-state verification have different meanings. A single free-form timeout and retry count cannot safely cover local scripts, SSH, HTTP, MQTT, WinRM, Redfish, and future operations. Leaving every executor without a common baseline risks unbounded processes, retry storms, and inconsistent policy timing on a resource-constrained router.

ADR 0025 defines retry eligibility but deliberately leaves numerical defaults open.

## Decision

Every typed operation declares an action budget within common platform bounds. Unless a qualified operation contract specifies stricter or different defaults, the baseline is:

- connection timeout: 5 seconds
- dispatch timeout: 30 seconds
- verification timeout: 300 seconds
- `nonrepeatable`: one dispatch attempt and zero post-dispatch automatic retries
- `idempotent` or `idempotency_keyed`: at most three total dispatch attempts, with default retry delays of 2 seconds and then 5 seconds
- one in-flight action per logical target
- at most two concurrent executor dispatches per NUTMerlin installation
- at most 30 dispatch starts in any rolling 60-second interval

Further rules:

- Validation and a provably pre-dispatch connection failure may be retried within the budget without changing a nonrepeatable action's one-dispatch limit.
- A timeout after durable dispatch intent is an unknown outcome and follows ADRs 0024 and 0025.
- Verification polling does not count as another dispatch and cannot issue a state-changing command.
- The policy may reduce attempts, timeouts, concurrency, or rate but cannot exceed the operation contract or qualified platform ceiling.
- Global hard configuration ranges are 1–30 seconds for connection, 1–300 seconds for dispatch, and 0–1800 seconds for verification. Zero verification is valid only when the operation contract declares that no verification is supported or required.
- A complete action, including retries and verification, has a hard ceiling of 3600 seconds unless a later specialized workflow defines its own lifecycle.
- Retry delay, queueing, and verification time remain inside the policy stage deadline; exhausting any applicable budget produces an explicit failed or unknown result rather than an unbounded wait.
- Platform qualification may lower concurrency or rate ceilings, never silently raise them.

## Consequences

- Executor behavior has predictable resource and wall-time bounds while retaining operation-specific semantics.
- Large target groups may take several minutes and must expose estimated worst-case stage duration before activation.
- Redfish or other slow operations can define longer tested verification defaults without weakening every executor.
- Tests need exact timeout boundaries, rolling-rate behavior, target serialization, queue cancellation, process cleanup, and unknown-outcome recovery.

## Rejected alternatives

A single administrator-selected timeout and retry count would be simple but would conflate transport failure, side-effect dispatch, and verification. Entirely executor-specific limits would maximize flexibility but provide no safe baseline when a contract omits or misstates a bound.
