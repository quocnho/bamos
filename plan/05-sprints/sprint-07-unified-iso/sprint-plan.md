# Sprint 7: Unified ISO — 3 ISOs thay 12, giữ nguyên keyboard + cấu hình

**Dates:** 2026-07-09 → 2026-07-09
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

### US-07-04: Update CI/CD pipeline
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
3. Update `.github/workflows/ci.yml` — build matrix
4. Update docs

---

## Definition of Done

1. ✅ `nix flake check` passes
2. ✅ 3 ISO builds work: `nix build .#iso-gnome-unified`
3. ✅ Edition selection in Calamares works
4. ✅ All existing keyboard config preserved
5. ✅ CI/CD updated
