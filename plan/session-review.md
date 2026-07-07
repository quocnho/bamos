# Session Review: Full Conversation Audit

**Date:** 2026-07-07
**Status:** 🟡 Draft — chờ xác nhận

## Legend
- ✅ Hoàn thành
- 🟡 Một phần (cần hoàn thiện)
- ⏳ Chưa thực hiện
- ❌ Đã huỷ/hủy bỏ

---

## 1. 🏗️ Architecture & Codebase Organization

| # | Yêu cầu | Trạng thái | File/Chi tiết |
|---|---------|-----------|---------------|
| 1.1 | Tổ chức /modules thành thư mục con (hardware, boot, core...) | ✅ | modules/hardware/, modules/boot/, modules/core/, modules/desktop/, modules/editions/, modules/apps/, modules/theming/ |
| 1.2 | .gitignore — iso/, result, tmp/, qcow2 | ✅ | .gitignore: 14 patterns |
| 1.3 | Xoá ISO 3.3GB khỏi git history | ✅ | git filter-branch + gc |
| 1.4 | Kiểm tra trùng lặp packages | ✅ | Xoá 10 duplicates khỏi hosts/lg/configuration.nix |
| 1.5 | Thêm hardware detect tools | ✅ | pciutils, usbutils, dmidecode, inxi, mesa-demos |

## 2. 🖥️ NVIDIA Setup

| # | Yêu cầu | Trạng thái | Chi tiết |
|---|---------|-----------|----------|
| 2.1 | services.xserver.videoDrivers = [ "nvidia" ] | ✅ | modules/hardware/nvidia.nix |
| 2.2 | Từ beta → stable driver | ✅ | nvidiaPackages.stable (595.84) |
| 2.3 | Bus IDs: intelBusId, nvidiaBusId | ✅ | "PCI:0:2:0" + "PCI:2:0:0" |
| 2.4 | Prime offload mode | ✅ | nvidia-offload command |
| 2.5 | Power management | ✅ | RTD3 fine-grained |
| 2.6 | NVIDIA đang chạy sau reboot | ✅ | nvidia-smi: 595.84, GTX 1650 |

## 3. ⚡ Power Management (tuned)

| # | Yêu cầu | Trạng thái | Chi tiết |
|---|---------|-----------|----------|
| 3.1 | Thay PPD bằng tuned | ✅ | modules/hardware/power-management.nix |
| 3.2 | PPD bridge (GNOME integration) | ✅ | services.tuned.ppdSupport = true |
| 3.3 | profile theo edition | ✅ | Standard→desktop, Developers→throughput-performance, Gaming/Studio→latency-performance |
| 3.4 | Battery optimization cho laptop | ✅ | ASPM, WiFi power save, runtime PM |
| 3.5 | Swap file 16GB | ✅ | swapfile.swap active |
| 3.6 | dynamic_tuning (thay auto-cpufreq) | ✅ | services.tuned.settings.dynamic_tuning |
| 3.7 | Case study LG Gram | ✅ | CPU governor powersave, ~2.6GHz, NVIDIA ~4W idle |

## 4. 🎨 Theming (RakuOS-inspired)

| # | Yêu cầu | Trạng thái | Chi tiết |
|---|---------|-----------|----------|
| 4.1 | Nordic GTK theme | ✅ | modules/theming/gnome-theme.nix |
| 4.2 | WhiteSur-dark icons | ✅ | whitesur-icon-theme |
| 4.3 | Bibata cursors | ✅ | bibata-cursors |
| 4.4 | Font: Inter 11 + Maple Mono NF 11 | ✅ | fonts.packages |
| 4.5 | GNOME extensions | ✅ | appindicator, no-overview, dash-to-dock, blur-my-shell, user-themes |
| 4.6 | System GTK settings.ini | ✅ | /etc/gtk-3.0/ + /etc/gtk-4.0/ |
| 4.7 | First-login gsettings activator | ✅ | bamos-gnome-first-login |
| 4.8 | DE-specific theme modules | ✅ | gnome-theme.nix, kde-theme.nix, cosmic-theme.nix |

## 5. 📦 Software Center & Apps

| # | Yêu cầu | Trạng thái | Chi tiết |
|---|---------|-----------|----------|
| 5.1 | GNOME Software + Flatpak | ✅ | modules/desktop/software-center.nix |
| 5.2 | AppImage support (binfmt) | ✅ | gearlever + appimage-run |
| 5.3 | WPS Office | ❌ Đã gỡ | Xoá khỏi software-center.nix, hosts/lg |
| 5.4 | curatedApps dọn gọn | ✅ | Chỉ Firefox, Chromium, VLC |
| 5.5 | installCuratedApps = false | ✅ | hosts/lg/configuration.nix |

## 6. 💿 Calamares Installer

| # | Yêu cầu | Trạng thái | Chi tiết |
|---|---------|-----------|----------|
| 6.1 | Partition Btrfs Ổ C — Ổ D | ✅ | partition.conf + mount.conf |
| 6.2 | Edition selector (packagechooser) | 🟡 Config OK, cần test ISO | packagechooser-edition.conf |
| 6.3 | Machine type selector | 🟡 Config OK, cần test ISO | packagechooser-machine.conf |
| 6.4 | Custom Python module bamos-config | 🟡 Code OK, cần test ISO | Sinh edition-config.nix + /iso-cfg |
| 6.5 | settings.conf override | 🟡 Code OK, cần test ISO | Thêm custom instances |
| 6.6 | Branding (logo, colors, slideshow) | 🟡 Config OK, cần screenshots | branding.desc |
| 6.7 | /iso-cfg flake template | 🟡 Code OK, cần test ISO | flake.nix → github:quocnho/bamos |
| 6.8 | 12 ISOs → 3 unified ISOs | ⏳ | Cần tái cấu trúc hosts/iso/ |

## 7. 🗄️ Ổ D Integration

| # | Yêu cầu | Trạng thái | Chi tiết |
|---|---------|-----------|----------|
| 7.1 | /data mount trong Calamares | ✅ | btrfsSubvolumes |
| 7.2 | Nautilus bookmark | ✅ | dconf: org/gnome/nautilus/preferences |
| 7.3 | Custom drive icon | 🟡 SVG tạo, PNG cần rsvg-convert fix | drive-data.svg |
| 7.4 | XDG user dirs → /data | ✅ | systemd.tmpfiles |

## 8. 🔧 Các yêu cầu khác

| # | Yêu cầu | Trạng thái | Chi tiết |
|---|---------|-----------|----------|
| 8.1 | GitHub SSH setup | ✅ | key added, auth OK |
| 8.2 | Push code lên GitHub | ⏳ | Cần tạo repo trên github.com/quocnho/bamos |
| 8.3 | idea.md update | ✅ | Phase 7-11 updated |
| 8.4 | Plan/Sprint update | ✅ | Sprint 5 (Auto-Detect), Sprint 6 (Unified Installer) |

---

## 📊 Status Summary

| Khu vực | Tổng số | ✅ Done | 🟡 Partial | ⏳ Todo | ❌ Cancelled |
|---------|---------|---------|------------|---------|-------------|
| Architecture | 5 | 5 | 0 | 0 | 0 |
| NVIDIA | 6 | 6 | 0 | 0 | 0 |
| Power Management | 7 | 7 | 0 | 0 | 0 |
| Theming | 8 | 8 | 0 | 0 | 0 |
| Software Center | 5 | 3 | 0 | 0 | 2 |
| Calamares Installer | 8 | 1 | 6 | 1 | 0 |
| Ổ D Integration | 4 | 3 | 1 | 0 | 0 |
| Other | 4 | 3 | 0 | 1 | 0 |
| **Total** | **47** | **36** | **7** | **2** | **2** |

## 🎯 Kế hoạch hoàn thiện

### Sprint 6 — Unified Calamares Installer (còn lại)

| Priority | Task | File | Dependencies |
|----------|------|------|-------------|
| 🔴 P1 | Test ISO build với Calamares mới | `nix build .#iso-gnome-standard` | Calamares config |
| 🔴 P2 | Fix drive icon SVG → PNG | modules/boot/calamares.nix | librsvg |
| 🟡 P3 | Thêm screenshot images cho packagechooser | assets/calamares/ | Design |
| 🟡 P4 | Tạo repo GitHub + push code | github.com/quocnho/bamos | SSH key |
