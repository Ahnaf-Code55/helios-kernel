# AGENTS.md - Kilo Code

Project-wide instructions read by Kilo Code every session.

## Project: Helios-Kernel for OnePlus 12

Custom arm64 Android kernel for OnePlus 12 (codename: `duchamp`, SoC: Snapdragon 8 Gen 3 / SM8550).

**Kernel Source:** LineageOS Qualcomm SM8550 (lineage-21) — clean base kernel without proprietary OPLUS code.

**Build Output:** `/home/ahnaf/helios-kernel-out/arch/arm64/boot/Image` (~38MB) and DTBs.

### Build Flow

```bash
make setup   # Install CachyOS/Arch build packages (needs sudo)
make env     # Check compilers and device config
make clone   # Clone KERNEL_REPO into src/kernel at KERNEL_REF
make config  # Run defconfig into out/
make build   # Build Image + dtbs (default JOBS=2; host has ~7 GiB RAM)
make clean   # Remove out/
```

### Build Notes

- Host: CachyOS Linux 7.2.2-1, 12 threads, 7.1 GiB RAM
- Cross-compiler: `aarch64-linux-gnu-` (installed via `make setup`)
- Kernel source at: `/home/ahnaf/helios-kernel-src`
- Output at: `/home/ahnaf/helios-kernel-out`
- Use `JOBS=4` for parallel builds

### Configuration

- Edit `config/device.env` — device name, codename, SoC, kernel git URL, branch, and defconfig.
- Current: OnePlus 12 (`duchamp`), SM8550, Qualcomm SM8550 kernel (lineage-21).

### Directory Layout

| Path | Description |
|------|-------------|
| `Makefile` | Top-level build orchestration |
| `config/device.env` | Per-device configuration (gitignored) |
| `scripts/check-env.sh` | Verifies required build tools |
| `scripts/setup-cachyos.sh` | Installs packages on CachyOS/Arch |
| `helios-kernel-src/` | Kernel source tree |
| `helios-kernel-out/` | Build output (gitignored) |
| `.kilo/` | Kilo Code project config |
