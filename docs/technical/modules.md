# NixOS Modules

## Core Modules

### system.nix
- **Options**: `bamos.system.kernelPackage`
- **Default**: `pkgs.linuxKernel.kernels.linux_zen`
- **Description**: Kernel package cho hệ thống

### locale.nix
- **Options**: `bamos.locale.language`, `bamos.locale.timezone`
- **Default**: `vi_VN.UTF-8`, `Asia/Ho_Chi_Minh`
- **Description**: Locale, timezone, language

### audio.nix
- **Options**: `bamos.audio.enable`
- **Default**: `true`
- **Description**: PipeWire với ALSA + PulseAudio + 32-bit

### input-method.nix
- **Options**: `bamos.inputMethod.enable`
- **Default**: `true`
- **Description**: Fcitx5 + Bamboo (Telex, VNI, VIQR)

### security.nix
- **Options**: `bamos.security.firewall`, `bamos.security.apparmor`
- **Default**: Both enabled
- **Description**: Firewall rules, AppArmor, sudo

### optimization.nix
- **Options**: `bamos.optimization.zram`, `bamos.optimization.gc`
- **Default**: ZRAM enabled
- **Description**: Dọn dẹp, tối ưu hiệu năng

## Desktop Modules

### gnome.nix
- **Options**: `bamos.desktop.gnome.enable`, `bamos.desktop.gnome.extensions`
- **GSettings**: Dock, font, theme, keybindings
- **Extensions**: dash-to-dock, appindicator, blur-my-shell

### kde.nix
- **Options**: `bamos.desktop.kde.enable`
- **Description**: KDE Plasma với SDDM

### cosmic.nix
- **Options**: `bamos.desktop.cosmic.enable`
- **Description**: COSMIC DE từ System76 (Rust-based)

## Edition Modules

### standard.nix
- **Apps**: Firefox, LibreOffice, VLC, Flatpak
- **Description**: Edition phổ thông

### developers.nix
- **Apps**: VS Code, Podman, Git, devenv, dev tools
- **Description**: Edition cho lập trình viên

### gaming.nix
- **Apps**: Steam, Lutris, GameScope, MangoHud
- **Kernel**: XanMod
- **Description**: Edition gaming

### studio.nix
- **Apps**: Blender, Kdenlive, Ardour, OBS, GIMP
- **Audio**: Low-latency configuration
- **Description**: Edition sáng tạo nội dung

## App Modules

### apps-standard.nix
Liệt kê applications cho Standard edition.

### apps-developers.nix
Liệt kê applications cho Developers edition.

### apps-gaming.nix
Liệt kê applications cho Gaming edition.

### apps-studio.nix
Liệt kê applications cho Studio edition.

## Hardware Modules

### nvidia.nix
- **Options**: `bamos.nvidia.enable`, `bamos.nvidia.mode`, `bamos.nvidia.open`
- **Modes (cho Optimus laptop)**:
  - `sync`: PRIME đồng bộ — ổn định, desktop/văn phòng
  - `async`: PRIME bất đồng bộ — gaming, cân bằng hiệu năng
  - `nvidia`: Chỉ dùng GPU rời — hiệu năng cao nhất, tắt iGPU
- **Driver options**:
  - `open = false` (default): Driver đóng (proprietary) — tương thích rộng
  - `open = true`: Open kernel module — Turing RTX 2000+ mới hơn
- **Power**: RTD3 fine-grained, udev rules, NVIDIA module auto-load
- **CUDA**: cudatoolkit + CUDA drivers cho compute workloads
- **G-Sync**: `__GL_VRR_ALLOWED` environment variable

## Other Modules

### disko-btrfs.nix
- **Description**: Declarative disk partitioning với Btrfs, mô hình "Ổ C — Ổ D"
- **Subvolumes (Ổ C — hệ thống)**: `@` → `/`, `@nix` → `/nix`, `@home` → `/home`
- **Subvolumes (Ổ D — dữ liệu)**: `@data` → `/data`
- **XDG Redirect**: `~/Documents` → `/data/Documents`, `~/Downloads` → `/data/Downloads`, v.v.

### fonts.nix
- **Description**: Fonts tiếng Việt + programming fonts
- **Includes**: Noto Sans, Fira Code, JetBrains Mono

### software-center.nix
- **Description**: Cấu hình Software Center theo DE
- **GNOME**: GNOME Software
- **KDE**: KDE Discover
- **Gear Lever**: AppImage management

### packages.nix
- **Description**: Package aggregator cho toàn bộ hệ thống

### user.nix
- **Options**: `bamos.user.name`, `bamos.user.extraGroups`
- **Description**: Cấu hình user mặc định

### calamares.nix
- **Description**: Calamares installer configuration (future)
