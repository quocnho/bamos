# Release Notes

## v0.6.0 — "Bamboo & Calamares" (Active — Sprint 6)
**Timeline:** 2026-07-07 → TBD
**Phase:** 9 — Unified Calamares Installer

### Features (Active)
- [ ] Unified ISO: 3 ISOs (GNOME/KDE/COSMIC) thay 12 — edition chọn khi install
- [ ] Calamares edition selector: Standard / Developers / Gaming / Studio
- [ ] Calamares machine type: Laptop / Desktop / Server
- [ ] Custom Python module bamos-config: sinh /etc/nixos/ + customized.nix
- [ ] Drive icon SVG → PNG fix
- [ ] Calamares screenshots cho packagechooser

---

## v0.5.0 — "RakuOS Theming & Hardware Detection" ✅ (Completed)
**Date:** 2026-07-06
**Phase:** 7 — Auto-Detect Hardware + Power Management

### Features ✅
- ✅ `modules/hardware/detect.nix` — auto-detect GPU, PCI bus IDs
- ✅ `bamos-detect-hardware.sh` — script quét hardware (lspci)
- ✅ tuned (Red Hat) thay PPD: dynamic_tuning, PPD bridge, profile per edition
- ✅ Battery optimization: ASPM powersupersave, WiFi power save, runtime PM
- ✅ RakuOS Theming: Switch papirus → WhiteSur icons, Bibata cursors, Nordic GTK
- ✅ `/etc/gtk-3.0/settings.ini` + `/etc/gtk-4.0/settings.ini` system-wide GTK
- ✅ `bamos-gnome-first-login` — one-time gsettings activator
- ✅ Documentation disabled (smaller ISO)

---

## v0.4.0 — "COSMIC & Studio" ✅ (Sprint 4 — Completed)
**Date:** 2026-07-06
**Phase:** 6 — COSMIC + Studio Edition

### Features ✅
- ✅ COSMIC desktop module + cosmic-greeter
- ✅ GNOME / KDE / COSMIC Studio ISO (Blender, GIMP, Krita, Ardour, OBS)
- ✅ All 12 ISO variants build OK
- ✅ Modules refactor (flat → subdirs: core/, boot/, desktop/, ...)
- ✅ Docs website (32+ trang, bazzite-style)
- ✅ Technical docs (architecture, modules, iso-build, kernel)
- ✅ NVIDIA hardware detection script

### Known Issues
- COSMIC pre-1.0, API chưa ổn định

---

## v0.3.0 — "Developers & Gaming" ✅ (Sprint 3 — Completed)
**Date:** 2026-07-05
**Phase:** 5 — Developers + Gaming Editions

### Features ✅
- ✅ GNOME / KDE Developers ISO — devenv, Podman, dev tools
- ✅ GNOME / KDE Gaming ISO — Steam, GameScope, MangoHud, Lutris
- ✅ Developer Workstation (hosts/lg): agenix, home-manager, GNOME extensions
- ✅ NVIDIA GTX 1650 support — Optimus PRIME + power management
- ✅ Software Center — GNOME Software + Flatpak + Gear Lever (AppImage)

---

## v0.2.0 — "KDE & Standard Apps" ✅ (Sprint 2 — Completed)
**Date:** 2026-07-04
**Phase:** 4 — Multi-DE + Standard Apps

### Features ✅
- ✅ KDE Plasma 6 desktop + SDDM Wayland
- ✅ `mkEdition` helper function
- ✅ Standard Edition apps (Firefox, Chromium, VLC, MPV)
- ✅ KDE Standard ISO bootable
- ✅ GNOME window buttons: Min/Max/Close (dconf)
- ✅ Btrfs Ổ C — Ổ D: @data subvolume + XDG redirect
- ✅ Calamares partition override (partition.conf + mount.conf)

---

## v0.1.0 — "First Light" ✅ (Sprint 1 — Completed)
**Date:** 2026-07-03
**Phase:** 3 — Distro ISO

### Features ✅
- ✅ ISO GNOME Standard bootable — `nix build .#iso-gnome-standard`
- ✅ Calamares graphical installer with BamOS branding
- ✅ Disko auto-partitioning (Btrfs: @, @home, @nix, @data)
- ✅ GNOME desktop (Wayland) + GDM
- ✅ Fcitx5 + Bamboo (Telex, VNI) OOTB
- ✅ Vietnamese locale + timezone
- ✅ Flatpak + Flathub qua Software Center
- ✅ PipeWire audio
- ✅ Zen kernel
- ✅ CI/CD pipeline: auto-build ISO on push
- ✅ Cachix binary cache (`bamos.cachix.org`)

### Known Issues (v0.1.0)
- ISO size ~3.2GB > target 2.5GB (optimized in v0.2.0+)
- COSMIC DE not yet supported
- Only x86_64-linux
- NVIDIA driver not pre-installed (opt-in)

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

### Technical Debt (resolved in later sprints)
- Modules structure refactored in Sprint 4
- lib/ helpers (mkEdition, mkHost, mkISO) implemented in Sprint 2-3
- Profiles for 12 variants completed by Sprint 4
