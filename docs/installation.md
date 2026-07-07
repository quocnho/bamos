# Hướng dẫn cài đặt BamOS

## Yêu cầu hệ thống

| Thành phần | Tối thiểu | Khuyên dùng |
|-----------|-----------|-------------|
| CPU | Intel/AMD 64-bit (x86_64) | Intel Core i5 / AMD Ryzen 5 |
| RAM | 4 GB | 8 GB+ |
| Ổ cứng | 30 GB | 256 GB SSD+ |
| UEFI | Có | Có (không hỗ trợ Legacy BIOS) |

> ⚠️ ISO ~3.2GB, cần USB 4GB+ hoặc DVD.

## Bước 1: Tải ISO

Truy cập [GitHub Releases](https://github.com/quocnho/bamos/releases) và chọn phiên bản phù hợp.

## Bước 2: Tạo USB Boot

### Cách 1: Balena Etcher (Khuyên dùng)
1. Tải [Balena Etcher](https://etcher.balena.io/)
2. Mở Etcher → Chọn ISO → Chọn USB → **Flash!**

### Cách 2: dd (Linux/macOS)
```bash
# Xác định thiết bị USB (ví dụ: /dev/sdb)
lsblk
# Flash ISO
sudo dd if=bamos-*.iso of=/dev/sdX bs=4M status=progress
```

## Bước 3: Cài đặt

1. Cắm USB → Khởi động lại → **Boot Menu** (F12/F2/Del)
2. Chọn USB → Màn hình **Calamares** xuất hiện
3. Chọn ngôn ngữ → Vị trí → Bàn phím
4. **Phân vùng**: Chọn "Xóa đĩa và cài đặt" hoặc "Tự động"
   - Btrfs subvolumes: `@` (/), `@home` (/home), `@nix` (/nix)
5. Tạo người dùng → Xác nhận → **Cài đặt**
6. Reboot → 🎉 Chào mừng đến với BamOS!
