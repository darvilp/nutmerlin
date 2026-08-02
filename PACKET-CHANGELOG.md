# Starter packet changelog

## 2026-08-02 optional WebUI correction

- Added ADR 0097 and the core component/WebUI component terminology.
- Made the complete CLI core the default installation and the exact-version Merlin WebUI an explicit optional component under the same signed release.
- Added independent UI install, removal, update, rollback, ownership, failure-isolation, security, and qualification contracts.
- Recorded current Merlin/amtm packaging evidence, including both separate companion UIs and bundled counterexamples.

## 2026-08-02 design reconciliation

- Added root CONTEXT.md, decision-ledger.md, and accepted ADRs 0001–0096 under the existing decisions/ hierarchy; ADR 0097 was added by the subsequent optional-WebUI correction.
- Reconciled requirements, architecture, security, testing, hardware, development, capability plan, backlog, README, repository policy, agent guidance, and primary references.
- Replaced the personal-hardware framing with current-family capability support, exact-hardware reports, and independently qualified UPS capabilities.
- Made client-local NUT secondary shutdown the P0 path and froze production FSD, abrupt/output control, restoration, writable UPS administration, direct SNMP/PDU, hibernation, multiple sources, and scheduling into Later.
- Defined authenticated first install, pinned OpenPGP releases, journaled two-slot update/rollback, immutable NUT configuration generations, conservative ownership, clean-uninstall refusal, and emergency detach.
- Defined monitoring-only defaults, exact listener/firewall scope, per-client credentials, two-phase cutover, privilege separation, typed operations, action evidence, bounded policies, storage journals/history, and recovery behavior.
- Corrected the public repository identity to darvilp/nutmerlin.
- Kept implementation code, GitHub issues, ticket generation, and formal implementation sequencing outside this reconciliation.

## 2026-08-01 revision

- Confirmed UPS model as CyberPower CP1500PFCLCD.
- Confirmed optional legacy router as ASUS RT-AC3100 currently running stock Asuswrt.
- Made the RT-AC3100 an optional 386/ARMv7 integration target rather than a development dependency.
- Added AP-mode bench topology and no-WAN/internet-egress guidance.
- Added WSL2/Codex IDE beta development workflow.
- Added public GitHub repository, GPL-3.0-or-later, and GitHub Actions defaults.
- Added storage-media qualification and write-minimization requirements.
- Added ADRs for optional legacy hardware, repository defaults, and storage durability.
- Added `.gitignore`, `.editorconfig`, and GPLv3 license text for repository bootstrap.
