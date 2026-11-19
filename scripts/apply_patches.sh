#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OWRT_DIR="${1:?usage: apply_patches.sh <openwrt-dir>}"

cd "$OWRT_DIR"

echo "[1/7] Installing unified Cudy TR3600 v1 DTS..."
cp -v "$REPO_ROOT/dts/mt7987b-cudy-tr3600-v1.dts" target/linux/mediatek/dts/mt7987b-cudy-tr3600-v1.dts

echo "[2/7] Registering cudy_tr3600-v1 in filogic.mk..."
python3 - <<'PY'
from pathlib import Path

p = Path("target/linux/mediatek/image/filogic.mk")
text = p.read_text()
if "define Device/cudy_tr3600-v1" not in text:
    anchor = "TARGET_DEVICES += cudy_tr3000-v1-ubootmod\n"
    assert anchor in text, "anchor not found in filogic.mk"
    block = """
define Device/cudy_tr3600-v1
  DEVICE_VENDOR := Cudy
  DEVICE_MODEL := TR3600
  DEVICE_VARIANT := v1
  DEVICE_DTS := mt7987b-cudy-tr3600-v1
  DEVICE_DTS_DIR := ../dts
  DEVICE_PACKAGES := mt7987-2p5g-phy-firmware kmod-mt7990-firmware \\
	kmod-hwmon-pwmfan kmod-usb3
  KERNEL = kernel-bin | lzma | \\
	fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb
  KERNEL_INITRAMFS = kernel-bin | lzma | \\
	fit lzma $$(KDIR)/image-$$(firstword $$(DEVICE_DTS)).dtb with-initrd
  KERNEL_IN_UBI := 1
  KERNEL_LOADADDR := 0x40000000
  UBINIZE_OPTS := -E 5
  BLOCKSIZE := 128k
  PAGESIZE := 2048
  IMAGE_SIZE := 237824k
  SUPPORTED_DEVICES += R126
  IMAGE/sysupgrade.bin := sysupgrade-tar | append-metadata
endef
TARGET_DEVICES += cudy_tr3600-v1
"""
    p.write_text(text.replace(anchor, anchor + block, 1))
assert "define Device/cudy_tr3600-v1" in p.read_text()
print("  -> filogic.mk patched OK")
PY

echo "[3/7] Registering cudy,tr3600-v1 in 02_network, 05_set_preinit_iface, uboot-envtools..."
python3 - <<'PY'
from pathlib import Path

for rel in [
    "target/linux/mediatek/filogic/base-files/etc/board.d/02_network",
    "target/linux/mediatek/base-files/lib/preinit/05_set_preinit_iface",
]:
    p = Path(rel)
    text = p.read_text()
    if "cudy,tr3600-v1" not in text:
        anchor = "\tcudy,tr3000-v1-ubootmod|\\\n"
        assert anchor in text, f"anchor not found in {rel}"
        p.write_text(text.replace(anchor, anchor + "\tcudy,tr3600-v1|\\\n", 1))
    assert "cudy,tr3600-v1" in p.read_text()
    print(f"  -> {rel} patched OK")

ub = Path("package/boot/uboot-tools/uboot-envtools/files/mediatek_filogic")
text = ub.read_text()
if "cudy,tr3600-v1" not in text:
    anchor = "glinet,gl-mt3000)\n"
    assert anchor in text, "anchor not found in mediatek_filogic"
    block = """cudy,tr3600-v1)
\t. /lib/upgrade/nand.sh
\tenvubi=$(nand_find_ubi ubi)
\tenvdev=/dev/$(nand_find_volume "$envubi" u-boot-env)
\tubootenv_add_uci_config "$envdev" "0x0" "0x80000" "0x80000" "1"
\t;;
"""
    ub.write_text(text.replace(anchor, block + anchor, 1))
assert "cudy,tr3600-v1" in ub.read_text()
print("  -> mediatek_filogic patched OK")
PY

echo "[4/7] Adding MT7990E entry to wifi_devices.json..."
python3 - <<'PY'
from pathlib import Path

p = Path("package/network/config/wifi-scripts/files-ucode/usr/share/wifi_devices.json")
text = p.read_text()
if "0x7993" not in text:
    anchor = '[ "0x14c3", "0x7992", "0x14C3", "0x7992", 0, 0, "MediaTek", "MT7992E" ],'
    alt = '[ "0x14c3", "0x7992", "0x14c3", "0x7992", 0, 0, "MediaTek", "MT7992E" ],'
    hit = anchor if anchor in text else alt
    assert hit in text, "MT7992E anchor not found in wifi_devices.json"
    addition = '\n\t\t[ "0x14c3", "0x7993", "0x14c3", "0x7993", 0, 0, "MediaTek", "MT7990E" ],'
    p.write_text(text.replace(hit, hit + addition, 1))
assert "0x7993" in p.read_text()
print("  -> wifi_devices.json patched OK")
PY

echo "[5/7] Installing audited mt76 stability patches..."
mkdir -p package/kernel/mt76/patches
cp -v "$REPO_ROOT/patches/mt76/"*.patch package/kernel/mt76/patches/

echo "[6/7] Setting default LAN IP to 192.168.2.1..."
sed -i 's/192\.168\.1\.1/192.168.2.1/g' package/base-files/files/bin/config_generate
grep -q '192.168.2.1' package/base-files/files/bin/config_generate

echo "[7/7] Copying rootfs overlay files/..."
mkdir -p files
cp -a "$REPO_ROOT/files/." files/
chmod +x files/etc/uci-defaults/*

echo "All patches applied and verified cleanly."
