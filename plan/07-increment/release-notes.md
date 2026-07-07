# Release Notes

## v0.1.0 — "First Light" (Planned)
**Target Date:** 2026-07-12 (Sprint 1)
**Phase:** 3 — Distro ISO

### Features (Planned)
- [ ] ISO GNOME Standard bootable — `nix build .#iso-gnome-standard`
- [ ] Calamares graphical installer with BamOS branding
- [ ] Disko auto-partitioning (Btrfs: @, @home, @nix)
- [ ] GNOME desktop (Wayland) + GDM
- [ ] Fcitx5 + Bamboo (Telex, VNI) hoạt động OOTB
- [ ] Vietnamese locale + timezone
- [ ] Flatpak + Flathub qua Software Center
- [ ] PipeWire audio
- [ ] Zen kernel
- [ ] CI/CD pipeline: auto-build ISO on push

### Known Issues (Expected)
- ISO size may exceed 3GB target (will optimize in v0.2.0)
- COSMIC DE not yet supported
- Only x86_64-linux
- No NVIDIA driver pre-installed (opt-in overlay)

---

## v0.0.1 — Foundation (Completed)
**Date:** 2026-06
**Phase:** 1-2 — Core Foundation + Bản địa hóa

### Features ✅
- ✅ flake-parts foundation with `mkFlake`
- ✅ Zen kernel (`linuxPackages_zen`)
- ✅ GNOME desktop (GDM + Wayland)
- ✅ Fcitx5 + Bamboo engine (Telex, VNI)
- ✅ Vietnamese locale + timezone
- ✅ PipeWire audio (ALSA + PulseAudio + 32-bit)
- ✅ Btrfs subvolume structure defined
- ✅ NixOS modules: core, desktop, hardware, input-method
- ✅ Host configuration (lg laptop)

### Bug Fixes
- N/A (internal development)

### Breaking Changes
- N/A

### Technical Debt
- `modules/` structure cần refactor theo `core/`, `desktop/`, `hardware/` như trong idea.md
- `lib/` stubs cần được implement (mkEdition, mkHost, mkISO)
- `profiles/` cần được tạo cho 12 variants

---

_This file is updated after each release with the delivered increment._
