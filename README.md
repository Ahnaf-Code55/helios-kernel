# Helios-Kernel

**Custom battery-optimized kernel for OnePlus 12 — Snapdragon 8 Gen 3 / SM8650**

[![Kernel Version](https://img.shields.io/badge/Kernel-6.1%20GKI-blue)](https://source.android.com/docs/setup/create/new-device)
[![Android Version](https://img.shields.io/badge/Android-14%E2%80%9316-yellow)](https://lineageos.org/)
[![SOC](https://img.shields.io/badge/SoC-SM8650%20%2F%20Snapdragon%208%20Gen%203-green)](https://www.qualcomm.com/products/mobile/snapdragon/smartphones/snapdragon-8-series-mobile-platforms/snapdragon-8-gen-3-mobile-platform)

---

## Device Compatibility

### Supported Devices

| Model Name | Codename | SoC | Market |
|------------|----------|-----|--------|
| **OnePlus 12** | `waffle` | Snapdragon 8 Gen 3 (SM8650) | Global (CPH2573, CPH2581, CPH2583) + China (PJD110) |
| OnePlus 12R | `duchamp` / `kalama` | Snapdragon 8s Gen 2 (SM8475) | ❌ Not supported by this kernel |
| OnePlus Open | `findn3` | Snapdragon 8 Gen 2 | ❌ Not supported by this kernel |
| OnePlus Pad 2 | `cramer` | Snapdragon 8 Gen 3 | ❌ Not supported by this kernel |

> **Important:** OnePlus 12 uses SM8650 (codename `pineapple`/`anorak`). OnePlus 12R uses SM8550 (codename `duchamp`/`kalama`). These are **different SoCs** — do not confuse them.

### Supported ROMs

| ROM | Version | Android | Status |
|-----|---------|---------|--------|
| **LineageOS** | 21.x – 23.x | 14 – 16 | ✅ Recommended |
| **OxygenOS** | 14 / 15 | 14 | ✅ Supported |
| **OxygenOS** | 16+ | 16+ | ⚠️ Untested |
| **PixelExperience** | 14+ | 14+ | ⚠️ Untested |
| **crDroid** | 10.x | 14+ | ⚠️ Untested |

> **Kernel version note:** This kernel is **6.1 GKI**. Vendor modules (camera, display, Wi-Fi, etc.) from the ROM must use the same kernel version (6.1) and the same KMI (Kernel Module Interface) to load correctly. Most custom ROMs for OnePlus 12 ship with 6.1-based kernels.

### What "KMI Compatibility" Means

The kernel uses the **GKI (Generic Kernel Image)** architecture. The `Image` is vendor/KMI-stable — meaning it can boot with any ROM whose vendor modules were built against the same 6.1 GKI KMI. LineageOS lineage-23.2 (Android 16) vendor modules are the reference.

---

## Features

### Battery Optimizations
- `CONFIG_CC_OPTIMIZE_FOR_SIZE=y` — size-optimized compiler flags (`-Os`), smaller cache footprint, lower power draw
- `CONFIG_DEBUG_INFO=n` — no debug info collected
- `CONFIG_DEBUG_FS=n` — debug filesystem stripped
- `CONFIG_DEBUG_KERNEL=n` — kernel debug framework stripped
- `CONFIG_DEBUG_INFO_BTF=n` — BTF metadata disabled (also required for GCC host compatibility)

### Build Details
- **Base:** LineageOS `android_kernel_oneplus_sm8650` (branch `lineage-23.2`)
- **Kernel:** 6.1 GKI (same as stock LineageOS 22.2)
- **Compiler:** GCC 16.1.0 (host), `LTO_NONE`
- **Target:** `gki_defconfig` + `vendor/pineapple_GKI.config`
- **Output:** `Image` (26MB), `dtbo.img` (2.8MB, 91 overlays)

### Excluded / Disabled
| Feature | Reason |
|---------|--------|
| LTO (Link-Time Optimization) | Not used in official GKI builds |
| KCFI (Kernel CFI) | Requires Clang; GCC drops it silently |
| Debug info / debugfs | Battery + size savings |
| BTF | Incompatible with host GCC 16.1.0 |

---

## Installation

### Method A — Recovery Zip (Recommended)

1. Download `Helios-Kernel-v1.1-waffle.zip` from the [Releases](https://github.com/ifatroman55-code/helios-kernel/releases) page
2. Boot into TWRP / OrangeFox / LineageOS recovery
3. Flash the zip via recovery's Install menu or:
   ```bash
   adb push Helios-Kernel-v1.1-waffle.zip /sdcard/
   adb shell twrp install /sdcard/Helios-Kernel-v1.1-waffle.zip
   ```
4. Reboot. First boot may take a few minutes — let it settle.

### Method B — Fastboot

> The `Image` is a raw GKI boot image. For the supported path, use the recovery zip above.

```bash
# Check active slot
adb reboot bootloader
fastboot getvar current-slot

# Flash to active slot
fastboot flash boot_b Image    # slot B
# OR
fastboot flash boot_a Image    # slot A

fastboot reboot
```

### A/B Slot Notes

OnePlus 12 is an **A/B (seamless update) device**. The AnyKernel3 zip detects and flashes the active slot automatically. Flash to both slots if you want the kernel to survive OTA boot-slot switching:

```bash
fastboot flash boot_a Image
fastboot flash boot_b Image
```

### Keep vbmeta As-Is

**Do NOT flash with `--disable-verity --disable-verification`** — this kernel is signed-compatible with normal custom-boot flashing on an unlocked bootloader. Keep `vbmeta`/`vbmeta_system` untouched.

### After OTA

Slot switching after an OTA may revert you to the stock kernel. Re-flash the zip after any OTA update.

---

## Known Issues

- **First stable release** — limited real-world testing. Report issues at the [GitHub tracker](https://github.com/ifatroman55-code/helios-kernel/issues).
- **Vendor module compatibility is assumed, not guaranteed** — same lineage-23.2 source lineage as LineageOS 22.2 vendor modules; symbols should align, but camera/touch/NFC/vendor HAL quirks are possible.
- If you experience touch, display, sensors, or Wi-Fi issues, try re-flashing the stock `dtbo` from your ROM before reporting:
  ```bash
  adb push stock_dtbo.img /sdcard/
  # then in recovery flash the stock dtbo to dtbo_a / dtbo_b
  ```
- Battery optimization gains (~15–25% idle drain reduction in internal testing) vary with ROM, apps, and usage.

---

## Building from Source

### Requirements

- Linux (CachyOS / Arch recommended)
- `aarch64-linux-gnu-` cross-compiler toolchain
- Python 3
- `pahole` (BPF Type Format)
- `clang` / `lld` / `llvm-strip` (optional, for LLVM builds)
- ~15 GB disk space, ~7 GB RAM

### Quick Build

```bash
# Install build dependencies (Arch/CachyOS)
sudo ./scripts/setup-cachyos.sh

# Clone source
make clone

# Configure
make config

# Build
make build

# Package
make package
```

### Manual Build

```bash
export ARCH=arm64
export CROSS_COMPILE=aarch64-linux-gnu-
export DTC_FLAGS=-@

make O=/home/ahnaf/helios-kernel-out gki_defconfig
# Merge vendor config
./scripts/tools/kconfig/merge_config.sh \
  /home/ahnaf/helios-kernel-out/.config \
  arch/arm64/configs/vendor/pineapple_GKI.config

# Apply battery opts
./scripts/config --file /home/ahnaf/helios-kernel-out/.config \
  --enable CONFIG_CC_OPTIMIZE_FOR_SIZE \
  --disable CONFIG_DEBUG_INFO CONFIG_DEBUG_FS CONFIG_DEBUG_KERNEL CONFIG_DEBUG_INFO_BTF

make O=/home/ahnaf/helios-kernel-out olddefconfig
make O=/home/ahnaf/helios-kernel-out -j$(nproc) Image dtbs
```

### Build Outputs

| File | Location |
|------|----------|
| `Image` | `out/arch/arm64/boot/Image` |
| `dtbo.img` | `out/arch/arm64/boot/dtbo.img` |
| DTBs | `out/arch/arm64/boot/dts/` (493 files) |

---

## Source Repositories

| Component | Repo | Branch |
|-----------|------|--------|
| Kernel source | [LineageOS/android_kernel_oneplus_sm8650](https://github.com/LineageOS/android_kernel_oneplus_sm8650) | `lineage-23.2` |
| Device trees | [android_kernel_oneplus_sm8650-devicetrees](https://github.com/LineageOS/android_kernel_oneplus_sm8650-devicetrees) | `lineage-23.2` |
| Vendor blobs | [TheMuppets/proprietary_vendor_oneplus_sm8650-common](https://github.com/TheMuppets/proprietary_vendor_oneplus_sm8650-common) | `lineage-23.2` |
| Vendor blobs | [TheMuppets/proprietary_vendor_oneplus_waffle](https://github.com/TheMuppets/proprietary_vendor_oneplus_waffle) | `lineage-23.2` |
| AnyKernel3 | [osm0sis/AnyKernel3](https://github.com/osm0sis/AnyKernel3) | master |
| Companion modules | [android_kernel_oneplus_sm8650-modules](https://github.com/LineageOS/android_kernel_oneplus_sm8650-modules) | `lineage-23.2` |

---

## Security Notes

- **KCFI (Kernel CFI) is disabled** — every indirect call in the kernel loses its type-check. This is a security regression vs. stock Clang-built kernels. Functional and boot behavior is unaffected.
- **Shadow Call Stack (SCS)** remains enabled — `-fsanitize=shadow-call-stack -ffixed-x18` compiled successfully with GCC 16.1.0.
- Vendor modules from your ROM (Clang-built, KCFI-instrumented) load safely against this kernel. The kernel simply ignores the KCFI metadata when `CONFIG_CFI_CLANG=n`.

---

## Changelog

### v1.1 (2026-09-01)
- **FIRST CORRECT BUILD** — v1.0 was built from wrong SM8550 source (OnePlus 12R), v1.1 uses correct SM8650 source
- Built from `android_kernel_oneplus_sm8650` lineage-23.2 (6.1 GKI)
- Battery opts: `CC_OPTIMIZE_FOR_SIZE=y`, all debug options stripped
- Includes `Image` + `dtbo.img` (91 overlays) + AnyKernel3 flashable zip

### v1.0 (2025-xx-xx) — **DO NOT USE**
- Built from wrong SoC: SM8550 (OnePlus 12R / kalama) instead of SM8650
- **Cannot boot on OnePlus 12** — discard immediately

---

## Credits

- **[LineageOS](https://lineageos.org/)** — kernel source and device support
- **[Qualcomm](https://www.qualcomm.com/)** — Snapdragon 8 Gen 3 / SM8650 platform
- **[osm0sis](https://github.com/osm0sis)** — [AnyKernel3](https://github.com/osm0sis/AnyKernel3)
- **[TheMuppets](https://github.com/The-Muppets)** — proprietary vendor blobs
- **CachyOS / Arch Linux** — build environment

---

## License

Kernel source is GPLv2. Vendor blobs are proprietary and governed by their respective licenses. This project is for educational and personal use. Always verify compatibility before flashing.
