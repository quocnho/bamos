# Product Backlog

> Ordered list of all known work items. Prioritized by ICE score.
> AI-augmented estimates: 1 dev + AI = 40-60 SP/sprint (5 days)

## Backlog Overview

| ID | Epic | User Story | Priority | SP | Status |
|----|------|------------|----------|-----|--------|
| **EPIC-001: Core Foundation 🟢 (Hoàn thành)** |
| US-001-01 | EPIC-001 | flake-parts foundation với mkFlake | Must | 5 | 🟢 Done |
| US-001-02 | EPIC-001 | Zen kernel (linuxPackages_zen) | Must | 2 | 🟢 Done |
| US-001-03 | EPIC-001 | GNOME desktop (GDM + Wayland) | Must | 5 | 🟢 Done |
| US-001-04 | EPIC-001 | systemd-boot EFI support | Must | 3 | 🟢 Done |
| US-001-05 | EPIC-001 | Dev environment (nix develop) | Must | 3 | 🟢 Done |
| US-001-06 | EPIC-001 | Custom packages overlay | Should | 3 | 🟢 Done |
| **EPIC-002: Bản Địa Hóa 🟢 (Hoàn thành)** |
| US-002-01 | EPIC-002 | Fcitx5 + Bamboo input method | Must | 5 | 🟢 Done |
| US-002-02 | EPIC-002 | Vietnamese locale + timezone | Must | 2 | 🟢 Done |
| US-002-03 | EPIC-002 | PipeWire audio (ALSA + PulseAudio + 32-bit) | Must | 3 | 🟢 Done |
| US-002-04 | EPIC-002 | Disable unnecessary services | Should | 2 | 🟢 Done |
| US-002-05 | EPIC-002 | Vietnamese + developer fonts | Should | 2 | 🟢 Done |
| **EPIC-003: Distro ISO Build 🟢 (Hoàn thành)** |
| US-003-01 | EPIC-003 | ISO build infrastructure (native system.build.images) | Must | 8 | 🟢 Done |
| US-003-02 | EPIC-003 | Calamares graphical installer | Must | 13 | 🟢 Done |
| US-003-03 | EPIC-003 | Disko Btrfs auto-partitioning | Must | 5 | 🟢 Done |
| US-003-04 | EPIC-003 | BamOS branding (logo, ISO label) | Should | 3 | 🟢 Done |
| US-003-05 | EPIC-003 | CI/CD pipeline build ISO | Must | 5 | 🟢 Done |
| **EPIC-004: Multi-DE Support 🟢 (Hoàn thành)** |
| US-004-01 | EPIC-004 | KDE Plasma desktop | Must | 8 | 🟢 Done |
| US-004-02 | EPIC-004 | SDDM display manager | Must | 3 | 🟢 Done |
| US-004-03 | EPIC-004 | COSMIC desktop | Could | 8 | 🟢 Done |
| US-004-04 | EPIC-004 | cosmic-greeter | Could | 3 | 🟢 Done |
| US-004-05 | EPIC-004 | mkEdition helper function | Must | 5 | 🟢 Done |
| US-004-06 | EPIC-004 | Consistent DE branding | Should | 5 | 🟢 Done |
| **EPIC-005: Edition Profiles 🟢 (Hoàn thành)** |
| US-005-01 | EPIC-005 | Standard apps (browser, office, media) | Must | 5 | 🟢 Done |
| US-005-02 | EPIC-005 | Flatpak + Flathub support | Must | 3 | 🟢 Done |
| US-005-03 | EPIC-005 | Developers Edition (devenv + Podman) | Should | 8 | 🟢 Done |
| US-005-04 | EPIC-005 | Gaming Edition (Steam + Proton + GameScope) | Should | 8 | 🟢 Done |
| US-005-05 | EPIC-005 | Studio Edition (Blender, Kdenlive, Ardour) | Could | 8 | 🟢 Done |
| US-005-06 | EPIC-005 | Gaming stream tools (MangoHud + OBS + Discord) | Should | 5 | 🟢 Done |
| US-005-07 | EPIC-005 | Distrobox pre-installed | Could | 3 | 🟢 Done |
| US-005-08 | EPIC-005 | Software Center (GNOME/KDE Discover + Gear Lever) | Should | 5 | 🟢 Done |
| **EPIC-009: Developer Workstation 🟢 (Hoàn thành)** |
| US-009-01 | EPIC-009 | Agenix secrets management (hosts/lg) | Must | 8 | 🟢 Done |
| US-009-02 | EPIC-009 | Home-manager user config | Must | 5 | 🟢 Done |
| US-009-03 | EPIC-009 | GNOME extensions for developer | Should | 3 | 🟢 Done |
| US-009-04 | EPIC-009 | Dev tools: gh, qemu, virt-manager, podman | Must | 5 | 🟢 Done |
| **EPIC-010: Auto-Detect + Power Mgmt 🟢 (Hoàn thành)** |
| US-010-01 | EPIC-010 | Auto-detect GPU module (detect.nix) | Must | 5 | 🟢 Done |
| US-010-02 | EPIC-010 | bamos-detect-hardware script | Must | 3 | 🟢 Done |
| US-010-03 | EPIC-010 | NVIDIA driver module (nvidia.nix) | Must | 8 | 🟢 Done |
| US-010-04 | EPIC-010 | tuned power management thay PPD | Must | 8 | 🟢 Done |
| US-010-05 | EPIC-010 | Battery optimization (ASPM, WiFi, runtime PM) | Should | 5 | 🟢 Done |
| US-010-06 | EPIC-010 | Hardware tools cho mọi edition | Should | 2 | 🟢 Done |
| **EPIC-011: Backup & Auto Update 🟢 (Hoàn thành)** |
| US-011-01 | EPIC-011 | btrbk backup engine | Must | 5 | 🟢 Done |
| US-011-02 | EPIC-011 | bam backup/restore CLI | Must | 8 | 🟢 Done |
| US-011-03 | EPIC-011 | bam clean command | Should | 3 | 🟢 Done |
| US-011-04 | EPIC-011 | Auto-upgrade engine (update.nix) | Must | 8 | 🟢 Done |
| US-011-05 | EPIC-011 | bam update interactive (changelog + confirm) | Must | 5 | 🟢 Done |
| US-011-06 | EPIC-011 | bam rollback + changelog | Should | 5 | 🟢 Done |
| US-011-07 | EPIC-011 | Version branding (/etc/os-release) | Should | 3 | 🟢 Done |
| US-011-08 | EPIC-011 | Third-party runtime (AppImage, FHS, Flatpak) | Should | 8 | 🟢 Done |
| **EPIC-012: Unified Calamares Installer 🟡 (Active)** |
| US-012-01 | EPIC-012 | Edition selector (packagechooser) | Must | 5 | 🟢 Done |
| US-012-02 | EPIC-012 | Machine type selector | Must | 3 | 🟢 Done |
| US-012-03 | EPIC-012 | Custom Python module bamos-config | Must | 8 | 🟢 Done |
| US-012-04 | EPIC-012 | iso-cfg template → /etc/nixos/ | Must | 5 | 🟢 Done |
| US-012-05 | EPIC-012 | Calamares branding + slideshow | Should | 5 | 🟡 Partial |
| US-012-06 | EPIC-012 | Drive icon SVG → PNG fix | Should | 3 | 🟡 Partial |
| US-012-07 | EPIC-012 | Screenshots cho packagechooser | Could | 5 | 🔴 Not started |
| US-012-08 | EPIC-012 | First-boot GPU detection in Calamares | Could | 5 | 🔴 Not started |
| **EPIC-006: BamOS Portal 🔮 (Future)** |
| US-006-01 | EPIC-006 | GUI settings app | Should | 13 | 🔴 Future |
| US-006-02 | EPIC-006 | Factory Reset 1-click | Should | 8 | 🔴 Future |
| US-006-03 | EPIC-006 | Driver Manager (NVIDIA auto-install) | Should | 8 | 🔴 Future |
| US-006-04 | EPIC-006 | System Info Dashboard | Could | 5 | 🔴 Future |
| US-006-05 | EPIC-006 | Edition Switcher GUI | Could | 8 | 🔴 Future |
| **EPIC-007: Complete 3×4 Matrix 🔮 (Future)** |
| US-007-01 | EPIC-007 | ISO size < 3GB | Should | 8 | 🔴 Future |
| US-007-02 | EPIC-007 | Automated ISO testing CI | Should | 8 | 🔴 Future |
| US-007-03 | EPIC-007 | Unified ISO for all DE | Could | 13 | 🔴 Future |
