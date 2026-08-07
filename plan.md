# NUTMerlin v0.1 implementation roadmap

## Product tracer

The v0.1 milestone is complete only when this exact path works:

```text
CP1500PFCLCD -> usbhid-ups -> upsd on RT-AX86U Pro
             -> one trusted LAN scope -> standard secondary client
```

The client owns its local shutdown. The router remains monitoring-only and provides no central action execution.

## Authoritative ticket graph

GitHub native dependencies are the blocking authority. Issue #2 remains the open umbrella and is not a blocking dependency.

```text
#14 -> #12 -> #15 -> #17 -> #16 -> #18 -> #51 -> #23 -> #21 -> #52 -> #37 -> #38
```

### #14 — Real dummy NUT vertical slice

Prove installed host `dummy-ups -> upsd -> upsc` in an isolated root. This ticket also removes the unused qualification/preflight framework; it is not complete until real NUT behavior passes.

### #12 — Owned install and configuration

Install the attributable core, perform read-only Entware and foreign-state checks, render one complete dummy configuration, and prove current/LKG activation.

### #15 — Merlin lifecycle and CLI

Add hooks, bounded reconciliation, delayed `/opt` behavior, service control, stable status, and diagnostics. Perform the first manually gated reference-router dummy smoke after this ticket.

### #17 — Stable physical source

Implement the closed `usbhid-ups` renderer and unique stable identity handling. Perform the first harmless local physical-UPS smoke after this ticket.

### #16 — Trusted-LAN exposure

Configure and verify one exact IPv4 listener and one exact source CIDR through an owned firewall chain. Dummy remains loopback-only.

### #18 — Secondary client

Generate unique `upsmon secondary` credentials, prove standard-client authentication, and support revocation without secret recovery or rollback resurrection.

### #51 — Targeted Entware NUT package refresh

After read-only ownership and Entware checks, offer a default-No refresh of exactly the six required NUT roots. Support the explicit noninteractive flag, stop owned live surfaces before mutation, re-probe compatibility, and fail stopped without general Entware management.

### #23 — Disable, repair, uninstall

Close live surfaces, restore only attributable artifacts, and remove owned code/configuration/credentials/hooks/jobs/firewall state while retaining Entware packages.

### #21 — Package and update

Build a deterministic core archive and implement local user-initiated update with one immediate backup and smoke recovery. No downloader or automatic check is part of v0.1.

### #52 — Interactive AMTM-style management

Add the conventional local menu for install/status/source/LAN/client/service/update/removal workflows, including the same default-No targeted Entware refresh. AMTM catalog submission remains outside v0.1.

### #37 — Exact hardware evidence

Run the complete tracer and failure/recovery matrix on the exact RT-AX86U Pro, CP1500PFCLCD, storage, Entware/NUT, and client environment.

### #38 — First alpha gate

Require all automated checks and #37 evidence, then prepare the deterministic archive, source tag, SHA-256, installation/update guide, known limitations, and narrowly scoped alpha claim.

## Development, alpha, and broader release gates

### Private development

- POSIX/static, unit/golden, real dummy NUT, and simulated Merlin tests.
- Local deterministic packages.
- No hardware or release-authentication prerequisite.

### First alpha

- Every ticket in the graph complete.
- Exact router/UPS/client evidence complete without destructive operations.
- Deterministic package and SHA-256 published from a tagged commit.
- Claims limited to the recorded combination.

### Broad public support

Later work may add wider router/UPS evidence, stronger release authentication and root recovery, optional WebUI, notifications, or other features. None is part of or a blocker for v0.1 alpha.

## Exit conditions

Code presence alone does not complete v0.1. The milestone requires working install, NUT processes, lifecycle, CLI, exact LAN admission, standard client authentication, physical-source identity/reconnect, owned repair/removal, and the separate evidence layers defined in `testing.md`.
