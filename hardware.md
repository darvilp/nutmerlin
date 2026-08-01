# NUTMerlin hardware and bench setup

## 1. Confirmed development environment

| Component | Confirmed role |
|---|---|
| CyberPower `CP1500PFCLCD` | Real UPS hardware reference; USB HID through NUT `usbhid-ups` |
| ASUS RT-AX86U Pro | Production router and final manually gated hardware target |
| ASUS RT-AC3100 | Optional legacy Merlin/ARMv7 integration target; currently stock Asuswrt |
| Windows desktop | Native Windows NUT-client and graceful-shutdown target |
| WSL2 + Codex IDE beta | Primary development, test, packaging, and Git workflow environment |

The CP1500PFCLCD is reported by the NUT Devices Dumps Library as working with `usbhid-ups`. Treat every writable variable and instant command as capability data, not as permission to expose it in the normal UI.

## 2. Hardware policy

The RT-AC3100 is useful but **not part of the critical development path**.

Normal development and pull requests shall require only:

- WSL2 or another Linux host
- repository test shims
- a container or local NUT installation
- NUT `dummy-ups`

The RT-AC3100 is an optional manually invoked target for:

- Asuswrt-Merlin 386 compatibility
- ARMv7 Entware compatibility
- Addons API and web-page integration
- `/jffs` hook behavior
- late `/opt` mounting
- USB hotplug and mount behavior
- install, upgrade, rollback, reboot, and uninstall tests

The RT-AX86U Pro is reserved for final read-only and controlled real-UPS tests. Automated development commands must not target it without an explicit production-router override.

## 3. RT-AC3100 qualification

The RT-AC3100 is no longer supported by current Asuswrt-Merlin development. Its final Merlin release line is 386, with `386.14_2` as the last listed release. This makes it valuable as a legacy target but inappropriate as an internet-facing router.

Before first use:

1. Record its current stock Asuswrt version and hardware revision.
2. Factory-reset it.
3. Flash the final correct RT-AC3100 Asuswrt-Merlin image.
4. Factory-reset after the firmware transition if required by the release notes or if configuration behavior is abnormal.
5. Do not restore an old settings backup.
6. Enable JFFS custom scripts/configs and LAN-only SSH.
7. Keep remote administration, AiCloud, DDNS, FTP, SMB, media services, Download Master, WPS, and UPnP disabled unless a test explicitly needs one.
8. Keep a copy of the stock firmware, Merlin image, checksum, rescue utility, and recovery instructions on the Windows PC.

The device has 128 MB flash, 512 MB RAM, one USB 2.0 port, and one USB 3.0 port. Use USB 3.0 for Entware storage and USB 2.0 for the UPS.

## 4. Recommended AP-mode topology

The least disruptive topology is:

```text
Windows desktop --Ethernet--> primary RT-AX86U Pro
                              |
                              +--LAN Ethernet--> RT-AC3100 in AP mode
                                                   |
                                                   +--USB 3.0 storage for Entware
                                                   +--USB 2.0 UPS cable when required
```

Recommended settings:

- operating mode: Access Point
- uplink: primary-router LAN or switch to an RT-AC3100 LAN port
- WAN port: unused
- management address: static or DHCP reservation on the primary LAN
- example hostname: `nutmerlin-ac3100`
- Wi-Fi radios: disabled unless a wireless-only test needs them
- SSH and web administration: trusted LAN only
- DHCP/NAT/firewall routing role: none

AP mode permits WSL2, Windows, WinNUT, and the test router to communicate over the existing Ethernet connection. No second Windows NIC, static route, double NAT, or direct PC-to-router cable is needed.

### Internet egress

"No WAN connection" and "no internet egress" are separate controls in AP mode. The WAN port can remain unused while the device still reaches the internet through its LAN gateway.

Recommended lifecycle:

1. Temporarily allow egress for firmware verification and initial Entware package installation.
2. After dependencies are installed, block the RT-AC3100 from internet access on the primary router.
3. Re-enable egress only for deliberate package/update testing.

NUTMerlin must not depend on internet access at runtime.

## 5. Alternative isolated-router topology

Use router mode only for tests that specifically require WAN/LAN firewall separation:

```text
Windows Wi-Fi or USB Ethernet
          |
          +--> RT-AC3100 LAN
                    |
                    +--> isolated test subnet

RT-AC3100 WAN: disconnected
```

This is not required for ordinary development. It is a manually prepared security/release test topology.

## 6. Persistent storage requirement

Asuswrt-Merlin itself is installed in internal flash. A USB drive is required only when running Entware and NUTMerlin on a real router.

Preferred media, in order:

1. Small SATA SSD in a reputable USB enclosure
2. Reputable external USB SSD
3. High-quality, known-brand flash drive for intermittent test use
4. High-endurance microSD card in a reliable USB reader for intermittent test use
5. Unknown, promotional, or very old USB flash drive only as disposable temporary media

A 16–64 GB device is ample. Capacity is not a meaningful quality indicator. Use ext4 and do not create swap by default.

## 7. Qualifying a USB flash drive

There is no reliable visual or benchmark-only way to prove that a consumer USB stick has adequate write endurance. Many sticks expose no useful wear counter or SMART data. Qualification can reject bad media but cannot certify future longevity.

### 7.1 Identify the device

Record:

```sh
lsusb
lsblk -o NAME,MODEL,SERIAL,SIZE,TRAN,FSTYPE,MOUNTPOINTS
udevadm info --query=all --name=/dev/sdX
```

Prefer a device with:

- a real manufacturer and model
- a stable serial number
- a published warranty
- consistent USB identity across reconnects
- no prior unexplained disconnects or corruption

### 7.2 Check whether health data exists

For a true USB flash drive:

```sh
sudo smartctl -a /dev/sdX
```

Useful SMART data is uncommon. For a SATA SSD in a USB enclosure, try:

```sh
sudo smartctl -a /dev/sdX
sudo smartctl -d sat -a /dev/sdX
```

A USB-to-SATA bridge must pass through native commands for SMART to work. Prefer an enclosure that exposes the SSD's SMART attributes, including media wear, reallocated sectors, unsafe shutdowns, and error logs.

### 7.3 Verify real capacity and data integrity

On an empty mounted filesystem:

```sh
f3write /path/to/mount
f3read /path/to/mount
```

This writes the free space and verifies that the data can be read back. It detects false capacity and immediate corruption. It does not measure remaining endurance.

The faster direct-device `f3probe --destructive` test destroys the existing partition/data and should be used only when the correct block device has been positively identified.

### 7.4 Inspect errors during qualification

Before and after the test:

```sh
dmesg --follow
sudo fsck.ext4 -f /dev/sdX1
```

Reject the device after any unexplained:

- USB resets or disconnects
- I/O errors
- read-only remounts
- checksum mismatches
- ext4 journal or metadata errors
- extreme write-speed collapse followed by errors
- unstable device identity

### 7.5 Practical decision rule

For the optional RT-AC3100 test rig, a known-brand stick that passes a complete F3 fill/read cycle and filesystem check can be used temporarily because the router will be powered only for testing. Keep the setup reproducible and assume the drive is disposable.

For an always-on production router, use an SSD rather than trying to infer endurance from an ordinary USB stick.

## 8. NUTMerlin write-minimization requirements

The addon shall be designed so that storage choice is not needlessly punished:

- no write on every NUT poll
- no swap requirement
- status snapshots in `/tmp`
- logs sent to syslog or bounded files under `/opt`
- persistent writes only for configuration, migrations, event transitions, and bounded audit records
- `noatime` recommended for the Entware filesystem
- explicit maximum log sizes and rotation
- no traffic database, history graph, or high-frequency telemetry retention in the MVP
- detect missing, read-only, or unhealthy `/opt` and fail safely
- provide configuration export/backup and reproducible reinstall
- cleanly stop before planned USB removal

## 9. Windows and WSL connectivity

Windows remains connected to the primary router by Ethernet. It reaches the optional RT-AC3100 through the normal LAN.

Runtime shutdown path:

```text
UPS -> NUT server on ASUS router -> native Windows NUT client -> Windows shutdown
```

WSL2 is not the production shutdown agent. It is used to develop, test, deploy, query port 3493, and inspect the router over SSH.

Typical checks from WSL2:

```sh
ssh admin@nutmerlin-ac3100
nc -vz nutmerlin-ac3100 3493
upsc ups@nutmerlin-ac3100
```

Use the native Windows client for service-start and actual shutdown tests.
