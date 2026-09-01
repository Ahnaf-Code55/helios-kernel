# Helios-Kernel build orchestration — OnePlus 12 (waffle / SM8650 / pineapple)
#
# GOTCHAS (read before touching anything):
# - Never build in-tree (no O=): the source tree must stay clean, else
#   the build fails with "source tree is not clean".
# - merge_config.sh without -O writes an in-tree .config that trips the clean
#   check: this Makefile always passes -O $(OUT). If a stray .config appears
#   in $(SRC) anyway, run `rm -f $(SRC)/.config`.
# - CONFIG_DEBUG_INFO_BTF MUST stay disabled: host GCC 16.1.0 fails building
#   tools/bpf/resolve_btfids (libbpf).
# - certs/extract-cert.c needs a local key_pass OpenSSL fix (re-apply after re-clone).
# - Modified files in $(SRC) (dts merge, key_pass fix) are intentional
#   uncommitted state: never `git checkout -- .` in the kernel tree.
# - Host has ~7 GiB RAM: default JOBS=6 works, but watch for OOM. Do not go higher.
#
# Full flow: make setup -> make env -> make clone -> make config -> make build
#            -> make dtbo -> make zip

ifneq (,$(wildcard config/device.env))
include config/device.env
endif

ARCH ?= arm64
CROSS_COMPILE ?= aarch64-linux-gnu-
JOBS ?= 6
KERNEL_IMAGE = $(OUT)/arch/arm64/boot/Image

.PHONY: help env setup clone config build dtbo zip clean

help:
	@echo "Helios-Kernel workspace — $(DEVICE_NAME) ($(DEVICE_CODENAME), $(SOC_CHIPSET))"
	@echo
	@echo "  make setup   Install CachyOS/Arch build packages (needs sudo)"
	@echo "  make env     Check compilers and device config"
	@echo "  make clone   Clone/update kernel + modules + devicetrees + vendor blobs"
	@echo "  make config  gki_defconfig + merge pineapple_GKI + battery opts + olddefconfig"
	@echo "  make build   Build Image + dtbs (JOBS=$(JOBS))"
	@echo "  make dtbo    Build DTBO via scripts/build-dtbo.sh"
	@echo "  make zip     Package AnyKernel3 flashable zip (Image copy + zip)"
	@echo "  make clean   Remove $(OUT)"
	@echo
	@echo "Battery opts: CC_OPTIMIZE_FOR_SIZE=y; DEBUG_INFO, DEBUG_FS, DEBUG_KERNEL,"
	@echo "DEBUG_INFO_BTF all disabled (BTF is mandatory-off: host GCC 16.1.0 breaks on libbpf)."
	@echo "Never build in-tree: always uses O=$(OUT)."

env:
	@bash scripts/check-env.sh

setup:
	@bash scripts/setup-cachyos.sh

# ---- clone / update sources ----------------------------------------------
# clone_one DIR URL REF: shallow-clone if missing, else fetch+checkout REF.
define clone_one
	@if [ -d "$(1)/.git" ]; then \
		git -C "$(1)" fetch --depth=1 origin "$(3)"; \
		git -C "$(1)" checkout --force FETCH_HEAD; \
	else \
		mkdir -p "$(1)"; \
		git clone --depth=1 --branch "$(3)" "$(2)" "$(1)"; \
	fi
endef

clone:
	@test -n "$(KERNEL_REPO)" || (echo "Set KERNEL_REPO in config/device.env" && exit 1)
	@test -n "$(KERNEL_REF)" || (echo "Set KERNEL_REF in config/device.env" && exit 1)
	@test -n "$(MODULES_REPO)" || (echo "Set MODULES_REPO in config/device.env" && exit 1)
	$(call clone_one,$(SRC),$(KERNEL_REPO),$(KERNEL_REF))
	$(call clone_one,$(MODULES_DIR),$(MODULES_REPO),$(KERNEL_REF))
	$(call clone_one,$(VENDOR_COMMON_DIR),$(VENDOR_COMMON_REPO),$(KERNEL_REF))
	$(call clone_one,$(VENDOR_DEVICE_DIR),$(VENDOR_DEVICE_REPO),$(KERNEL_REF))
	@echo "Devicetrees repo is already merged into $(SRC) (arch/arm64/boot/dts/qcom + oplus)."
	@echo "If re-cloning the kernel from scratch, re-merge:"
	@echo "  $(DEVICETREE_REPO)"

# ---- config -----------------------------------------------------------------
# 1. gki_defconfig into OUT (out-of-tree)
# 2. merge pineapple_GKI.config (with -O $(OUT): without it merge_config.sh
#    writes an in-tree .config, which trips the "source tree is not clean" check)
# 3. battery optimizations (size + no debug/BTF)
# 4. olddefconfig
# NOTE: modified files in the src tree (dts merge, certs key_pass fix) are
# intentional uncommitted state - never run `git checkout -- .` there.
config: env
	@test -n "$(VENDOR_CONFIG)" || (echo "Set VENDOR_CONFIG in config/device.env" && exit 1)
	@mkdir -p "$(OUT)"
	$(MAKE) -C "$(SRC)" O="$(OUT)" ARCH="$(ARCH)" CROSS_COMPILE="$(CROSS_COMPILE)" $(DEFCONFIG)
	cd "$(SRC)" && ./scripts/kconfig/merge_config.sh -m -O "$(OUT)" "$(OUT)/.config" "$(VENDOR_CONFIG)"
	@rm -f "$(SRC)/.config"
	cd "$(SRC)" && scripts/config --file "$(OUT)/.config" \
		--enable CONFIG_CC_OPTIMIZE_FOR_SIZE \
		--disable CONFIG_DEBUG_INFO \
		--disable CONFIG_DEBUG_INFO_BTF \
		--disable CONFIG_DEBUG_FS \
		--disable CONFIG_DEBUG_KERNEL
	$(MAKE) -C "$(SRC)" O="$(OUT)" ARCH="$(ARCH)" CROSS_COMPILE="$(CROSS_COMPILE)" olddefconfig
	@grep -q '^# CONFIG_DEBUG_INFO_BTF is not set' "$(OUT)/.config" || \
		(echo "ERROR: CONFIG_DEBUG_INFO_BTF got re-enabled; host GCC 16.1.0 will fail." && exit 1)

# ---- build ------------------------------------------------------------------
build: config
	$(MAKE) -C "$(SRC)" O="$(OUT)" ARCH="$(ARCH)" CROSS_COMPILE="$(CROSS_COMPILE)" -j$(JOBS) Image dtbs
	@test -f "$(KERNEL_IMAGE)" && echo "Built: $(KERNEL_IMAGE)"

dtbo:
	@bash scripts/build-dtbo.sh

# ---- package ----------------------------------------------------------------
# Placeholder packaging: copy Image into AnyKernel3 and zip it up.
ZIP_NAME = Helios-$(DEVICE_CODENAME)-$(shell date +%Y%m%d).zip
zip:
	@test -f "$(KERNEL_IMAGE)" || (echo "No Image at $(KERNEL_IMAGE); run 'make build' first." && exit 1)
	@test -d "$(ANYKERNEL_DIR)" || (echo "Missing $(ANYKERNEL_DIR)" && exit 1)
	cp "$(KERNEL_IMAGE)" "$(ANYKERNEL_DIR)/Image"
	cd "$(ANYKERNEL_DIR)" && zip -r9q $(ZIP_NAME) . -x ".git" -x ".git/*" -x "README.md" -x "patches/*"
	@echo "Flashable zip: $(ANYKERNEL_DIR)/$(ZIP_NAME)"

clean:
	rm -rf "$(OUT)"
