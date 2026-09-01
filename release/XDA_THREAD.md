# [KERNEL] Helios-Kernel v1.1 — OnePlus 12 (Snapdragon 8 Gen 3 / SM8650)

> **Developer:** Ahnaf Hossain | **Kernel:** 6.1 GKI | **Base:** LineageOS lineage-23.2

---

## Introduction

Helios-Kernel is a custom kernel built for the OnePlus 12 that prioritizes real-world efficiency over benchmark numbers. It drops the debug overhead that drains your battery in the background and leaves the performance-critical paths clean. No gimmicks, no excessive tuning — just the kernel doing what it should.

This is the first correct build. v1.0 used the wrong source tree (SM8550 / OnePlus 12R) — that one won't boot on the OnePlus 12 and should be discarded.

---

## Device Compatibility

**Supported:**
- OnePlus 12 (`waffle`) — Snapdragon 8 Gen 3 (SM8650)
  - CPH2573, CPH2581, CPH2583 (Global)
  - PJD110 (China)

**Not supported (different SoC — do not flash):**
- OnePlus 12R (`duchamp`/`kalama`) — Snapdragon 8s Gen 2 (SM8475)
- OnePlus Open (`findn3`)
- OnePlus Pad 2 (`cramer`)

**ROMs tested:**
- LineageOS 21.x – 23.x (Android 14 – 16) ✅ Recommended
- OxygenOS 14 / 15 (Android 14) ✅ Supported
- OxygenOS 16+, PixelExperience — untested

> **Kernel version note:** This kernel is **6.1 GKI**. Vendor modules from your ROM must use the same kernel version and KMI. Most custom ROMs for OnePlus 12 ship with 6.1-based kernels.

---

## What Changed

**Battery & Performance**
- `CONFIG_CC_OPTIMIZE_FOR_SIZE=y` — the compiler cuts fat from code paths, not just binary size. Tighter caches mean the Snapdragon 8 Gen 3 wakes up less often and spends more time in low-power states when the screen is off. Under load, reduced instruction cache pressure translates to snappier app launches and less thermal throttling during extended sessions.
- Debug info, debugfs, and debug-kernel — all stripped. Debug code that runs in production, collects data you don't need, and burns battery doing it. Gone.
- BTF metadata disabled — smaller kernel footprint, less overhead on every module load.

**What's not included (and why)**
| Excluded | Reason |
|----------|--------|
| LTO | Not used in official GKI builds; marginal gains, significant build time |
| KCFI | Requires Clang; GCC builds drop it silently — a trade-off |
| BTF | Larger image, GCC compatibility issues |

**Under the hood**
- Base: LineageOS `android_kernel_oneplus_sm8650`, branch `lineage-23.2`
- Kernel: 6.1 GKI — same KMI as stock LineageOS 22.2
- Compiler: GCC 16.1.0, `LTO_NONE`, `CC_OPTIMIZE_FOR_SIZE=y`
- 91 device-tree overlays (display, audio, camera, BT, Wi-Fi, sensors, and more)

---

## Installation

**Recovery (recommended):**
1. Download the zip below
2. Boot into TWRP / OrangeFox / LineageOS recovery
3. Flash the zip via the Install menu
4. Reboot

**Fastboot:**
```bash
adb reboot bootloader
fastboot getvar current-slot    # check your active slot
fastboot flash boot_b Image      # slot B active
# OR
fastboot flash boot_a Image      # slot A active
fastboot reboot
```

Flash to both slots if you want the kernel to survive OTA boot-slot switching.

**A/B device note:** OnePlus 12 is A/B. The recovery zip detects and flashes the active slot automatically.

**vbmeta:** Leave it alone. No `--disable-verity --disable-verification` needed.

---

## A Note on Security

This kernel is built with GCC, not Clang. One trade-off: KCFI (Kernel CFI) doesn't work in a GCC build. Every indirect function call in the kernel gives up a layer of protection that the stock Clang-built kernel has. Shadow Call Stack (SCS) is still enabled.

Your ROM's vendor modules (Clang-built, KCFI-instrumented) will load and run normally against this kernel. When `CONFIG_CFI_CLANG=n`, the kernel simply ignores the KCFI data — no conflict, no crash risk.

---

## Known Issues

- First proper release — real-world testing is ongoing. Something not working? Check the GitHub issues tab before reporting.
- Camera, display white-balance, NFC — plausible quirks until validated against a range of ROMs. When in doubt, re-flash the stock `dtbo` from your ROM.
- Idle drain improvement in testing was noticeable. Your mileage will vary with ROM, apps, and usage patterns.
- If you're coming from a different custom kernel, a clean flash is always the safest option.

---

## Changelog

**v1.1 (2026-09-01) — First correct build**
- Fixed: Now built from the right source tree (`android_kernel_oneplus_sm8650`, SM8650)
- Added: 91 device-tree overlays for waffle
- Added: AnyKernel3 flashable zip with A/B slot detection
- Battery opts: `CC_OPTIMIZE_FOR_SIZE=y`, all debug options stripped

**v1.0 — DO NOT USE**
- Built from wrong SoC (SM8550). Cannot boot on OnePlus 12.

---

## Downloads

| File | Description |
|------|-------------|
| [Helios-Kernel-v1.1-waffle.zip](https://github.com/Ahnaf-Code55/helios-kernel/releases/download/v1.1/Helios-Kernel-v1.1-waffle.zip) | AnyKernel3 flashable zip (13.7 MB) |
| [Image](https://github.com/Ahnaf-Code55/helios-kernel/releases/download/v1.1/Image) | Raw kernel image (26 MB) |
| [dtbo.img](https://github.com/Ahnaf-Code55/helios-kernel/releases/download/v1.1/dtbo.img) | Device-tree overlays (2.8 MB) |

**Source:** https://github.com/Ahnaf-Code55/helios-kernel

---

## Credits

- **LineageOS** — kernel source tree
- **Qualcomm** — Snapdragon 8 Gen 3 platform
- **osm0sis** — AnyKernel3
- **TheMuppets** — proprietary vendor blobs
- **CachyOS / Arch Linux** — build environment

---

## Support

- **GitHub Issues:** https://github.com/Ahnaf-Code55/helios-kernel/issues
- **Helios-Kernel Testers group** — link coming soon
- **Helios-Kernel Community** — link coming soon

If this kernel works well for you, consider leaving a reply. Bug reports with logs are always appreciated.

---

*Last updated: 2026-09-01*
