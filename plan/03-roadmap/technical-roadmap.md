# Technical Roadmap

> **Last Updated:** 2026-07-09
> **Updated by:** Sprint 1-5 actual progress + Phases 7-8 complete

---

## Phase 1 — Core Foundation ✅ (Sprint 0)
**Goal:** Thiết lập nền tảng NixOS + flake-parts vững chắc

### Milestones
- [x] flake-parts foundation với `mkFlake`
- [x] Zen kernel (`linuxPackages_zen`)
- [x] GNOME desktop (GDM + Wayland)
- [x] Btrfs subvolume layout (`@`, `@home`, `@nix`)
- [x] systemd-boot (UEFI)
- [x] Base NixOS modules structure (core, desktop, hardware)

## Phase 2 — Bản địa hóa ✅ (Sprint 0)
**Goal:** Trải nghiệm tiếng Việt hoàn chỉnh out-of-the-box

### Milestones
- [x] Fcitx5 + Bamboo engine (Telex, VNI)
- [x] Vietnamese locale + timezone
- [x] PipeWire audio (ALSA + PulseAudio + 32-bit)
- [x] System optimization (tắt dịch vụ không cần thiết)
- [x] Vietnamese fonts

## Phase 3 — Distro ISO ✅ (Sprint 1 — v0.1.0)
**Timeline:** 2026-07-03 → v0.1.0

### Milestones
- [x] ISO build infrastructure
- [x] Dual-kernel: LTS 6.12 (ISO) → Zen (OS sau cài)
- [x] **GNOME Standard ISO** — `nix build .#iso-gnome-standard`
- [x] Calamares graphical installer
- [x] Disko Btrfs auto-partitioning
- [x] Flatpak + Flathub integration
- [x] Cachix binary cache
- [x] CI/CD pipeline (GitHub Actions)

## Phase 4 — Multi-DE + Standard Apps ✅ (Sprint 2 — v0.2.0)
**Timeline:** 2026-07-04 → v0.2.0

### Milestones
- [x] KDE Plasma 6 desktop + SDDM Wayland
- [x] `mkEdition` helper
- [x] Standard Edition apps
- [x] **KDE Standard ISO**
- [x] GNOME window buttons (Min/Max/Close)
- [x] Btrfs Ổ C — Ổ D: `@data` subvolume + XDG redirect
- [x] Calamares partition override (partition.conf + mount.conf)

## Phase 5 — Developers + Gaming ✅ (Sprint 3 — v0.3.0)
**Timeline:** 2026-07-05 → v0.3.0

### Milestones
- [x] **GNOME Developers ISO** — devenv, Podman, dev tools
- [x] **GNOME Gaming ISO** — Steam, GameScope, MangoHud, Lutris
- [x] **KDE Developers ISO** — KDE + dev tools
- [x] **KDE Gaming ISO** — KDE + gaming stack
- [x] Developer Workstation (hosts/lg): agenix, home-manager, GNOME extensions
- [x] NVIDIA GTX 1650 support — Optimus PRIME + power management
- [x] Software Center — GNOME Software + Flatpak + Gear Lever

## Phase 6 — COSMIC + Studio ✅ (Sprint 4 — v0.4.0)
**Timeline:** 2026-07-06 → v0.4.0

### Milestones
- [x] COSMIC desktop module + cosmic-greeter (3 editions)
- [x] **GNOME Studio ISO** — creative suite
- [x] **KDE Studio ISO** — KDE + studio apps
- [x] **COSMIC Studio ISO** — Cosmic + studio apps
- [x] All 12 ISO variants build OK
- [x] Modules refactor (flat → subdirs)
- [x] Docs website (32+ trang, bazzite-style)
- [x] Technical docs (architecture, modules, iso-build, kernel)

## Phase 7 — Auto-Detect Hardware ✅ (Hoàn thành)
**Timeline:** 2026-07-06 (Sprint 5)

### Milestones
- [x] `modules/hardware/detect.nix` — auto-detect module
- [x] `bamos-detect-hardware` script — GPU detection via lspci
- [x] Detect NVIDIA + AMD + Intel GPU and PCI bus IDs
- [x] `services.xserver.videoDrivers` fix via nvidia.nix (hardware.video.nvidia)
- [x] **tuned** (Red Hat) thay PPD: dynamic_tuning, PPD bridge, profile theo edition
- [x] **Case study LG Gram**: i5-10210U, GTX 1650, NVMe — CPU governor powersave
- [x] **Battery optimization**: ASPM powersupersave, WiFi power save, runtime PM, swap 16GB
- [x] **RakuOS Theming**: WhiteSur icons, Bibata cursors, Nordic GTK, Maple Mono NF
- [x] **Hardware tools**: pciutils, usbutils, dmidecode, inxi, mesa-demos trong mọi edition
- [ ] First-boot service chạy auto-detect (⏳ deferred)
- [ ] Tích hợp lên Calamares GUI installer (⏳ deferred)

## Phase 8 — Btrfs Backup & Restore + Auto Update ✅ (Hoàn thành)
**Timeline:** 2026-07-07 (Sprint 6 prep)

### Milestones
- [x] `modules/hardware/backup.nix` — btrbk snapshot engine
- [x] Retention policy: 24 hourly, 7 daily, 4 weekly, 3 monthly
- [x] Auto snapshot: systemd timer hourly, pruning tự động
- [x] `bam backup [-s] [-h] [-d]` — selective backup
- [x] `bam restore [-s] [-h] [-d]` — selective restore + interactive menu
- [x] `bam clean [--keep N]` — dọn Nix generations + Btrfs snapshots
- [x] `modules/core/update.nix` — auto-upgrade engine (GLF-OS pattern)
- [x] Systemd timer: 1 phút sau boot, lặp lại mỗi 12h
- [x] Version checking: local vs GitHub, changelog notification
- [x] `modules/core/version.nix` — /etc/os-release branding (NAME=BamOS)
- [x] `bam update` — flake update → rebuild → gc → regen boot
- [x] `bam rollback [gen]` — rollback generation
- [x] `bam changelog` — xem changelog các version mới

## Phase 9 — Unified Calamares Installer 🟡 (Đang thực hiện — Sprint 6)
**Timeline:** 2026-07-07 → TBD

### Milestones
- [x] `modules/boot/calamares.nix` — Calamares config với partition + mount
- [x] Edition selector: packagechooser 4 editions (Standard/Developers/Gaming/Studio)
- [x] Machine type selector: Laptop/Desktop/Server — auto power profile
- [x] Ổ D integration: /data mount + custom drive icon + Nautilus bookmark
- [x] Calamares branding: Logo bamboo, Nord colors, slideshow
- [x] `iso-cfg/` template: flake.nix, configuration.nix, customized.nix, customConfig/
- [x] Custom Python module bamos-config: copy template → /etc/nixos/ + apply selections
- [x] Post-install flake: `github:quocnho/bamos` — dễ update
- [x] `environment.etc."nixos-template/..."` — expose iso-cfg lên ISO live
- [ ] Drive icon SVG → PNG (cần librsvg fix)
- [ ] Calamares screenshots cho packagechooser
- [ ] Unified ISO: 3 ISOs (GNOME/KDE/COSMIC) thay 12 hiện tại
- [ ] First-boot GPU detection tích hợp trong Calamares

## Phase 10 — BamOS Portal (Tương lai)

### Milestones
- [ ] Factory Reset Desktop (1-click restore UI)
- [ ] Driver Manager (NVIDIA, AMD auto-install)
- [ ] System Info Dashboard
- [ ] Edition Switcher

## Phase 11 — Hoàn thiện ma trận 3×4 (Tương lai)

### Milestones
- [ ] Unified ISO cho tất cả DE
- [ ] Testing: QEMU VM + CI/CD tự động test ISO
- [ ] Binary cache đầy đủ — build lần đầu, cache mãi mãi

## Phase 12 — Community (Tương lai)

### Milestones
- [ ] Home Manager integration
- [ ] Custom packages for Vietnamese software
- [ ] Documentation website + guides
- [ ] 500+ users

## Technical Debt Tracking
| Item | Impact | Effort | Priority | Sprint |
|------|--------|--------|----------|--------|
| `system.build.image/images` warning | Low | S | 3 | Deferred |
| ISO size 3.2GB > target 2.5GB | Medium | M | 2 | Sprint 8 |
| Flatpak warning (password) | Low | S | 4 | Deferred |
| Calamares custom branding | Medium | M | 2 | Sprint 7 |
| Calamares NVIDIA detection (main.py) | Medium | M | 3 | Sprint 7 |
