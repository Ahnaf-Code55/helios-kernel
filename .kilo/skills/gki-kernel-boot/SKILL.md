---
name: gki-kernel-boot
description: Hard-won knowledge for making GKI kernels (5.10+, boot header v4) actually BOOT on modern Android devices - clang/KMI compatibility, vendor module loading, partition layout (boot/init_boot/vendor_boot/vendor_dlkm/dtbo), DTB/DTBO matching, boot-chain-critical modules, and common build error fixes. Verified on Helios-Kernel (OnePlus 12 waffle/SM8650, LineageOS lineage-23.2, kernel 6.1 GKI).
metadata:
  origin: helios-kernel
---

# GKI Kernel Boot Compatibility

Everything that determines whether a custom-built GKI kernel will actually boot on a modern Android device (Android 13+, boot header v4, GKI 2.0). A kernel that compiles cleanly is NOT a kernel that boots.

Verified on: OnePlus 12 (`waffle`/`pineapple`/SM8650), LineageOS lineage-23.2, kernel 6.1 GKI (android14-6.1 KMI).

## 1. Compiler Is CRITICAL for GKI (KMI Compatibility)

GKI kernels (5.10+) are officially built with **Clang/LLVM, NOT GCC**. This is not a style choice — it is an ABI requirement.

- Check `build.config.common` for `CLANG_VERSION` (e.g. `r487747c` for android14-6.1) and `LLVM=1`.
- Vendor modules on device (`.ko` files in `vendor_boot`/`vendor_dlkm`) were built with that **exact** clang toolchain.
- A **GCC-built** kernel `Image` will fail module loading with:
  - `invalid module format`
  - CRC mismatches in `module_layout` / vermagic
  - struct layout differences between core kernel and vendor `.ko` modules
- GCC and clang differ in struct padding, symbol versioning (CRCs), and codegen conventions; the KMI is only defined against the official clang.

**Rule: ALWAYS build GKI kernels with clang + ld.lld + LLVM binutils tools** (`LLVM=1 LLVM_IAS=1`), matching or close to the official `CLANG_VERSION`. Host clang 22 works for android14-6.1 (newer than `r487747c` but ABI-compatible for C code).

Verify after config/build:

```
grep CONFIG_CC_IS_CLANG out/.config    # must be =y
grep CONFIG_CC_VERSION_TEXT out/.config # must show clang, e.g. "clang version 22..."
```

If `CONFIG_CC_IS_CLANG` is not set, the build used GCC and the resulting Image will not load vendor modules — rebuild before wasting a flash cycle.

## 2. KMI Symbol List

`build.config.msm.gki` (or per-SoC `build.config.msm.<soc>`) sets:

- `KMI_ENFORCED=1`
- `GKI_KMI_SYMBOL_LIST_STRICT_MODE=1`
- `KMI_SYMBOL_LIST=android/abi_gki_aarch64_qcom`

The kernel must export exactly the symbols in that list, with matching CRCs, because vendor `.ko` modules link against them.

**Config changes and KMI safety:**

| Change type | KMI risk |
|-------------|----------|
| Scheduler tunables (e.g. sched tunable ranges) | Safe |
| CPU governors | Safe |
| `CC_OPTIMIZE_FOR_*` | Safe |
| Debug options (`DEBUG_INFO*`, `DEBUG_FS`) | Safe |
| Anything changing exported function signatures or struct layouts | **UNSAFE — breaks module loading** |

When in doubt, verify the KMI is unchanged with the kernel's ABI check tooling (`scripts/check-abi`, `build/abi` helpers, libabigail-based diff) before flashing.

## 3. GKI Partition Layout (Android 13+, boot header v4, kernel 5.10+ GKI 2.0)

| Partition | Contents |
|-----------|----------|
| `boot` | Kernel **Image only** (GZ generic ramdisk moved to `init_boot`) |
| `init_boot` | Generic ramdisk (GZ) |
| `vendor_boot` | Vendor ramdisk + first-stage `.ko` modules (**110+** for pineapple/SM8650) |
| `vendor_dlkm` | Rest of the `.ko` modules |
| `dtbo` | Device tree overlays (bootloader applies onto base DTB) |

- `KERNEL_BINARY=Image` — **NOT** `Image.gz-dtb`. The DTB is **NOT appended** to the kernel in GKI; it lives in dtbo/base-DT partitions.
- AnyKernel3 flash replaces **only the boot partition kernel**. Keep `do.modules=0` in anykernel3.sh and rely on the existing vendor partitions to supply modules — as long as KMI is intact (sections 1–2), stock vendor modules load against your custom Image.

## 4. DTB/DTBO

- `DT_OVERLAY_SUPPORT=1` in `build.config.msm.<soc>` → the build produces `dtbo.img` via `mkdtboimg create --page_size=4096 *.dtbo`.
- If your base DTB is unchanged from stock, the **stock dtbo partition works** — no need to flash dtbo.
- If you changed the DTB, you **must flash the matching `dtbo.img`** or the device hangs at splash (bootloader applies old overlays onto a changed base or vice versa).

## 5. Boot-Chain Modules That Cannot Fail

These first-stage modules (in `vendor_boot`) must load or the device **bootloops**. Any kernel change that breaks their loading is fatal:

| Module | Failure consequence |
|--------|---------------------|
| `qcom-scm` | Firmware calls fail — everything downstream breaks |
| `qcom_rpmh` | Power/resource management dead |
| `cmd-db` | Resource commands unavailable |
| `pinctrl-<soc>` | Pin control dead — peripherals unreachable |
| `clk-qcom` / `gcc-<soc>` | Clocks dead — nothing initializes |
| `arm_smmu` | IOMMU dead — DMA devices fail |
| `ufs_qcom` + `phy-qcom-ufs-qmp-v4-<soc>` + `sdhci-msm` | **No storage = no boot** |
| `smem` | Shared memory dead — inter-processor comms fail |
| `spmi-pmic-arb` | PMIC bus dead |
| `qpnp-power-on` | Power key / reset dead |
| `qcom_tsens` | Thermal monitoring dead |
| `qcom_wdt_core` | Watchdog dead |

If the kernel Image is KMI-incompatible, these are the modules whose load failure manifests as a silent bootloop.

## 6. Common Build Errors and Fixes

| Error | Fix |
|-------|-----|
| `tools/bpf/resolve_btfids` `libbpf.c` `-Werror=discarded-qualifiers` with new host GCC | Disable `CONFIG_DEBUG_INFO_BTF` (also required when `pahole` is absent) |
| `certs/extract-cert.c` `'key_pass' undeclared` with new OpenSSL | Remove the `#ifdef USE_PKCS11_ENGINE` guard around the `key_pass` declaration (re-apply after re-clone — it is a local fix) |
| `source tree is not clean` | **Always build out-of-tree with `O=outdir`**, never in-tree; `rm -f .config` in the src tree if dirtied |
| `merge_config.sh` dirties the source tree | Run it from the src dir, then remove the generated `.config` from the src tree and keep the real one in `O=` output |

## 7. Decision Tree: "Will My Custom GKI Kernel Boot?"

```
1. Built with clang matching the official CLANG_VERSION (LLVM=1 LLVM_IAS=1)?
   NO  -> rebuild with clang. A GCC Image WILL fail module loading.
   YES -> continue

2. KMI symbol list unchanged (no exported symbols/signatures/struct layouts altered)?
   Verify with scripts/check-abi (libabigail) tooling.
   CHANGED -> fix or accept that vendor modules will fail (bootloop).

3. Only the boot partition kernel replaced (AnyKernel3 with do.modules=0)?
   OK  -> existing vendor_boot/vendor_dlkm modules load against your Image
          (safe as long as steps 1-2 hold).

4. Did you change the base DTB?
   YES -> flash the matching dtbo.img too, or device hangs at splash.
   NO  -> stock dtbo partition is fine.
```

All four checks green = the kernel should boot. The most common silent-bootloop causes, in order: GCC-built Image (KMI mismatch), KMI-breaking config change, flashed changed DTB without matching dtbo.
