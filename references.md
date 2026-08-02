# Reference sources

These links are implementation references, not vendored dependencies. Recheck current versions and behavior during development.

## Asuswrt-Merlin

- Addons API  
  https://github.com/RMerl/asuswrt-merlin.ng/wiki/Addons-API
- User scripts  
  https://github.com/RMerl/asuswrt-merlin.ng/wiki/User-scripts
- Asuswrt-Merlin repository  
  https://github.com/RMerl/asuswrt-merlin.ng
- AMTM  
  https://github.com/decoderman/amtm

The current ecosystem survey for bundled, optional, and separately installed addon WebUIs is recorded in [research/merlin-webui-packaging.md](research/merlin-webui-packaging.md). It found both established companion UIs and numerous bundled counterexamples; the Addons API itself is packaging-neutral.

Key facts to verify during implementation:

- Addons API detection through `rc_support`.
- `/jffs/addons` conventions.
- shared `custom_settings.txt` limits.
- custom web-page mounting.
- `service-event` dispatch.
- lifecycle hook names and behavior on current firmware branches.

## Entware

- AArch64 package index  
  https://bin.entware.net/aarch64-k3.10/Packages.html
- Entware project  
  https://github.com/Entware/Entware

Confirm package names and versions at install time. Do not assume the AArch64 feed applies to every supported router.

## Network UPS Tools

- NUT documentation  
  https://networkupstools.org/docs/
- upsmon.conf
  https://networkupstools.org/docs/man/upsmon.conf.html
- upsd.conf
  https://networkupstools.org/docs/man/upsd.conf.html
- upsd and NUT_CONFPATH
  https://networkupstools.org/docs/man/upsd.html
- upsdrvctl and NUT_CONFPATH
  https://networkupstools.org/docs/man/upsdrvctl.html
- usbhid-ups
  https://networkupstools.org/docs/man/usbhid-ups.html
- `dummy-ups`  
  https://networkupstools.org/docs/man/dummy-ups.html
- Developer simulation notes  
  https://networkupstools.org/docs/developer-guide.chunked/dev-tools.html
- Advanced scheduling  
  https://networkupstools.org/docs/user-manual.chunked/Advanced_usage_scheduling_notes.html
- `upsmon`  
  https://networkupstools.org/docs/man/upsmon.html
- Configuration notes / shutdown workflow  
  https://networkupstools.org/docs/user-manual.chunked/Configuration_notes.html
- Devices Dumps Library  
  https://github.com/networkupstools/nut-ddl
- CyberPower CP1500PFCLCD compatibility report  
  https://networkupstools.org/ddl/Cyber_Power_Systems/CP1500PFCLCD.html

Important semantics:

- `dummy-ups` can use static `.dev` data or timed `.seq` replay.
- FSD is intentionally latched and normally means the installation is committed to completing a shutdown sequence.
- UPS telemetry and commands vary by model.
- Polling/dead-time values in NUT are inputs to, not replacements for, NUTMerlin's own freshness contract.
- Managed processes must be checked against the selected Entware build for consistent NUT_CONFPATH behavior.

## Messaging protocols

- OASIS MQTT 5.0
  https://docs.oasis-open.org/mqtt/mqtt/v5.0/mqtt-v5.0.html
- OASIS MQTT 3.1.1
  https://docs.oasis-open.org/mqtt/mqtt/v3.1.1/mqtt-v3.1.1.html

NUTMerlin's P1 MQTT profile is outbound only, QoS 1, and ephemeral. Use the specifications to verify Clean Start/Session Expiry, Clean Session, retained-message, acknowledgement, and reconnect behavior. Recheck broker/client interoperability during release qualification.

## SSH

- OpenBSD ssh_config manual
  https://man.openbsd.org/OpenBSD-7.4/ssh_config.5
- OpenBSD ssh-keygen manual
  https://man.openbsd.org/OpenBSD-7.3/ssh-keygen.1

Use current Entware OpenSSH behavior for release evidence. The accepted design requires independently verified host fingerprints, one binding keypair, target-enforced restriction, Ed25519 by default, and only qualified RSA-SHA2 compatibility.

## WinRM and constrained PowerShell

- Microsoft JEA role capabilities
  https://learn.microsoft.com/en-us/powershell/scripting/security/remoting/jea/role-capabilities
- Microsoft JEA security considerations
  https://learn.microsoft.com/en-us/powershell/scripting/security/remoting/jea/security-considerations
- PowerShell remoting troubleshooting, including workgroup/HTTPS/TrustedHosts
  https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_remote_troubleshooting

These sources define target-side constraints; they do not establish that a suitable Entware WSMan client exists. WinRM remains absent until its router client stack is reproducibly qualified.

## Redfish

- DMTF Redfish schemas and current data model
  https://redfish.dmtf.org/schemas/
- DMTF Redfish data model DSP0268
  https://redfish.dmtf.org/schemas/v1/DSP0268_2025.3.html

Use these references for ComputerSystem identity, Reset, GracefulShutdown, asynchronous task, and power-state vocabulary. P2 qualification still requires target-side least privilege that denies broader power/admin operations; schema support alone is insufficient.

## Windows clients

- WinNUT Client  
  https://github.com/nutdotnet/WinNUT-Client

Treat WinNUT as one client option. Keep NUTMerlin's server and tests client-neutral because Windows client projects and capabilities may change.

## Firmware emulation research

- Community discussion of Merlin virtualization  
  https://www.snbforums.com/threads/running-asuswrt-merlin-firmware-in-a-vm-docker-virtualisation.77964/
- ASUS/QEMU reverse-engineering notes  
  https://localh0st.run/post/asus-afl/
- FirmAE  
  https://github.com/pr0v3rbs/FirmAE
- Firmadyne  
  https://github.com/firmadyne/firmadyne
- QEMU  
  https://www.qemu.org/

Firmware rehosting is optional research and does not replace hardware integration tests.


## Confirmed hardware and development environment

- RT-AC3100 specifications  
  https://www.asus.com/us/networking-iot-servers/wifi-routers/asus-wifi-routers/rt-ac3100/techspec/
- ASUS AP-mode setup  
  https://www.asus.com/us/support/faq/1015009/
- Asuswrt-Merlin 386 changelog (`386.14_2`)  
  https://www.asuswrt-merlin.net/changelog-386
- Current Asuswrt-Merlin supported/no-longer-supported device list  
  https://github.com/RMerl/asuswrt-merlin.ng/blob/main/README-merlin.txt
- Entware ARMv7 package index  
  https://bin.entware.net/armv7sf-k3.2/Packages.html
- Entware AArch64 package index  
  https://bin.entware.net/aarch64-k3.10/Packages.html
- CyberPower CP1500PFCLCD NUT device report  
  https://networkupstools.org/ddl/Cyber_Power_Systems/CP1500PFCLCD.html
- WSL filesystem performance guidance  
  https://learn.microsoft.com/windows/wsl/filesystems
- WSL networking  
  https://learn.microsoft.com/windows/wsl/networking
- WSL USB attachment  
  https://learn.microsoft.com/windows/wsl/connect-usb
- F3 flash-capacity/integrity testing  
  https://github.com/AltraMayor/f3
- smartmontools USB support notes  
  https://www.smartmontools.org/wiki/USB
