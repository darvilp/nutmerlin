# ADR 0046: Require qualified numeric telemetry for threshold actions

- Status: Deferred research - non-authoritative for v0.1
- Date: 2026-08-02

## Context

NUT exposes whatever variables a UPS and driver combination can report, but the presence of `battery.runtime` or `battery.charge` does not establish accuracy, responsiveness, or suitability for an action threshold. Coercing absent or malformed data to zero is already prohibited; accepting every parseable estimate would retain a similar safety hazard.

## Decision

Numeric runtime and charge values must be qualified for the exact UPS and driver combination before they can authorize a policy action.

- A fresh, syntactically and physically valid value may be displayed even when unqualified, with an explicit `observed`, `qualified`, or `known_unreliable` confidence state.
- Qualification may come from a matching published hardware report or an explicit local observation workflow that records source identity, driver version, status transitions, value behavior, and known limitations.
- A known-unreliable field is display-only until new evidence supersedes that classification.
- Runtime- and charge-threshold conditions are evaluated only during a confirmed on-battery episode. Low values while online, charging, calibrating, stale, or in contradictory state cannot trip these conditions.
- A threshold becomes active only after two consecutive fresh qualified values meet it, following the observation interval and freshness rules in ADR 0045.
- No runtime or charge threshold is enabled or prefilled by default.
- The default charge clear threshold is the configured trip threshold plus 2 percentage points.
- The default runtime clear threshold is the configured trip threshold plus the larger of 60 seconds or 10 percent of the trip threshold.
- A policy may configure a larger clear margin but not a smaller one without a separately qualified source profile.
- A threshold transition fires at most once per outage episode unless an explicitly modeled later stage uses a distinct threshold.
- Numeric values and qualification evidence never override contradictory categorical status or stale-source inhibition.

## Consequences

- Unknown UPS models retain useful dashboards without silently gaining unsafe automation authority.
- Community hardware reports can progressively enable safe threshold capabilities without hard-coding a vendor allowlist.
- Threshold onboarding needs confidence labels, evidence provenance, and harmless simulation separate from real-device qualification.
- Tests must cover unqualified-but-displayable data, known-unreliable data, charging values, hysteresis boundaries, implausible values, and source/profile changes.

## Rejected alternative

Allowing every fresh parseable value after a one-time warning would make threshold policies immediately available on more devices, but would turn an administrator acknowledgement into evidence that the UPS estimate is trustworthy.
