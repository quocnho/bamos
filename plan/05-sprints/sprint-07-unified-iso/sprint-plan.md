# Sprint 7: Unified ISO — 3 ISOs thay 12, giữ nguyên keyboard + cấu hình

**Dates:** 2026-07-09 → 2026-07-10
**Branch:** `sprint/07/unified-iso`
**Target:** v0.7.0

---

## Goal

Gộp 12 ISO variants thành 3 unified ISO (GNOME/KDE/COSMIC). Edition + Machine Type được chọn trong Calamares (đã có sẵn từ Sprint 6). Giữ nguyên keyboard specialisations, locale, NVIDIA, và mọi cấu hình BamOS hiện tại.

---

## Backlog

### US-07-01: Reduce ISO variants — 12 → 3 unified
- [ ] `hosts/iso/default.nix`: Remove per-edition variants, keep only gnome/kde/cosmic
- [ ] `flake.nix`: Update packages list — 3 ISOs instead of 12
- [ ] `lib/mkISO.nix`: Keep as-is (still works with any nixosConfiguration)

### US-07-02: Add profile import back into unified ISO
- [ ] Each unified ISO imports a **default** profile (e.g., gnome-standard.nix)
- [ ] Edition switching happens via Calamares customized.nix (already implemented)
- [ ] Keep all 4 editions selectable during install

### US-07-03: Verify keyboard specialisations
- [ ] GLF-OS pattern: keyboard-setup service + kernel params
- [ ] BamOS chỉ cần us layout + Fcitx5 Bamboo cho tiếng Việt
- [ ] Giữ nguyên `keyboard-setup` nếu có, không thêm mới

### US-07-04: Update CI/CD pipeline (ublue-os pattern)
- [ ] `ci.yml` — Refactor: chỉ chạy cho PR + non-main, build GNOME + VM test
- [ ] `release.yml` — NEW: push to main → build 3 ISOs, auto tag, GitHub Release
- [ ] `release-cd.yml` — NEW: tag push → deploy ISOs lên Cloudflare R2 + Cosign sign
- [ ] `.github/scripts/generate-changelog.py` — Script sinh changelog từ git history
- [ ] Build matrix: 3 unified ISOs instead of 12
- [ ] VM test chỉ cần test GNOME unified

### US-07-05: Update documentation
- [ ] idea.md: Update Phase 9 with unified ISO
- [ ] README.md: Update build commands
- [ ] Sprint dashboard: Mark Sprint 7

---

## Day-by-Day Plan

### Day 1 (2026-07-09): Core Implementation
1. Update `hosts/iso/default.nix` — 3 unified variants
2. Update `flake.nix` — 3 ISO packages
3. Update `.github/workflows/ci.yml` — build matrix + refactor
4. Update docs

### Day 2 (2026-07-10): CI/CD Pipeline (ublue-os pattern)
1. Create `.github/workflows/release.yml` — auto-release on push to main
2. Create `.github/workflows/release-cd.yml` — Cloudflare R2 deploy + signing
3. Create `.github/scripts/generate-changelog.py` — changelog generator
4. Create `.github/scripts/generate-metadata.sh` — metadata generator
5. Test validation: `nix flake check`, workflow lint
6. Update sprint docs + daily scrum

---

## Definition of Done

1. ✅ `nix flake check` passes
2. ✅ 3 ISO builds work: `nix build .#iso-gnome-unified`
3. ✅ Edition selection in Calamares works
4. ✅ All existing keyboard config preserved
5. ✅ `ci.yml` — quick validation cho PR (build GNOME + VM test)
6. ✅ `release.yml` — main → build 3 ISOs + Cachix + auto tag + GitHub Release
7. ✅ `release-cd.yml` — tag → Cloudflare R2 + Cosign sign + metadata
8. ✅ `generate-changelog.py` — auto-changelog từ conventional commits
