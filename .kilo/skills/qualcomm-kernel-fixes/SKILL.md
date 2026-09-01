---
name: qualcomm-kernel-fixes
description: Fix playbook for every build and boot error hit in Helios-Kernel (OnePlus 12 waffle/SM8650, kernel 6.1 GKI, LineageOS lineage-23.2) - extract-cert key_pass OpenSSL failure, resolve_btfids libbpf -Werror, BTF/GCC-14, "source tree is not clean", broken sm8650-modules symlinks, GCC-vs-clang KMI breakage, boot header v4 packaging, dtbo flashing. Symptoms, cause, and exact fix commands for each.
metadata:
  origin: helios-kernel
---

# Qualcomm Kernel Fix Playbook (Helios-Kernel, SM8650/pineapple)

Every error below was actually hit building/booting Helios-Kernel on
CachyOS (GCC 16.1.0, OpenSSL 3.x, ~7 GiB RAM). For each: symptoms, cause, fix.

Build environment constants used in fix commands:

```bash
SRC=/home/ahnaf/helios-kernel-src          # kernel source (lineage-23.2)
OUT=/home/ahnaf/helios-kernel-out          # out-of-tree build dir (always O=)
MOD=/home/ahnaf/sm8650-modules             # companion vendor modules repo
```

## 1. `certs/extract-cert.c: 'key_pass' undeclared` (OpenSSL 3.x)

### Symptoms

```
certs/extract-cert.c: In function 'main':
certs/extract-cert.c:147:32: error: 'key_pass' undeclared (first use in this function)
  147 |                 ERR(!ENGINE_ctrl_cmd_string(e, "PIN", key_pass, 0), "Set PKCS#11 PIN");
      |                                ^~
make[2]: *** [scripts/Makefile.build:1141: certs/extract-cert.o] Error 1
```

Fails during `make` host-tools compilation, early in the build (certs stage).

### Cause

Upstream declares `key_pass` inside `#ifdef USE_PKCS11_ENGINE`
(`certs/extract-cert.c:109`), but references it inside the
`#ifndef OPENSSL_IS_BORINGSSL` PKCS#11 branch (line 147). On modern hosts
with OpenSSL 3.x, `USE_PKCS11_ENGINE` is never defined (engine headers
removed/optional), so the declaration is compiled out while the use is not.

### Fix

Move the declaration out of the `#ifdef` so it is unconditional.

Apply by hand — the exact edit is:

```c
/* near top of file, with other statics (UNCONDITIONAL): */
static const char *key_pass;
static BIO *wb;
static char *cert_dst;

/* in main(), keep as-is (assignment may stay inside the ifdef): */
#ifdef USE_PKCS11_ENGINE
	key_pass = getenv("KBUILD_SIGN_PIN");
#endif
```

Verify:

```bash
grep -n 'key_pass' certs/extract-cert.c
# expect: declaration OUTSIDE any #ifdef, plus getenv + PIN usage sites
```

> **Re-apply after every `make clone` / re-clone** — this is a local fix,
> not upstream. Track it as a patch file in the build repo if possible.

## 2. `resolve_btfids` / `libbpf` `-Werror` host-GCC failures (BTF tools)

### Symptoms

```
  HOSTCC  tools/bpf/resolve_btfids/libbpf/libbpf.o
tools/bpf/resolve_btfids/libbpf/libbpf.c: In function 'libbpf_assert':
tools/bpf/resolve_btfids/libbpf/libbpf.c:211:9: error: 'strncpy' specified bound
  ... equals destination size [-Werror=stringop-truncation]
  cc1: all warnings being treated as errors
make[3]: *** [tools/bpf/resolve_btfids/Makefile:...] Error 1
```

Variants include `-Werror=discarded-qualifiers`,
`-Werror=stringop-truncation`, and other host-GCC-14-vs-old-libbpf
warnings. Always in `tools/bpf/resolve_btfids` or `tools/lib/bpf`.

### Cause

The vendored libbpf copy in kernel 6.1 predates host GCC 16.1.0. The BTF tool
build (`tools/bpf/resolve_btfids`) builds host libs with `-Werror`; GCC 16.1.0
emits new warnings the old code trips. Only triggered when BTF metadata
generation is enabled (`CONFIG_DEBUG_INFO_BTF=y`) or the tool is built
anyway.

### Fix

Disable `CONFIG_DEBUG_INFO_BTF` — required on this host anyway (pahole/
libbpf combo incompatible with GCC 16.1.0 debug info):

```bash
cd "$SRC"
./scripts/config --file "$OUT/.config" -d DEBUG_INFO_BTF
# or directly:
scripts/config --enable CONFIG_DEBUG_INFO_NONE --disable CONFIG_DEBUG_INFO_BTF  # 6.1 naming may vary; verify with:
grep -n "CONFIG_DEBUG_INFO_BTF" "$OUT/.config"   # must be "# CONFIG_DEBUG_INFO_BTF is not set"
make O="$OUT" olddefconfig
```

Helios build flow already disables it via battery opts
(`DEBUG_INFO`, `DEBUG_FS`, `DEBUG_KERNEL`, `DEBUG_INFO_BTF` off). If the
error still appears, a stale `tools/` artifact is being rebuilt — clean
just that tool:

```bash
make O="$OUT" tools/clean   # or: rm -rf "$OUT/tools/bpf/resolve_btfids"
```

Do NOT try to fix libbpf source; disabling BTF is the sanctioned GKI-build
workaround for GCC-14 hosts and is what the Helios defconfig enforces.

## 3. `source tree is not clean` — out-of-tree build violated

### Symptoms

```
make[1]: *** [...]: WARNING: "source tree is not clean, please run 'make mrproper'
...
  source tree is not clean
```
or a `.config` suddenly appearing inside `$SRC` after a config-merge step.

### Cause

Something wrote build state into the source tree (usually a
`merge_config.sh` run without `O=`, or `make defconfig` in the wrong
directory). Kernel kbuild refuses mixing in-tree artifacts with an `O=`
build of the same tree.

### Fix

Always build out-of-tree with `O=` and keep the source pristine:

```bash
# Clean the pollution in $SRC (never loses tracked files):
cd "$SRC"
rm -f .config .config.old .version include/config/kernel.release
git status --porcelain | grep '^??' | awk '{print $2}' | xargs -r rm -rf
# (if heavily dirtied: make mrproper in $SRC, then git checkout any touched files)

# Correct config flow — all steps with O=:
make O="$OUT" ARCH=arm64 gki_defconfig
scripts/kconfig/merge_config.sh -m "$OUT/.config" arch/arm64/configs/vendor/pineapple_GKI.config
make O="$OUT" ARCH=arm64 olddefconfig
```

Note `merge_config.sh -m` with the `-O=` output path as the target config;
without `-m` and the output-dir path it writes `.config` into the source
tree. After merging, `rm -f "$SRC/.config"` if one appeared.

## 4. Broken `sm8650-modules` symlinks (dangling vendor module dirs)

### Symptoms

```
make[4]: *** No rule to make target 'drivers/base/kernelFwUpdate/...'.
  Stop.
```
or `ls: cannot readlink ... No such file or directory` on entries under
`drivers/` / `include/`, or a vanished `oplus/` driver directory after a
modules-repo move/clone.

### Cause

The LineageOS sm8650 kernel symlinks vendor module directories into the
tree via relative symlinks pointing to `../../sm8650-modules` (i.e. a
sibling of the kernel source dir):

```
$SRC/drivers/base/kernelFwUpdate       -> ../../../sm8650-modules/oplus/kernel/touchpanel/kernelFwUpdate
$SRC/drivers/base/touchpanel_notify    -> ../../../sm8650-modules/...
$SRC/drivers/input/oplus_secure_drivers-> ../../../sm8650-modules/...
$SRC/drivers/input/uff_fp_drivers      -> ../../../sm8650-modules/...
$SRC/drivers/misc/vibrator             -> ../../../sm8650-modules/...
$SRC/drivers/power/oplus               -> ../../../sm8650-modules/...
$SRC/include/linux/pogo_common.h       -> ../../../sm8650-modules/oplus/kernel/device_info/pogo_keyboard/pogo_common.h
```

If `/home/ahnaf/sm8650-modules` is missing, at the wrong path, or the
kernel source was cloned to a different directory depth, every symlink
dangles.

### Fix

1. Ensure the companion repo exists as a SIBLING of the kernel source:

```bash
ls -d /home/ahnaf/sm8650-modules   # must contain: Android.bp Android.mk nxp oplus qcom
# if missing:
git clone https://github.com/LineageOS/android_vendor_qcom_pineapple-modules \
  --branch lineage-23.2 /home/ahnaf/sm8650-modules
```

2. Verify each symlink resolves:

```bash
find "$SRC" -maxdepth 3 -lname '*sm8650-modules*' | while read -r l; do
  [ -e "$l" ] || echo "DANGLING: $l -> $(readlink "$l")"
done
# no output = all good
```

3. If the source tree was moved and depth changed, re-point the symlinks:

```bash
find "$SRC" -maxdepth 3 -lname '*sm8650-modules*' | while read -r l; do
  tgt=$(readlink "$l")
  newtgt=$(python3 -c "import os,sys; print(os.path.relpath(os.path.abspath('/home/ahnaf/sm8650-modules' + '$tgt'.split('sm8650-modules')[1]), os.path.dirname(os.path.abspath('$l'))))")
  ln -sfn "$newtgt" "$l"
done
```

Re-running `make clone` in the build repo recreates the correct layout.

## 5. GCC-built Image breaks KMI — vendor modules won't load (bootloop)

### Symptoms

- Build succeeds with `aarch64-linux-gnu-gcc` (cross GCC), device flashes
  fine, then **bootloops silently** or drops to fastboot.
- `dmesg`/pstore on a non-booting device (via `fastboot oem`/recovery logs)
  shows `module: invalid module format`, CRC mismatch on `module_layout`,
  or `Unknown symbol in module` for boot-critical `.ko`
  (`qcom-scm`, `ufs_qcom`, `clk-qcom`, `pinctrl-*`).

### Cause

GKI 6.1 (android14-6.1) KMI is defined against the official **Clang/LLVM
toolchain** (`CLANG_VERSION` in `build.config.common`, e.g. `r487747c`).
Vendor `.ko` modules in the device's `vendor_boot`/`vendor_dlkm` partitions
were built with that clang. A GCC-built core kernel differs in struct
padding, symbol CRCs, and codegen → module ABI mismatch → modules rejected
→ bootloop. `CONFIG_CC_IS_CLANG` in `.config` tells you which compiler was
used.

### Fix

Build with Clang + full LLVM tooling — NOT cross GCC:

```bash
make O="$OUT" ARCH=arm64 LLVM=1 LLVM_IAS=1 -j6 Image dtbs
```

- `LLVM=1` → clang, ld.lld, llvm-ar, llvm-nm, llvm-objcopy, llvm-strip
- `LLVM_IAS=1` → clang integrated assembler (default on 6.1+ but pass it
  explicitly)
- Host clang newer than the official `r487747c` is fine (verified: host
  clang builds a bootable android14-6.1 Image on waffle).

Verify BEFORE flashing:

```bash
grep CONFIG_CC_IS_CLANG "$OUT/.config"      # CONFIG_CC_IS_CLANG=y  (required)
grep CONFIG_CC_VERSION_TEXT "$OUT/.config"  # must contain "clang"
grep CONFIG_LD_IS_LLD "$OUT/.config"        # CONFIG_LD_IS_LLD=y    (required)
```

If `CONFIG_CC_IS_CLANG` is missing and `CONFIG_CC_IS_GCC=y` — stop, rebuild
with `LLVM=1`. Do not waste a flash cycle on a GCC Image.

## 6. Boot partition / header v4 packaging (AnyKernel3)

### Symptoms

- `fastboot flash boot` of a raw Image errors or boots to nothing.
- Kernel boots but the DTB from the Image is ignored (GKI does not append
  DTB — see §7).
- AnyKernel zip flashes but device bootloops although the same Image boots
  via direct `fastboot boot`.

### Cause

Android 13+ / kernel 5.10+ devices (waffle included) use **boot image
header v4**:

- `boot` partition holds the kernel **Image only** (gzipped generic
  ramdisk moved to `init_boot`).
- Kernel cmdline and vendor ramdisk live in `vendor_boot` (header v4).
- DTB is NOT concatenated to the kernel — it lives in dtbo/base-DTB
  partitions and is applied by the bootloader.
- waffle is an **A/B slot device** — flashing goes to the current slot;
  AnyKernel3 needs `IS_SLOT_DEVICE=1`.

### Fix

AnyKernel3 packaging (repo at `/home/ahnaf/AnyKernel3`):

```bash
# anykernel3.sh must have:
#   IS_SLOT_DEVICE=1
#   do.modules=0          # NEVER replace vendor modules; stock vendor_boot/
#                          # vendor_dlkm modules load against your Image
#   block=auto:/dev/block/bootdevice/by-name/boot$slot
```

Flashable zip build:

```bash
cp "$OUT/arch/arm64/boot/Image" /home/ahnaf/AnyKernel3/Image
cd /home/ahnaf/AnyKernel3 && zip -r9 ../helios-waffle-$(date +%Y%m%d).zip * -x .git README.md
adb reboot bootloader   # or recovery sideload
fastboot flash boot helios-waffle-*.zip  # recovery: adb sideload <zip>
```

Direct fastboot path (header v4 wrapping happens on device when flashing
the raw Image to the boot partition on A/B GKI devices — verify with
`fastboot boot` first):

```bash
fastboot flash boot "$OUT/arch/arm64/boot/Image"
fastboot reboot
```

Keep `do.modules=0` unless you also rebuilt and re-pack the entire module
set with the same clang — KMI-compatible stock modules are the safe path.

## 7. dtbo mismatch after DTB changes (hang at splash)

### Symptoms

- Device hangs at the OnePlus splash / bootloader logo, never reaches
  `init`. `fastboot boot` of the Image also fails when DTBs mismatch.
- Happens exactly when the base DTB (anorak/pineapple DTS) was changed but
  the dtbo partition was not updated.

### Cause

SM8650 GKI builds DT overlays (`DT_OVERLAY_SUPPORT=1`): the bootloader
applies the dtbo partition's overlays onto the base DTB. If your build
changed the base DTB but the device keeps the stock dtbo, the overlay
application fails or produces an inconsistent tree → early boot hang.

### Fix

- **Base DTB unchanged from stock** (normal Helios build, no DTS edits):
  do NOT flash dtbo — the stock dtbo partition is correct.
- **Base DTB changed** (DTS edits in `/home/ahnaf/waffle-device-tree`):
  build and flash the matching dtbo:

```bash
make O="$OUT" ARCH=arm64 dtbs
"$OUT"/scripts/dtc/dtc -@ -I dts -O dtb ...  # or use the build's dtbo.img:
# dtbo.img from build: mkdtboimg create --page_size=4096 "$OUT"/arch/arm64/boot/dts/*.dtbo
fastboot flash dtbo dtbo.img
```

Flash order when DTB changed: `fastboot flash dtbo dtbo.img && fastboot
flash boot Image && fastboot reboot`.

## 8. Battery/size optimizations that broke nothing (safe set)

Verified-safe config changes applied on Helios (re-check after re-clone
via `make config`):

```
CONFIG_CC_OPTIMIZE_FOR_SIZE=y
# CONFIG_DEBUG_INFO is not set
# CONFIG_DEBUG_FS is not set
# CONFIG_DEBUG_KERNEL is not set
# CONFIG_DEBUG_INFO_BTF is not set
```

These are KMI-safe (no exported symbol/struct changes), reduce Image size
and build time, and avoid all host-GCC-14 debug tooling failures (§1, §2).

## Quick triage index

| Symptom | Section |
|---------|---------|
| `key_pass undeclared` in certs/extract-cert.c | §1 |
| libbpf/resolve_btfids `-Werror` build stop | §2 |
| `source tree is not clean` / .config in src | §3 |
| No rule to make target oplus driver / dangling symlinks | §4 |
| Compiles+flashes, bootloops; `invalid module format` | §5 |
| Zip boots wrong slot / modules wiped by AnyKernel | §6 |
| Hang at splash after DTS edits | §7 |
