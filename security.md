# NUTMerlin v0.1 security model

## 1. Assets and trust boundaries

NUTMerlin protects:

- Router integrity and availability.
- Foreign Entware/NUT configuration and shared packages.
- Client credentials.
- Physical-source identity.
- The trusted-LAN listener and firewall boundary.
- The distinction between simulation and a real UPS.

The administrator's local router shell is trusted. NUT client traffic, NUT-reported values, USB identity data, archive contents, configuration inputs, hook contents, package output, and filesystem state are untrusted until validated.

v0.1 deliberately creates no browser, HTTP management, remote-action, inbound message, or general command surface. Its menu is local, invoked, and interactive only.

## 2. Privilege boundary

Install, hook editing, firewall changes, and service lifecycle require router administration. Parsing and rendering remain narrow shell code. Network-facing `upsd` must use a qualified non-root Entware identity; driver privilege behavior must match the exact supported package/profile.

No input may become shell code, an environment assignment, redirection, pipeline, executable path, hook name, arbitrary driver option, arbitrary NUT directive, firewall fragment, or command argument outside a closed validated position. Runtime code must not use `eval` or source administrator-writable state.

The menu accepts bounded choices, confirmations, and literal fields and dispatches only fixed CLI operations. It verifies the complete installed ownership state before executing the installed CLI. Invalid input, unverified installation state, and end-of-input are inert. It does not provide a shell escape, raw configuration editor, arbitrary executable path, or alternate authorization path; consequential choices retain explicit confirmations.

## 3. Ownership and filesystem safety

- Refuse foreign or ambiguous NUT files, processes, listeners, hooks, or ownership metadata before mutation.
- Treat symlinks, unexpected hard links, wrong file types, traversal, and roots outside the configured installation roots as refusal.
- Use private candidate directories and same-filesystem atomic rename.
- Verify owner and mode after writes.
- Put high-frequency and retry state in `/tmp`.
- Missing/read-only/replaced `/opt` closes live exposure and does not authorize adoption or reconstruction.
- Complete uninstall requires positive ownership and present storage; uncertainty retains data rather than deleting foreign state.
- Missing storage permits code-root-verified disable and exact removal of attributable live surfaces, but not deletion of residual `/opt` data.

## 4. Source safety

Dummy is always named `dummy`, loopback-only, and unable to inherit physical-source or LAN authority. Physical activation requires one exact stable identity. VID/PID alone is insufficient when multiple compatible devices exist; logical bus and device numbers never establish authority.

v0.1 emits no `allowfrom`, writable-user, `actions`, `instcmds`, `SET`, `FSD`, `SHUTDOWNCMD`, output-off, outlet, PDU, Redfish, or remote-executor capability beyond the standard restricted secondary role.

## 5. Network boundary

Read-only NUT status is normally unauthenticated inside NUT, so listener and firewall scope are the security boundary.

- Require one explicit router LAN IPv4 address and one explicit source CIDR.
- Reject wildcard, `/0`, loopback, multicast, broadcast, WAN-equal, invalid, and default IPv6 exposure.
- Install an allow-then-deny rule only in an attributable chain.
- Verify effective listener and rules before reporting exposure healthy.
- Dummy, unhealthy real source, missing storage, invalid configuration, and firewall failure remain loopback-only or stopped.
- Never add a WAN, guest, VPN, or generic private-address assumption.

## 6. Credential handling

Each client receives 24 independent random bytes from `/dev/urandom`, encoded as 48 lowercase hexadecimal characters. Secret files are root-only and omitted from logs, status, diagnostics, arguments, package artifacts, update metadata, and documentation. Creation may return the value once to the invoking administrator. There is no recovery or display command; loss requires add/revoke.

Credential revocation is a security-reducing configuration change and cannot be undone by automatic fallback.

## 7. Package and update safety

NUTMerlin never bootstraps or repairs Entware, changes feeds, invokes a blanket package upgrade, downgrades/removes packages, or installs optional roots. Before any package mutation it verifies ownership, foreign-NUT state, storage, package-manager health, and the current six-root compatibility result. Interactive install and installed-menu refresh both default to no; installer-only noninteractive authorization requires `--install-dependencies`. Authorization permits only `/opt/bin/opkg update` and one targeted install of all six roots with normal dependency resolution. Existing owned service/recovery/network surfaces close first. Mutation or post-check failure remains disabled and stopped; compatible decline proceeds without `opkg`, while missing/incompatible decline stops.

Update accepts only a local archive with a required adjacent `<archive>.sha256` sidecar and an internal allowlisted per-file checksum manifest. It verifies the archive digest, safe paths/types, inventory, file digests, and compatibility before replacing code. v0.1 checks transport integrity but does not claim an independent publisher-authentication root. There is no network downloader or stream-to-shell path.

## 8. Failure response

A failed or ambiguous source, storage, configuration, ownership, listener, firewall, credential, or service state fails closed for NUTMerlin without changing unrelated router networking. Recovery work is serialized and bounded. Successful polls create no persistent writes.

Security-relevant diagnostics identify categories and safe remediation while redacting secrets, full device serials in public output, and reusable network details.

## 9. Prohibited testing

Automated and v0.1 release tests must not perform host shutdown, NUT FSD, writable UPS variables, instant commands, output-off, outlet switching, deep discharge, or sacrificial network/storage tests. Physical tests begin read-only and use only brief utility-input removal and USB reconnect.

## 10. Deferred threats

WebUI/CSRF, remote executor credentials, signed release roots, event/action journals, multi-source authority, output control, notification transports, and client outcome verification are deferred with their features. They are not justification for adding preventive frameworks to v0.1.
