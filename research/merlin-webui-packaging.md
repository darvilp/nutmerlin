# Merlin and amtm WebUI packaging practice

Date: 2026-08-02

## Question and classification

Does the Asuswrt-Merlin/amtm ecosystem establish a normal packaging rule in which an addon's CLI/core is installed first and its WebUI is a separate optional package or install component?

This note distinguishes three arrangements that can otherwise be confused:

- **separate component** — the WebUI has its own installer/catalog entry and can be absent while the core remains installed;
- **bundled automatic WebUI** — the core install path fetches and installs the WebUI without offering a separate choice;
- **optional enablement** — the core install includes the WebUI files, but mounting or displaying the page can later be disabled.

In this ecosystem, “install” usually means a project shell installer invoked directly or through amtm, not an Entware `opkg` package. The survey therefore treats a separately invoked installer as a component boundary even when both projects distribute plain files rather than package-manager artifacts.

## Finding

There is **no uniform community packaging rule**. Separate WebUI companions are an established amtm pattern, but current amtm also contains numerous strong counterexamples whose sole install action automatically includes the WebUI and whose normal startup mounts it. The Merlin Addons API permits either product shape and does not prescribe component packaging.

### Established separate-component examples

- The current amtm catalog presents Diversion and scribe as core entries and uiDivStats and uiScribe as different installable entries ([catalog definitions](https://github.com/decoderman/amtm/blob/4b015ab2d8a5364abb981a9cc6925a70559c91bd/amtm_modules/amtm.mod#L225-L250)).
- **Diversion + uiDivStats:** amtm exposes uiDivStats through its own installer. That installer refuses installation unless Diversion is already present, then downloads and runs the uiDivStats project independently. This is a genuine optional WebUI companion, not merely a show/hide setting. See the current amtm [`uiDivStats.mod` lines 26–44](https://github.com/decoderman/amtm/blob/4b015ab2d8a5364abb981a9cc6925a70559c91bd/amtm_modules/uiDivStats.mod#L26-L44).
- **scribe + uiScribe:** amtm likewise exposes uiScribe through its own installer, verifies that scribe is present, and installs the UI project separately. See [`uiScribe.mod` lines 26–43](https://github.com/decoderman/amtm/blob/4b015ab2d8a5364abb981a9cc6925a70559c91bd/amtm_modules/uiScribe.mod#L26-L43).

These two projects support the proposed NUTMerlin split as recognizable community precedent.

### Strong counterexamples: one install automatically includes the WebUI

The following current amtm-managed projects expose one addon install action and have that installer fetch the ASP page as part of ordinary installation, without a WebUI choice:

| Addon | Primary-source evidence |
| --- | --- |
| YazFi | amtm invokes one YazFi installer ([amtm module](https://github.com/decoderman/amtm/blob/4b015ab2d8a5364abb981a9cc6925a70559c91bd/amtm_modules/YazFi.mod#L26-L33)); that installer automatically fetches `YazFi_www.asp` when the firmware supports addons ([installer](https://github.com/AMTM-OSR/YazFi/blob/5cfeee776e0f8b87a8a916004c7873e5a939d78d/YazFi.sh#L3260-L3291)) and startup mounts it ([startup](https://github.com/AMTM-OSR/YazFi/blob/5cfeee776e0f8b87a8a916004c7873e5a939d78d/YazFi.sh#L3325-L3345)). |
| scMerlin | Its only install flow downloads `scmerlin_www.asp`, the sitemap, shared assets, and the core helpers together ([installer](https://github.com/AMTM-OSR/scMerlin/blob/55176475b14afbc4e8d8afcf5336c59a8191eebb/scmerlin.sh#L3833-L3871)); normal startup mounts the WebUI ([startup](https://github.com/AMTM-OSR/scMerlin/blob/55176475b14afbc4e8d8afcf5336c59a8191eebb/scmerlin.sh#L3898-L3918)). |
| spdMerlin | Its ordinary installer automatically downloads `spdstats_www.asp` and the shared UI assets ([installer](https://github.com/AMTM-OSR/spdMerlin/blob/15d3fa1865cabe75e3bebdd55b3342c4ddef907b/spdmerlin.sh#L4851-L4910)). |
| connmon | Its ordinary installer automatically downloads `connmonstats_www.asp` and shared UI assets ([installer](https://github.com/AMTM-OSR/connmon/blob/efda7ececcbfd65c6780bc64fcd1741922e98ef4/connmon.sh#L5408-L5435)). |
| ntpMerlin | Its ordinary installer automatically downloads `ntpdstats_www.asp` and shared UI assets ([installer](https://github.com/AMTM-OSR/ntpMerlin/blob/f46f2412836553c575537372bc1652928ccf53f7/ntpmerlin.sh#L2984-L3011)). |
| FlexQoS | The single `install()` function explicitly installs the script and WebUI together and calls `install_webui` unconditionally ([installer](https://github.com/AMTM-OSR/FlexQoS/blob/ba6a0d6e482620be4f05cc077c0c9e17aaf2db70/flexqos.sh#L2247-L2275)). |
| YazDHCP | Its one install workflow warns that the existing firmware page will be replaced, waits only for backup/screenshot acknowledgement, and then fetches the modified ASP page; it does not offer a CLI-only choice ([installer](https://github.com/AMTM-OSR/YazDHCP/blob/43b9ebd772560ca47c3574535151ba28d3c44da2/YazDHCP.sh#L4628-L4658)). |
| vnStat-on-Merlin | Its ordinary install flow automatically fetches `vnstat-ui.asp` with the core configuration and service files ([installer](https://github.com/AMTM-OSR/vnstat-on-merlin/blob/7616285eb9dacbbaf0a48713bbee3c5b2944bc9d/dn-vnstat.sh#L3181-L3198)); startup mounts it ([startup](https://github.com/AMTM-OSR/vnstat-on-merlin/blob/7616285eb9dacbbaf0a48713bbee3c5b2944bc9d/dn-vnstat.sh#L3275-L3294)). |

These are counterexamples to the stronger claim that addons with both CLI and WebUI normally publish or require a separately selectable UI component.

### Hybrid example: optional display, bundled files

Skynet supports `settings webui enable|disable`, which mounts or unmounts its page ([command implementation](https://github.com/Adamm00/IPSet_ASUS/blob/10dd62dffc2832a6d264d2682d6b474c0bcfe4b5/firewall.sh#L5741-L5764)). Its core install nevertheless downloads the WebUI assets and ASP page and defaults `displaywebui` to enabled ([install defaults](https://github.com/Adamm00/IPSet_ASUS/blob/10dd62dffc2832a6d264d2682d6b474c0bcfe4b5/firewall.sh#L6501-L6523)). Skynet is therefore evidence for optional **enablement**, not for a separately installed UI package.

### Firmware API is neutral on release packaging

The official [Asuswrt-Merlin Addons API](https://github.com/RMerl/asuswrt-merlin.ng/wiki/Addons-API#custom-pages) says to keep the custom page in the addon's `/jffs/addons/<addon>/` directory “along with the install script” and demonstrates mounting it at boot. It defines page placement and integration mechanics, but neither requires nor forbids a separately selectable WebUI component.

## Implication for NUTMerlin

Unbundling NUTMerlin's WebUI is consistent with a recognized amtm pattern, especially the Diversion/uiDivStats and scribe/uiScribe companion model. It should be recorded as a deliberate NUTMerlin product and lifecycle decision, not as compliance with a universal Merlin rule.

A separate **installable component within the same authenticated release and version** obtains the useful boundary without creating an independently versioned release product. ADR 0097 subsequently settled install defaults, exact version matching, update and rollback atomicity, UI-only uninstall behavior, ownership records, and failure isolation; this survey supplies evidence rather than changing that decision.
