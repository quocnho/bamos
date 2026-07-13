# 🏠 BamOS — My Configuration

Đây là thư mục cấu hình NixOS của bạn, được tạo bởi BamOS Calamares installer.
Toàn bộ hệ thống được quản lý qua các file `.nix` — chỉnh sửa là rebuild, không cần "cài lại".

## 📋 Cấu trúc thư mục

```
/etc/nixos/
├── flake.nix                  # 📄 Định nghĩa inputs (nixpkgs + bamos) + outputs
├── flake.lock                 # 🔒 Pinned versions (tự sinh)
├── configuration.nix          # ⚙️ Cấu hình chính: hostname, locale, user
├── customized.nix             # 🎯 Edition + Machine Type (Calamares sinh)
├── hardware-configuration.nix # 🔧 Hardware scan (tự sinh)
├── modules/                   # 🧩 Modules người dùng (mở rộng tùy ý)
│   └── default.nix            #   Aggregator
├── customConfig/              # 🛡️ Config cá nhân (KHÔNG bị ghi đè!)
│   └── default.nix            #   Thêm config của bạn ở đây
├── home.nix                   # 🏠 Home-manager (optional)
└── secrets/                   # 🔐 Encrypted secrets (optional)
```

## 🚀 Quick Start

### Xem thông tin hệ thống
```bash
bam info
```

### Cập nhật hệ thống
```bash
sudo bam update
# hoặc: sudo nixos-rebuild switch --flake /etc/nixos#bamos
```

### Thay đổi edition
Sửa file `customized.nix`:
```nix
# Đổi từ standard → gaming
bamos.nixosModules.gaming
```
```bash
sudo nixos-rebuild switch --flake /etc/nixos#bamos
```

### Cài thêm phần mềm
Thêm vào `customConfig/default.nix`:
```nix
environment.systemPackages = with pkgs; [ htop neofetch ];
```
```bash
sudo nixos-rebuild switch --flake /etc/nixos#bamos
```

### Build ISO để chia sẻ với bạn bè
```bash
bam share iso           # Build ISO với config hiện tại
bam usb /dev/sda        # Ghi ISO vào USB
```

### Tạo portable snapshot
```bash
sudo bam snapshot create my-config  # Snapshot toàn bộ cấu hình
bam snapshot share my-config        # Đóng gói để gửi cho bạn
```

## 📚 Commands

| Command | Mô tả |
|---------|-------|
| `bam info` | Xem thông tin hệ thống |
| `sudo bam switch` | Rebuild + apply config |
| `sudo bam update` | Flake update + rebuild |
| `sudo bam backup` | Backup system + home |
| `bam iso` | Build ISO |
| `bam vm` | Chạy VM với ISO |
| `bam usb /dev/sda` | Ghi ISO vào USB |
| `sudo bam snapshot create` | Tạo system snapshot |
| `bam share iso` | Build ISO với config hiện tại |

## 🔄 Luồng làm việc

```
1. Chỉnh sửa file .nix  →  2. sudo bam switch  →  3. Xong!
```

Không cần cài lại. Không sợ hỏng. Luôn có rollback.
