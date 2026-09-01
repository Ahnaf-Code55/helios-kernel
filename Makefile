# Custom Android / arm64 kernel workspace.
# Do not pass -j here; this host has ~7 GiB RAM. Start with -j2 or -j4.

ARCH ?= arm64
CROSS_COMPILE ?= aarch64-linux-gnu-
OUT ?= /home/ahnaf/helios-kernel-out
SRC ?= /home/ahnaf/helios-kernel-src
JOBS ?= 2

ifneq (,$(wildcard config/device.env))
include config/device.env
endif

.PHONY: help env setup clone config build clean

help:
	@echo "Custom mobile kernel workspace"
	@echo
	@echo "  make env     Check compilers and device config"
	@echo "  make setup   Install CachyOS packages (needs sudo)"
	@echo "  make clone   Clone KERNEL_REPO into src/kernel"
	@echo "  make config  Run defconfig into out/"
	@echo "  make build   Build Image (JOBS=$(JOBS))"
	@echo "  make clean   Remove out/"
	@echo
	@echo "Fill config/device.env before clone/config/build."

env:
	@bash scripts/check-env.sh

setup:
	@bash scripts/setup-cachyos.sh

clone:
	@test -n "$(KERNEL_REPO)" || (echo "Set KERNEL_REPO in config/device.env" && exit 1)
	@test -n "$(KERNEL_REF)" || (echo "Set KERNEL_REF in config/device.env" && exit 1)
	@mkdir -p "$(SRC)"
	@if [ -d "$(SRC)/.git" ]; then \
		git -C "$(SRC)" fetch --depth=1 origin "$(KERNEL_REF)"; \
		git -C "$(SRC)" checkout --force FETCH_HEAD; \
	else \
		git clone --depth=1 --branch "$(KERNEL_REF)" "$(KERNEL_REPO)" "$(SRC)"; \
	fi

config: env
	@test -n "$(DEFCONFIG)" || (echo "Set DEFCONFIG in config/device.env" && exit 1)
	@mkdir -p "$(OUT)"
	$(MAKE) -C "$(SRC)" O="$(OUT)" ARCH="$(ARCH)" CROSS_COMPILE="$(CROSS_COMPILE)" $(DEFCONFIG)

build: config
	$(MAKE) -C "$(SRC)" O="$(OUT)" ARCH="$(ARCH)" CROSS_COMPILE="$(CROSS_COMPILE)" -j$(JOBS) Image dtbs

clean:
	rm -rf "$(OUT)"
