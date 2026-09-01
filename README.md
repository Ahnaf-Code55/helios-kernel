# Helios-Kernel
**Developer: Ahnaf Hossain**

**A kernel built for the kind of phone use that actually matters — snappy response, longer screen-on time, and thermal headroom when you need it.**

Built on the LineageOS 6.1 GKI tree for the OnePlus 12 (Snapdragon 8 Gen 3 / SM8650), Helios drops the bloat that drains your battery in the background and leaves the performance-critical paths clean. No gimmicks, no excessive tuning — just the kernel doing what it should.

---

## Device Compatibility

### Supported Devices

| Model Name | Codename | SoC | Market |
|------------|----------|-----|--------|
| **OnePlus 12** | `waffle` | Snapdragon 8 Gen 3 (SM8650) | Global (CPH2573, CPH2581, CPH2583) + China (PJD110) |
| OnePlus 12R | `duchamp` / `kalama` | Snapdragon 8s Gen 2 (SM8475) | ❌ Different SoC — not supported |
| OnePlus Open | `findn3` | Snapdragon 8 Gen 2 | ❌ Different device |
| OnePlus Pad 2 | `cramer` | Snapdragon 8 Gen 3 | ❌ Different device |

> **A quick note:** OnePlus 12 runs SM8650. OnePlus 12R runs SM8550. These are not the same chip — flashing the wrong kernel won't boot.

### Supported ROMs

| ROM | Version | Android | Status |
|-----|---------|---------|--------|
| **LineageOS** | 21.x – 23.x | 14 – 16 | ✅ Recommended |
| **OxygenOS** | 14 / 15 | 14 | ✅ Supported |
| OxygenOS | 16+ | 16+ | ⚠️ Untested |
| PixelExperience | 14+ | 14+ | ⚠️ Untested |
| crDroid | 10.x | 14+ | ⚠️ Untested |

> This kernel is **6.1 GKI**. Vendor modules from your ROM (camera, display, Wi-Fi, etc.) need to be built against the same 6.1 kernel KMI to load. Most custom ROMs for OnePlus 12 already use 6.1 — just confirm before flashing.

### What KMI Compatibility Means

The GKI (Generic Kernel Image) architecture keeps the kernel ABI stable across ROM updates. Helios is built against the same KMI as LineageOS 22.2, so it plays nicely with vendor modules from any ROM built on that foundation.

---

## What's Inside

### Performance & Efficiency
- `CONFIG_CC_OPTIMIZE_FOR_SIZE=y` — the compiler cuts the fat from code paths, not just binary size. Tighter caches mean the Snapdragon 8 Gen 3 wakes up less often and spends more time in low-power states when the screen is off. Under load, the reduced instruction cache pressure translates to snappier app launches and less thermal throttling during extended sessions.
- `CONFIG_DEBUG_INFO=n`, `CONFIG_DEBUG_FS=n`, `CONFIG_DEBUG_KERNEL=n` — debug code that runs in production, collects data you don't need, and burns battery doing it. All of it removed.
- BTF metadata disabled — smaller kernel footprint, less overhead from BPF type format processing on every module load.

### Under the Hood
- **Base:** LineageOS `android_kernel_oneplus_sm8650`, branch `lineage-23.2`
- **Kernel:** 6.1 GKI — same baseline as stock LineageOS 22.2, same KMI
- **Compiler:** GCC 16.1.0, `LTO_NONE` (stock GKI doesn't use LTO)
- **Config:** `gki_defconfig` + `vendor/pineapple_GKI.config` fragment
- **Output:** `Image` (26MB), `dtbo.img` (2.8MB, 91 device-tree overlays)

### What's Not Included (and Why)
| Excluded | Reason |
|----------|--------|
| LTO (Link-Time Optimization) | Not used in official GKI builds; increases build time with marginal gains on this hardware |
| KCFI (Kernel CFI) | Requires Clang; GCC builds drop it silently — a trade-off, not a flaw |
| Debug info / debugfs | Drains battery for data you don't use in daily driver |
| BTF metadata | Larger kernel image, more load-time overhead, host GCC compatibility issue |

---

## Quick Install

### Method A — Recovery Zip (Recommended)

1. Download `Helios-Kernel-v1.1-waffle.zip` from the [Releases](https://github.com/Ahnaf-Code55/helios-kernel/releases) page
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

### vbmeta — Leave It Alone

No need for `--disable-verity --disable-verification`. Helios works fine with standard custom-boot flashing on an unlocked bootloader. Keep `vbmeta` and `vbmeta_system` as they are.

### After an OTA

OnePlus 12 switches slots after system updates, and the new slot will boot the stock kernel. Just re-flash the Helios zip after any OTA and you're back to normal.

---

## A Few Things to Know

- This is the first proper release. It's been built carefully and checks out on paper, but real-world testing is ongoing. If something doesn't feel right, check the GitHub issues tab.
- Vendor modules from your ROM should load without issues — same kernel version, same KMI. But camera quirks, display white-balance hiccups, and NFC weirdness are all plausible until proven otherwise. When in doubt, re-flash the stock `dtbo` that came with your ROM.
- Idle drain improvement in testing was noticeable — your mileage will vary depending on the ROM, your apps, and how you use your phone.

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

## A Note on Security

This kernel is built with GCC 16.1.0, not Clang. One consequence: KCFI (Kernel CFI) doesn't work in a GCC build — the compiler doesn't emit the type checks that Clang would. This means every indirect function call in the kernel gives up a layer of protection that the stock Clang-built kernel has. It's a trade-off, not a bug. Shadow Call Stack (SCS) is still enabled and working.

Your ROM's vendor modules (which were built with Clang and have KCFI instrumentation baked in) will load and run normally against this kernel. When `CONFIG_CFI_CLANG=n`, the kernel simply ignores the KCFI data in those modules — no conflict, no crash risk. The reverse is what would be a problem: a KCFI-enabled kernel with non-KCFI modules.

---

## Changelog

### v1.1 (2026-09-01)
- First correct build for OnePlus 12. v1.0 used the wrong source tree (SM8550 / OnePlus 12R) — that one won't boot on OnePlus 12 and should be discarded.
- Source is now the right one: `android_kernel_oneplus_sm8650`, branch `lineage-23.2`, kernel 6.1 GKI
- 91 device-tree overlays included (display, audio, camera, BT, Wi-Fi, sensors, and more)
- AnyKernel3 flashable zip with A/B slot detection

### v1.0 — **DO NOT USE**
- Built from the wrong SoC. SM8550 != SM8650. Flashing it on a OnePlus 12 will leave you with a phone that won't boot.

---

## Developer

**Ahnaf Hossain** — [GitHub](https://github.com/Ahnaf-Code55)

---

## Credits

This kernel stands on the shoulders of projects that make custom Android possible:

- **[LineageOS](https://lineageos.org/)** — the kernel source tree and the reason any of this works
- **[Qualcomm](https://www.qualcomm.com/)** — the Snapdragon 8 Gen 3 is a solid platform to build on
- **[osm0sis](https://github.com/osm0sis)** — [AnyKernel3](https://github.com/osm0sis/AnyKernel3) made the flashable zip straightforward
- **[TheMuppets](https://github.com/The-Muppets)** — vendor blobs for everything the open-source tree doesn't include
- **CachyOS / Arch Linux** — the build environment this was compiled on

---

## License

Kernel source is GPLv2. Vendor blobs are proprietary. This project is for anyone who wants to learn how kernels work and actually use their phone instead of charging it.

Always verify compatibility with your ROM before flashing. When in doubt, flash to the inactive slot first.
