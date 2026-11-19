# Cudy TR3600 v1 — Auditable OpenWrt 25.12 Build

Clean, self-built OpenWrt `25.12` firmware for **Cudy TR3600 v1** (`MT7987B + MT7990 Wi-Fi 7`), compiled directly from official `openwrt/openwrt` via GitHub Actions with minimal auditable patches.

## Included Hardware Fixes

1. **Board Support (`PR #24596` + `PR #25860`)**:
   - 512 MiB DDR4 memory, `fan_3p3v` GPIO6 regulator, PWM channel 0 fan control
   - Correct Red (`GPIO46`) / White (`GPIO48`) status LEDs and MAC address layout
   - `SUPPORTED_DEVICES += R126` (compatible with Cudy's official intermediate firmware)
   - `MT7990E` `wifi_devices.json` entry & `uboot-envtools`
2. **2.5G WAN Port EEE Fix (`PR #25996`)**:
   - Marks `eee-broken-100tx` / `eee-broken-1000t` on `phy1` (RTL8221B) to eliminate ~41% packet loss on 1G WAN links in Linux 6.12.
3. **Wi-Fi 7 (`mt76` / `mt7996`) Stability Patches**:
   - `901-mt7996-sta-rec-before-vow.patch`: fixes `wifi down; wifi up` breaking client association until reboot.
   - `902-mt7996-guard-pcie-recovery.patch` + `pci=noaer`: prevents kernel panic if PCIe link drops before L1 SER recovery.
4. **Thermal & Network Defaults**:
   - Silent idle fan curve (`68 / 78 / 88 °C`, PWM `50% / 78% / 100%`, `5 °C` hysteresis).
   - Default LAN IP `192.168.2.1`, Chinese LuCI UI, `fq + BBR`, hardware/software flow offloading disabled by default so `nftables` + transparent proxy inspect 100% of packets.
5. **Preinstalled Proxy GUI**:
   - **Nikki** (`mihomo-meta` + `luci-app-nikki` + Chinese UI + Metacubexd/Yacd dashboard).

## Flashing Steps

1. Download Cudy's official intermediate firmware (`Develop_files_for_TR3600.zip`) from Cudy Download Center and flash it in stock UI (`192.168.10.1`).
2. After reboot, open `http://192.168.1.1` → System → Backup / Flash Firmware → upload `*-cudy_tr3600-v1-squashfs-sysupgrade.bin` from Releases (**uncheck "Keep settings"**).
3. After reboot, open `http://192.168.2.1` (`root`, empty password — set password immediately).
