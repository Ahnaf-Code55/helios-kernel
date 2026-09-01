#!/usr/bin/env bash
#
# Helios-Kernel v1.1 release packaging script
# Packages the built kernel Image + dtbo.img into the AnyKernel3
# flashable zip for OnePlus 12 (waffle, SM8650).
#
set -euo pipefail

KERNEL_IMAGE="/home/ahnaf/helios-kernel-out/arch/arm64/boot/Image"
DTBO_IMG="/home/ahnaf/dtbo.img"
AK3_DIR="/home/ahnaf/AnyKernel3"
ZIP_OUT="/home/ahnaf/Helios-Kernel-v1.1-waffle.zip"

echo "==> Helios-Kernel v1.1 (waffle) packaging"

# --- Verify inputs -----------------------------------------------------------
if [[ ! -f "$KERNEL_IMAGE" ]]; then
    echo "ERROR: kernel Image not found at: $KERNEL_IMAGE" >&2
    exit 1
fi
if [[ ! -f "$DTBO_IMG" ]]; then
    echo "ERROR: dtbo.img not found at: $DTBO_IMG" >&2
    exit 1
fi
if [[ ! -d "$AK3_DIR" ]]; then
    echo "ERROR: AnyKernel3 directory not found at: $AK3_DIR" >&2
    exit 1
fi
if [[ ! -f "${AK3_DIR}/anykernel.sh" ]]; then
    echo "ERROR: ${AK3_DIR}/anykernel.sh missing — is this a valid AnyKernel3 tree?" >&2
    exit 1
fi

# --- Copy artifacts into AnyKernel3 ------------------------------------------
echo "==> Copying Image -> ${AK3_DIR}/Image"
cp -f "$KERNEL_IMAGE" "${AK3_DIR}/Image"

echo "==> Copying dtbo.img -> ${AK3_DIR}/dtbo.img (flashed by AK3 if configured)"
cp -f "$DTBO_IMG" "${AK3_DIR}/dtbo.img"

# --- Build the flashable zip --------------------------------------------------
echo "==> Creating ${ZIP_OUT}"
if [[ -f "$ZIP_OUT" ]]; then
    rm -f "$ZIP_OUT"
fi

(
    cd "$AK3_DIR"
    zip -r9 "$ZIP_OUT" \
        anykernel.sh META-INF tools Image dtbo.img ramdisk patch modules \
        -x "*.git*"
)

# --- Checksum ----------------------------------------------------------------
echo "==> Done. SHA-256:"
sha256sum "$ZIP_OUT"
