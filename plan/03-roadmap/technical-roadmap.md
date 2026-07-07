# Technical Roadmap

> **Last Updated:** 2026-07-06
> **Updated by:** Sprint 1-4 actual progress + Phase 7

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

## Phase 7 — Auto-Detect Hardware 🟡 (Đang thực hiện)
**Timeline:** 2026-07-06

### Milestones
- [x] `modules/hardware/detect.nix` — auto-detect module
- [x] `bamos-detect-hardware` script — GPU detection via lspci
- [ ] Detect NVIDIA + AMD + Intel GPU and PCI bus IDs
- [ ] First-boot service chạy auto-detect
- [ ] Tích hợp lên Calamares GUI installer

## Phase 8 — BamOS Portal (Tương lai)

### Milestones
- [ ] Factory Reset Desktop
- [ ] Driver Manager (NVIDIA, AMD auto-install)
- [ ] System Info Dashboard
- [ ] Edition Switcher

## Phase 9 — Hoàn thiện ma trận 3×4 (Tương lai)

### Milestones
- [ ] COSMIC Standard/Developers/Gaming ISO
- [ ] Complete 12/12 production-quality ISOs
- [ ] ISO size < 2.5GB

## Phase 10 — Community (Tương lai)

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
