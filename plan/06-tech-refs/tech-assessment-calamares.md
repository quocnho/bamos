# Technology Assessment: Calamares Unified Installer

**Date:** 2026-07-07
**Status:** Draft — chờ xác nhận

## Hiện trạng

| Khía cạnh | Hiện tại (12 ISOs) | Mục tiêu (Unified) |
|-----------|-------------------|-------------------|
| Số lượng ISO | 12 (3 DE × 4 Edition) | **3** (1 ISO/DE, chọn edition khi install) |
| Chọn Edition | Build-time (mỗi ISO 1 edition) | **Install-time** (Calamares wizard) |
| Chọn Machine Type | Không có | **Laptop/Desktop/Server** → auto power profile |
| Hardware detect | Script chạy sau install | **Tích hợp trong Calamares** (pre-install scan) |

## Kiến trúc đề xuất

```
Calamares Installation Flow:
┌─────────────────────────────────────────────────────────────┐
│ 1. Chọn ngôn ngữ + timezone    (Calamares built-in)        │
├─────────────────────────────────────────────────────────────┤
│ 2. Partition disk              (Calamares partition)        │
│    └─ Btrfs Ổ C — Ổ D (luôn có)                           │
├─────────────────────────────────────────────────────────────┤
│ 3. Chọn Edition                (CUSTOM: bamos-edition)      │
│    ├─ Standard  → desktop profile + apps                   │
│    ├─ Developers → desktop + dev tools + containers        │
│    ├─ Gaming    → desktop + gaming stack + GameMode        │
│    └─ Studio    → desktop + creative apps + low-latency    │
├─────────────────────────────────────────────────────────────┤
│ 4. Chọn Machine Type           (CUSTOM: bamos-machine)     │
│    ├─ Laptop   → batteryOptimized=true, tuned laptop profile│
│    ├─ Desktop  → batteryOptimized=false, tuned desktop      │
│    └─ Server   → tuned throughput-performance, no GUI       │
├─────────────────────────────────────────────────────────────┤
│ 5. Tạo user + hostname          (Calamares nixospage)      │
├─────────────────────────────────────────────────────────────┤
│ 6. Hardware detection           (CUSTOM: bamos-detect)     │
│    ├─ lspci → GPU (NVIDIA/AMD/Intel)                       │
│    ├─ dmidecode → machine type cross-check                 │
│    └─ Sinh /etc/bamos/hardware-configuration.nix           │
├─────────────────────────────────────────────────────────────┤
│ 7. Generate /etc/nixos/ + install  (calamares-nixos)        │
└─────────────────────────────────────────────────────────────┘
```

## NixOS Calamares modules available

| Module | Chức năng | Trạng thái |
|--------|-----------|-----------|
| `partition` | Disk partitioning (EFI + Btrfs) | ✅ Đã override |
| `mount` | Mount config (subvolumes) | ✅ Đã override |
| `nixos` | Run nixos-install with generated config | ✅ Built-in |
| `nixospage` | User/hostname/desktop config | ✅ Built-in |
| `finished` | Post-install actions | ✅ Built-in |
| **`bamos-edition`** | Edition selector + machine type | ❌ Cần tạo |
| **`bamos-detect`** | Hardware scan + hardware.nix | ❌ Cần tạo |

## Công nghệ cần research

1. **Calamares Python modules**: Calamares supports custom Python modules (`.py` + `module.desc`)
2. **calamares-nixos-extensions**: How to add custom pages to the Calamares wizard
3. **GLF-OS approach**: How they pass edition selection to nixos-install
4. **NixOS config generation**: How to safely generate `/etc/nixos/*.nix` from user selections

## Risks

| Risk | Impact | Mitigation |
|------|--------|-----------|
| Calamares Python API changes | Cao | Pin calamares version |
| nixos-install không hỗ trợ dynamic config | Cao | Cần GLF-OS pattern |
| Tăng ISO size do include all editions | Trung bình | Dùng layers/cache |
| User selection phức tạp | Thấp | Wizard UX tối giản |
