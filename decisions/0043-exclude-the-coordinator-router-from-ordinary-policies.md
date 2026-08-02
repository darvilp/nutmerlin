# ADR 0043: Exclude the coordinator router from ordinary policies

- Status: Accepted
- Date: 2026-08-02

## Context

NUTMerlin depends on its host router for policy execution, NUT service, LAN reachability, firewall enforcement, diagnostics, and recovery. The architecture and safety guidance intend network infrastructure to remain available during ordinary host load shedding, but an unrestricted logical-target model could permit a local or remote binding to address the router itself.

Router shutdown is also part of the separately defined complete NUT FSD lifecycle, where ordering, latching, power-down state, output behavior, and restoration must be handled together.

## Decision

The coordinator router is structurally excluded from all ordinary policy actions.

- It cannot be created or selected as an ordinary logical target, whether addressed through a local name, loopback, a router interface address, or another identity NUTMerlin can establish as local.
- P0 through P2 typed policy operations cannot shut down or reboot the coordinator, stop NUTMerlin, or disrupt routing, DNS, firewall, Wi-Fi, WAN, or other router control-plane services.
- Local-script execution does not provide an exception to this invariant.
- Administrator-initiated lifecycle operations such as validating or restarting NUT services remain operational controls outside the policy engine.
- Shutting down the coordinator is permitted only as an explicit step of a complete production FSD workflow satisfying ADR 0038 and its separate gates.
- Ambiguous self-target identity fails closed rather than permitting policy activation.

## Consequences

- Ordinary load shedding cannot strand its own coordinator or intentionally interrupt the site's network services.
- Target and binding validation must compare configured and effective identities against the router's local interfaces and known names.
- Users wanting the router to shut down must use the complete FSD lifecycle rather than a generic local script, SSH action, or router-shutdown operation.
- Tests must cover loopback, interface addresses, aliases, name-resolution changes, and local-script attempts to affect protected services.

## Rejected alternative

An explicitly enabled terminal `router.graceful_shutdown` action could turn off the router after prior stages complete, but would duplicate FSD lifecycle responsibilities and could sever execution, verification, diagnostics, and restoration handling at an unsafe point.
