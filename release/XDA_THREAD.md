# [KERNEL] Helios-Kernel v1.1 — OnePlus 12 (Snapdragon 8 Gen 3 / SM8650)

**Developer:** Ahnaf Hossain | **Kernel:** 6.1 GKI | **Base:** LineageOS lineage-23.2

---

## Introduction

Helios-Kernel is a custom kernel for the OnePlus 12 that cuts out the debug overhead that runs in the background and wastes battery, leaving the performance paths clean. No gimmicks, no excessive tuning.

v1.0 used the wrong source tree (SM8550 / OnePlus 12R). That one does not boot on the OnePlus 12. Discard it.

---

## Device Compatibility

**Works with:**
- OnePlus 12 (`waffle`) — Snapdragon 8 Gen 3 (SM8650)
  - CPH2573, CPH2581, CPH2583 (Global)
  - PJD110 (China)

**Does not work with (different SoC — do not flash):**
- OnePlus 12R (`duchamp`/`kalama`) — Snapdragon 8s Gen 2 (SM8475)
- OnePlus Open (`findn3`)
- OnePlus Pad 2 (`cramer`)

**ROMs:**
- LineageOS 21.x – 23.x (Android 14 – 16) — recommended
- OxygenOS 14 / 15 (Android 14) — supported
- OxygenOS 16+, PixelExperience — untested

This kernel is 6.1 GKI. Vendor modules from your ROM need the same kernel version and KMI to load. Most custom ROMs for OnePlus 12 use 6.1 kernels.

---

## What Changed

**Battery and performance:**
- `CONFIG_CC_OPTIMIZE_FOR_SIZE=y` — the compiler removes code that just adds size without helping. Smaller instruction cache footprint means the Snapdragon 8 Gen 3 stays in low-power states longer when the screen is off. Under load, less cache pressure means faster app launches and less throttling during long sessions.
- Debug info, debugfs, and debug-kernel — all removed. This code runs on your phone, collects data you do not use, and uses battery doing it.
- BTF metadata disabled — smaller kernel, less overhead when modules load.

**What is not included:**
| Not included | Why |
|---|---|
| LTO | Not used in official GKI builds; marginal gains for the build time cost |
| KCFI | Requires Clang; GCC builds drop it without error — a trade-off |
| BTF | Larger image, more load-time overhead, breaks with this host compiler |

**Source details:**
- Base: LineageOS `android_kernel_oneplus_sm8650`, branch `lineage-23.2`
- Kernel: 6.1 GKI — same KMI as stock LineageOS 22.2
- Compiler: GCC 16.1.0, `LTO_NONE`, `CC_OPTIMIZE_FOR_SIZE=y`
- 91 device-tree overlays: display, audio, camera, BT, Wi-Fi, sensors, and more

---

## Installation

**Recovery (recommended):**
1. Download the zip below
2. Boot into TWRP / OrangeFox / LineageOS recovery
3. Flash the zip from the Install menu
4. Reboot

**Fastboot:**
```
adb reboot bootloader
fastboot getvar current-slot
fastboot flash boot_b Image      # if slot B is active
fastboot flash boot_a Image      # if slot A is active
fastboot reboot
```

Flash to both slots if you want the kernel to survive OTA slot switching.

OnePlus 12 is an A/B device. The recovery zip detects the active slot automatically.

Leave vbmeta alone. No `--disable-verity --disable-verification` needed.

---

## A Note on Security

This kernel was built with GCC, not Clang. One trade-off: KCFI does not work in a GCC build. The stock Clang kernel has type checks on indirect function calls. This one does not. Shadow Call Stack (SCS) is still on.

Your ROM's vendor modules were built with Clang and have KCFI data. They load normally against this kernel. When `CONFIG_CFI_CLANG=n`, the kernel ignores the KCFI data in those modules. No conflict, no crash risk.

---

## Known Issues

This is the first proper release. Real-world testing is ongoing. If something does not work, check the GitHub issues tab before posting.

Camera, display white-balance, NFC — possible quirks until someone tests across a range of ROMs. When something feels wrong, try re-flashing the stock `dtbo` from your ROM first.

Idle battery improvement was noticeable in testing. Your results will vary with ROM, apps, and usage.

If you are switching from a different custom kernel, a clean flash is the safest option.

---

## Changelog

**v1.1 (2026-09-01) — first correct build**
- Fixed: now built from the right source tree (`android_kernel_oneplus_sm8650`, SM8650)
- Added: 91 device-tree overlays for waffle
- Added: AnyKernel3 flashable zip with A/B slot detection
- Battery opts: `CC_OPTIMIZE_FOR_SIZE=y`, all debug options stripped

**v1.0 — do not use**
- Built from the wrong SoC (SM8550). Does not boot on OnePlus 12.

---

## Downloads

| File | Description |
|---|---|
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
- **Helios-Kernel Testers** — link coming soon
- **Helios-Kernel Community** — link coming soon

If it works well for you, a reply helps. Bug reports with logs are better.

---

*Last updated: 2026-09-01*
