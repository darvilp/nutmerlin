# ADR 0079: Constrain P0 local scripts to a portable contract

- Status: Deferred research - non-authoritative for v0.1
- Date: 2026-08-02

## Context

Immutable import and an unprivileged identity prevent live path replacement and ambient root execution, but an unrestricted local executable could still consume router resources, read exposed files, open arbitrary network connections, leak policy data, spawn descendants beyond its timeout, or invent a result format. Treating administrator import as a complete sandbox claim would obscure those residual risks.

## Decision

The P0 local-script executor is a narrow, portable POSIX shell adapter, not a general router command facility.

- A P0 imported artifact is a regular text file of at most 256 KiB with no NUL bytes, uses `/bin/sh`, and passes the platform shell's syntax validation before registration. Other interpreters or native binaries require a later runtime-specific ADR and dependency contract.
- NUTMerlin invokes the immutable owned copy directly through the qualified `/bin/sh`; policy data never selects an interpreter, executable path, shell fragment, environment assignment, redirection, or pipeline.
- The only input is one versioned JSON document on standard input, limited to 32 KiB, containing the declared typed-operation parameters and a minimized normalized event view. No policy-controlled command-line argument is used.
- Standard output is one versioned JSON result limited to 16 KiB. Standard error is diagnostic-only, captured to 8 KiB, redacted, and never parsed as authority. Missing, malformed, extra, or oversized output fails closed.
- P0 passes no NUTMerlin credential, secret reference, ambient user configuration, or inherited environment. The script runtime cannot read the secret store or safety journal.
- The runtime uses a private transient working directory, restrictive umask, read-only access to its imported artifact, bounded file/process/CPU resources where the qualified platform permits, and no core dump.
- The execution broker starts a dedicated process group. On budget expiry it sends termination, waits 2 seconds, then force-kills the remaining group; any uncertain side effect still follows the operation's retry and evidence rules.
- P0 local scripts have no network egress. Enabling the executor requires a qualified UID- or process-scoped firewall mechanism proving that the script identity cannot reach LAN, WAN, loopback control endpoints, or other namespaces except its protected broker result channel.
- If privilege drop, process cleanup, filesystem denial, resource bounds, or no-egress enforcement cannot be qualified on a platform, the local-script executor is unavailable there while core NUT service may remain supported.
- The P0 local-script operation registry is closed and excludes coordinator-router administration, host shutdown, FSD, writable UPS administration, and abrupt or output control. A manifest selects supported installed operation versions; it cannot create arbitrary semantics or lower an operation safety class.
- An operation-specific verifier may invoke a separately declared read-only script mode and parse its structured result. Ordinary exit zero or an execute-mode assertion establishes no more than the evidence its contract permits.
- Documentation states that imported code is administrator-trusted logic inside these boundaries, not hostile-code containment. NUTMerlin does not claim a general chroot, container, or mandatory-access-control sandbox.

## Consequences

- P0 scripts are useful for local markers and narrowly registered local integrations but cannot replace webhook, SSH, MQTT, or privileged router lifecycle modules.
- Some supported router profiles may lack this optional executor if their firewall or privilege mechanisms cannot enforce the boundary.
- Scripts requiring Python, credentials, network calls, root, live editing, or arbitrary arguments are intentionally excluded.
- Tests must cover file format and size, shell syntax, input/output limits, malformed and adversarial JSON, environment and secret denial, filesystem permissions, forked descendants, timeout escalation, resource exhaustion, no-egress rules and recovery, loopback denial, result evidence, and complete capability removal when any boundary is unavailable.

## Rejected alternative

Allowing any administrator-imported executable with ambient unprivileged network access and a free-form argument template would support more integrations, but would make the local-script executor an unstructured remote-command and data-exfiltration platform whose effective contract could not be inferred from policy or manifest metadata.
