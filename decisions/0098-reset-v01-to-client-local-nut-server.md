# ADR 0098: Reset v0.1 to a client-local NUT server tracer

- Status: Accepted
- Date: 2026-08-02
- Updated: 2026-08-06 by ADR 0083

## Context

The prior plan was building release authority, storage qualification, policy, action, journaling, recovery, and WebUI frameworks before proving that Entware NUT could serve a real UPS through Merlin lifecycle hooks to a standard client. That sequence made a useful initial add-on distant and encouraged a large concurrent orchestration engine in POSIX shell.

The central initial use case needs no router-side action dispatch. NUT already provides UPS drivers, `upsd`, status clients, and standard secondary semantics. A secondary client can own its local shutdown policy and command.

## Decision

NUTMerlin v0.1 is a conventional monitoring-only NUT server add-on.

- Prove real `dummy-ups -> upsd -> upsc` before broader installation or release infrastructure.
- Install a small attributable POSIX-shell core under `/jffs` and complete owned NUT configuration under `/opt`.
- Use one loopback-only dummy source and one uniquely identified `usbhid-ups` source.
- Use the local CLI, small Merlin hook blocks, NUT processes, and one periodic reconciler; introduce no NUTMerlin daemon.
- Select complete configuration sets atomically through `NUT_CONFPATH`, retaining only current and last-known-good. This is not a general transaction or release-slot framework.
- Expose the real source only on one explicit router IPv4 address and one explicit trusted IPv4 CIDR with verified listener/firewall agreement.
- Give each standard secondary client one unique restricted credential. The client owns local shutdown; the router neither dispatches nor verifies it.
- Keep install and update monitoring-only, local, and user-initiated. Entware itself remains a preexisting prerequisite; installation may explicitly refresh only the six required NUT roots under ADR 0083.
- Qualify one exact RT-AX86U Pro and one exact CyberPower CP1500PFCLCD combination before the first alpha; do not generalize those results.

The v0.1 runtime excludes policy authoring/execution, targets, action registries, brokers, journals, scheduling, remote executors, FSD, writable UPS administration, output control, generalized clock/transaction/history systems, import/export, support bundles, WebUI, notification transports, broad hardware matrices, and release-root ceremony.

Dummy remains loopback-only. Trusted-LAN and standard-client configuration may be implemented before physical evidence, but actual external admission opens only for a healthy uniquely identified real source.

## Consequences

- A useful NUT server and standard-client path become the first milestone.
- Shell remains limited to installation, rendering, hooks, lifecycle, credentials, and diagnostics.
- Existing preflight and orchestration work is retained in history only where it does not accelerate the tracer.
- Private development and alpha integrity checks do not wait for public signing-root infrastructure.
- Broader support or centralized orchestration requires a new architecture review. A concurrent future controller should be considered as a small compiled component instead of expanding the v0.1 shell modules.

## Rejected alternative

Continuing the prior milestone graph would preserve already-written qualification work but would keep the first functioning NUT server transitively blocked by speculative release and orchestration infrastructure. Restarting from `main` would discard useful host-safety work while retaining much of the same product over-scope.
