# NUTMerlin decision index

This is the sole ADR authority index for v0.1. An ADR binds v0.1 only when listed active here, regardless of historical status or wording elsewhere.

## Active

- [ADR 0001: Name and scope](0001-name-and-scope.md)
- [ADR 0002: Default to client-local shutdown](0002-default-client-local-shutdown.md)
- [ADR 0004: Test without a full firmware emulator](0004-testing-without-full-firmware-emulator.md)
- [ADR 0006: Repository and license defaults](0006-repository-defaults.md)
- [ADR 0007: Treat Entware storage as fallible and minimize writes](0007-storage-durability.md)
- [ADR 0010: Refuse foreign or ambiguously owned NUT deployments](0010-refuse-foreign-nut-deployments.md)
- [ADR 0013: Retain Entware packages during normal uninstall](0013-retain-entware-packages-on-uninstall.md)
- [ADR 0016: Make addon updates user-initiated](0016-user-initiated-addon-updates.md)
- [ADR 0020: Use independent shutdown-client credentials](0020-use-independent-shutdown-client-credentials.md)
- [ADR 0042: Default to monitoring-only](0042-default-to-monitoring-only.md)
- [ADR 0055: Use permissioned secret files without secret backup](0055-use-permissioned-secret-files-without-a-secret-backup.md)
- [ADR 0058: Require a unique stable USB source identity](0058-require-a-unique-stable-usb-source-identity.md)
- [ADR 0059: Gate external NUT access on verified firewall scope](0059-gate-external-nut-access-on-verified-firewall-scope.md)
- [ADR 0083: Require healthy Entware and confirm a bounded NUT package refresh](0083-require-a-preexisting-healthy-entware-installation.md)
- [ADR 0098: Reset v0.1 to a client-local NUT server tracer](0098-reset-v01-to-client-local-nut-server.md)

## Superseded

Inactive ADRs marked `Superseded by ADR 0098` describe replaced v0.1 architecture, interfaces, milestones, or acceptance gates. They remain historical evidence but must not be implemented.

## Deferred research

Inactive ADRs marked `Deferred research - non-authoritative for v0.1` describe possible future capabilities or evidence. They have no accepted current interface, milestone, or dependency and require a fresh review before implementation.

Both groups are non-authoritative for v0.1. This includes the former policy/action framework, safety journal, target and operation registries, release-root ceremony, generalized transaction and rollback manager, WebUI, notifications, centralized executors, FSD, output control, broad platform matrices, and other speculative extensions.

## Conflict handling

`requirements.md` defines current product behavior. Active ADRs settle durable choices. ADR 0098 narrows earlier active decisions where necessary to fit the approved v0.1 tracer. Safety and explicit GitHub ticket acceptance criteria take precedence over summaries.
