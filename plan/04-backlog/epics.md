# Epics

> An epic is a large body of work that can be broken down into user stories.
> Mỗi Epic tương ứng với một Phase trong Technical Roadmap.

| ID | Epic | Goal | Stories | Status |
|----|------|------|---------|--------|
| EPIC-001 | Core Foundation | Nền tảng NixOS + flake-parts vững chắc | 6 | 🟢 Done |
| EPIC-002 | Bản Địa Hóa | Trải nghiệm tiếng Việt OOTB | 5 | 🟢 Done |
| EPIC-003 | Distro ISO Build | ISO bootable đầu tiên có thể cài đặt | 6 | 🔄 Active |
| EPIC-004 | Multi-DE Support | 3 Desktop Environments hoàn chỉnh | 6 | 🔴 Backlog |
| EPIC-005 | Edition Profiles | 4 Editions với đầy đủ apps | 8 | 🔴 Backlog |
| EPIC-006 | BamOS Portal | GUI system settings app | 5 | 🔴 Backlog |
| EPIC-007 | Complete 3×4 Matrix | Tối ưu + ổn định 12 variants | 5 | 🔴 Backlog |
| EPIC-008 | Community Platform | Website, docs, cộng đồng | 5 | 🔴 Backlog |

---

## Epic Details

### EPIC-001: Core Foundation ✅
**Goal:** Thiết lập nền tảng NixOS + flake-parts để xây dựng distro
**Value Hypothesis:** NixOS declarative + immutable sẽ giải quyết vấn đề "sợ cài lại OS" và "dependency hell"
**Success Metrics:** 
- flake.nix build thành công không lỗi
- GNOME desktop boot được
- systemd-boot hoạt động
**Status:** 🟢 Hoàn thành

### EPIC-002: Bản Địa Hóa ✅
**Goal:** Người dùng Việt gõ tiếng Việt ngay sau cài đặt, không cần terminal
**Value Hypothesis:** Fcitx5+Bamboo OOTB sẽ là USP chính thu hút người dùng Việt
**Success Metrics:**
- Gõ tiếng Việt Telex, VNI trên mọi ứng dụng (GTK, Qt, Electron)
- Locale VN, timezone HCM hoạt động
- Fonts tiếng Việt hiển thị đúng
**Status:** 🟢 Hoàn thành

### EPIC-003: Distro ISO Build 🔄
**Goal:** Tạo ISO có thể boot, cài đặt, và sử dụng — sẵn sàng phân phối
**Value Hypothesis:** ISO là điều kiện tiên quyết để BamOS trở thành distro thực sự, không chỉ là dotfiles
**Success Metrics:**
- ISO GNOME Standard boot được trên QEMU + bare metal
- Calamares installer hoạt động
- Disko auto-partitioning hoạt động
- CI/CD build ISO tự động
**Dependencies:** EPIC-001, EPIC-002
**Risks:** Calamares + NixOS integration phức tạp; ISO size có thể > 3GB
**Status:** 🔄 Đang thực hiện

### EPIC-004: Multi-DE Support
**Goal:** Hỗ trợ KDE Plasma và COSMIC bên cạnh GNOME
**Value Hypothesis:** 3 DE giúp BamOS phục vụ được mọi đối tượng người dùng
**Success Metrics:**
- KDE Plasma + SDDM boot thành công
- COSMIC + cosmic-greeter boot thành công
- Mỗi DE có theme riêng (BamOS branding)
**Dependencies:** EPIC-003
**Risks:** COSMIC chưa stable; KDE config phức tạp hơn GNOME

### EPIC-005: Edition Profiles
**Goal:** Hoàn thiện 4 Editions (Standard, Developers, Gaming, Studio) cho mỗi DE
**Value Hypothesis:** Editions chuyên biệt giúp BamOS phục vụ đúng nhu cầu từng phân khúc
**Success Metrics:**
- Standard: Firefox, LibreOffice, VLC, Flatpak hoạt động
- Developers: devenv + Podman + dev tools hoạt động
- Gaming: Steam + Proton + GameScope + MangoHud hoạt động
- Studio: Blender + Kdenlive + Ardour + low-latency audio hoạt động
**Dependencies:** EPIC-003, EPIC-004

### EPIC-006: BamOS Portal
**Goal:** Ứng dụng GUI giúp người dùng quản lý hệ thống không cần terminal
**Value Hypothesis:** Portal giúp người dùng phổ thông sử dụng BamOS mà không sợ terminal
**Success Metrics:**
- Cài đặt ngôn ngữ, theme, font qua GUI
- Quản lý Flatpak apps
- Factory Reset 1-click
- System update notification

### EPIC-007: Complete 3×4 Matrix
**Goal:** Tối ưu và ổn định tất cả 12 ISO variants
**Value Hypothesis:** 12 variants chất lượng cao = BamOS sẵn sàng cho mass adoption
**Success Metrics:**
- Tất cả 12 ISO build thành công trên CI/CD
- Mỗi ISO < 3GB
- Test automation cho tất cả variants

### EPIC-008: Community Platform
**Goal:** Xây dựng cộng đồng người dùng và contributors
**Value Hypothesis:** Cộng đồng là moat bền vững nhất
**Success Metrics:**
- Website bamos.vn hoạt động
- Tài liệu tiếng Việt 100%
- 10+ active contributors
- 500+ GitHub stars
