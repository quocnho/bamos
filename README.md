<div align="center">
  <img src="https://raw.githubusercontent.com/NixOS/nixos-artwork/master/logo/nixos-logo-only-hires.png" width="120" alt="NixOS Logo"/>

  # ⚡ BamOS

  <p align="center">
    <strong>NixOS Distribution for the Vietnamese Community</strong>
    <br />
    <strong>Bản phân phối NixOS dành cho người Việt — Tích hợp sẵn, dùng được ngay</strong>
    <br />
    <em>"Out-of-the-box. Plug & Play. Cài xong là dùng."</em>
  </p>

  <p>
    <img src="https://img.shields.io/badge/NixOS-26.05-7EB5E5?style=flat-square&logo=nixos&logoColor=white" alt="NixOS"/>
    <img src="https://img.shields.io/badge/Kernel-Zen-ed791a?style=flat-square&logo=linux&logoColor=white" alt="Kernel Zen"/>
    <img src="https://img.shields.io/badge/Desktop-GNOME-lightgrey?style=flat-square&logo=gnome&logoColor=white" alt="GNOME"/>
    <img src="https://img.shields.io/badge/Framework-flake--parts-5277C3?style=flat-square" alt="flake-parts"/>
    <img src="https://img.shields.io/badge/Input-Fcitx5%20Bamboo-2ecc71?style=flat-square" alt="Fcitx5 Bamboo"/>
    <img src="https://img.shields.io/badge/Status-Development-yellow?style=flat-square" alt="Status"/>
  </p>
</div>

---

## 📋 Overview / Tổng quan

**BamOS** là một **bản phân phối Linux** (Linux distribution) được xây dựng trên nền tảng [NixOS](https://nixos.org/) với sức mạnh của [`flake-parts`](https://flake.parts/), thiết kế dành riêng cho người dùng Việt Nam.

### 🎯 Mục tiêu

> **"Tích hợp sẵn" (Out-of-the-box)** — Mọi thứ hoạt động ngay sau khi cài đặt:
> - ✅ Gõ tiếng Việt (Fcitx5 + Bamboo)
> - ✅ GNOME desktop thuần Việt (locale, timezone)
> - ✅ Kernel Zen — tối ưu cho desktop & gaming
> - ✅ Âm thanh (PipeWire), Bluetooth, Wi-Fi
> - ✅ Trình duyệt Firefox, dev tools cơ bản
> - 🚧 Flatpak + Distrobox (kế hoạch)
> - 🚧 ISO installer (kế hoạch)

### 📦 Distro Stack

| Thành phần | Công nghệ |
|-----------|-----------|
| **Nền tảng** | NixOS 26.05 (nixos-unstable) |
| **Kernel** | Linux Zen (`linuxPackages_zen`) |
| **Desktop** | GNOME + GDM (Wayland-native) |
| **Gõ tiếng Việt** | Fcitx5 + Bamboo (Telex, VNI) |
| **Âm thanh** | PipeWire (ALSA + PulseAudio compat) |
| **Hệ thống file** | Btrfs (subvolumes: `/`, `/home`, `/nix`) |
| **Boot** | systemd-boot (UEFI) |
| **Framework Flake** | [flake-parts](https://flake.parts/) (hercules-ci) |

---

## 🚀 Dùng thử / Quick Start

### ⚠️ Trạng thái hiện tại

> BamOS đang trong giai đoạn **phát triển (development)**. `hosts/lg` là cấu hình test trên máy laptop của developer. ISO installer cho người dùng cuối đang được xây dựng.

### Test trên máy của bạn

```bash
# Clone repository
git clone <your-repo-url> ~/bamos
cd ~/bamos

# Enter dev environment
nix develop

# Build NixOS config cho máy test
# (Cần hardware-configuration.nix phù hợp với máy bạn)
sudo nixos-rebuild switch --flake .#lg
```

### Build ISO (Kế hoạch)

Khi pipeline ISO hoàn thiện, bạn sẽ có thể:

```bash
# Build ISO trực tiếp
nix build .#nixosConfigurations.iso.config.system.build.isoImage

# Hoặc dùng nixos-generators
nix run nixpkgs#nixos-generate -- --flake .#iso --format iso
```

---

## 🏗️ Project Structure / Cấu trúc dự án

```
bamos/
├── flake.nix                           # Entry point — flake-parts mkFlake
├── flake.lock                          # Pinned dependencies
├── README.md                           # File này
├── ARCHITECH.md                        # Tài liệu kiến trúc
│
├── hosts/                              # Định nghĩa máy
│   └── lg/                             # 🧪 Máy test developer
│       └── default.nix                 #   → nixosConfigurations.lg
│   # (future) iso/
│   #     └── default.nix               # → nixosConfigurations.iso
│
├── nixos/                              # Cấu hình NixOS
│   ├── configuration.nix               #   Cấu hình chính (thin)
│   └── hardware-configuration.nix      #   Hardware scan (auto-generated)
│
├── modules/                            # NixOS modules (dùng chung)
│   ├── default.nix                     #   Aggregator
│   ├── system.nix                      #   Boot, kernel Zen, Flakes
│   ├── packages.nix                    #   System packages
│   ├── input-method.nix                #   Fcitx5 + Bamboo
│   ├── locale.nix                      #   VN locale, time zone
│   ├── audio.nix                       #   PipeWire
│   ├── user.nix                        #   User accounts
│   ├── optimization.nix                #   Tắt dịch vụ không dùng
│   ├── hardware/
│   │   ├── bluetooth.nix               #   Bluetooth
│   │   └── network.nix                 #   NetworkManager
│   └── desktop/
│       └── gnome.nix                   #   GNOME + GDM
│
├── pkgs/                               # Custom packages (sẵn sàng)
│   └── default.nix                     #   Placeholder
│
├── overlays/                           # Nix overlays (sẵn sàng)
│   └── default.nix                     #   Placeholder
│
└── .zed/
    └── settings.json                   # Zed editor config
```

### Giải thích module tree

| Module | Chức năng |
|--------|-----------|
| `system.nix` | Bootloader, kernel Zen, hostname, experimental-features |
| `packages.nix` | Dev tools: `git`, `vim`, `zed-editor`, `fzf`, `ripgrep`, `bluez`, `nil`, `nixpkgs-fmt` |
| `input-method.nix` | **Fcitx5** + **Bamboo** engine + session variables |
| `locale.nix` | `Asia/Ho_Chi_Minh`, `vi_VN` locale, `en_US` default |
| `desktop/gnome.nix` | GNOME desktop via GDM, loại bỏ bloatware |
| `audio.nix` | PipeWire với ALSA + PulseAudio compat |
| `hardware/bluetooth.nix` | Bluetooth + auto power-on |
| `hardware/network.nix` | NetworkManager (Wi-Fi + Ethernet) |
| `user.nix` | User account |
| `optimization.nix` | Tắt printing, avahi, power-profiles-daemon |

---

## ⚙️ Key Features / Tính năng chính

### 🐧 Linux Zen Kernel

Kernel được tối ưu cho desktop và gaming — thay thế kernel mặc định của NixOS bằng `linuxPackages_zen`:

- **Desktop-optimized scheduler** — mượt mà hơn cho tác vụ hàng ngày
- **Low latency** — âm thanh, đồ họa không giật lag
- **Tương thích Intel & AMD** — phù hợp máy tính lắp ráp và laptop phổ thông

```nix
boot.kernelPackages = pkgs.linuxPackages_zen;
```

### 🇻🇳 Vietnamese Input — Fcitx5 Bamboo

```nix
i18n.inputMethod = {
  enable = true;
  type = "fcitx5";
  fcitx5.addons = with pkgs; [ fcitx5-bamboo fcitx5-gtk ];
};
```

Hỗ trợ gõ tiếng Việt native:
- **Bamboo engine** — Telex, VNI, và các kiểu gõ phổ biến
- **Wayland-native** — hoạt động trên GNOME Wayland session
- **GTK + Qt + Electron** — tương thích mọi ứng dụng

### 🎵 PipeWire Audio

Modern audio framework thay thế PulseAudio:

```nix
services.pipewire = {
  enable = true;
  alsa.enable = true;
  pulse.enable = true;
};
```

### 🧠 flake-parts Framework

Dự án sử dụng [**flake-parts**](https://flake.parts/) — framework modular của [hercules-ci](https://github.com/hercules-ci/flake-parts):

- **`perSystem`** — Tự động xử lý per-system attributes
- **Module imports** — Chia flake thành nhiều file module riêng biệt
- **`debug = true`** — Inspect config qua `nix repl`
- **Reusable** — `nixosModules.default` có thể được dùng bởi flake khác

---

## 🛠️ Usage / Sử dụng

### Development

```bash
# Dev environment
nix develop

# Format all .nix files
nix fmt

# Show flake outputs
nix flake show
```

### Test trên máy

```bash
# Build NixOS configuration (cần hardware scan phù hợp)
sudo nixos-rebuild switch --flake .#lg
```

### Flake outputs

```
nix flake show
├───debug                          # Inspect với nix repl
├───devShells.x86_64-linux.default # nix develop
├───formatter.x86_64-linux         # nix fmt
├───nixosConfigurations.lg         # OS config (test)
├───nixosModules.default           # Re-usable module
└───overlays.default               # Nixpkgs overlay
```

---

## 🗺️ Roadmap / Lộ trình

### ✅ Phase 1 — Core (Hoàn thành)
- [x] flake-parts foundation + Zen kernel + GNOME desktop

### ✅ Phase 2 — Bản địa hóa (Hoàn thành)
- [x] Fcitx5 Bamboo + VN locale + PipeWire + tối ưu dịch vụ

### 🔄 Phase 3 — ISO Distro (Đang làm)
- [ ] ISO build pipeline (`nix build .#iso`)
- [ ] Disko partitioning (Btrfs subvolumes)
- [ ] Installer (TUI hoặc đồ họa)
- [ ] QEMU testing

### ⏳ Phase 4 — App Layer
- [ ] Flatpak + Flathub (GNOME Software)
- [ ] Distrobox containers

### ⏳ Phase 5 — Community
- [ ] Home Manager
- [ ] Custom packages + Overlays
- [ ] Documentation

---

## 📦 Dependencies / Phụ thuộc

| Input | Source | Vai trò |
|-------|--------|---------|
| `nixpkgs` | `nixos/nixpkgs/nixos-unstable` | Package repository |
| `flake-parts` | `hercules-ci/flake-parts` | Modular flake framework |

---

## 🤝 Đóng góp / Contributing

BamOS là dự án mã nguồn mở dành cho cộng đồng người Việt.

Bạn có thể đóng góp bằng cách:

- 🐛 **Báo lỗi**: Mở issue nếu gặp vấn đề
- 💡 **Đề xuất tính năng**: Ý tưởng mới cho distro
- 🔧 **Pull request**: Cải thiện code, thêm module mới
- 🌐 **Chia sẻ**: Giới thiệu BamOS đến người khác

Hãy tạo Pull Request hoặc Issue trên repository này!

---

## 📄 License

This project is licensed under the MIT License.

---

<div align="center">
  <sub>Built with ❤️ for the Vietnamese NixOS community — Bởi cộng đồng, vì cộng đồng.</sub>
  <br />
  <sub>Powered by <a href="https://nixos.org">NixOS</a> · <a href="https://flake.parts">flake-parts</a> · <a href="https://github.com/NixOS/nixpkgs">nixpkgs</a></sub>
  <br />
  <sub><a href="https://github.com/hercules-ci/flake-parts">🔄 flake-parts</a> · <a href="https://github.com/Misterio77/nix-starter-configs">📁 nix-starter-configs</a></sub>
</div>
