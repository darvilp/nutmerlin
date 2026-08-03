# NUTMerlin v0.1 hardware and bench guide

## 1. Reference targets

| Component | v0.1 role | Claim boundary |
| --- | --- | --- |
| ASUS RT-AX86U Pro | Production-reference router | Only the recorded revision, Merlin build, Entware/NUT, storage, and addon version |
| CyberPower CP1500PFCLCD | Physical reference UPS | Only the recorded USB identity, NUT version, and closed usbhid profile |
| Standard NUT secondary | Client interoperability | Authentication/status and local client ownership; no general OS shutdown certification |

The RT-AC3100, other Merlin families, other UPS models, and other NUT drivers are not v0.1 prerequisites or support claims.

## 2. Router gate

The RT-AX86U Pro is an in-use production router. Every deployment or modification requires:

```text
NUTMERLIN_ALLOW_PRODUCTION_ROUTER=1
```

Before testing:

- Record model, hardware revision, exact Merlin build, architecture, Entware feed and NUT packages, storage/filesystem/mount, and addon commit/package.
- Preserve router configuration and an independent local recovery path.
- Inspect proposed hook and firewall changes.
- Use dummy before the physical UPS.
- Confirm no test changes WAN, routing, DNS, DHCP, remote administration, or unrelated firewall policy.

## 3. Storage

Use the existing healthy Entware storage. Prefer an always-on SSD with native Unix ownership and modes. The v0.1 product checks only the properties it needs: expected mount, writeability, ownership/modes, safe file types, free space, and same-filesystem atomic rename.

Missing, read-only, replaced, or ownership-mismatched `/opt` keeps NUT unavailable and external access closed. Storage benchmarking, endurance certification, destructive media tests, generalized filesystem qualification, and swap are outside the product.

## 4. Physical identity

The accepted profile requires exact VID/PID plus stable serial or accepted stable physical busport. Logical bus/device values are diagnostics only. Reboot and reconnect must resolve the same physical identity; duplicate or changed matches must refuse.

If the reference UPS exposes no stable discriminator that survives reboot/reconnect, stop the physical-source claim. Do not weaken selection to first match.

## 5. Harmless physical test

1. Start read-only `usbhid-ups`, `upsd`, and local `upsc`.
2. Confirm stable identity and OL.
3. Briefly remove utility input while low-risk load remains attached; observe OB.
4. Restore utility input well before deep discharge; observe OL.
5. Disconnect and reconnect USB; observe bounded recovery to the same identity.
6. Query from one client in the configured trusted LAN scope.
7. Start one standard secondary with its unique credential; prove wrong/revoked credentials fail.
8. Exercise reboot, delayed `/opt`, killed services, firewall restart, disable, repair, update, and uninstall.

Never perform FSD, host shutdown, writable variables, instant commands, output-off, outlet control, delayed power, deep discharge, or sacrificial networking/storage tests.

## 6. Evidence report

Publish exact versions, steps, results, failures, and skipped checks. Redact full serials and reusable network/client details. Label numeric telemetry observed, absent, or unreliable; do not generalize charge/runtime/load/voltage accuracy from one run.

A negative result with exact evidence blocks only the affected reference claim. It does not invalidate host development or justify broadening the profile.
