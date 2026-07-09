<div align="center">
  <img src="https://raw.githubusercontent.com/NixOS/nixos-artwork/master/logo/nixos-logo-only-hires.png" width="120" alt="NixOS Logo"/>

  # ⚡ BamOS

  <p align="center">
    <strong>NixOS Distribution for the Vietnamese Community</strong>
    <br />
    <strong>Bản phân phối NixOS dành cho người Việt — Tích hợp sẵn, dùng được ngay</strong>
    <br />
    <em>"Cài xong là dùng. Ổ C — Ổ D cho Linux."</em>
  </p>

  <p>
    <img src="https://img.shields.io/badge/NixOS-26.11-7EB5E5?style=flat-square&logo=nixos&logoColor=white" alt="NixOS"/>
    <img src="https://img.shields.io/badge/Kernel-Zen-ed791a?style=flat-square&logo=linux&logoColor=white" alt="Kernel Zen"/>
    <img src="https://img.shields.io/badge/Desktop-GNOME%20|%20KDE%20|%20COSMIC-lightgrey?style=flat-square" alt="Desktop"/>
    <img src="https://img.shields.io/badge/Framework-flake--parts-5277C3?style=flat-square" alt="flake-parts"/>
    <img src="https://img.shields.io/badge/Input-Fcitx5%20Bamboo-2ecc71?style=flat-square" alt="Fcitx5 Bamboo"/>
    <img src="https://img.shields.io/badge/ISO-12%20variants-88C0D0?style=flat-square" alt="ISO"/>
    <img src="https://img.shields.io/badge/Cachix-bamos-8A2BE2?style=flat-square" alt="Cachix"/>
  </p>
</div>

---

## 📋 Tổng quan

**BamOS** là bản phân phối Linux dựa trên [NixOS](https://nixos.org/), thiết kế cho người dùng Việt Nam với triết lý **"Cài xong là dùng"**:

- ✅ Gõ tiếng Việt (Fcitx5 + Bamboo) — Telex, VNI, VIQR
- ✅ 3 Desktop Environments: **GNOME** | **KDE Plasma** | **COSMIC**
- ✅ 4 Editions: **Standard** | **Developers** | **Gaming** | **Studio**
- ✅ 12 ISO variants — 1 ISO mỗi tổ hợp DE × Edition
- ✅ Btrfs Ổ C — Ổ D: `/data` an toàn tuyệt đối khi cài lại
- ✅ NVIDIA Optimus: GTX 1650, driver 595.84, PRIME Offload
- ✅ Power Management: **tuned** (Red Hat) — dynamic tuning, battery optimized
- ✅ Theming RakuOS-inspired: Nordic, WhiteSur icons, Bibata cursors
- ✅ AppImage + Flatpak + Software Center
- ✅ Hardware auto-detect: GPU, PCI bus IDs
- ✅ Binary Cache: [bamos.cachix.org](https://bamos.cachix.org)

---

## 🚀 Quick Start

### Sử dụng ISO (dành cho người dùng cuối)

```bash
# Tải ISO từ GitHub Releases (sắp có)
# Boot ISO → Calamares installer → chọn Edition + Machine Type → Cài đặt

# Sau cài đặt, cập nhật hệ thống:
cd /iso-cfg
sudo nix flake update
sudo nixos-rebuild switch --flake .#
```

### Build ISO từ source

```bash
git clone https://github.com/quocnho/bamos.git
cd bamos

# Build ISO (chọn 1 trong 12 variants)
nix build .#iso-gnome-standard --no-link

# Copy ISO ra thư mục iso/
nix run .#iso-export -- iso-gnome-standard

# Test trong QEMU
qemu-system-x86_64 -enable-kvm -m 4G -cdrom iso/*.iso
```

### Test trên máy thật (developer)

```bash
# Build + switch
sudo nixos-rebuild switch --flake .#lg
```

---

## 📦 Distro Stack

| Thành phần | Công nghệ |
|-----------|-----------|
| **Nền tảng** | NixOS 26.11 (nixos-unstable) |
| **Framework** | [flake-parts](https://flake.parts/) (hercules-ci) |
| **Kernel** | Linux Zen (`linuxPackages_zen`) |
| **Desktop** | GNOME + GDM / KDE + SDDM / COSMIC (Wayland) |
| **Gõ tiếng Việt** | Fcitx5 + Bamboo (Telex, VNI) |
| **Âm thanh** | PipeWire (ALSA + PulseAudio + JACK) |
| **Hệ thống file** | Btrfs subvolumes: `@`, `@home`, `@nix`, `@data` |
| **Boot** | systemd-boot (UEFI) |
| **GPU** | NVIDIA 595.84 stable + Intel iGPU (Optimus) |
| **Power** | tuned (Red Hat), dynamic tuning, PPD bridge |
| **Installer** | Calamares + custom Python module |

---

## 🗂️ Cấu trúc dự án

```
bamos/
├── flake.nix                        # Entry point — flake-parts mkFlake
├── flake.lock                       # Pinned dependencies
├── idea.md                          # Project vision & requirements
├── README.md                        # File này
│
├── modules/                         # 📦 NixOS modules
│   ├── default.nix                  #   Aggregator
│   ├── core/                        #   🧱 Lõi hệ thống
│   │   ├── system.nix              #     Boot, kernel, nix settings
│   │   ├── packages.nix            #     Packages cơ bản + hardware tools
│   │   ├── locale.nix              #     VN locale, timezone
│   │   ├── audio.nix               #     PipeWire
│   │   ├── input-method.nix        #     Fcitx5 + Bamboo
│   │   ├── optimization.nix        #     Tắt dịch vụ không cần
│   │   ├── fonts.nix               #     Fonts
│   │   └── user.nix                #     User accounts
│   ├── boot/                        #   🚀 Boot & Partition
│   │   ├── disko-btrfs.nix         #     Disko partitioning (Ổ C — Ổ D)
│   │   └── calamares.nix           #     Calamares unified installer
│   ├── desktop/                     #   🖥 Desktop Environments
│   │   ├── gnome.nix               #     GNOME + GDM
│   │   ├── kde.nix                 #     KDE Plasma + SDDM
│   │   ├── cosmic.nix              #     COSMIC + cosmic-greeter
│   │   └── software-center.nix     #     GNOME/KDE Software + Flatpak
│   ├── hardware/                    #   🔧 Phần cứng
│   │   ├── bluetooth.nix           #     Bluetooth
│   │   ├── network.nix             #     NetworkManager
│   │   ├── nvidia.nix              #     NVIDIA driver + PRIME + Power
│   │   ├── detect.nix              #     Auto-detect hardware
│   │   └── power-management.nix    #     tuned + battery optimization
│   ├── editions/                    #   📦 Edition-specific
│   │   ├── developers.nix          #     Dev tools, containers
│   │   ├── gaming.nix              #     Steam, GameScope, MangoHud
│   │   └── studio.nix              #     Creative apps, low-latency
│   ├── apps/                        #   📱 Ứng dụng
│   │   └── standard.nix            #     Standard edition apps
│   └── theming/                     #   🎨 Giao diện
│       ├── bamos-branding.nix      #     Logo, wallpaper, plymouth
│       ├── gtk-theme.nix           #     GTK/icon/cursor options
│       ├── gnome-theme.nix         #     GNOME: Nordic + WhiteSur + Bibata
│       ├── kde-theme.nix           #     KDE: Plasma theme + Kvantum
│       └── cosmic-theme.nix        #     COSMIC theme
│
├── profiles/                        # 🎯 Profiles (tổ hợp module)
│   ├── gnome-standard.nix          #   GNOME + Standard
│   ├── gnome-developers.nix        #   GNOME + Developers
│   ├── gnome-gaming.nix            #   GNOME + Gaming
│   ├── gnome-studio.nix            #   GNOME + Studio
│   ├── kde-standard.nix            #   KDE + Standard
│   ├── kde-developers.nix          #   KDE + Developers
│   ├── kde-gaming.nix              #   KDE + Gaming
│   ├── kde-studio.nix              #   KDE + Studio
│   ├── cosmic-standard.nix         #   COSMIC + Standard
│   ├── cosmic-developers.nix       #   COSMIC + Developers
│   ├── cosmic-gaming.nix           #   COSMIC + Gaming
│   └── cosmic-studio.nix           #   COSMIC + Studio
│
├── hosts/                           # 🖥 Host configurations
│   ├── lg/                          #   Developer laptop (LG Gram)
│   │   ├── default.nix             #     flake-parts module
│   │   ├── configuration.nix       #     Host-specific config
│   │   └── hardware-configuration.nix
│   ├── iso/                         #   💿 ISO builders
│   │   ├── default.nix             #     12 ISO variants
│   │   ├── configuration.nix       #     GNOME ISO config
│   │   ├── configuration-kde.nix   #     KDE ISO config
│   │   ├── configuration-studio.nix#     Studio ISO config
│   │   └── customConfig/           #     User customization slot
│   └── vm/                          #   🖳 QEMU test VM
│       └── default.nix
│
├── lib/                             # 🧠 Helper functions
│   ├── mkISO.nix                   #   ISO package builder
│   └── utils.nix                   #   Utilities
│
├── pkgs/                            # 📦 Custom packages
│   ├── default.nix                 #   Aggregator
│   ├── bamos-branding/             #   Logos, wallpapers
│   └── bamos-detect-hardware.sh    #   Hardware detection script
│
├── assets/                          # 🎨 Static assets
│   ├── wallpapers/                 #   Bamos wallpapers
│   ├── logo/                       #   Logo SVG
│   ├── icons/                      #   Theme icons
│   ├── cursors/                    #   Cursor themes
│   └── fonts/                      #   Font files
│
├── plan/                            # 📋 Project planning
│   └── 05-sprints/                 #   Sprint dashboard
│
└── docs/                            # 📖 Documentation website
    ├── installation/
    ├── general/
    ├── gaming/
    ├── software/
    └── advanced/
```

---

## 🎯 Editions

| Edition | Đối tượng | Tính năng chính | tuned profile |
|---------|-----------|----------------|---------------|
| **Standard** | Người dùng phổ thông | Firefox, Chromium, VLC, LibreOffice, MPV | `desktop` |
| **Developers** | Lập trình viên | devenv, Podman, Distrobox, VS Code, Git | `throughput-performance` |
| **Gaming** | Game thủ | Steam, Lutris, Heroic, GameScope, MangoHud, ProtonGE | `latency-performance` |
| **Studio** | Sáng tạo | Blender, GIMP, Krita, Ardour, OBS, low-latency audio | `latency-performance` |

### Machine Types (chọn khi cài đặt)

| Type | Power Profile | Use Case |
|------|--------------|----------|
| **Laptop** | batteryOptimized, ASPM, WiFi pwr save, 16GB swap | Máy tính xách tay |
| **Desktop** | Hiệu năng tối đa | PC bàn, Workstation |
| **Server** | throughput-performance, no GUI | Máy chủ |

---

## ⚙️ Key Features

### 🇻🇳 Tiếng Việt
- **Fcitx5 + Bamboo**: Telex, VNI, VIQR — Wayland-native
- **Locale**: `Asia/Ho_Chi_Minh`, `vi_VN.UTF-8`
- **Noto CJK fonts**: Hiển thị tiếng Việt + Trung + Nhật + Hàn

### 🗄️ Btrfs Ổ C — Ổ D
- **Ổ C** (`@`, `@home`, `@nix`): Có thể ghi đè khi cài lại
- **Ổ D** (`@data`): An toàn tuyệt đối — Documents, Downloads, Pictures
- **Nautilus bookmark**: `/data` hiển thị trong sidebar với icon riêng

### 🖥️ NVIDIA Optimus
- Driver **NVIDIA 595.84** stable (GeForce GTX 1650)
- **PRIME Offload**: Intel iGPU cho desktop, NVIDIA cho app nặng
- `nvidia-offload <app>` — chạy app với GPU rời
- Power Management: RTD3 fine-grained

### ⚡ Power Management
- **tuned** (Red Hat Enterprise) thay thế PPD/TLP
- **Dynamic tuning**: tự động CPU governor theo load
- **PPD bridge**: GNOME Settings → Power vẫn điều chỉnh được
- **Battery optimized**: ASPM powersupersave, WiFi power saving
- **Profile per edition**: desktop / throughput-performance / latency-performance

### 🎨 Theming (RakuOS-inspired)
- **GTK Theme**: Nordic (~ OrigamiPaper)
- **Icons**: WhiteSur-dark
- **Cursor**: Bibata-Modern-Classic
- **Font**: Inter 11 (UI) + Maple Mono NF 11 (monospace)
- **Extensions**: appindicator, dash-to-dock, blur-my-shell, no-overview

### 📦 Calamares Unified Installer
- **Edition selector**: Standard / Developers / Gaming / Studio
- **Machine type**: Laptop / Desktop / Server
- **Custom Python module**: sinh `/etc/nixos/` + `/iso-cfg/` động
- **Post-install flake**: `github:quocnho/bamos` — dễ update
- **Branding**: Logo Nord + slideshow (GLF-OS inspired)

### 🛠️ Development Workflow

```bash
# Enter dev shell
nix develop

# Format code
nix fmt

# Build OS
sudo nixos-rebuild switch --flake .#lg

# Quét hardware (trước rebuild)
sudo bamos-detect-hardware

# Build ISO
nix build .#iso-gnome-standard

# Copy ISO ra thư mục iso/
nix run .#iso-export -- iso-gnome-standard

# Push cache
nix run .#push-cachix
```

---

## 📊 Sprint Status

| Sprint | Goal | Status |
|--------|------|--------|
| Sprint 1 | ISO GNOME Standard | ✅ Done |
| Sprint 2 | KDE + Standard Apps | ✅ Done |
| Sprint 3 | Developers + Gaming | ✅ Done |
| Sprint 4 | COSMIC + Studio | ✅ Done |
| Sprint 5 | Auto-Detect + Theming | 🟡 Active |
| Sprint 6 | Unified Installer | 🟡 Active |

---

## 🤝 Đóng góp

BamOS là mã nguồn mở cho cộng đồng người Việt:

- 🐛 **Báo lỗi**: Mở issue
- 💡 **Đề xuất**: Ý tưởng cho distro
- 🔧 **Pull request**: Module mới, cải thiện code
- 🌐 **Chia sẻ**: Giới thiệu BamOS

---

## 📄 License

MIT License

---

<div align="center">
  <sub>Built with ❤️ for the Vietnamese NixOS community</sub>
  <br />
  <sub>Powered by <a href="https://nixos.org">NixOS</a> · <a href="https://flake.parts">flake-parts</a> · <a href="https://github.com/NixOS/nixpkgs">nixpkgs</a></sub>
  <br />
  <sub><a href="https://bamos.cachix.org">Cachix Cache</a></sub>
</div>
