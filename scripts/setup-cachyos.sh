#!/usr/bin/env bash
set -euo pipefail

# CachyOS / Arch packages needed to cross-build an arm64 Android kernel.
packages=(
  aarch64-linux-gnu-gcc
  aarch64-linux-gnu-binutils
  bc
  clang
  llvm
  lld
  bison
  flex
  dtc
  pahole
  openssl
  elfutils
  ncurses
  cpio
  kmod
  xmlto
  python
  perl
  git
  make
  rsync
)

echo "Installing: ${packages[*]}"
sudo pacman -S --needed --noconfirm "${packages[@]}"
echo
echo "Installed. Next: fill config/device.env, then we clone the matching kernel tree."
