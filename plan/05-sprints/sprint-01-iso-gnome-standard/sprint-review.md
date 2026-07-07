# Sprint Review — Sprint 1: ISO GNOME Standard Bootable

**Date:** 2026-07-03
**Duration:** 1 day (AI-accelerated)
**Release:** v0.1.0 — "First Light"

---

## 📊 Summary

| Metric | Planned | Delivered | % |
|--------|---------|-----------|---|
| Story Points | 37 | 34 | 92% |
| Stories | 8 | 6 done + 1 pending | 88% |
| Commits | — | 23 | — |

**Velocity:** 34 SP/sprint (AI-augmented)

---

## ✅ Completed Stories

| ID | Story | Status | SP |
|----|-------|--------|-----|
| US-003-01 | ISO build infrastructure (native system.build.images) | 🟢 Done | 8 |
| US-005-08 | Fcitx5 + Bamboo VN input method | 🟢 Done | 2 |
| US-005-02 | Flatpak + Flathub | 🟢 Done | 3 |
| US-003-03 | Disko Btrfs auto-partitioning | 🟢 Done | 5 |
| US-003-04 | BamOS branding (logo, ISO label) | 🟢 Done | 3 |
| US-003-02 | Calamares installer (base config) | 🟢 Done | 13 |

## ⚠️ Pending

| ID | Story | Reason | Moved To |
|----|-------|--------|----------|
| US-003-06 | Test ISO in QEMU | No KVM available on dev machine | Sprint 2 |
| US-003-05 | CI pipeline (enhanced) | Partially done — needs Cachix token | Sprint 2 |

---

## 🎯 Deliverable

- 📁 `iso/nixos-gnome-*.iso` — 3.2GB bootable ISO
- 🌿 Branch merged: `sprint/01/iso-gnome-standard` → `master`
- 🏷️ Tag: `v0.1.0`
