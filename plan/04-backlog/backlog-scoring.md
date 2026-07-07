# Backlog Scoring (ICE Framework)

## Scoring Methodology

| Factor | Scale | Description |
|--------|-------|-------------|
| **Impact** | 1-5 | How much does this move BamOS toward being a real distro? (5 = unlocks next phase) |
| **Confidence** | 1-5 | How certain are we about the impact estimate? (5 = validated by Phase 1-2) |
| **Ease** | 1-5 | How easy to implement with AI? (5 = AI can do 80%+, 1 = requires deep Nix expertise) |

**ICE Score = Impact × Confidence × Ease**
**Max Score = 125**

## Scoring Table — All User Stories

| ID | Story | Impact | Confidence | Ease | ICE | Priority Tier |
|----|-------|--------|------------|------|-----|---------------|
| **EPIC-003: Distro ISO** | | | | | | |
| US-003-01 | ISO từ flake (nixos-generators) | 5 | 5 | 4 | **100** | 🔥 Must Now |
| US-003-05 | CI/CD pipeline build ISO | 5 | 4 | 4 | **80** | 🔥 Must Now |
| US-003-03 | Auto-partitioning disko | 5 | 5 | 4 | **100** | 🔥 Must Now |
| US-003-04 | BamOS branding | 3 | 4 | 5 | **60** | ✅ Must Have |
| US-003-02 | Calamares installer | 5 | 3 | 2 | **30** | 🟡 Should Have |
| US-003-06 | Test ISO QEMU | 3 | 4 | 5 | **60** | ✅ Must Have |
| **EPIC-004: Multi-DE** | | | | | | |
| US-004-06 | mkEdition helper | 4 | 4 | 4 | **64** | ✅ Must Have |
| US-004-01 | KDE Plasma | 4 | 4 | 4 | **64** | ✅ Must Have |
| US-004-03 | SDDM display manager | 3 | 5 | 5 | **75** | ✅ Must Have |
| US-004-02 | COSMIC desktop | 3 | 3 | 3 | **27** | 🟡 Should Have |
| US-004-04 | cosmic-greeter | 2 | 3 | 4 | **24** | 🟡 Should Have |
| US-004-05 | DE branding consistency | 2 | 3 | 3 | **18** | 🔵 Could Have |
| **EPIC-005: Editions** | | | | | | |
| US-005-08 | VN input method ALL editions | 5 | 5 | 5 | **125** | 🔥 Must Now |
| US-005-01 | Standard apps | 5 | 5 | 4 | **100** | 🔥 Must Now |
| US-005-02 | Flatpak + Flathub | 4 | 5 | 5 | **100** | 🔥 Must Now |
| US-005-03 | Developers (devenv+Podman) | 4 | 4 | 4 | **64** | ✅ Must Have |
| US-005-04 | Gaming (Steam+Proton) | 4 | 3 | 3 | **36** | 🟡 Should Have |
| US-005-06 | Gaming stream tools | 3 | 3 | 4 | **36** | 🟡 Should Have |
| US-005-05 | Studio apps | 3 | 3 | 3 | **27** | 🟡 Should Have |
| US-005-07 | Distrobox | 2 | 4 | 5 | **40** | ✅ Must Have |
| **EPIC-006: Portal** | | | | | | |
| US-006-01 | GUI settings app | 4 | 2 | 2 | **16** | 🔵 Could Have |
| US-006-02 | Factory Reset | 4 | 3 | 2 | **24** | 🟡 Should Have |
| **EPIC-007: Matrix** | | | | | | |
| US-007-01 | ISO size < 3GB | 4 | 3 | 3 | **36** | 🟡 Should Have |
| US-007-02 | Automated ISO testing | 4 | 3 | 3 | **36** | 🟡 Should Have |
| **EPIC-008: Community** | | | | | | |
| US-008-01 | VN documentation | 5 | 5 | 3 | **75** | ✅ Must Have |
| US-008-02 | Website bamos.vn | 4 | 4 | 3 | **48** | ✅ Must Have |

---

## Priority Tiers

### 🔥 Must Now (ICE ≥ 80)
Non-negotiable for Sprint 1. Ship-blockers for first ISO.
| ID | Story | ICE | Sprint |
|----|-------|-----|--------|
| US-005-08 | VN input ALL editions | 125 | Sprint 1 |
| US-003-01 | ISO from flake | 100 | Sprint 1 |
| US-003-03 | Disko auto-partition | 100 | Sprint 1 |
| US-005-01 | Standard apps | 100 | Sprint 2 |
| US-005-02 | Flatpak + Flathub | 100 | Sprint 1 |
| US-003-05 | CI/CD ISO pipeline | 80 | Sprint 1 |

### ✅ Must Have (ICE 40-79)
Important for v0.1.0 release. Sprint 1-2.
| ID | Story | ICE |
|----|-------|-----|
| US-008-01 | VN documentation | 75 |
| US-004-03 | SDDM (KDE) | 75 |
| US-004-06 | mkEdition helper | 64 |
| US-004-01 | KDE Plasma | 64 |
| US-005-03 | Developers edition | 64 |
| US-003-06 | Test ISO QEMU | 60 |
| US-003-04 | BamOS branding | 60 |
| US-008-02 | Website | 48 |
| US-005-07 | Distrobox | 40 |

### 🟡 Should Have (ICE 20-39)
Sprint 3-4.
### 🔵 Could Have (ICE < 20)
Sprint 5+.

---

## Velocity Planning

| Sprint | Focus | Est. SP | Cumulative |
|--------|-------|---------|------------|
| **Sprint 1** | ISO GNOME Standard | 37 SP (ambitious) | — |
| **Sprint 2** | KDE + Standard apps | 30-40 SP | ISO KDE Standard |
| **Sprint 3** | Developers + Gaming editions | 30-40 SP | 2 editions |
| **Sprint 4** | COSMIC + Studio edition | 30-40 SP | 3×4 complete |
| **Sprint 5+** | Portal, docs, community | 20-30 SP | Production ready |
