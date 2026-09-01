# Helios-Kernel v1.2 Release Notes

**Device:** OnePlus 12 (waffle) | **SoC:** Snapdragon 8 Gen 3 (SM8650)
**Developer:** Ahnaf Hossain

---

## What's New in v1.2

This release adds memory management improvements and storage latency reductions on top of v1.1.

### Networking

**TCP congestion type changed from CUBIC to BBR.** BBR handles mobile networks and 5G connections better than CUBIC. Latency is lower on variable network conditions.

### Memory

**KSM (Kernel Samepage Merging) is now enabled.** KSM scans memory for identical pages and merges them into a single writable page. This reduces RAM usage across apps with similar memory content.

**ZRAM writeback is enabled.** When memory gets tight, ZRAM writes dormant pages to storage instead of dropping them. This keeps more pages compressed in RAM rather than evicting them.

**ZSWAP is enabled.** ZSWAP creates a compressed cache layer before swap. Pages compress before reaching swap storage, which reduces wear on UFS and improves swap performance.

**ZRAM now uses multiple compression streams.** Cold pages compress using multiple CPU threads in parallel. Throughput is higher than single-threaded compression.

### Storage

**MQ-Deadline I/O scheduler replaces the default.** MQ-Deadline gives read requests priority over writes and processes them in batches. This lowers read latency on storage operations.

### Responsiveness

**RCU_BOOST_DELAY lowered from 500ms to 250ms.** RCU_BOOST_DELAY controls how long the kernel waits before boosting delayed task priority. Cutting it in half improves wakeup latency for background tasks.

### Build

**Debug options removed:** DEBUG_MISC, PM_SLEEP_DEBUG, SLUB_DEBUG. These were already minimal. Removing them further shrinks the kernel footprint and eliminates a small amount of overhead.

---

## Downloads

**Source:** https://github.com/Ahnaf-Code55/helios-kernel

**XDA Thread:** https://xdaforums.com/t/kernel-helios-kernel-v1-1-oneplus-12-snapdragon-8-gen-3-sm8650.4800289/

**Telegram:** @helios_kernel

---

## Notes

Build output location: `/home/ahnaf/helios-kernel-out/arch/arm64/boot/Image`

The kernel uses the LineageOS lineage-23.2 branch (Android 16) as its base.

Compile with `make -j6 Image dtbs O=/home/ahnaf/helios-kernel-out` after running `make setup` and `make config`.

Companion modules repo required at `/home/ahnaf/sm8650-modules`.
