# Technology Assessment: Software Center / App Store

**Date:** 2026-07-04
**Researched by:** AI Agent (tech skill)
**Status:** Draft

## Executive Summary

BamOS cần một Software Center để người dùng dễ dàng cài đặt, theo dõi và cập nhật ứng dụng
từ nhiều nguồn: Flatpak, AppImage, và Nix packages.

## Requirements Context

### Functional Requirements
- Duyệt và tìm kiếm ứng dụng
- Cài đặt / Gỡ bỏ / Cập nhật ứng dụng
- Hỗ trợ Flatpak (Flathub) + AppImage
- Hiển thị thông tin ứng dụng (screenshots, mô tả, đánh giá)
- Tích hợp với GNOME / KDE Desktop

### Non-Functional Requirements
- GUI thân thiện, phù hợp người dùng phổ thông
- Không yêu cầu terminal
- Cập nhật tự động (optional)

## Candidates Considered

### Candidate 1: GNOME Software (GNOME Software Center)
- **Nixpkgs:** `gnome-software` (v50.2)
- **Backend:** Flatpak + rpm-ostree + fwupd
- **GUI:** GTK4 + Libadwaita
- **Ưu điểm:**
  - Tích hợp sẵn với GNOME desktop
  - Hỗ trợ Flatpak + Flathub
  - Hiển thị screenshots, đánh giá
  - Cập nhật firmware (fwupd)
- **Nhược điểm:**
  - Chỉ hoạt động tốt trên GNOME
  - Không hỗ trợ AppImage native
- **Cấu hình NixOS:** `services.gnome.gnome-software.enable = true;`

### Candidate 2: KDE Discover
- **Nixpkgs:** `libsForQt5.discover` hoặc `kdePackages.discover`
- **Backend:** PackageKit + Flatpak + fwupd
- **GUI:** Qt + Kirigami
- **Ưu điểm:**
  - Tích hợp với KDE Plasma
  - Hỗ trợ Flatpak + PackageKit
  - Hỗ trợ firmware updates
- **Nhược điểm:**
  - Chỉ hoạt động tốt trên KDE
  - PackageKit không tối ưu cho NixOS
- **Cấu hình NixOS:** `services.kde.discover.enable = true;`

### Candidate 3: Flatpak CLI (Terminal)
- **Nixpkgs:** `flatpak` (v1.18.0) — đã cài sẵn
- **GUI:** GNOME Software / Discover làm GUI
- **Cấu hình:** `services.flatpak.enable = true;` ✅ Đã có

### Candidate 4: AppImageLauncher
- **Nixpkgs:** `appimage-run` + `appimage-launcher`
- **Mục đích:** Tích hợp AppImage vào desktop
- **Cấu hình:**
```nix
boot.binfmt.registrations.appimage = {
  wrapInterpreterInShell = true;
  interpreter = "${pkgs.appimage-run}/bin/appimage-run";
  recognitionType = "magic";
  offset = 0;
  mask = ''\xff\xff\xff\xff\x00\x00\x00\x00\xff\xff\xff'';
  magicOrExtension = ''\x41\x49\x02\x00\x00\x00\x00\x00\x00\x00\x00\x00'';
};
```

### Candidate 5: GLF-OS Pattern (Patched Calamares)
- **Cách làm:** Patch `calamares-nixos-extensions` để thêm edition selection
- **Chi tiết:** GLF-OS có `glf-apps` module + customizer GUI
- **State:** ⏳ Sprint 2+ — cần patch Calamares

## Recommendation

| Candidate | Score | Notes |
|-----------|-------|-------|
| **GNOME Software** | 🔥 **Chọn** | Có sẵn trong nixpkgs, Flatpak backend, GUI hoàn chỉnh |
| KDE Discover | 🟡 Khi cần | Tương tự, dùng cho KDE editions |
| Flatpak CLI | ✅ Đã có | Backend mặc định |
| AppImageLauncher | 🟢 Bổ sung | Tích hợp AppImage vào app menu |
| GLF-OS Pattern | ⏳ Sprint 2+ | Calamares custom patches |

## Decision

**GNOME Software** làm Software Center chính:
- ✅ Có sẵn trong nixpkgs (v50.2)
- ✅ Flatpak backend + Flathub
- ✅ GUI hiện đại (GTK4 + Libadwaita)
- ✅ Tích hợp với GNOME

**AppImageLauncher** bổ sung:
- ✅ Chạy AppImage không cần terminal
- ✅ Tích hợp vào app menu

```nix
# modules/software-center.nix
{ config, pkgs, lib, ... }: {
  # GNOME Software Center + Flatpak backend
  services.gnome.gnome-software.enable = true;

  # Flatpak (đã cấu hình trong profile)
  services.flatpak.enable = true;

  # AppImage support
  boot.binfmt.registrations.appimage = {
    wrapInterpreterInShell = true;
    interpreter = "${pkgs.appimage-run}/bin/appimage-run";
    recognitionType = "magic";
    offset = 0;
    mask = "\xff\xff\xff\xff\x00\x00\x00\x00\xff\xff\xff";
    magicOrExtension = "\x41\x49\x02\x00\x00\x00\x00\x00\x00\x00\x00\x00";
  };
}
```

## Risk Analysis
- GNOME Software ≈200MB → ảnh hưởng ISO size
- AppImage binfmt cần kernel support (đã có sẵn)
- Cần Flathub repository cho app discovery

## References
- GLF-OS: calamares-nixos-extensions patches
- Bazzite: Bazzite Portal (custom GUI installer)
- Nixpkgs: `gnome-software`, `flatpak`, `appimage-run`
