# ADR 0085: Snapshot explicit targets into policy stages

- Status: Accepted
- Date: 2026-08-02

## Context

The load-shedding examples name `noncritical`, `important`, and `critical` target groups. If those are live priority classes, changing group membership could silently add a target to an active shutdown policy, and merely assigning a label could grant state-changing authority. Fixed tiers also do not fit every household, lab, NAS, service, or network layout.

## Decision

Target groups are authoring and display metadata; executable policies contain explicit immutable target and action snapshots.

- `noncritical`, `important`, and `critical` are example labels only. NUTMerlin defines no built-in group names, fixed priority count, or implicit action for a group.
- A target may have zero or more administrator labels or groups, none of which grants an operation safety class, binding permission, protection removal, stage position, or policy activation.
- A policy draft may use a group or query as an authoring selector. Before validation, it expands to exact target IDs, binding requirements, actions, and operation versions; the immutable candidate and active policy contain that explicit expansion.
- Adding, removing, or relabeling a target after activation never changes an active policy or in-progress episode. The administrator must create, preview, test, and activate a new policy version.
- Activation preview lists every exact target and operation by stage, highlights additions, removals, protection changes, and safety-class changes from the previous active version, and rejects an unexpectedly empty expanded action stage.
- Stages have explicit stable IDs, administrator labels, trigger/elapsed conditions, and action sets. Stage order controls eligibility timing only; it creates no action prerequisite, success dependency, or permission by itself under ADR 0049.
- A target may appear in multiple stages or policies only when conflict analysis under ADR 0050 permits the resulting exact intents.
- Coordinator and infrastructure protections, binding capability, current activation evidence, and target safety gates are revalidated after expansion and cannot be inherited from group membership.
- Copy-only policy templates may demonstrate a three-stage shedding pattern, but contain no enabled targets, timer, numeric threshold, or live group reference and remain inert under ADR 0042.

## Consequences

- Renaming a group is harmless to active execution, and adding a new server cannot silently place it in an outage action.
- Policy activation requires a concrete target diff, increasing safety and auditability for large groups.
- Administrators may need to activate a new policy version after ordinary inventory changes.
- Tests must cover group additions and removals during active and in-progress policies, empty expansion, multiple membership, protected targets, prior-version diffs, template copying, stage-order nondependency, and cross-policy conflict after expansion.

## Rejected alternative

Three live built-in priority tiers would make common load shedding easier to configure, but would hard-code subjective semantics and allow an inventory edit to mutate executable shutdown scope without a policy-version review.
