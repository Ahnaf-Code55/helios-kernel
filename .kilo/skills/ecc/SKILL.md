---
name: ecc-helios-kernel
description: Everything Claude Code for Helios-Kernel - custom Android kernel compilation, optimization, and release management for OnePlus 12 (waffle/SM8650).
metadata:
  origin: helios-kernel
---

# ECC: Helios-Kernel Compilation

Everything for building, optimizing, and releasing Helios-Kernel for OnePlus 12.

## Device Codenames (IMPORTANT!)

| Item | Value |
|------|-------|
| **Device** | **OnePlus 12** |
| Marketing codename | **waffle** |
| Qualcomm platform codename | **pineapple** |
| Qualcomm board name | **anorak** (`anorak.dts` = SM8650 base DTB) |
| SoC | **SM8650** Snapdragon 8 Gen 3 |
| Supported models | CPH2573, CPH2581, CPH2583, PJD110 |

**CORRECTION:** Previous docs said `duchamp`/`kalama`/SM8550 — those were WRONG. `kalama`/SM8550 belongs to the OnePlus 12R family. The OnePlus 12 is `waffle` on the `pineapple` platform.

Device tree overlays (in `oplus/` of the devicetrees repo):
- `waffle-22825-pineapple-overlay.dts` — **22825 = China** model
- `waffle-22877-pineapple-overlay.dts` — **22877 = international** model

## Hardware Specs

- Display: 6.82" LTPO AMOLED, 1440x3216, 120Hz
- GPU: Adreno 750
- RAM: up to 24GB
- Storage: UFS 4.0
- Battery: 5400mAh

## Repos (all lineage-23.2)

Kernel: **6.1 GKI**, LineageOS lineage-23.2 branch (Android 16).

| Repo | URL | Branch | Clone to |
|------|-----|--------|----------|
| Kernel | https://github.com/LineageOS/android_kernel_oneplus_sm8650 | lineage-23.2 | `/home/ahnaf/helios-kernel-src` |
| **Modules (required companion)** | https://github.com/LineageOS/android_kernel_oneplus_sm8650-modules | lineage-23.2 | `/home/ahnaf/sm8650-modules` |
| Device trees | https://github.com/LineageOS/android_kernel_oneplus_sm8650-devicetrees | lineage-23.2 | `/home/ahnaf/waffle-device-tree` |
| Vendor blobs (SM8650 common) | https://github.com/TheMuppets/proprietary_vendor_oneplus_sm8650-common | lineage-23.2 | `/home/ahnaf/proprietary_vendor_oneplus_sm8650-common` |
| Vendor blobs (waffle) | https://github.com/TheMuppets/proprietary_vendor_oneplus_waffle | lineage-23.2 | `/home/ahnaf/proprietary_vendor_oneplus_waffle` |

## Paths

| Path | Description |
|------|-------------|
| `/home/ahnaf/helios-kernel-src/` | Kernel source (LineageOS sm8650, lineage-23.2) |
| `/home/ahnaf/sm8650-modules/` | **Required** companion modules repo — kernel symlinks resolve here via `../../sm8650-modules` |
| `/home/ahnaf/waffle-device-tree/` | Device trees: `qcom/` base (incl. anorak) + `oplus/` waffle overlays |
| `/home/ahnaf/proprietary_vendor_oneplus_sm8650-common/` | SM8650 common vendor blobs (TheMuppets) |
| `/home/ahnaf/proprietary_vendor_oneplus_waffle/` | waffle-specific vendor blobs (TheMuppets) |
| `/home/ahnaf/AnyKernel3/` | Flashable zip builder (configured for waffle, `IS_SLOT_DEVICE=1`) |
| `/home/ahnaf/helios-kernel-out/` | Build output (`O=` directory) |

## Build Flow

```bash
export ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu-
SRC=/home/ahnaf/helios-kernel-src
OUT=/home/ahnaf/helios-kernel-out

# 1. GKI base config
make -C $SRC O=$OUT gki_defconfig

# 2. Merge Qualcomm pineapple GKI fragment
$SRC/scripts/kconfig/merge_config.sh -m $OUT/.config \
  $SRC/arch/arm64/configs/vendor/pineapple_GKI.config

# 3. Apply battery optimizations (see table below)
$SRC/scripts/config --file $OUT/.config \
  --enable  CC_OPTIMIZE_FOR_SIZE \
  --disable DEBUG_INFO \
  --disable DEBUG_FS \
  --disable DEBUG_KERNEL \
  --disable DEBUG_INFO_BTF

# 4. Resolve config
make -C $SRC O=$OUT olddefconfig

# 5. Build (host: 12 threads, ~7 GiB RAM; -j6 works)
make -C $SRC O=$OUT -j6 Image dtbs
```

Build output: `/home/ahnaf/helios-kernel-out/arch/arm64/boot/Image` + DTBs under `.../dts/`.

## Build Gotchas

1. **Always use `O=`** (out-of-tree build). Building in-source pollutes the kernel tree, overwrites configs, and breaks reproducibility. Always pass `O=/home/ahnaf/helios-kernel-out`.
2. **`CONFIG_DEBUG_INFO_BTF` must be disabled** — host GCC 16.1.0 (CachyOS) fails BTF generation. This is required, not optional; keep `DEBUG_INFO_BTF` disabled.
3. **`certs/extract-cert.c` key_pass fix** — upstream declares `key_pass` only under `#ifdef USE_PKCS11_ENGINE` but references it unconditionally, breaking the build with host GCC 16.1.0 / OpenSSL 3. **Fix (already applied locally in `helios-kernel-src`):** remove the `#ifdef USE_PKCS11_ENGINE` / `#endif` guard around `static const char *key_pass;` (~line 80). Re-apply after any fresh re-clone.
4. **Modules repo must exist at `/home/ahnaf/sm8650-modules`** — the kernel tree contains relative symlinks that resolve through `../../sm8650-modules`:
   - `drivers/power/oplus -> ../../../sm8650-modules/oplus/kernel/charger`
   - `drivers/misc/vibrator -> ../../../sm8650-modules/oplus/kernel/vibrator`
   - `include/linux/pogo_common.h -> .../device_info/pogo_keyboard/pogo_common.h`
   - `drivers/base/kernelFwUpdate`, `drivers/base/touchpanel_notify`, `drivers/input/oplus_secure_drivers`, `drivers/input/uff_fp_drivers`

   If `/home/ahnaf/sm8650-modules` is missing, these dangle and headers/build steps fail.

## Battery Optimization (current state)

| Option | State |
|--------|-------|
| `CONFIG_CC_OPTIMIZE_FOR_SIZE` | **y** |
| `CONFIG_DEBUG_INFO` | **disabled** |
| `CONFIG_DEBUG_FS` | **disabled** |
| `CONFIG_DEBUG_KERNEL` | **disabled** |
| `CONFIG_DEBUG_INFO_BTF` | **disabled** (required for host GCC 16.1.0) |

## Flash Instructions

OnePlus 12 is an **A/B (seamless update)** device — two boot slots, `boot_a` and `boot_b`.

**AnyKernel3 recovery zip** (AnyKernel3 at `/home/ahnaf/AnyKernel3`, `IS_SLOT_DEVICE=1` set in `anykernel.sh`):
1. Copy the built `Image` into `/home/ahnaf/AnyKernel3/`
2. Zip the AnyKernel3 directory
3. Flash the zip from recovery (it targets the current active slot automatically)

**fastboot**:
```bash
adb reboot bootloader
fastboot flash boot_a Image   # or boot_b, per active slot
fastboot reboot
```

## Troubleshooting (actual errors hit)

| Error | Cause | Fix |
|-------|-------|-----|
| Build failure in `certs/extract-cert.c` — `key_pass` undeclared / OpenSSL ENGINE errors | `key_pass` declaration wrapped in `#ifdef USE_PKCS11_ENGINE` but used unconditionally (host GCC 16.1.0 / OpenSSL 3) | Remove the `#ifdef`/`#endif` around `static const char *key_pass;` (local patch already applied in `helios-kernel-src`; re-apply after re-clone) |
| Link-stage BTF / pahole errors | Host GCC 16.1.0 cannot generate BTF as configured | `CONFIG_DEBUG_INFO_BTF` must be **disabled** |
| Missing headers / dangling symlinks under `drivers/power/oplus`, `drivers/misc/vibrator`, etc. | `/home/ahnaf/sm8650-modules` not cloned — kernel symlinks point to `../../sm8650-modules` | Clone `android_kernel_oneplus_sm8650-modules` (lineage-23.2) to `/home/ahnaf/sm8650-modules` |
| Config drift: debug options reappear between builds | Building in-source or omitting `O=` | Always build with `O=/home/ahnaf/helios-kernel-out` |
| References to duchamp/kalama/SM8550 anywhere | Stale docs / old zips from before the codename correction | Ignore them — correct names: **waffle / pineapple / anorak / SM8650** |

## Release Process

1. Verify `/home/ahnaf/sm8650-modules` and `/home/ahnaf/waffle-device-tree` exist
2. Build Image + DTBs (build flow above)
3. Copy `Image` into `/home/ahnaf/AnyKernel3/` and package the recovery zip
4. Flash via recovery zip or fastboot (A/B slots)
5. Tag / publish the release with the waffle codename

## Key Scripts

- `scripts/check-env.sh` — verify build tools
- `scripts/setup-cachyos.sh` — install dependencies on CachyOS/Arch
- `scripts/build-dtbo.sh` — build waffle DTBO from device tree overlays
