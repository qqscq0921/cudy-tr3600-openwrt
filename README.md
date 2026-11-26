# Cudy TR3600 v1：可审计的 OpenWrt 25.12 构建

面向 **Cudy TR3600 v1**（`MT7987B + MT7990 Wi-Fi 7`）的纯净自编译 OpenWrt `25.12` 固件。该固件通过 GitHub Actions 直接基于官方 `openwrt/openwrt` 编译，仅包含少量可审计的补丁。

## 已包含的硬件修复

1. **开发板支持（`PR #24596` + `PR #25860`）**：
   - 512 MiB DDR4 内存、MT7987 内置 2.5G PHY 驱动、`fan_3p3v` GPIO6 稳压器，以及 PWM 通道 0 风扇控制。
   - 正确的红色（`GPIO46`）/ 白色（`GPIO48`）状态 LED 和 MAC 地址布局。
   - `SUPPORTED_DEVICES += R126`（兼容 Cudy 官方过渡固件）。
   - `MT7990E` 的 `wifi_devices.json` 条目及 `uboot-envtools`。
2. **2.5G WAN 端口 EEE 修复（`PR #25996`）**：
   - 为 `phy1`（RTL8221B）标记 `eee-broken-100tx` / `eee-broken-1000t`，消除 Linux 6.12 中 1G WAN 链路约 41% 的丢包。
3. **Wi-Fi 7（`mt76` / `mt7996`）稳定性补丁**：
   - `901-mt7996-sta-rec-before-vow.patch`：修复执行 `wifi down; wifi up` 后客户端无法重新关联、必须重启的问题。
   - `902-mt7996-guard-pcie-recovery.patch` + `pci=noaer`：防止在 L1 SER 恢复前 PCIe 链路断开时发生内核崩溃。
4. **散热和网络默认设置**：
   - 静音待机风扇曲线（`68 / 78 / 88 °C`，PWM `50% / 78% / 100%`，`5 °C` 回差）。
   - 默认 LAN IP 为 `192.168.10.1`，LuCI 使用中文界面，启用 `fq + BBR`；默认关闭硬件/软件流量分载，使 `nftables` 和透明代理能够检查 100% 的数据包。
5. **预装代理图形界面**：
   - **Nikki**（`mihomo-meta` + `luci-app-nikki` + 中文界面 + Metacubexd/Yacd 面板）。
6. **预装 Tailscale**：
   - 包含 `tailscale` 服务及 `luci-app-tailscale-community` LuCI 管理页面。
7. **USB 有线网卡支持**：
   - 包含 Realtek RTL8152/8153/8156、ASIX AX88172 与 AX88179/178A、AQC111、Microchip LAN78xx、SMSC LAN75xx/95xx，以及 CDC Ethernet/NCM 和 RNDIS 驱动。

## 刷写步骤

1. 从 Cudy 下载中心下载官方过渡固件（`Develop_files_for_TR3600.zip`），并在原厂管理界面（`192.168.10.1`）中刷入。
2. 重启后，访问 `http://192.168.1.1`，依次打开“系统”→“备份 / 刷写固件”，从 Releases 上传 `*-cudy_tr3600-v1-squashfs-sysupgrade.bin`（**取消勾选“保留配置”**）。
3. 再次重启后，访问 `http://192.168.10.1`（用户名为 `root`，初始密码为空；请立即设置密码）。
