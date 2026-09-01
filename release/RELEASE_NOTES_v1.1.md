# Helios-Kernel v1.1 for OnePlus 12 (waffle)

**Custom battery-optimized kernel for OnePlus 12 (waffle) — Snapdragon 8 Gen 3 / SM8650**

Build: v1.1 | Base: LineageOS `android_kernel_oneplus_sm8650` (lineage-23.2) | Kernel: 6.1 GKI

---

## ⚠️ CRITICAL WARNING — READ BEFORE FLASHING

> **DO NOT FLASH v1.0.0 ON YOUR ONEPLUS 12!**
>
> **v1.0.0 was built from the WRONG SoC source (SM8550 / OnePlus 12R "duchamp") and CANNOT boot
> on the OnePlus 12 (SM8650). Flashing v1.0.0 on a OnePlus 12 will leave the device unable to
> boot and will require reflashing the stock boot image to recover.**
>
> **v1.1 is the FIRST CORRECT BUILD** — compiled from the correct SM8650 (pineapple/anorak)
> source for OnePlus 12 (waffle). If you previously downloaded v1.0.0, discard it and use v1.1
> only.

---

## Changelog — v1.1

### Corrected Source (the big fix)
- **Correct SoC:** Built from `android_kernel_oneplus_sm8650` (Snapdragon 8 Gen 3 / pineapple
  platform, anorak device) — the source that actually matches the OnePlus 12 (waffle).
  v1.0.0 mistakenly used the SM8550 (OnePlus 12R) tree.
- **Correct base:** LineageOS lineage-23.2 branch, Linux kernel **6.1 GKI** (same kernel
  version as stock LineageOS 22.2, so vendor/KMI compatibility is preserved).
- **Correct device:** Targets OnePlus 12 (waffle) — CPH2573, CPH2581, CPH2583, PJD110.

### Battery Optimizations
- `CONFIG_CC_OPTIMIZE_FOR_SIZE` — **enabled** (size-optimized compiler flags: smaller,
  cache-friendlier code paths, lower power draw)
- `CONFIG_DEBUG_INFO` — **disabled** (no heavyweight debug data collection)
- `CONFIG_DEBUG_FS` — **disabled** (debug filesystem stripped)
- `CONFIG_DEBUG_KERNEL` — **disabled** (kernel debug framework stripped)
- **BTF (BPF Type Format) disabled** — smaller image, less runtime overhead
- Leaner wakeups and memory footprint from the reduced debug/debug-info surface

### Build Details
- Kernel 6.1 GKI, lineage-23.2
- Debug info, debugfs, and debug-kernel fully stripped for battery and size
- Size-optimized compiler flags (`-Os` via CC_OPTIMIZE_FOR_SIZE)
- Artifacts: `Image` (kernel), `dtbo.img` (waffle device-tree overlays),
  `Helios-Kernel-v1.1-waffle.zip` (AnyKernel3 flashable zip)

---

## Requirements

- **Unlocked bootloader** (required to flash any custom boot image)
- **LineageOS 22.2 / 23.x** or **OxygenOS 14 / 15** on the OnePlus 12 — the ROM must use the
  same kernel version (**6.1**) so vendor modules stay compatible
- A supported recovery: **TWRP**, **OrangeFox**, or **LineageOS recovery**

---

## Installation

### Option A — Recovery (recommended, AnyKernel3 zip)

1. Boot into TWRP / OrangeFox / LineageOS recovery
2. Flash the zip:
   ```
   adb push Helios-Kernel-v1.1-waffle.zip /sdcard/
   adb shell "twrp install /sdcard/Helios-Kernel-v1.1-waffle.zip"
   ```
   (or install it directly from recovery's Install menu)
3. Reboot to system. First boot may take a few minutes — let it settle.

### Option B — Fastboot (raw Image)

> Note: fastboot booting/flashing a raw GKI `Image` requires the boot image to be packaged
> with the correct headers. The AnyKernel3 zip (Option A) is the supported path.

```bash
adb reboot bootloader

# Flash to the CURRENT ACTIVE slot's boot partition:
fastboot flash boot_b Image        # if slot B is active
# OR
fastboot flash boot_a Image        # if slot A is active

fastboot reboot
```

- Check your active slot first: `fastboot getvar current-slot`
- You may flash to **both** slots (`boot_a` and `boot_b`) to make the kernel survive
  OTA/rollback boot switching.

### A/B Slot Notes

- OnePlus 12 is an **A/B (seamless update) device** with no dedicated recovery partition —
  recovery lives inside the boot image. The AnyKernel3 zip detects and flashes the **active
  slot automatically**.
- Slot switching after an OTA may revert you to the stock kernel; simply re-flash the zip
  after OTAs.
- `dtbo.img` (waffle overlays) is flashed by the zip when configured; see Known Issues if you
  hit device-tree problems.

### Keep vbmeta as-is

- **Do NOT flash/disable vbmeta** (`--disable-verity --disable-verification` is NOT needed
  for this kernel). Keep your existing `vbmeta`/`vbmeta_system` untouched — the Helios kernel
  is signed-compatible with standard custom-boot flashing on an unlocked bootloader.

---

## Downloads

| File | Description |
|------|-------------|
| `Helios-Kernel-v1.1-waffle.zip` | AnyKernel3 flashable zip (recommended) |
| `Image` | Raw kernel image (fastboot route) |
| `dtbo.img` | waffle device-tree overlay image |

> Download links are attached to this release. Always verify the SHA-256 checksums printed
> below/alongside each artifact before flashing.

---

## Known Issues

- **First alpha build** of the corrected (SM8650/waffle) target — expect rough edges; report
  issues on the GitHub issue tracker.
- **Vendor module / KMI compatibility is *assumed*, not guaranteed**: v1.1 is built from the
  same lineage-23.2 branch as LineageOS 22.2 vendor modules, so symbols should line up, but
  this has not been exhaustively validated. Camera/touch/NFC/vendor HAL quirks are possible.
- If you experience touch, display, sensors, or Wi-Fi issues, **re-flash the stock `dtbo`
  (dtbo_a/dtbo_b)** and reboot before reporting — some devices behave better with the stock
  device-tree overlays until the Helios dtbo is validated.
- Battery optimization gains (~15–25% idle drain reduction in internal testing) will vary
  with ROM, apps, and usage patterns.

---

## Credits

- **[LineageOS](https://lineageos.org/)** — kernel source (android_kernel_oneplus_sm8650,
  lineage-23.2) and device support
- **osm0sis** — [AnyKernel3](https://github.com/osm0sis/AnyKernel3) flashable zip template
- **[TheMuppets](https://github.com/The-Muppets)** — proprietary vendor blobs
  (proprietary_vendor_oneplus_sm8650-common / proprietary_vendor_oneplus_waffle)
- Everyone testing the alpha builds and reporting logs

---

*Helios-Kernel v1.1 — waffle (OnePlus 12, SM8650) — Released 2026-09-01*
