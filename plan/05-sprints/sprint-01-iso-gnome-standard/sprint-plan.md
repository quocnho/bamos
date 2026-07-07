# AI Sprint 1: ISO GNOME Standard Bootable

**Status:** 🔄 Active
**Dates:** 2026-07-03 → 2026-07-12 (10 days)
**Git Branch:** `sprint/01/iso-gnome-standard`
**Target Release:** v0.1.0 — "First Light"
**Capacity:** 37 story points (AI-augmented, 1 developer)

---

## Sprint Goal (SMART)
**Tạo ISO GNOME Standard bootable đầu tiên — có thể boot, cài đặt qua Calamares, và gõ tiếng Việt ngay sau khi vào desktop.**

---

## Sprint Backlog

| ID | Epic | Story | AI? | Day | SP | Status |
|----|------|-------|-----|-----|-----|--------|
| US-003-01 | EPIC-003 | As a developer, I want to generate a bootable ISO from the flake so that BamOS can be distributed | ✅ | 1-2 | 8 | 🔴 Todo |
| US-005-08 | EPIC-005 | As a user, I want Vietnamese input method in the ISO so that I can type Vietnamese after install | ✅ | 1 | 2 | 🔴 Todo |
| US-005-02 | EPIC-005 | As a user, I want Flatpak + Flathub support in the ISO so that I can install apps from Software Center | ✅ | 2 | 3 | 🔴 Todo |
| US-003-05 | EPIC-003 | As a developer, I want automated ISO builds on CI so that every commit produces a testable ISO | ✅ | 2-3 | 5 | 🔴 Todo |
| US-003-03 | EPIC-003 | As a user, I want automatic disk partitioning (disko) so that I don't need to manually partition | ✅ | 3 | 5 | 🔴 Todo |
| US-003-04 | EPIC-003 | As a user, I want to see BamOS branding (boot screen, wallpaper) so that the distro feels professional | ✅ | 4 | 3 | 🔴 Todo |
| US-003-02 | EPIC-003 | As a user, I want a graphical installer (Calamares) so that I can install BamOS without terminal | — | 4-5 | 13 | 🔴 Todo |
| US-003-06 | EPIC-003 | As a developer, I want to test the ISO in QEMU VM so that I can verify it works before release | ✅ | 5 | 3 | 🔴 Todo |

**Total:** 37 SP (effective ~42 SP with buffer for edge cases)

---

## Day-by-Day Plan

### Day 1 (2026-07-03): Architecture & ISO Scaffold
- [ ] Review flake.nix, xác định ISO output structure (`hosts/iso/`)
- [ ] Tích hợp nixos-generators vào flake outputs
- [ ] Tạo `profiles/gnome-standard.nix` — tổ hợp modules cho GNOME Standard
- [ ] Include Fcitx5+Bamboo (US-005-08) trong ISO profile
- [ ] `nix flake check` — xác nhận flake structure hợp lệ
- **Output:** ISO profile skeleton, flake output `iso-gnome-standard` defined

### Day 2 (2026-07-04): First ISO Build + CI Pipeline
- [ ] Build ISO GNOME Standard lần đầu: `nix build .#iso-gnome-standard`
- [ ] Fix build errors (missing packages, config conflicts, module import issues)
- [ ] Include Flatpak + Flathub (US-005-02) trong ISO
- [ ] Verify ISO size, ghi nhận để tối ưu sau
- [ ] Setup Cachix cache cho ISO builds
- [ ] CI/CD pipeline: `.github/workflows/ci.yml` — add ISO build job
- **Output:** ISO build thành công locally + CI pipeline active

### Day 3 (2026-07-05): Disko Auto-Partitioning
- [ ] Cấu hình disko module cho Btrfs subvolumes: `@`, `@home`, `@nix`
- [ ] Tích hợp disko config vào ISO installer
- [ ] Test auto-partitioning logic: verify partition layout
- [ ] Verify rollback capability: `/nix` và `/home` survive reinstall
- **Output:** Disko config hoạt động trong ISO, partition layout verified

### Day 4 (2026-07-06): Branding + Calamares Setup
- [ ] Tạo placeholder BamOS branding assets (wallpaper 1920x1080, logo SVG)
- [ ] Cấu hình plymouth boot screen với BamOS logo
- [ ] Cấu hình Calamares: branding (`bamos-installer` module)
- [ ] Calamares modules: locale, keyboard, partition (disko), user, summary
- [ ] Rebuild ISO với branding + Calamares
- **Output:** ISO có BamOS branding, Calamares installer skeleton

### Day 5 (2026-07-07): Calamares Completion + Testing
- [ ] Hoàn thiện Calamares config: tất cả steps hoạt động
- [ ] Test ISO boot trong QEMU VM: `qemu-system-x86_64 -enable-kvm -m 4G -cdrom`
- [ ] Verify flow: boot → Calamares → install → reboot → GNOME desktop
- [ ] Verify: gõ tiếng Việt hoạt động (Telex, VNI)
- [ ] Verify: Flatpak apps cài được qua Software Center
- **Output:** ISO installable trong VM, full flow verified

### Day 6-7 (2026-07-08 → 2026-07-09): Buffer — Fix & Polish
- [ ] Xử lý edge cases từ QEMU testing
- [ ] Tối ưu ISO size (nếu > 3GB)
- [ ] Viết `docs/installation.md` — hướng dẫn cài đặt
- [ ] Test trên bare metal nếu có sẵn máy test
- **Output:** ISO sẵn sàng cho release candidate

### Day 8-10 (2026-07-10 → 2026-07-12): Final Testing + Release
- [ ] Test ISO trên ít nhất 2 cấu hình (VM + bare metal nếu có)
- [ ] Fix critical bugs
- [ ] Sprint review → `sprint-review.md`
- [ ] Retrospective → `sprint-retro.md`
- [ ] Merge `sprint/01/iso-gnome-standard` → `master`
- [ ] Git tag `v0.1.0`
- [ ] GitHub Release với ISO download
- **Output:** v0.1.0 released 🚀

---

## Burndown

| Date | Day | SP Remaining | SP Completed | Notes |
|------|-----|-------------|--------------|-------|
| 2026-07-03 | 1 | 37 | 0 | Sprint started — architecture & scaffold |
| | 2 | | | |
| | 3 | | | |
| | 4 | | | |
| | 5 | | | |
| | 6 | | | |
| | 7 | | | |
| | 8 | | | |
| | 9 | | | |
| | 10 | | | |

---

## Impediments
- [ ] Cần Cachix auth token cho CI pipeline → thêm `CACHIX_AUTH_TOKEN` vào GitHub Secrets
- [ ] Calamares + NixOS integration: tài liệu hạn chế, cần nghiên cứu từ nixos-anywhere và các dự án tương tự
- [ ] ISO size có thể vượt 3GB target (GNOME + apps) → accept ở Sprint 1, optimize ở Sprint 2+

---

## Definition of Done (AI-Enhanced)
- [ ] `nix build .#iso-gnome-standard` thành công không lỗi
- [ ] `nix flake check` passes
- [ ] ISO boot trong QEMU: `qemu-system-x86_64 -enable-kvm -m 4G`
- [ ] Calamares installer hoàn thành tất cả steps không lỗi
- [ ] Sau install: boot vào GNOME desktop
- [ ] Gõ tiếng Việt Telex, VNI hoạt động ngay
- [ ] Flatpak apps cài được qua Software Center
- [ ] CI/CD pipeline build ISO tự động trên push
- [ ] AI-generated code reviewed by human
- [ ] Sprint review + retro completed
- [ ] Branch merged to master
- [ ] Git tag `v0.1.0` created

---

## Git Workflow for This Sprint

```bash
# Start sprint
git checkout -b sprint/01/iso-gnome-standard master

# Daily commits — map to user stories
git commit -m "feat(US-003-01): add nixos-generators ISO config to flake"
git commit -m "feat(US-005-08): include Fcitx5+Bamboo in ISO profile"
git commit -m "feat(US-003-05): add ISO build job to CI pipeline"
git commit -m "feat(US-003-03): configure disko Btrfs auto-partitioning"
git commit -m "feat(US-003-04): add BamOS branding (plymouth, wallpaper)"
git commit -m "feat(US-003-02): configure Calamares installer"
git commit -m "test(US-003-06): verify ISO boots in QEMU"
git commit -m "docs: add installation guide"

# End sprint
git checkout master
git merge sprint/01/iso-gnome-standard
git tag v0.1.0 -m "BamOS v0.1.0 — First Light: GNOME Standard ISO"
git push origin master --tags
```
