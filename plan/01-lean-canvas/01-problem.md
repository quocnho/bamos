# Problem

## Current State
Người dùng Việt Nam gặp nhiều rào cản khi sử dụng Linux:

1. **Gõ tiếng Việt phức tạp**: Phải cài đặt và cấu hình thủ công bộ gõ (ibus/fcitx + bamboo/unikey), xử lý biến môi trường, xung đột giữa các ứng dụng GTK/Qt/Electron/Flatpak.

2. **Cấu hình rời rạc, khó tái tạo**: Mỗi lần cài lại hệ điều hành là một lần "hành xác" với hàng giờ cấu hình lại từ đầu. Cấu hình không được quản lý tập trung, dễ bị thất lạc, không thể rollback khi gặp lỗi.

3. **Lo sợ mất dữ liệu khi cài lại OS**: Người dùng phổ thông quen với mô hình "Ổ C — Ổ D" của Windows. Trên Linux, việc cài lại thường đồng nghĩa với xóa sạch phân vùng, gây mất dữ liệu cá nhân.

4. **Thiếu distro Việt hóa chuyên nghiệp**: Các distro Linux phổ biến (Ubuntu, Fedora, Arch) không được tối ưu cho người Việt ngay từ đầu. Người dùng phải tự mày mò, dễ nản và quay lại Windows.

5. **Dependency Hell**: Cài đặt phần mềm `.deb`/`.rpm` trực tiếp lên hệ thống dễ gây xung đột thư viện, hỏng hệ thống, khó gỡ bỏ triệt để.

6. **Thiếu distro chuyên biệt cho từng nhu cầu**: Người dùng phổ thông, developer, gamer, và người làm studio đều bị dồn vào một distro chung chung, phải tự cài đặt thêm hàng tá phần mềm và cấu hình phức tạp.

## Existing Alternatives
- Ubuntu, Linux Mint: Có cộng đồng lớn nhưng không tối ưu cho người Việt
- Bazzite OS, Nobara: Gaming-focused nhưng không hỗ trợ tiếng Việt
- Không có distro NixOS nào dành riêng cho người Việt

## Hypotheses
[To be filled]

## Validated Learning
- Phase 1 & 2 hoàn thành: Core foundation + bản địa hóa đã hoạt động trên máy developer
- Zen kernel + GNOME + Fcitx5/Bamboo đã được verify

## Action Items
- [ ] Hoàn thiện Phase 3: Distro ISO build
- [ ] Phase 4: Multi-DE + Editions
- [ ] Tiếp cận cộng đồng người dùng Linux Việt Nam

## Last Updated
2026-07-03
