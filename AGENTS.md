# AGENTS.md - Kilo Code

Project-wide instructions read by Kilo Code every session.

## Project: Helios-Kernel for OnePlus 12

Custom arm64 Android kernel for OnePlus 12 (codename: `waffle`, platform: `pineapple`, board: `anorak`, SoC: Snapdragon 8 Gen 3 / SM8650). Models: CPH2573, CPH2581, CPH2583, PJD110.

**Kernel:** 6.1 GKI, LineageOS `lineage-23.2` branch (Android 16) — https://github.com/LineageOS/android_kernel_oneplus_sm8650

**Build Output:** `/home/ahnaf/helios-kernel-out/arch/arm64/boot/Image` and DTBs.

### Build Flow

```bash
make setup   # Install CachyOS/Arch build packages (needs sudo)
make env     # Check compilers and device config
make clone   # Clone KERNEL_REPO into src/kernel at KERNEL_REF
make config  # Run defconfig into out/
make build   # Build Image + dtbs (default JOBS=2; host has ~7 GiB RAM)
make clean   # Remove out/
```

Manual equivalent (always use `O=`): `gki_defconfig` -> merge `arch/arm64/configs/vendor/pineapple_GKI.config` -> apply battery opts -> `olddefconfig` -> `make -j6 Image dtbs O=/home/ahnaf/helios-kernel-out`.

### Build Notes

- Host: CachyOS Linux 7.2.2-1, 12 threads, 7.1 GiB RAM
- Cross-compiler: `aarch64-linux-gnu-` (installed via `make setup`)
- Kernel source at: `/home/ahnaf/helios-kernel-src`
- Output at: `/home/ahnaf/helios-kernel-out` (always build out-of-tree with `O=`)
- Companion modules repo required at: `/home/ahnaf/sm8650-modules` (kernel symlinks depend on it: `../../sm8650-modules`)
- `CONFIG_DEBUG_INFO_BTF` must stay disabled (host GCC 16.1.0 / CachyOS)
- `certs/extract-cert.c` has a local `key_pass` OpenSSL fix (re-apply after re-clone)
- Use `JOBS=4` (or `-j6`) for parallel builds

### Configuration

- Edit `config/device.env` — device name, codename, SoC, kernel git URL, branch, and defconfig.
- Current: OnePlus 12 (`waffle`), SM8650, LineageOS sm8650 kernel (lineage-23.2), gki_defconfig + `vendor/pineapple_GKI.config`.
- Battery optimizations applied: `CC_OPTIMIZE_FOR_SIZE=y`; `DEBUG_INFO`, `DEBUG_FS`, `DEBUG_KERNEL`, `DEBUG_INFO_BTF` disabled.

### Directory Layout

| Path | Description |
|------|-------------|
| `Makefile` | Top-level build orchestration |
| `config/device.env` | Per-device configuration (gitignored) |
| `scripts/check-env.sh` | Verifies required build tools |
| `scripts/setup-cachyos.sh` | Installs packages on CachyOS/Arch |
| `/home/ahnaf/helios-kernel-src/` | Kernel source tree (lineage-23.2) |
| `/home/ahnaf/helios-kernel-out/` | Build output (gitignored) |
| `/home/ahnaf/sm8650-modules/` | Required companion modules repo |
| `/home/ahnaf/waffle-device-tree/` | Device trees (anorak base + waffle overlays in `oplus/`) |
| `/home/ahnaf/proprietary_vendor_oneplus_sm8650-common/` | Vendor blobs (TheMuppets, lineage-23.2) |
| `/home/ahnaf/proprietary_vendor_oneplus_waffle/` | Vendor blobs (TheMuppets, lineage-23.2) |
| `/home/ahnaf/AnyKernel3/` | Flashable zip builder (`IS_SLOT_DEVICE=1`, A/B slots) |
| `.kilo/` | Kilo Code project config |
