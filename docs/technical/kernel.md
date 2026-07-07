# Multi-Kernel Strategy

BamOS sử dụng chiến lược đa kernel để tối ưu cho từng mục đích sử dụng.

## Các Kernel

| Kernel | Base | Đặc điểm | Dùng cho |
|--------|------|----------|----------|
| **LTS** (linux_lts) | Linux 6.12 LTS | Ổn định nhất, bảo mật lâu dài | ISO Live |
| **Zen** (linux_zen) | Linux mainline + Zen patches | Cân bằng, responsive, desktop-tuned | Mặc định, Developers, Studio, hosts/lg |
| **XanMod** | Linux mainline + XanMod patches | Tối ưu gaming, latency thấp nhất | Gaming edition |

## So sánh chi tiết

| Tiêu chí | LTS | Zen | XanMod |
|----------|-----|-----|--------|
| **Ổn định** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |
| **Hiệu năng desktop** | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Gaming (FPS)** | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Latency** | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **Tương thích phần cứng** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **Kích thước kernel** | Nhỏ | Trung bình | Trung bình |
| **Bảo mật** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |

## Cấu hình kernel trong NixOS

### Mặc định (Zen)

```nix
boot.kernelPackages = pkgs.linuxKernel.packages.linux_zen;
```

### Gaming (XanMod)

```nix
boot.kernelPackages = pkgs.linuxKernel.packages.linux_xanmod;
```

### ISO (LTS)

```nix
boot.kernelPackages = pkgs.linuxKernel.packages.linux_lts;
```

## Kernel boot parameters

### Mặc định

```nix
boot.kernelParams = [
  "quiet"
  "splash"
  "nowatchdog"
  "mitigations=off"  # Gaming/Desktop performance
];
```

### Studio (low-latency audio)

```nix
boot.kernelParams = [
  "quiet"
  "threadirqs"
  "preempt=full"
];
```

## Chuyển đổi kernel

Người dùng có thể chuyển kernel sau cài đặt:

```bash
# Sửa /etc/nixos/configuration.nix
# Hoặc dùng BamOS Portal (tương lai)

# Kiểm tra kernel hiện tại
uname -r

// Cập nhật kernel trong flake
# boot.kernelPackages = pkgs.linuxKernel.packages.linux_zen;
```

## Tham khảo

- [Zen Kernel](https://github.com/zen-kernel/zen-kernel)
- [XanMod Kernel](https://xanmod.org/)
- [Linux LTS](https://www.kernel.org/category/releases.html)
