# NUTMerlin v0.1 context

NUTMerlin is an Asuswrt-Merlin add-on that owns a small integration layer around a preexisting Entware installation of Network UPS Tools (NUT).

## Product terms

**NUT source**

One NUT driver instance. v0.1 supports the closed `dummy-ups` profile named `dummy` and one closed `usbhid-ups` profile named `ups`.

**Real source**

The uniquely identified physical UPS served as `ups`. It is the only source eligible for trusted-LAN exposure.

**Dummy source**

The release-owned `dummy-ups` fixture served as `dummy`. It is loopback-only and never substitutes for the real source.

**NUT server**

The Entware `upsd` process started by NUTMerlin with an exact `NUT_CONFPATH`.

**Secondary client**

A standard NUT `upsmon` client using a unique restricted credential. It owns its local outage delay, cancellation, and shutdown command. NUTMerlin neither sends nor verifies that shutdown.

**Configuration set**

A complete private directory containing the typed model and generated NUT configuration. NUTMerlin retains only current and last-known-good sets and atomically selects the current set.

**Installation identity**

A random non-secret identifier recorded under both `/jffs` and `/opt`. It distinguishes NUTMerlin-owned artifacts from foreign or ambiguous NUT state.

**Trusted LAN scope**

One administrator-entered router IPv4 listener address and one administrator-entered IPv4 CIDR admitted by an owned firewall rule.

**Monitoring-only**

The server may expose status and authenticate a standard secondary client, but it provides no writable UPS operation, FSD, remote action, router-side policy, or output control.

**Reconciliation**

Idempotent lifecycle work invoked by Merlin hooks, the local CLI, or one periodic `cru` job. It starts or recovers only when ownership, storage, configuration, source, listener, and firewall evidence are valid.

**Evidence layer**

One of: POSIX/static, host unit, real host NUT, simulated Merlin, exact router, or physical UPS. Success in one layer does not imply another.

## Reference hardware

- Router: ASUS RT-AX86U Pro, with exact revision and Merlin build recorded by the test report.
- UPS: CyberPower CP1500PFCLCD, with exact USB identity and NUT version recorded by the test report.

No wider router-family or UPS-model support claim is made by v0.1 alpha.
