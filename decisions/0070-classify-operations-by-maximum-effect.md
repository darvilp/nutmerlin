# ADR 0070: Classify operations by maximum effect

- Status: Deferred research - non-authoritative for v0.1
- Date: 2026-08-02

## Context

The packet repeatedly refers to "destructive" actions, but that term currently covers effects ranging from stopping one service to cutting all UPS output. A single boolean or executor-wide permission cannot express materially different commitment, privilege, verification, qualification, and physical-hazard requirements. It also risks allowing a broad administrative-command switch to authorize a newly added operation accidentally.

## Decision

Every typed operation version declares exactly one closed safety class representing its maximum credible effect:

1. `observe` — read-only query, validation, or harmless capability test.
2. `notify` — outbound information delivery with no contract to change a managed target's state.
3. `service_graceful` — graceful stop or shedding of an application, workload, or non-host service.
4. `host_graceful` — an operating-system-managed shutdown or hibernation request.
5. `shutdown_committed` — entry into a distributed or locally latched shutdown lifecycle that does not cancel after its commit boundary, including production FSD.
6. `power_abrupt` — force-off, hard reset, or equivalent removal of host execution without an operating-system graceful-shutdown contract.
7. `output_control` — UPS or PDU output off, cycle, delayed cut, stay-off, return, or equivalent control of delivered power.

The classes have these rules:

- An operation capable of more than one effect receives the highest applicable class. A parameter, executor, or policy cannot lower it at runtime.
- Operation classes are registry-controlled metadata covered by the release manifest and tests; imported script manifests request a class but cannot introduce a class or operation contract absent from the installed registry.
- Changing an existing operation to a higher-risk effect requires a new operation version and invalidates activation evidence and policy compatibility. A release never silently reclassifies an active version downward to bypass gates.
- `observe` and `notify` still require binding, transport, data-disclosure, and monitoring-only activation controls; their class does not mean universally harmless.
- Every class from `service_graceful` upward requires an enabled central-action capability, explicit target permission for that class or higher, an immutable activated policy reference, current harmless activation evidence, and the operation's own runtime safety checks.
- `host_graceful` additionally requires the host-shutdown test gate in destructive test environments. It never grants `shutdown_committed`, `power_abrupt`, or `output_control` authority.
- `shutdown_committed` requires a separately complete and qualified lifecycle gate. Production FSD remains unavailable under ADR 0038 until that lifecycle exists.
- `power_abrupt` and `output_control` remain absent from P0 through P2 operation registries under ADRs 0039 and 0040. Future support requires class-specific ADRs, qualification, interaction design, and independent global, target, binding, and policy authorization.
- A generic switch such as `NUTMERLIN_ALLOW_UPS_COMMANDS` cannot register an operation, widen a credential, satisfy a class gate, or authorize `output_control`.
- Executor credentials and target-side permissions are provisioned for the least powerful operation set actually enabled. Enabling one class does not pre-provision dormant authority for a higher class.
- Dry-run, simulation, discovery, or a harmless test cannot acquire production authority for its simulated operation class.
- Destructive lifecycle administration such as uninstall is governed by its lifecycle transaction and confirmation contract, not misrepresented as a policy operation.

## Consequences

- UI, CLI, audit, policy validation, credential provisioning, and tests can refer to exact effects instead of one ambiguous destructive flag.
- Adding a higher-risk operation cannot become active through an old target opt-in or broad UPS-command environment variable.
- Some protocol credentials or endpoints need separate bindings when their server-side authority spans different classes.
- Tests must exhaustively map every registered operation version to one class, reject unknown classes and downward overrides, prove gate non-substitution, and prove P0 through P2 contain no `power_abrupt` or `output_control` operation.

## Rejected alternative

A `safe` versus `destructive` boolean plus global and target opt-in would be simpler, but would treat graceful service shedding, committed FSD, forced host power-off, and UPS output removal as interchangeable authority.
