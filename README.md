<div align="center">
  <img src="https://raw.githubusercontent.com/quocnho/bamos/main/assets/logo/bamos-logo.svg" width="140" height="140" alt="BamOS Bamboo Logo"/>

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
    <img src="https://github.com/quocnho/bamos/actions/workflows/ci.yml/badge.svg?branch=main" alt="CI"/>
    <img src="https://github.com/quocnho/bamos/actions/workflows/release.yml/badge.svg?branch=main" alt="Release"/>
    <img src="https://github.com/quocnho/bamos/actions/workflows/release-cd.yml/badge.svg?branch=main" alt="CD"/>
    <img src="https://img.shields.io/badge/Kernel-Zen-ed791a?style=flat-square&logo=linux&logoColor=white" alt="Kernel Zen"/>
    <img src="https://img.shields.io/badge/Desktop-GNOME%20|%20KDE%20|%20COSMIC-lightgrey?style=flat-square" alt="Desktop"/>
    <img src="https://img.shields.io/badge/Framework-flake--parts-5277C3?style=flat-square" alt="flake-parts"/>
    <img src="https://img.shields.io/badge/Input-Fcitx5%20Bamboo-2ecc71?style=flat-square" alt="Fcitx5 Bamboo"/>
    <img src="https://img.shields.io/badge/ISO-12%20variants-88C0D0?style=flat-square" alt="ISO"/>
    <img src="https://img.shields.io/badge/Cachix-bamos-8A2BE2?style=flat-square" alt="Cachix"/>
    <img src="https://img.shields.io/badge/Version-2.0.0-blue?style=flat-square" alt="Version"/>
    <img src="https://img.shields.io/badge/License-MIT-green?style=flat-square" alt="License"/>
  </p>

  <p align="center">
    <sub><em>Logo: Mosaic lục giác tre — "Cây tre trăm đốt", mỗi đốt là một module Nix</em></sub>
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
- ✅ **bam CLI** — install/remove/search/run, backup/restore, update (interactive + changelog), rollback, changelog, clean
- ✅ Theming RakuOS-inspired: Nordic, WhiteSur icons, Bibata cursors
- ✅ Bamboo branding: logo mosaic lục giác tre, 13 bộ wallpaper, Plymouth boot splash
- ✅ AppImage + Flatpak + Software Center + FHS compatibility
- ✅ Btrfs snapshot engine (btrbk) — auto hourly/daily/weekly snapshots
- ✅ Auto-upgrade engine: check-only timer + interactive `sudo bam update` with changelog preview + confirmation
- ✅ Calamares Unified Installer — chọn Edition + Machine Type khi cài đặt
- ✅ Hardware auto-detect: GPU, PCI bus IDs, kernel modules
- ✅ Binary Cache: [bamos.cachix.org](https://bamos.cachix.org)

---

## 🚀 Quick Start

### Sử dụng ISO (dành cho người dùng cuối)

```bash
# Tải ISO từ GitHub Releases (sắp có)
# Boot ISO → Calamares installer → chọn Edition + Machine Type → Cài đặt

# Sau cài đặt, kiểm tra và cập nhật hệ thống:
sudo bam update              # Check → show changelog → confirm → apply
sudo bam update --check      # Chỉ kiểm tra, không apply
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
| **Kernel** | Linux Zen (`linuxPackages_zen`) — Gaming: XanMod |
| **Desktop** | GNOME + GDM / KDE + SDDM / COSMIC (Wayland) |
| **Gõ tiếng Việt** | Fcitx5 + Bamboo (Telex, VNI, VIQR) |
| **Âm thanh** | PipeWire (ALSA + PulseAudio + 32-bit) |
| **Hệ thống file** | Btrfs subvolumes: `@`, `@home`, `@nix`, `@data` |
| **Boot** | systemd-boot (UEFI) — Plymouth bamboo logo |
| **GPU** | NVIDIA 595.84 stable + Intel iGPU (Optimus) |
| **Power** | tuned (Red Hat), dynamic tuning, PPD bridge |
| **Installer** | Calamares + custom Python module |
| **CLI** | `bam` — universal command manager (13 commands) |
| **Snapshot** | btrbk — Btrfs incremental snapshot engine (24h/7d/4w/3m) |
| **Partitioning** | Disko — declarative disk layout |

---

## 🗂️ Cấu trúc dự án

```
bamos/
├── flake.nix                        # Entry point — flake-parts mkFlake
├── flake.lock                       # Pinned dependencies
├── VERSION                          # Phiên bản BamOS hiện tại (2.0.0)
├── CHANGELOG.md                     # Lịch sử thay đổi (Keep a Changelog)
├── idea.md                          # Project vision & requirements
├── README.md                        # File này
│
├── lib/                             # 🧠 Thư viện & hàm dùng chung
│   ├── mkEdition.nix               #   Tạo edition từ profile + DE
│   ├── mkHost.nix                  #   Tạo nixosConfiguration từ host
│   ├── mkISO.nix                   #   Build ISO từ profile
│   └── utils.nix                   #   Helper functions
│
├── modules/                         # 📦 NixOS modules
│   ├── default.nix                 #   Aggregator
│   ├── core/                       #   🧱 Lõi hệ thống
│   │   ├── system.nix             #     Boot, kernel Zen, nix settings, cachix
│   │   ├── packages.nix           #     Common packages + hardware tools
│   │   ├── locale.nix             #     VN locale, timezone
│   │   ├── audio.nix              #     PipeWire
│   │   ├── input-method.nix       #     Fcitx5 + Bamboo
│   │   ├── optimization.nix       #     Tắt dịch vụ không cần
│   │   ├── fonts.nix              #     Fonts (Noto, Fira, JetBrains Mono)
│   │   ├── user.nix               #     User accounts
│   │   ├── third-party.nix        #     AppImage, Flatpak, FHS, containers, codecs
│   │   ├── version.nix            #     /etc/os-release + /etc/lsb-release branding
│   │   └── update.nix             #     Auto-upgrade engine: check-only timer + notify
│   ├── boot/                       #   🚀 Boot & Partition
│   │   ├── disko-btrfs.nix        #     Disko partitioning (Ổ C — Ổ D)
│   │   └── calamares.nix          #     Calamares unified installer
│   ├── desktop/                    #   🖥 Desktop Environments
│   │   ├── gnome.nix              #     GNOME + GDM
│   │   ├── kde.nix                #     KDE Plasma + SDDM
│   │   ├── cosmic.nix             #     COSMIC + cosmic-greeter
│   │   └── software-center.nix    #     GNOME/KDE Software + Flatpak + AppImage
│   ├── hardware/                   #   🔧 Phần cứng
│   │   ├── bluetooth.nix          #     Bluetooth + auto power-on
│   │   ├── network.nix            #     NetworkManager
│   │   ├── nvidia.nix             #     NVIDIA driver + PRIME + Power
│   │   ├── detect.nix             #     Auto-detect hardware
│   │   ├── power-management.nix   #     tuned + battery optimization
│   │   └── backup.nix             #     Btrfs snapshot + btrbk engine
│   ├── editions/                   #   📦 Edition-specific
│   │   ├── developers.nix         #     Dev tools, Podman, Distrobox
│   │   ├── gaming.nix             #     Steam, GameScope, MangoHud, XanMod
│   │   └── studio.nix             #     Creative apps, low-latency audio
│   ├── apps/                       #   📱 Ứng dụng
│   │   └── standard.nix           #     Firefox, Chromium, VLC, MPV...
│   └── theming/                    #   🎨 Giao diện & thương hiệu
│       ├── bamos-branding.nix     #     Bamboo logo, 26 wallpapers, Plymouth
│       ├── gtk-theme.nix          #     GTK/icon/cursor options
│       ├── gnome-theme.nix        #     GNOME: Nordic + WhiteSur + Bibata
│       ├── kde-theme.nix          #     KDE: Plasma theme + Kvantum
│       └── cosmic-theme.nix       #     COSMIC theme
│
├── profiles/                       # 🎯 Profiles (tổ hợp module)
│   ├── gnome-standard.nix         #   GNOME + Standard
│   ├── gnome-developers.nix       #   GNOME + Developers
│   ├── gnome-gaming.nix           #   GNOME + Gaming
│   ├── gnome-studio.nix           #   GNOME + Studio
│   ├── kde-standard.nix           #   KDE + Standard
│   ├── kde-developers.nix         #   KDE + Developers
│   ├── kde-gaming.nix             #   KDE + Gaming
│   ├── kde-studio.nix             #   KDE + Studio
│   ├── cosmic-standard.nix        #   COSMIC + Standard
│   ├── cosmic-developers.nix      #   COSMIC + Developers
│   ├── cosmic-gaming.nix          #   COSMIC + Gaming
│   └── cosmic-studio.nix          #   COSMIC + Studio
│
├── hosts/                          # 🖥 Host configurations
│   ├── default.nix                #   Aggregator
│   ├── lg/                        #   🖥 Developer laptop (LG Gram)
│   │   ├── default.nix            #     flake-parts module
│   │   ├── configuration.nix      #     Host-specific config
│   │   └── hardware-configuration.nix
│   ├── iso/                       #   💿 ISO builders (12 variants)
│   │   ├── default.nix            #     flake-parts module → mkISOVariant
│   │   ├── configuration.nix      #     GNOME ISO config
│   │   ├── configuration-kde.nix  #     KDE ISO config
│   │   ├── configuration-studio.nix#    Studio ISO config
│   │   └── customConfig/          #     User customization slot
│   └── vm/                        #   🖳 QEMU test VM
│       └── default.nix
│
├── pkgs/                           # 📦 Custom packages
│   ├── default.nix                #   Aggregator
│   ├── bam-cli/                   #   BamOS CLI (bam) — 13 commands
│   │   └── default.nix            #     FHS env + bam.sh wrapper
│   ├── bamos-branding/            #   Bamboo logos, 26 wallpapers, GNOME XML
│   │   └── default.nix
│   └── bamos-detect-hardware.sh   #   Hardware detection script
│
├── iso-cfg/                        # 💿 ISO user template (copy vào /etc/nixos/ khi cài)
│   ├── flake.nix                   #   Flake tham chiếu github:quocnho/bamos
│   ├── configuration.nix          #   Base config (hostname, locale, user)
│   ├── customized.nix             #   Edition + Machine type config
│   └── customConfig/              #   User customizations (không bị ghi đè)
│
├── overlays/                       # 🔄 Nixpkgs overlays
│   └── default.nix
│
├── assets/                         # 🎨 Static assets (92 MB)
│   ├── logo/                      #   Bamboo SVG + PNG logos (6 sizes)
│   │   └── ref/                   #     Reference PNGs (dark + light)
│   ├── wallpapers/                #   13 bộ background (light + dark)
│   │   └── ref/                   #     BamOS Dalle, Leather, Vintage, Frost...
│   ├── css/                       #   Website CSS
│   ├── js/                        #   Website JS
│   ├── cursors/                   #   Cursor themes
│   ├── fonts/                     #   Font files
│   └── icons/                     #   Theme icons
│
├── docs/                           # 📖 Documentation website
│   ├── user/                      #   Website (32+ trang, bazzite-style)
│   │   └── index.html             #     Landing page
│   ├── technical/                 #   Architecture, modules, ISO build
│   └── ...                        #   Installation, gaming, software guides
│
├── plan/                           # 📋 Project planning (sprints + lean canvas)
├── .github/workflows/              # 🚀 CI/CD pipelines
└── .zed/                           # Zed editor config
```

---

## 🎯 Editions

| Edition | Đối tượng | Tính năng chính | tuned profile | Kernel |
|---------|-----------|----------------|---------------|--------|
| **Standard** | Người dùng phổ thông | Firefox, Chromium, VLC, MPV, GNOME Software | `desktop` | Zen |
| **Developers** | Lập trình viên | devenv, Podman, Distrobox, VS Code, Git, VM tools | `throughput-performance` | Zen |
| **Gaming** | Game thủ | Steam, Lutris, Heroic, GameScope, MangoHud, ProtonGE, OBS, Discord | `latency-performance` | **XanMod** |
| **Studio** | Sáng tạo | Blender, GIMP, Krita, Ardour, OBS, low-latency audio | `latency-performance` | Zen |

### Machine Types (chọn khi cài đặt qua Calamares)

| Type | Power Profile | Use Case |
|------|--------------|----------|
| **Laptop** | batteryOptimized, ASPM, WiFi pwr save, 16GB swap | Máy tính xách tay |
| **Desktop** | Hiệu năng tối đa, AC mode | PC bàn, Workstation |
| **Server** | throughput-performance, no GUI | Máy chủ |

---

## ⚙️ Key Features

### 🎋 Thương hiệu BamOS
- **Bamboo Logo**: Mosaic lục giác tre 6 cánh — "Cây tre trăm đốt"
- **26 Wallpapers**: 13 bộ light+dark — Default, Dalle, Leather, Vintage, Frost (2/4/5/Phoenix), Gaming, Mini, Studio, Quasar, Solid
- **GNOME Background**: Tất cả có sẵn trong Settings → Background (13 XML properties)
- **Plymouth Boot**: Logo bamboo khi khởi động
- **Multi-size Logos**: SVG + PNG từ 16×16 → 256×256

### 🇻🇳 Tiếng Việt
- **Fcitx5 + Bamboo**: Telex, VNI, VIQR — Wayland-native
- **Locale**: `Asia/Ho_Chi_Minh`, `vi_VN.UTF-8`
- **Noto CJK fonts**: Hiển thị tiếng Việt + Trung + Nhật + Hàn

### 🗄️ Btrfs Ổ C — Ổ D
- **Ổ C** (`@`, `@home`, `@nix`): Có thể ghi đè khi cài lại
- **Ổ D** (`@data`): An toàn tuyệt đối — Documents, Downloads, Pictures
- **Nautilus bookmark**: `/data` hiển thị trong sidebar với icon riêng
- **XDG User Dir redirect**: `~/Documents` → `/data/Documents`

### 🖥️ NVIDIA Optimus
- Driver **NVIDIA 595.84** stable (GeForce GTX 1650)
- **PRIME Offload**: Intel iGPU cho desktop, NVIDIA cho app nặng
- `nvidia-offload <app>` — chạy app với GPU rời
- Power Management: RTD3 fine-grained
- 3 chế độ: `sync`, `async`, `nvidia`

### ⚡ Power Management (tuned)
- **tuned** (Red Hat Enterprise) thay thế PPD/TLP
- **Dynamic tuning**: tự động CPU governor theo load
- **PPD bridge**: GNOME Settings → Power vẫn điều chỉnh được
- **Battery optimized**: ASPM powersupersave, WiFi power saving, runtime PM
- **Profile per edition**: desktop / throughput-performance / latency-performance

### 🛠️ BamOS CLI (`bam`) — 13 commands

| Command | Chức năng | Ví dụ |
|---------|-----------|-------|
| `install` | Cài package (nix + flatpak) | `bam install firefox` |
| `remove` | Gỡ package | `bam remove firefox` |
| `search` | Tìm trong nixpkgs | `bam search video` |
| `shell` | Shell tạm với package | `bam shell python` |
| `run` | Chạy binary trong FHS env | `sudo bam run ./VentoyWeb.sh` |
| `update` | Check → show changelog → confirm → rebuild | `sudo bam update` |
| `update --check` | Chỉ kiểm tra, không apply | `sudo bam update --check` |
| `info` | System info (CPU, GPU, RAM, Disk, Backups, Version) | `bam info` |
| `clean [--keep N]` | Dọn Nix generations + Btrfs snapshots | `sudo bam clean --keep 7` |
| `rollback [gen]` | Rollback về generation trước | `sudo bam rollback` |
| `changelog` | Xem changelog các version mới (từ GitHub hoặc update_change) | `bam changelog` |
| `backup [-s] [-h] [-d]` | Backup system/home/data | `sudo bam backup` |
| `restore [-s] [-h] [-d]` | Restore system/home/data | `sudo bam restore --list` |

> **Lưu ý**: `bam install/remove/search` hoạt động như `apt`/`dnf` trên distro FHS — tự động fallback qua nix profile → flatpak.

### 💾 Backup & Restore (Btrfs + btrbk)

- **Btrfs snapshots**: tự động hourly (giữ 24), daily (7), weekly (4), monthly (3)
- **bam backup**: nén `/etc/nixos/` (system), `~/.config` + `~/.local/share` (home), `/data/` lưu vào `/data/backups/{system,home,data}/`
- **bam restore**: liệt kê danh sách backup → chọn số thứ tự → restore
- **`bam backup -s -h -d`**: chọn thành phần cụ thể
- **`bam restore --list`**: xem danh sách backup

### 🔄 Auto-Update Engine

```
┌─────────────────────────────────────────────────────────────┐
│  1. Auto timer (systemd, 12h) — check-only                 │
│     ├── So sánh /etc/bamos/version vs GitHub VERSION        │
│     ├── Nếu mới → tạo /etc/bamos/update_change             │
│     └── Desktop notification: "Run: sudo bam update"       │
├─────────────────────────────────────────────────────────────┤
│  2. sudo bam update — interactive apply                    │
│     ├── Hiển thị changelog (từ update_change hoặc GitHub)   │
│     ├── Hỏi xác nhận "Apply now? [Y/n]"                    │
│     ├── Download VERSION + CHANGELOG.md → ghi đè /etc/bamos/│
│     ├── nix flake update → nixos-rebuild switch → GC       │
│     └── nixos-rebuild boot (regen boot menu)               │
└─────────────────────────────────────────────────────────────┘
```

- **Check-only timer**: KHÔNG tự rebuild — chỉ check + notify
- **Interactive update**: changelog preview → confirmation → apply
- **Version lifecycle**: `/etc/bamos/version` được cập nhật từ GitHub mỗi lần update
- **Failure notification**: desktop cảnh báo nếu update thất bại

### 🎨 Theming (RakuOS-inspired)
- **GTK Theme**: Nordic (~ OrigamiPaper, Nord color scheme)
- **Icons**: WhiteSur-dark
- **Cursor**: Bibata-Modern-Classic
- **Font**: Inter 11 (UI) + Maple Mono NF 11 (monospace)
- **GNOME Extensions**: dash-to-dock, appindicator, blur-my-shell, no-overview, user-themes, vitals, gsconnect
- **Plymouth boot splash**: Bamboo logo + spinner

### 📦 Calamares Unified Installer
- **Edition selector**: Standard / Developers / Gaming / Studio
- **Machine type**: Laptop / Desktop / Server
- **Custom Python module**: sinh `/etc/nixos/` + `customized.nix` động
- **Post-install flake**: `github:quocnho/bamos` — dễ update
- **Branding**: Logo bamboo, Nord colors, slideshow
- **Ổ D drive icon + Nautilus bookmark**: tự động tạo

### 📦 Third-Party Runtime
| Công nghệ | Mô tả | Module toggle |
|-----------|-------|--------------|
| **FHS Compat** | `bam run <cmd>` — chạy binary tĩnh (Ventoy, Zoom, MATLAB) | `bamos.third-party.fhs-compat` |
| **AppImage** | `appimage-run` + Gear Lever GUI + binfmt | `bamos.third-party.appimage` |
| **Flatpak** | Flatpak + Flathub + XDG Desktop Portal | `bamos.third-party.flatpak` |
| **Podman** | Container runtime + Docker compat | `bamos.third-party.container` |
| **Distrobox** | Container-based distro emulation | `bamos.third-party.distrobox` |
| **Wine** | Windows apps (Gaming edition) | `bamos.third-party.wine` |
| **Waydroid** | Android runtime | `bamos.third-party.waydroid` |
| **Codecs** | ffmpeg, gstreamer, VA-API | `bamos.third-party.codecs` |

---

## 🖥️ Developer Machine — hosts/lg (LG Gram)

Cấu hình tham khảo cho laptop LG Gram (i5-10210U, GTX 1650):

- **OS**: NixOS 26.11 + Zen kernel
- **GPU**: NVIDIA 595.84 (proprietary) + Intel UHD iGPU — PRIME mode `nvidia`
- **Desktop**: GNOME + GDM (Wayland)
- **Power**: tuned `desktop` profile + batteryOptimized + 16GB swap
- **Storage**: Btrfs NVMe 476GB
- **Developer tools**: QEMU, Virt-manager, Podman, Distrobox, VS Code, Zed
- **VM**: libvirtd + VirtualBox
- **Auto-update**: enabled (systemd timer every 12h)

```bash
# Build + switch trên máy LG
sudo nixos-rebuild switch --flake .#lg

# Hardware detection trước khi rebuild
sudo bamos-detect-hardware
```

---

## 🛠️ Development Workflow

```bash
# Enter dev shell
nix develop

# Format code
nix fmt

# Check flake
nix flake check --all-systems

# Quét hardware (trước rebuild)
sudo bamos-detect-hardware

# Build OS
sudo nixos-rebuild switch --flake .#lg

# Build ISO
nix build .#iso-gnome-standard

# Copy ISO ra thư mục iso/
nix run .#iso-export -- iso-gnome-standard

# Push cache
nix run .#push-cachix

# One-command build + push
nix run .#update
```

---

## 📊 Sprint Status

| Sprint | Goal | Status |
|--------|------|--------|
| Sprint 1 | ISO GNOME Standard | ✅ Done |
| Sprint 2 | KDE + Standard Apps | ✅ Done |
| Sprint 3 | Developers + Gaming | ✅ Done |
| Sprint 4 | COSMIC + Studio | ✅ Done |
| Sprint 5 | Auto-Detect Hardware + RakuOS Theming | ✅ Done |
| Sprint 6 | Btrfs Backup & Restore + Auto Update Engine | ✅ Done |
| Sprint 7 | Unified Calamares Installer | 🟡 Active |
| Sprint 8 | BamOS Portal + Community | 🔮 Future |

---

## 🤝 Đóng góp

BamOS là mã nguồn mở cho cộng đồng người Việt:

- 🐛 **Báo lỗi**: Mở issue trên [GitHub](https://github.com/quocnho/bamos/issues)
- 💡 **Đề xuất**: Ý tưởng cho distro
- 🔧 **Pull request**: Module mới, cải thiện code
- 🌐 **Chia sẻ**: Giới thiệu BamOS đến bạn bè

---

## 📄 License

MIT License

---

<div align="center">
  <sub>Built with ❤️ for the Vietnamese NixOS community</sub>
  <br />
  <sub>Powered by <a href="https://nixos.org">NixOS</a> · <a href="https://flake.parts">flake-parts</a> · <a href="https://github.com/NixOS/nixpkgs">nixpkgs</a></sub>
  <br />
  <sub><a href="https://bamos.cachix.org">Cachix Cache</a> · <a href="https://github.com/quocnho/bamos">GitHub</a></sub>
  <br />
  <sub><strong>Version 2.0.0</strong> — Logo: <a href="assets/logo/bamos-logo.svg">Bamboo Mosaic</a></sub>
</div>
