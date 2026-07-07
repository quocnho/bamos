# Tài liệu BamOS

## User Documentation (docs/user/)

Website hướng dẫn sử dụng dành cho người dùng cuối (tiếng Việt):

```bash
open docs/user/index.html
```

| Trang | Nội dung |
|-------|---------|
| 🏠 Giới thiệu | Tổng quan, tính năng, đối tượng |
| 🚀 Bắt đầu | Tải ISO, tạo USB, boot, yêu cầu hệ thống |
| 💿 Cài đặt | 6 bước cài đặt từ Calamares |
| 🔄 Nâng cấp | Cập nhật phiên bản |
| 📋 Phiên bản | 12 variants, hướng dẫn chọn |
| 🇻🇳 Gõ tiếng Việt | Fcitx5 + Bamboo, Telex/VNI |
| 📦 Cài phần mềm | Flatpak, Nix, Distrobox |
| 🔄 Cập nhật & Rollback | Update, rollback, dọn dẹp |
| 💾 Sao lưu | Cài lại không mất dữ liệu |
| 🎮 Game | Steam, Proton, GameScope |
| 💻 Phát triển | devenv, Podman |
| 🐳 Container | Distrobox |
| 📱 Android | Waydroid |
| 🤝 Đóng góp | GitHub, Pull Request |
| ❓ FAQ | 7 câu hỏi thường gặp |
| 🔧 Thông số | Specs, kernel, cache |

## Technical Documentation (docs/technical/)

Tài liệu kỹ thuật cho developer và maintainer:

| File | Nội dung |
|------|---------|
| `architecture.md` | Kiến trúc tổng thể, layers, module structure |
| `modules.md` | Danh sách modules, options, cách dùng |
| `iso-build.md` | Build ISO, variants, cache, optimization |
| `kernel.md` | Multi-kernel LTS/Zen/XanMod, so sánh |
| `dev-workstation.md` | Cấu hình hosts/lg, VM tools |

## Reference Documentation (docs/)

| File | Nội dung |
|------|---------|
| `installation.md` | Hướng dẫn cài đặt từng bước |
| `editions.md` | 12 phiên bản, kernel strategy |
| `contributing.md` | Hướng dẫn đóng góp cho developer |

## Build commands

```bash
# Kiểm tra flake
nix flake check

# Build ISO
nix build .#iso-gnome-standard

# Build VM từ config
nixos-rebuild build-vm --flake .#lg
./result/bin/run-nixos-vm.sh

# Áp dụng config cho máy thật
sudo nixos-rebuild switch --flake .#lg

# Build + push cache
nix run .#push-cachix
```
