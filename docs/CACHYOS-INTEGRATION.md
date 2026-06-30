# BamOS CachyOS Integration Guide
#
# BamOS uses CachyOS performance tuning WITHOUT replacing the uBlue kernel.
# This gives us:
#   - CachyOS-optimized CPU scheduling (scx_bpfland)
#   - CachyOS-optimized IO scheduling (bfq/kyber/none per device)
#   - CachyOS-optimized kernel parameters (preempt, THP, zswap)
#   - uBlue/akmods stable kernel modules (NVIDIA, xone, xpadneo, etc.)
#
# =============================================================================
# Architecture Decision
# =============================================================================
#
# RakuOS approach: Replace kernel entirely with kernel-cachyos + DKMS drivers
#   Pros: Full CachyOS kernel optimizations (BORE scheduler, LTO, etc.)
#   Cons: DKMS must rebuild on every kernel update, fragile, heavy build
#
# BamOS approach: uBlue kernel + CachyOS userspace tuning
#   Pros: Stable akmods ecosystem, pre-built modules, reliable updates
#   Cons: Missing in-kernel CachyOS patches (BORE, LTO, etc.)
#
# This is the optimal balance for Vietnamese users who need:
#   1. Stable NVIDIA/GPU drivers (uBlue akmods)
#   2. Stable printer drivers
#   3. Stable USB token/digital signature support
#   4. Desktop responsiveness improvements
#
# =============================================================================
# Components Applied
# =============================================================================
#
# 1. cachyos-settings       → Kernel cmdline, sysctl, udev rules
# 2. cachyos-ananicy-rules  → Process priority rules for desktop apps
# 3. scx-scheds + scx-tools → BPF CPU schedulers (scx_bpfland default)
# 4. ananicy-cpp            → Auto-nice daemon for foreground apps
# 5. bore-sysctl             → BORE scheduler sysctl tweaks
# 6. IO scheduler rules      → Per-device scheduler selection
# 7. BBR TCP                 → Network congestion control
#
# =============================================================================
# How to switch CPU schedulers
# =============================================================================
#
# scx_bpfland  (default) → Balanced interactive + throughput
# scx_lavd      → Gaming/low-latency
# scx_rusty     → Server-oriented
#
# Change: sudo systemctl edit scx.service
#   ExecStart=/usr/bin/scx_lavd
