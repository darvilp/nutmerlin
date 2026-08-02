# ADR 0065: Qualify UPS capabilities independently

- Status: Accepted
- Date: 2026-08-02

## Context

NUTMerlin delegates device protocols to NUT and should not maintain a competing vendor allowlist. A driver successfully opening a device does not establish that every reported field is accurate, that low-battery behavior is observable, or that any discovered instant command is safe. One overall supported/unsupported label cannot represent these differences.

## Decision

UPS eligibility follows NUT compatibility and harmless runtime probes; exact qualification is capability-specific.

- A uniquely matched source accepted by a packaged NUT driver through an installed validated NUTMerlin driver profile is eligible for basic use when it provides syntactically valid `ups.status`, passes freshness and lifecycle probes, and has no known base incompatibility.
- Eligibility is not a claim that numerical telemetry, low-battery signaling, writable variables, instant commands, or output behavior are qualified.
- One complete reproducible physical report is sufficient to qualify a named capability for the recorded UPS model, hardware revision and firmware when exposed, USB IDs, NUT driver and configuration, NUT package version, addon version, and router/platform context.
- Base monitoring qualification requires stable online observation, a controlled short on-battery transition and recovery, stale-data behavior, USB disconnect/reconnect, source-identity continuity, and absence of routing or log disruption.
- Charge, runtime, low-battery signaling, overload, replace-battery, writable variables, harmless administrative operations, and output behavior are independent capability records with their own evidence.
- A reported field may remain observed or known-unreliable under ADR 0046 even when base monitoring is qualified.
- Listing or discovering a writable variable or instant command is read-only capability inventory and never qualifies or authorizes execution.
- Ordinary physical qualification runs no output-cutting command and does not require deep battery discharge.
- A community report and a maintainer report use identical evidence rules.
- Reproducible negative evidence revokes the affected capability. It makes the whole source known-incompatible only when a mandatory base capability cannot operate safely.
- Router qualification and UPS capability qualification are independent; neither substitutes for the other.

## Consequences

- New devices supported by an installed NUTMerlin driver profile can provide basic monitoring without waiting for a NUTMerlin model allowlist.
- The UI can accurately show that OL/OB is qualified while runtime is merely observed or known unreliable.
- Advanced capabilities accumulate evidence without broadening permission from discovery alone.
- Tests and report schemas need capability IDs, exact provenance, positive and negative evidence, and independent carry-forward triggers.

## Rejected alternative

A model allowlist with one pass/fail status would be easy to communicate but would duplicate NUT's compatibility work and could not safely represent partial or unreliable device capabilities.
