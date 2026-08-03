# Graceful-only Redfish target profile qualification

> Historical research only. This document is non-authoritative for v0.1; Redfish execution is deferred.

Date: 2026-08-02

## Question and safety boundary

Can NUTMerlin qualify one exact BMC, firmware, account role, Redfish service,
and `ComputerSystem` binding that can read the selected system and request
`GracefulShutdown`, while target-side authorization denies `ForceOff`, reset,
power-on, administration, and access to unrelated systems?

This investigation used specifications, vendor documentation, and repository
inventory only. It did not contact a BMC, use credentials, create a session, or
issue any power or reset request. In particular, it did not attempt a dangerous
operation to test that the operation would be denied.

## Result: reproducible no-go for the currently documented environment

No exact target profile can be qualified from the available evidence.

The repository's hardware inventory names routers, one UPS, a Windows desktop,
and the WSL2 development host, but no BMC vendor, BMC model, server model,
firmware version, Redfish service identity, certificate, account role, or exact
`ComputerSystem` URI. Consequently there is no target on which to establish the
required exact identity, TLS behavior, role definition, session behavior,
already-Off behavior, asynchronous behavior, or independent `Off` observations.

The protocol standard cannot fill that evidence gap. DMTF defines graceful and
abrupt values, including `GracefulShutdown`, `ForceOff`, `ForceRestart`, `On`,
and `PowerCycle`, as parameters of the same `ComputerSystem.Reset` action
([DMTF Redfish Resource and Schema Guide, `ResetType`](https://redfish.dmtf.org/schemas/v1/DSP2046_2025.2.html#resettype)).
The standard privilege registry maps `GET` on a `ComputerSystem` to `Login` and
maps `POST` on that entity to one privilege, `ConfigureComponents`; it does not
express authorization conditional on the `ResetType` request value
([DMTF Redfish Privilege Registry 1.8.0](https://redfish.dmtf.org/registries/v1/Redfish_1.8.0_PrivilegeRegistry.json)).
The Redfish authorization model allows service-defined operation mappings and
OEM privileges, but those are implementation evidence, not a standard promise
that a graceful-only role exists
([DMTF Redfish Specification 1.20.1, authorization](https://redfish.dmtf.org/schemas/DSP0266_1.20.1.html#authorization)).

No generic vendor-family survey could qualify a target in place of the missing
inventory. Qualification requires first-party role evidence for one nominated
model and exact firmware, followed by harmless evidence from that exact target.
This no-go therefore makes no claim about whether an unexamined OEM service can
define a sufficiently narrow custom privilege.

The conditional P2 Redfish capability therefore remains **unavailable**. This
does not block the safe core release, and it does not weaken the contract by
substituting client-side omission for target-side least privilege.

## Reproduction of the no-go conclusion

The repository inventory was evaluated at ticket starting commit
`91eb10e6cf72cca39153dae92ce188d8d89e7657`. From the repository root, inspect
the complete committed reference inventory directly:

```sh
git show \
  91eb10e6cf72cca39153dae92ce188d8d89e7657:hardware.md
```

That immutable reference-environment table enumerates two ASUS routers, one
CyberPower UPS, a Windows desktop, and the WSL2 development host. It identifies
no server or BMC, so it cannot supply an exact Redfish target profile. Generic
Redfish requirements elsewhere in the tracked tree are contracts, not target
inventory.

The normative DMTF Privilege Registry 1.8.0 was retrieved on 2026-08-02. Its
SHA-256 is
`0ac76f33b78f2f6625de5add1f1de49162dd8a2adcb6cfb005a146842e349a03`.
Inspect it without a pipeline that could mask a failed download:

```sh
set -eu
registry_file=$(mktemp)
trap 'rm -f "$registry_file"' EXIT HUP INT TERM
curl -fsS -o "$registry_file" \
  https://redfish.dmtf.org/registries/v1/Redfish_1.8.0_PrivilegeRegistry.json
printf '%s  %s\n' \
  0ac76f33b78f2f6625de5add1f1de49162dd8a2adcb6cfb005a146842e349a03 \
  "$registry_file" | sha256sum -c -
jq -e '.Mappings[] | select(.Entity == "ComputerSystem") |
  .OperationMap.POST == [{"Privilege":["ConfigureComponents"]}]' \
  "$registry_file"
```

`set -eu` makes the download and pinned checksum control-flow gates: if either
fails, the shell exits before the registry query. With the pinned document, the
checksum command returns `OK` and the final command returns `true`: `POST` is
controlled by `ConfigureComponents`, with no body-value-specific entry for
`GracefulShutdown`. This is a harmless documentation query, not a target probe.
The cited DMTF DSP2046 2025.2 and DSP0266 1.20.1 documents are versioned
editions and were also retrieved on 2026-08-02. Their retrieved SHA-256 values
were respectively
`4480eb0410785faa87fcf0858635a24868e3c487720054517389af7c9e025d29` and
`92516e9933d92455a7863b55300c1e1a4df7ed55897845103e2dba1cae4a1f68`.

## Acceptance audit

Issue 11 explicitly permits either one exact qualified profile or a
reproducible no-go outcome. The evidence above satisfies only the no-go branch:

- Exact service and `ComputerSystem` identity cannot be pinned because the
  committed reference inventory contains no BMC target. The capability remains
  unavailable rather than accepting discovery drift or a first collection
  member, as required by
  [ADR 0075](../decisions/0075-constrain-and-verify-redfish-graceful-shutdown.md).
- TLS 1.2+, service identity, session behavior, already-Off handling,
  asynchronous behavior, five-second polling, and two consecutive fresh `Off`
  observations cannot be demonstrated without an exact target. They remain
  mandatory evidence for any future profile under
  [ADR 0075](../decisions/0075-constrain-and-verify-redfish-graceful-shutdown.md)
  and are not inferred from the protocol specification.
- The pinned privilege registry demonstrates that the standard
  `ComputerSystem` POST mapping does not itself distinguish
  `GracefulShutdown` from broader reset values. With no exact-firmware OEM role
  evidence, the required target-side denials are unproven and the profile must
  remain unavailable under
  [ADR 0075](../decisions/0075-constrain-and-verify-redfish-graceful-shutdown.md).
- Timeout, task failure, lost response, identity drift, or insufficient role
  evidence therefore cannot activate or escalate a binding. Any future
  implementation remains bound by the failed/unknown and no-escalation rules in
  [ADR 0040](../decisions/0040-defer-redfish-forceoff-to-later.md),
  [ADR 0075](../decisions/0075-constrain-and-verify-redfish-graceful-shutdown.md),
  and [ADR 0078](../decisions/0078-use-explicit-action-evidence-grades.md).

No acceptance criterion is represented as target-qualified evidence. The
reproducible no-go conclusion is the acceptance outcome until the exact target
and harmless evidence listed below are supplied.

## Evidence required to replace the no-go with one qualified profile

All of the following evidence belongs to one immutable profile. Evidence from
different BMC models or firmware versions cannot be combined.

### Exact target and service identity

Record:

- BMC vendor and exact model, server model and hardware revision, and exact BMC
  firmware build;
- one administrator-entered HTTPS base endpoint, with redirects disabled;
- TLS certificate chain or explicit certificate/public-key pin, certificate
  names, and the observed TLS protocol and cipher;
- service-root identity and Redfish version;
- one manually selected canonical `ComputerSystem` URI, plus stable target
  identifiers such as UUID, serial number, manufacturer, and model;
- the expected relationship between that system and its managing BMC.

Activation and every later use must compare the effective peer, service
identity, and selected-system identity with the pinned record. A redirect,
address or certificate drift, changed canonical URI, mismatched stable
identifier, multiple plausible systems, or missing identity evidence makes the
binding unavailable. The DMTF specification notes that resource trees are not
guaranteed to be identical between service instances, which is why selecting
the first collection member is not identity evidence
([DMTF Redfish Specification 1.20.1, resource-tree stability](https://redfish.dmtf.org/schemas/DSP0266_1.20.1.html#resource-tree-stability)).

### Verified transport and session lifecycle

Demonstrate TLS 1.2 or newer with normal hostname and chain verification using
a public CA, an explicitly installed private CA, or an explicit pin. Do not use
plaintext, trust-all, `--insecure`, redirect following, or automatic downgrade.
DMTF requires TLS 1.2 support or later and X.509 v3 certificates
([DMTF Redfish Specification 1.20.1, TLS](https://redfish.dmtf.org/schemas/DSP0266_1.20.1.html#transport-layer-security-tls-protocol)).

Before certificate-validity evaluation or session establishment, require
positive same-boot wall-clock synchronization evidence under ADR 0081. An
untrusted wall clock refuses a new TLS session or dispatch even when a
certificate is pinned; it never falls back to plaintext or trust-all.

Using the dedicated account, establish a Redfish session through the service's
advertised `Sessions` URI. Record the returned session resource location but
never the `X-Auth-Token`; keep the token transient and out of command arguments,
logs, reports, and persistent configuration. Use the token only over the pinned
connection. On completion, `DELETE` that exact session resource and record the
result. DMTF defines session creation, token use, timeout, and logout by deleting
the session resource
([DMTF Redfish Specification 1.20.1, session authentication](https://redfish.dmtf.org/schemas/DSP0266_1.20.1.html#redfish-session-login-authentication)).

### Non-actuating least-privilege proof

The account must have a dedicated target-side role. Preserve redacted,
version-specific evidence from the BMC's own role configuration or API and the
vendor's exact-firmware documentation showing that the role:

- can read the service root, selected system, its current `PowerState`, the
  reset action metadata, and asynchronous task state;
- can submit only `ResetType: GracefulShutdown` to the selected system;
- cannot submit `ForceOff`, `ForceRestart`, `GracefulRestart`, `On`,
  `PowerCycle`, `PushPowerButton`, NMI, or any other reset/power operation;
- cannot manage accounts, firmware, BIOS, boot configuration, virtual media,
  console, BMC configuration, or another `ComputerSystem`.

`ResetType@Redfish.AllowableValues` is capability evidence, not authorization
evidence. Likewise, a client allowlist containing only `GracefulShutdown` does
not constrain a stolen credential. Do not test denial by sending any dangerous
request. If exact role metadata or first-party documentation cannot prove each
denial, record the profile as `unavailable`.

## Qualification behavior to record on the exact target

Only after the preceding identity, TLS, and non-actuating role evidence is
complete may a separately authorized, controlled graceful-shutdown
qualification exercise run.

1. Require current trusted-wall-clock evidence, create one session, and
   revalidate the pinned peer, service, and selected system. If wall-clock
   trust is revoked before dispatch, close the session where safely possible
   and refuse dispatch. If it is revoked after the nonrepeatable request might
   have been accepted, preserve the accepted or unknown outcome, decline new
   wall-clock-dependent work, and never reinterpret it as not dispatched.
2. Fetch a fresh selected-system representation. If `PowerState` is `Off`,
   confirm it with a second fresh observation five seconds later, then return
   status `already_satisfied` with evidence grade `effect_verified` without
   POSTing an action. A missing, contradictory, stale, or unrecognized state
   returns status `refused` with evidence grade `not_dispatched` and inhibits
   dispatch.
3. Confirm that the selected system currently advertises
   `GracefulShutdown`. Send exactly one POST to its exact
   `ComputerSystem.Reset` target with the closed body
   `{"ResetType":"GracefulShutdown"}`. Never retry after dispatch might have
   occurred.
4. Treat a synchronous successful response only as status `accepted` with
   evidence grade `dispatch_accepted`. A conclusive target rejection before
   acceptance returns status `failed` with `dispatch_rejected`. For
   `202 Accepted`, require a same-origin `Location` task-monitor URI and follow
   it according to the DMTF asynchronous-operation contract. A cross-origin
   location, identity change, failed task, malformed task, vanished task before
   its outcome is known, timeout, or lost response never triggers another POST
   or a stronger operation. A conclusively accepted task that later fails is
   status `failed` with `dispatch_accepted`; ambiguity about whether the request
   was accepted or what target it affected is status `unknown` with
   `outcome_unknown`. DMTF
   specifies `202`, `Location`, optional `Retry-After`, task monitoring, and
   terminal error handling
   ([DMTF Redfish Specification 1.20.1, asynchronous operations](https://redfish.dmtf.org/schemas/DSP0266_1.20.1.html#asynchronous-operations)).
5. Independently GET the same pinned `ComputerSystem` every five seconds,
   measured with monotonic time. Revalidate peer, service, and system identity
   on every response. Each observation must be a newly completed response, not
   a replayed or locally cached sample.
6. Return status `verified` with evidence grade `effect_verified` only after
   two consecutive fresh observations report `PowerState: Off`. The
   observations are therefore separated by a polling interval. Stop at 300
   seconds. Any intervening non-Off observation resets the consecutive count.
   Missing, stale, contradictory, or identity-drifted evidence after possible
   dispatch ends status `unknown`. When dispatch acceptance was conclusive, its
   evidence grade remains `dispatch_accepted`; later verification failure or
   identity drift cannot erase that fact. Use `outcome_unknown` only when the
   dispatch response or the affected target identity was uncertain at the
   dispatch boundary.
7. On timeout, task failure, session failure, lost response, or ambiguous final
   state, preserve the most precise status/evidence pair above. A timeout with
   conclusive acceptance and continuous fresh non-Off observations is status
   `failed` with `dispatch_accepted`; uncertain acceptance or observation is
   status `unknown`, preserving `dispatch_accepted` when acceptance was already
   established. `outcome_unknown` is reserved for uncertainty about dispatch
   acceptance or affected-target identity at dispatch. Do not send `ForceOff`,
   reset, power-on, or a second `GracefulShutdown`. Terminate the session when
   the service remains safely reachable and record redacted cleanup evidence.

The result must distinguish request acceptance from verified target state and
follow the standard executor-result contract. It records executor name, target
ID, policy ID and immutable policy version, event ID, operation ID and version,
start and finish timestamps, dry-run state, exit/result status, retry count
(zero after dispatch), evidence grade, the two qualifying observation times,
and a bounded redacted diagnostic message.

Every failure before the POST, including untrusted clock, identity or TLS
failure, insufficient role evidence, unavailable state, or missing advertised
capability, is status `refused` or `failed` with `not_dispatched`. Session
cleanup failure cannot upgrade, erase, or otherwise change the evidence grade
already established for the action.

## Decision-thread input needed

To reopen qualification, a maintainer must nominate an exact, disposable or
otherwise safely controlled BMC/server profile and provide non-secret inventory
details plus access to its first-party firmware documentation. A BMC account,
certificate trust material, maintenance window, and authorization for one
graceful shutdown remain separate human-controlled prerequisites. Until then,
issue #11 should conclude with this no-go and Redfish should not be advertised
as available.
