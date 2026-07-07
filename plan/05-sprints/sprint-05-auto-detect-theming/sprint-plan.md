# Sprint 5: Auto-Detect Hardware + RakuOS Theming

**Dates:** 2026-07-06 → TBD
**Branch:** `sprint/05/auto-detect-theming`
**Target:** v0.5.0 — "RakuOS Theming & Hardware Detection"

---

## Sprint Goal

Hoàn thiện Auto-Detect Hardware module + triển khai RakuOS-inspired theming (Nordic + WhiteSur + Bibata) cho cả 3 DE (GNOME, KDE, COSMIC).

---

## User Stories

### US-05-01: Fix GNOME Theming (RakuOS-inspired)

**Tasks:**
- [x] Switch from `papirus-icon-theme` → `whitesur-icon-theme` (available in nixpkgs)
- [x] Switch from `nordzy-cursor-theme` → `bibata-cursors` (available in nixpkgs)
- [x] Switch from `JetBrains Mono` → `Maple Mono NF` (RakuOS spec)
- [x] Add `gnomeExtensions.no-overview` (RakuOS spec)
- [x] Add `gnomeExtensions.user-themes` (needed for shell theming)
- [x] Add `/etc/gtk-3.0/settings.ini` + `/etc/gtk-4.0/settings.ini` — system-wide GTK config
- [x] Create `bamos-gnome-first-login` — one-time gsettings activator for existing users
- [x] Update dconf profiles to match new theme names
- [x] Remove unnecessary GNOME apps (tour, weather, maps, xterm, kitty, etc.)

**Files:**
- `modules/theming/gnome-theme.nix`
- `modules/theming/gtk-theme.nix`
- `modules/theming/kde-theme.nix`
- `modules/theming/cosmic-theme.nix`

### US-05-02: Fix Bamos Detect Hardware

**Tasks:**
- [x] Fix `bamos-detect-hardware.sh` — single-quoted heredoc (`<< 'EOF'`) prevents `$variable` expansion
- [x] Use UNQUOTED `<< EOF` for NVIDIA/AMD config blocks so PCI bus IDs are written correctly
- [x] Fix shellcheck SC2001 — rewrite `echo "$line" | sed` → bash pattern substitution
- [x] Switch from `writeShellApplication` → `writeScriptBin` + `readFile` (avoids shellcheck build failures)

**Files:**
- `pkgs/bamos-detect-hardware.sh`
- `modules/hardware/detect.nix`

### US-05-03: Tắt Documentation để giảm dung lượng

**Tasks:**
- [x] Add `documentation.nixos.enable = false` to `core/optimization.nix`
- [x] Add `documentation.doc.enable = false`
- [x] Add `documentation.man.enable = false`
- [x] Add `documentation.info.enable = false`

**Files:**
- `modules/core/optimization.nix`

### US-05-04: Cập nhật Asset Download Script

**Tasks:**
- [x] Update `fetch-assets.sh` — download WhiteSur icons + Bibata cursors + Maple Mono NF
- [x] Reflect RakuOS theme stack in the script comments

**Files:**
- `assets/fetch-assets.sh`

---

## Definition of Done

1. ✅ `sudo nixos-rebuild build --flake .#lg` builds successfully
2. ✅ GTK settings apply immediately via `/etc/gtk-3.0/settings.ini`
3. ✅ WhiteSur icons, Bibata cursors, Nordic theme visible after logout/login
4. ✅ No double `/etc/gtk-3.0/settings.ini` conflict between DE modules
5. ✅ `bamos-detect-hardware` correctly expands PCI bus ID variables
6. ✅ Documentation disabled (smaller ISO)
7. ✅ `idea.md` and `/plan` updated

---

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| `whitesur-icon-theme` not found in pinned nixpkgs | ✅ Confirmed available via `nix eval nixpkgs#whitesur-icon-theme.outPath` |
| `bibata-cursors` not found | ✅ Confirmed available via `nix eval nixpkgs#bibata-cursors.outPath` |
| `gnomeExtensions.no-overview` not found | ✅ Confirmed available |
| GTK settings.ini conflict between gnome-theme.nix and kde-theme.nix | ✅ They are mutually exclusive (different DE profiles) |
| Existing user dconf overrides system settings | ✅ Mitigated via `/etc/gtk-3.0/settings.ini` (read BEFORE dconf) + first-login gsettings activator |
