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
