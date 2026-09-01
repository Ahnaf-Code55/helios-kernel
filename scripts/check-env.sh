#!/usr/bin/env bash
set -euo pipefail

ok=0
fail=0

check() {
  local name="$1"
  shift
  if "$@" >/dev/null 2>&1; then
    printf '  OK   %s\n' "$name"
    ok=$((ok + 1))
  else
    printf '  MISS %s\n' "$name"
    fail=$((fail + 1))
  fi
}

echo "Host: $(uname -sr)"
echo "CPU threads: $(nproc)"
echo "RAM: $(awk '/MemTotal/ { printf "%.1f GiB", $2/1024/1024 }' /proc/meminfo)"
echo
echo "Build tools:"
check "clang" command -v clang
check "lld" command -v lld
check "llvm-strip" command -v llvm-strip
check "make" command -v make
check "git" command -v git
check "python3" command -v python3
check "bison" command -v bison
check "flex" command -v flex
check "dtc" command -v dtc
check "pahole" command -v pahole
check "bc" command -v bc
check "aarch64-linux-gnu-gcc" command -v aarch64-linux-gnu-gcc
check "aarch64-linux-gnu-ld" command -v aarch64-linux-gnu-ld

echo
if [[ -f config/device.env ]]; then
  # shellcheck disable=SC1091
  source config/device.env
  echo "Device config:"
  printf '  name     %s\n' "${DEVICE_NAME:-unset}"
  printf '  codename %s\n' "${DEVICE_CODENAME:-unset}"
  printf '  soc      %s %s\n' "${SOC_VENDOR:-unset}" "${SOC_CHIPSET:-unset}"
  printf '  repo     %s\n' "${KERNEL_REPO:-unset}"
  printf '  defconfig %s\n' "${DEFCONFIG:-unset}"
else
  echo "Device config: missing (copy config/device.env.example -> config/device.env)"
  fail=$((fail + 1))
fi

echo
echo "Summary: $ok ok, $fail missing"
if (( fail > 0 )); then
  echo "Run: bash scripts/setup-cachyos.sh"
  exit 1
fi
