# Kiến trúc BamOS

## Tổng quan

BamOS là bản phân phối NixOS immutable dành cho cộng đồng Việt Nam, được tổ chức theo chuẩn flake-parts + NixOS module system.

```
┌─────────────────────────────────────────────────────────┐
│                    BamOS Distro                          │
├─────────────────────────────────────────────────────────┤
│  Layer 1: flake.nix (Entry Point)                       │
│  - flake-parts mkFlake                                  │
│  - Systems: x86_64-linux                                │
│  - Imports: hosts/, pkgs/, modules/                     │
├─────────────────────────────────────────────────────────┤
│  Layer 2: Hosts (nixosConfigurations)                   │
│  - hosts/iso/*        → ISO builds (12 variants)        │
│  - hosts/lg/*         → Developer workstation           │
│  - hosts/vm/*         → Test VMs                        │
├─────────────────────────────────────────────────────────┤
│  Layer 3: Profiles (Edition × DE)                       │
│  - profiles/*.nix    → 12 combos (3 DE × 4 Editions)   │
│  Mỗi profile = core + DE + edition + apps               │
├─────────────────────────────────────────────────────────┤
│  Layer 4: Modules (Shared Config)                       │
│  - modules/core/*    → System, locale, audio, input...  │
│  - modules/desktop/* → GNOME, KDE, COSMIC configs       │
│  - modules/editions/* → Standard, Dev, Gaming, Studio   │
│  - modules/apps/*    → Per-edition app sets             │
├─────────────────────────────────────────────────────────┤
│  Layer 5: Packages & Overlays                           │
│  - pkgs/*            → Custom Nix packages              │
│  - overlays/*        → Nixpkgs overlays                 │
└─────────────────────────────────────────────────────────┘
```

## Layers chi tiết

### Layer 1: flake.nix

Entry point sử dụng flake-parts, khai báo:
- **inputs**: nixpkgs (unstable), flake-parts, disko
- **imports**: `./hosts` (flake-parts module)
- **perSystem**: packages (12 ISOs), formatter, devShells
- **nixosConfigurations**: hosts/lg, hosts/iso/*, hosts/vm

### Layer 2: Hosts

Mỗi host là một nixosConfiguration hoàn chỉnh:
- **ISO hosts**: Build ISO với nixos-generators + disko
- **lg**: Developer workstation với VM tools, secret management (agenix), home-manager
- **vm**: Test VM cho CI/CD

### Layer 3: Profiles

12 profiles = 3 DE × 4 Editions:

| DE → | GNOME | KDE | COSMIC |
|------|-------|-----|--------|
| **Standard** | gnome-standard | kde-standard | cosmic-standard |
| **Developers** | gnome-developers | kde-developers | cosmic-developers |
| **Gaming** | gnome-gaming | kde-gaming | cosmic-gaming |
| **Studio** | gnome-studio | kde-studio | cosmic-studio |

### Layer 4: Modules

Modules được chia thành các nhóm:
- **core/**: Bắt buộc cho mọi edition (system, locale, audio, input-method, security, optimization)
- **desktop/**: Cấu hình DE cụ thể (GNOME, KDE, COSMIC)
- **editions/**: Cấu hình edition (standard, developers, gaming, studio)
- **apps/**: Danh sách ứng dụng theo edition
- **hardware/**: Hỗ trợ hardware (NVIDIA, AMD, Intel)
- **theming/**: BamOS branding và themes

### Layer 5: Packages

Custom packages được đặt trong `pkgs/`:
- Hiện tại: aggregator, sẵn sàng cho bamos-tools, bamos-portal

## Luồng Build

```
flake.nix
  → hosts/default.nix (flake-parts module)
    → mkHost for each host
      → lib/mkEdition.nix
        → profiles/<de>-<edition>.nix
          → modules/default.nix (aggregator)
            → core/*, desktop/*, editions/*, apps/*
      → ISO: lib/mkISO.nix → nixos-generators
```

## Kernel Strategy

| Kernel | Dùng cho | Đặc điểm |
|--------|----------|----------|
| **LTS** | ISO Live | Ổn định nhất, tương thích cao |
| **Zen** | Mặc định, Developers, Studio, hosts/lg | Cân bằng hiệu năng và ổn định |
| **XanMod** | Gaming edition | Tối ưu gaming, latency thấp |

## Binary Cache (Cachix)

- Cache công cộng: `bamos.cachix.org`
- CI/CD tự động push cache khi build ISO
- Người dùng tự động hưởng lợi từ cache

## Security

- Secret management: agenix (age encryption)
- Firewall: Enabled by default
- AppArmor: Enabled
- Impermanence: (Future) /etc được quản lý bởi NixOS
