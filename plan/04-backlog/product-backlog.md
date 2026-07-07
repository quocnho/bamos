# Product Backlog

> Ordered list of all known work items. Prioritized by ICE score.
> AI-augmented estimates: 1 dev + AI = 40-60 SP/sprint (5 days)

## Backlog Overview

| ID | Epic | User Story | Priority | SP | AI? | Status |
|----|------|------------|----------|-----|-----|--------|
| **EPIC-003: Distro ISO Build 🟢 (Hoàn thành)** |
| US-003-01 | EPIC-003 | ISO build infrastructure (native system.build.images) | Must | 8 | ✅ | 🟢 Done |
| US-003-02 | EPIC-003 | Graphical installer (Calamares) | Must | 13 | — | 🟢 Done |
| US-003-03 | EPIC-003 | Disko Btrfs auto-partitioning | Must | 5 | ✅ | 🟢 Done |
| US-003-04 | EPIC-003 | BamOS branding (logo, ISO label) | Should | 3 | ✅ | 🟢 Done |
| US-003-05 | EPIC-003 | CI/CD pipeline build ISO | Must | 5 | ✅ | 🟢 Done |
| US-003-06 | EPIC-003 | Test ISO in QEMU VM | Should | 3 | ✅ | ⚫ Blocked (no KVM) |
| **EPIC-004: Multi-DE Support 🟡** |
| US-004-01 | EPIC-004 | KDE Plasma desktop | Must | 8 | ✅ | 🟢 Done |
| US-004-03 | EPIC-004 | SDDM display manager | Must | 3 | ✅ | 🟢 Done |
| US-004-06 | EPIC-004 | `mkEdition` helper function | Must | 5 | ✅ | 🟢 Done |
| US-004-02 | EPIC-004 | COSMIC desktop | Could | 8 | ✅ | 🔴 Backlog |
| US-004-04 | EPIC-004 | cosmic-greeter | Could | 3 | ✅ | 🔴 Backlog |
| US-004-05 | EPIC-004 | Consistent BamOS branding across all DEs | Should | 5 | — | 🔴 Sprint 3 |
| **EPIC-005: Edition Profiles 🟡** |
| US-005-01 | EPIC-005 | Essential Standard apps (browser, office, media) | Must | 5 | ✅ | 🟢 Done |
| US-005-02 | EPIC-005 | Flatpak + Flathub support | Must | 3 | ✅ | 🟢 Done |
| US-005-08 | EPIC-005 | Vietnamese fonts + input method ALL editions | Must | 2 | ✅ | 🟢 Done |
| US-005-03 | EPIC-005 | Developers Edition (devenv + Podman) | Should | 8 | ✅ | 🔴 Sprint 3 |
| US-005-04 | EPIC-005 | Gaming Edition (Steam + Proton + GameScope) | Should | 8 | ✅ | 🔴 Sprint 3 |
| US-005-06 | EPIC-005 | Gaming stream tools (MangoHud + OBS + Discord) | Should | 5 | ✅ | 🔴 Sprint 3 |
| US-005-07 | EPIC-005 | Distrobox pre-installed | Could | 3 | ✅ | 🔴 Sprint 3 |
| US-005-05 | EPIC-005 | Studio Edition (Blender, Kdenlive, Ardour) | Could | 8 | ✅ | 🔴 Sprint 4 |
| **EPIC-009: Developer Workstation 🟡** |
| US-009-01 | EPIC-009 | Agenix secrets management (hosts/lg) | Must | 8 | ✅ | 🔴 Sprint 3 |
| US-009-02 | EPIC-009 | Home-manager user config | Must | 5 | ✅ | 🔴 Sprint 3 |
| US-009-03 | EPIC-009 | GNOME extensions for developer | Should | 3 | ✅ | 🔴 Sprint 3 |
| US-009-04 | EPIC-009 | GitHub CLI + dev tools pre-installed | Must | 5 | ✅ | 🔴 Sprint 3 |
| **EPIC-006: BamOS Portal** |
| US-006-01 | EPIC-006 | GUI settings app | Should | 13 | — | 🔴 Future |
| US-006-02 | EPIC-006 | Factory Reset | Should | 8 | — | 🔴 Future |
| **EPIC-007: Complete Matrix** |
| US-007-01 | EPIC-007 | ISO size < 3GB | Should | 8 | ✅ | 🔴 Sprint 4 |
| US-007-02 | EPIC-007 | Automated ISO testing CI | Should | 8 | ✅ | 🔴 Sprint 4 |
| **EPIC-008: Community** |
| US-008-01 | EPIC-008 | Vietnamese documentation | Must | 8 | ✅ | 🔴 Future |
| US-008-02 | EPIC-008 | Website (bamos.vn) | Must | 8 | ✅ | 🔴 Future |

---

## Sprint 1 ✅ (v0.1.0) — ISO GNOME Standard

| ID | Story | SP | Status |
|----|-------|-----|--------|
| US-003-01 | ISO build infrastructure (native system.build.images) | 8 | 🟢 |
| US-003-05 | CI/CD pipeline build ISO tự động | 5 | 🟢 |
| US-003-03 | Disko Btrfs auto-partitioning | 5 | 🟢 |
| US-003-04 | BamOS branding (logo, ISO label) | 3 | 🟢 |
| US-003-02 | Calamares installer | 13 | 🟢 |
| US-005-08 | VN input method | 2 | 🟢 |
| US-005-02 | Flatpak + Flathub | 3 | 🟢 |
| **TOTAL** | | **39 SP** | ✅ Released v0.1.0 |

## Sprint 2 🟡 (v0.2.0) — KDE Plasma + Standard Apps

| ID | Story | SP | Status |
|----|-------|-----|--------|
| US-004-01 | KDE Plasma desktop | 8 | 🟢 |
| US-004-03 | SDDM display manager | 3 | 🟢 |
| US-004-06 | `mkEdition` helper | 5 | 🟢 |
| US-005-01 | Standard apps (Firefox, LibreOffice, VLC) | 5 | 🟢 |
| US-003-06 | Test ISO in QEMU | 3 | ⚫ Blocked |
| **TOTAL** | | **24 SP** | 🔄 Branch active |

## Sprint 3 🔴 (v0.3.0) — Developers + Gaming + Developer Workstation

| ID | Story | SP | AI? |
|----|-------|-----|-----|
| US-009-01 | Agenix secrets (hosts/lg) | 8 | ✅ |
| US-009-02 | Home-manager user config | 5 | ✅ |
| US-009-03 | GNOME extensions | 3 | ✅ |
| US-009-04 | gh + dev tools (hosts/lg) | 5 | ✅ |
| US-005-03 | Developers Edition (devenv + Podman) | 8 | ✅ |
| US-005-04 | Gaming Edition (Steam + Proton) | 8 | ✅ |
| US-005-06 | Gaming stream tools | 5 | ✅ |
| US-005-07 | Distrobox pre-installed | 3 | ✅ |
| US-004-05 | DE branding consistency | 5 | — |
| **TOTAL** | | **50 SP** | |
