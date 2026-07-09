# Epics

> An epic is a large body of work that can be broken down into user stories.
> Mỗi Epic tương ứng với một Phase trong Technical Roadmap.

| ID | Epic | Goal | Stories | Status |
|----|------|------|---------|--------|
| EPIC-001 | Core Foundation | Nền tảng NixOS + flake-parts vững chắc | 6 | 🟢 Done |
| EPIC-002 | Bản Địa Hóa | Trải nghiệm tiếng Việt OOTB | 5 | 🟢 Done |
| EPIC-003 | Distro ISO Build | ISO bootable đầu tiên có thể cài đặt | 6 | 🟢 Done |
| EPIC-004 | Multi-DE Support | 3 Desktop Environments hoàn chỉnh | 6 | 🟢 Done |
| EPIC-005 | Edition Profiles | 4 Editions với đầy đủ apps | 8 | 🟢 Done |
| EPIC-009 | Developer Workstation | hosts/lg dev machine | 4 | 🟢 Done |
| EPIC-010 | Auto-Detect + Power Mgmt | Hardware detection + tuned | 6 | 🟢 Done |
| EPIC-011 | Backup & Restore + Auto Update | Btrfs backup + update engine | 8 | 🟢 Done |
| EPIC-012 | Unified Calamares Installer | Unified installer GUI | 6 | 🟡 Active |
| EPIC-006 | BamOS Portal | GUI system settings app | 5 | 🔴 Future |
| EPIC-007 | Complete 3×4 Matrix | Tối ưu + ổn định 12 variants | 5 | 🔴 Future |
| EPIC-008 | Community Platform | Website, docs, cộng đồng | 5 | 🔴 Future |

---

## Epic Details

### EPIC-001: Core Foundation ✅
**Goal:** Thiết lập nền tảng NixOS + flake-parts để xây dựng distro
**Status:** 🟢 Hoàn thành

### EPIC-002: Bản Địa Hóa ✅
**Goal:** Người dùng Việt gõ tiếng Việt ngay sau cài đặt, không cần terminal
**Status:** 🟢 Hoàn thành

### EPIC-003: Distro ISO Build ✅
**Goal:** Tạo ISO có thể boot, cài đặt, và sử dụng — sẵn sàng phân phối
**Status:** 🟢 Hoàn thành

### EPIC-004: Multi-DE Support ✅
**Goal:** Hỗ trợ KDE Plasma và COSMIC bên cạnh GNOME
**Status:** 🟢 Hoàn thành

### EPIC-005: Edition Profiles ✅
**Goal:** Hoàn thiện 4 Editions (Standard, Developers, Gaming, Studio) cho mỗi DE
**Status:** 🟢 Hoàn thành

### EPIC-009: Developer Workstation ✅
**Goal:** hosts/lg với agenix + home-manager + GNOME extensions + dev tools
**Status:** 🟢 Hoàn thành

### EPIC-010: Auto-Detect + Power Management ✅
**Goal:** Auto-detect GPU + tuned power management + battery optimization
**Files:** `modules/hardware/detect.nix`, `power-management.nix`, `bamos-detect-hardware.sh`
**Status:** 🟢 Hoàn thành

### EPIC-011: Backup & Restore + Auto Update ✅
**Goal:** Btrfs snapshot engine + bam backup/restore + interactive update engine
**Files:** `modules/hardware/backup.nix`, `modules/core/update.nix`, `pkgs/bam.sh`
**Status:** 🟢 Hoàn thành

### EPIC-012: Unified Calamares Installer 🟡
**Goal:** Unified installer với edition + machine type selector
**Status:** 🟡 Active (Sprint 6)

### EPIC-006: BamOS Portal 🔮
**Goal:** Ứng dụng GUI giúp người dùng quản lý hệ thống không cần terminal
**Status:** 🔴 Future

### EPIC-007: Complete 3×4 Matrix 🔮
**Goal:** Tối ưu và ổn định tất cả 12 ISO variants
**Status:** 🔴 Future

### EPIC-008: Community Platform 🔮
**Goal:** Xây dựng cộng đồng người dùng và contributors
**Status:** 🔴 Future
