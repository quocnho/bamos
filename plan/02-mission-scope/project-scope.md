# Project Scope

## In Scope
- NixOS-based Linux distribution với flake-parts framework
- 3 Desktop Environments: GNOME, KDE Plasma, COSMIC
- 4 Editions: Standard, Developers, Gaming, Studio
- Bản địa hóa tiếng Việt OOTB (Fcitx5 + Bamboo, locale, fonts)
- Btrfs subvolume layout (@, @home, @nix) với disko declarative partitioning
- ISO generation cho tất cả 12 variants
- Custom installer (Calamares-based)
- CI/CD pipeline với GitHub Actions + Cachix binary cache
- Tài liệu tiếng Việt đầy đủ
- BamOS Portal (system settings app) — Phase 5+
- Community platform — Phase 7+

## Out of Scope (Explicitly)
- ARM/aarch64 support (hiện tại chỉ x86_64-linux)
- Server edition (chỉ desktop/laptop)
- Dual-boot Windows tự động (người dùng tự quản lý)
- Proprietary NVIDIA driver cài sẵn (opt-in qua overlay)

## MVP Definition
Minimum set of features for first release (v0.1.0):
- [x] Core foundation (flake-parts, Zen kernel, GNOME, Btrfs, disko)
- [x] Bản địa hóa (Fcitx5+Bamboo, VN locale, fonts, input method)
- [ ] ISO build cho GNOME Standard (1 variant đầu tiên)
- [ ] ISO có thể boot và cài đặt thành công
- [ ] Gõ tiếng Việt hoạt động ngay sau cài đặt
- [ ] Rollback hoạt động (< 2 phút)
- [ ] Flatpak + Flathub hoạt động

## Success Criteria
1. ISO có thể boot và cài đặt thành công trên ít nhất 3 cấu hình phần cứng khác nhau
2. Gõ tiếng Việt hoạt động ngay sau cài đặt — không cần cấu hình thủ công
3. Rollback hoạt động: khôi phục về generation cũ trong < 2 phút
4. 12 ISO variants được build tự động qua CI/CD, mỗi ISO < 3GB
5. Thời gian cài đặt < 30 phút từ ISO boot đến desktop sẵn sàng
6. 100% reproducible: mọi bản cài đặt từ cùng git commit đều giống hệt nhau
7. Tài liệu tiếng Việt đầy đủ cho người dùng phổ thông
