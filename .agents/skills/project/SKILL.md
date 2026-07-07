---
name: project
description: Project context for BamOS — NixOS distribution for the Vietnamese community. Auto-generated from idea.md by the init skill.
---

# BamOS — Project Context

**Initialized:** 2026-07-03
**Stack:** Nix + flake-parts + GNOME/KDE/COSMIC

## Quick Facts
- **Language:** Nix (purely functional package management language)
- **Base OS:** NixOS (nixos-unstable channel)
- **Framework:** flake-parts (hercules-ci) — modular flake framework
- **Kernel:** Linux Zen (`linuxPackages_zen`)
- **Desktop Environments:** GNOME, KDE Plasma, COSMIC
- **Filesystem:** Btrfs (subvolumes: `@`, `@home`, `@nix`)
- **CI/CD:** GitHub Actions (Nix Flakes)
- **Binary Cache:** Cachix

## Architecture

BamOS is a NixOS-based Linux distribution targeting 3 Desktop Environments × 4 Editions = 12 ISO variants:

|  | **Standard** | **Developers** | **Gaming** | **Studio** |
|---|-------------|---------------|-----------|-----------|
| **GNOME** | ✅ | ✅ | ✅ | ✅ |
| **KDE Plasma** | ✅ | ✅ | ✅ | ✅ |
| **COSMIC** | ✅ | ✅ | ✅ | ✅ |

### Architecture Layers
```
lib/        → Thư viện & hàm (mkEdition, mkHost, mkISO)
modules/    → Khai báo NixOS modules (options + config)
profiles/   → Tổ hợp modules cho từng edition+DE
hosts/      → Phần cứng cụ thể (hardware-configuration)
pkgs/       → Custom Nix packages
overlays/   → Ghi đè nixpkgs
```

### Key Principles
1. **modules/** = KHAI BÁO (declare): options + config, toggle qua enable
2. **profiles/** = TỔ HỢP (compose): imports modules, set tham số
3. **hosts/** = PHẦN CỨNG (hardware): hardware scan + params, imports profile
4. **lib/** = HÀM (functions): helpers, builders, no side effects
5. **pkgs/** = PACKAGES: mỗi package một thư mục, callPackage
6. **overlays/** = GHI ĐÈ (overrides): thay đổi packages từ nixpkgs

## Development Setup

```bash
nix develop          # Enter dev shell (nil, nixd, nixpkgs-fmt, deadnix, statix)
nix fmt              # Format all .nix files
nix flake check      # Validate flake
nix flake show       # Show all outputs
```

## Testing

```bash
sudo nixos-rebuild switch --flake .#lg    # Apply config to current machine
sudo nixos-rebuild test --flake .#lg      # Test without making boot entry
nix build .#iso-gnome-standard            # Build specific ISO variant
nix build .#all-isos                      # Build all 12 ISO variants
```

## Current Phase: Phase 3 — Distro ISO 🔄

- ✅ Phase 1: Core Foundation (flake-parts, Zen kernel, GNOME, Btrfs, disko)
- ✅ Phase 2: Bản địa hóa (Fcitx5+Bamboo, VN locale, fonts)
- 🔄 Phase 3: Distro ISO (nixos-generators, Calamares, auto-partition)
- ⏳ Phase 4: Multi-DE + Editions (KDE, COSMIC, Gaming, Studio, Developers)
- ⏳ Phase 5: BamOS Portal (system settings app)
- ⏳ Phase 6: Hoàn thiện ma trận 3×4
- ⏳ Phase 7: Community

## Active Sprint

**AI Sprint 1: ISO GNOME Standard** (2026-07-03 → 2026-07-12)
- 🎯 Goal: First bootable BamOS ISO (GNOME Standard)
- 📊 Capacity: 37 SP (AI-augmented)
- 🌿 Branch: `sprint/01/iso-gnome-standard`
- 🔥 Top stories: US-003-01 (ISO build), US-003-03 (Disko), US-005-08 (VN input)
- 📋 Plan: [`plan/05-sprints/sprint-01-iso-gnome-standard/`](../../plan/05-sprints/sprint-01-iso-gnome-standard/sprint-plan.md)
- 📅 Today: [`daily-scrum/2026-07-03.md`](../../plan/05-sprints/sprint-01-iso-gnome-standard/daily-scrum/2026-07-03.md)

## Sprint Roadmap

| Sprint | Goal | Status | Branch |
|--------|------|--------|--------|
| [Sprint 1](../../plan/05-sprints/sprint-01-iso-gnome-standard/) | ISO GNOME Standard | 🔄 Active | `sprint/01/iso-gnome-standard` |
| [Sprint 2](../../plan/05-sprints/sprint-02-kde-standard-apps/) | KDE + Standard apps | 🔴 Planned | `sprint/02/kde-standard-apps` |
| [Sprint 3](../../plan/05-sprints/sprint-03-developers-gaming/) | Dev + Gaming editions | 🔴 Planned | `sprint/03/developers-gaming` |
| [Sprint 4](../../plan/05-sprints/sprint-04-cosmic-studio/) | COSMIC + Studio | 🔴 Planned | `sprint/04/cosmic-studio` |

📊 [Full Dashboard](../../plan/05-sprints/README.md)

## AI Sprint Cadence
This project uses AI-augmented development:
- Sprint duration: **5-10 days** (vs 2-4 weeks traditional)
- 8 Epics, 24 User Stories defined in `/plan/04-backlog/`
- All stories ICE-scored and prioritized
- Git workflow: `sprint/NN/goal` branches, `feat(US-XXX):` commits
- Per-sprint directories preserve full history forever
- Automated CI/CD via GitHub Actions with Cachix cache
