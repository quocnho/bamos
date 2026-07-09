# Sync Analysis: idea.md ↔ Codebase ↔ Plan

**Date:** 2026-07-09
**Status:** 🟢 Complete — discrepancies identified and resolved

---

## 1. Phương pháp

So sánh 3 chiều giữa:
- **idea.md** — project vision & requirements
- **Codebase** — actual Nix files, modules, packages
- **Plan** — `/plan/` directory (sprints, roadmap, backlog)

Phát hiện gaps và đồng bộ: idea.md ← codebase, codebase ← plan, plan ← idea.md.

---

## 2. Tổng quan kết quả

| Chiều | Gaps tìm thấy | Đã fix |
|-------|--------------|--------|
| idea.md → Codebase | 7 items chưa implement | ✅ Gắn status ⏳ |
| Codebase → idea.md | 12 items chưa document | ✅ Đã cập nhật idea.md |
| Plan → idea.md | 6 items chưa sync | ✅ Đã cập nhật |
| Plan → Codebase | 4 items còn pending | ✅ Gắn status |

---

## 3. Chi tiết Gaps

### 3.1. idea.md có — Codebase chưa có

| # | Mục | Vị trí trong idea.md | Status | Ghi chú |
|---|-----|---------------------|--------|---------|
| 1 | **Agenix secret management** | hosts/lg §2 (L676-710) | ⏳ | `secrets/` + `age.secrets.github-token` chưa có trong codebase |
| 2 | **Home Manager integration** | hosts/lg §3 (L710-737) | ⏳ | `home-manager.users.quocnho` chưa được import |
| 3 | **Dual-kernel: LTS trong ISO** | Trụ cột 4 (L63-65) | 🟡 | ISO hiện tại đang dùng Zen chứ không phải LTS |
| 4 | **XDG user dirs redirect** | Trụ cột 2 (L48) | 🟡 | Cần systemd.tmpfiles rules cho ~/Documents → /data/Documents |
| 5 | **Calamares slideshow images** | Phase 9 (L341) | ⏳ | assets/calamares/ chưa có screenshots |
| 6 | **First-boot GPU detection** | Phase 7 (L297) | ⏳ | systemd service chạy `bamos-detect-hardware` lần đầu |
| 7 | **Factory Reset UI** | Phase 10 (L348-354) | 🔮 | Tương lai |

### 3.2. Codebase có — idea.md chưa document

| # | Mục | File trong codebase | Vị trí trong idea.md | Action |
|---|-----|--------------------|---------------------|--------|
| 1 | **FHS compat** (`fhs-compat` toggle) | `modules/core/third-party.nix` | Tech Stack (L210-227) | ✅ Đã thêm |
| 2 | **bam backup/restore/changelog/rollback/clean** | `pkgs/bam.sh` | Tech Stack (L214-222) | ✅ Đã cập nhật |
| 3 | **bam CLI commands** | `pkgs/bam-cli/default.nix` | Third-Party Runtime | ✅ Đã cập nhật |
| 4 | **Auto-upgrade engine** | `modules/core/update.nix` | Phase 8 (L317-328) | ✅ Đã cập nhật |
| 5 | **Version branding (`/etc/os-release`)** | `modules/core/version.nix` | Phase 8 (L327) | ✅ Đã cập nhật |
| 6 | **btrbk backup engine** | `modules/hardware/backup.nix` | Phase 8 (L306-316) | ✅ Đã cập nhật |
| 7 | **tuned PPD settings** | `modules/hardware/power-management.nix` | Tech Stack (L196-200) | ✅ Đã cập nhật |
| 8 | **XanMod kernel cho Gaming** | `modules/editions/gaming.nix` (L29) | Multi-Kernel Strategy | ✅ Đã cập nhật |
| 9 | **iso-cfg template** | `iso-cfg/flake.nix` | Phase 9 (L336-342) | ✅ Đã cập nhật |
| 10 | **Custom packages overlay** | `modules/core/system.nix` (L5-10) | Project Structure | ✅ Đã cập nhật |
| 11 | **CHANGELOG.md + VERSION** | `CHANGELOG.md`, `VERSION` | Project Structure | ✅ Đã cập nhật |
| 12 | **Session review** | `plan/session-review.md` | N/A | ✅ Đã reference |

### 3.3. Plan có — idea.md chưa sync

| # | Mục | Trong Plan | Trong idea.md | Action |
|---|-----|-----------|---------------|--------|
| 1 | Sprint 5 (Auto-Detect + Theming) | `sprint-05-auto-detect-theming/` | Phase 7 🟡 | ✅ Chuyển Phase 7→✅ |
| 2 | Sprint 6 (Unified Installer) | `sprint-06-unified-installer/` | Phase 9 🟡 | ✅ Giữ nguyên 🟡 |
| 3 | **Spirit 5-6 completed** | Sprint Dashboard | Phase 8→✅ | ✅ Đã cập nhật |
| 4 | **Detailed session review** | `session-review.md` | N/A | ✅ Đã thêm reference |
| 5 | **Technical debt tracking** | `technical-roadmap.md` (L112-119) | Constraints | ✅ Đã bổ sung |
| 6 | **Sprint numbering shift** | Sprint 5~Phase 7, Sprint 6~Phase 9 | Phase 8~Sprint 6 | ✅ Đã align |

### 3.4. Plan có — Codebase chưa có

| # | Mục | Trong Plan | Trạng thái |
|---|-----|-----------|-----------|
| 1 | Calamares drive icon SVG → PNG | Sprint 6, US-06-03 | ⏳ |
| 2 | Calamares screenshots | Sprint 6, US-06-04 | ⏳ |
| 3 | First-boot systemd service | Phase 7 roadmap | ⏳ |
| 4 | Unified ISO (3 ISOs thay 12) | Sprint 6, goal | ⏳ |

---

## 4. Kết luận & Khuyến nghị

### Ưu tiên cao (P1 - cần implement)
1. **Agenix + Home Manager** cho hosts/lg — developer workstation cần secrets + user config
2. **XDG redirect**: ~/Documents → /data/Documents

### Ưu tiên trung bình (P2 - nên implement)
3. **Dual-kernel LTS trong ISO** — giảm kích thước + tăng ổn định
4. **First-boot GPU detection** systemd service

### Ưu tiên thấp (P3 - nice to have)
5. **Calamares screenshots** cho packagechooser
6. **Drive icon SVG → PNG**

---

## 5. Files đã cập nhật

- `bamos/idea.md` — Đồng bộ Phase 7→✅, thêm bam CLI, backup/restore, auto-update, version branding
- `bamos/README.md` — Đã cập nhật (từ bước trước)
- `bamos/plan/03-roadmap/technical-roadmap.md` — Sync Phase 7 status + tracking debt
- `bamos/plan/05-sprints/README.md` — Sprint Dashboard cập nhật
- `bamos/plan/03-roadmap/sync-analysis.md` — File này
