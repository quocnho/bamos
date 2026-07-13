# Project Idea: BamOS

> **"BamOS — NixOS Distribution for the Vietnamese Community"**
> **"Bản phân phối NixOS dành cho người Việt — Tích hợp sẵn, dùng được ngay"**

---

## Vision

BamOS là một **bản phân phối Linux hoàn chỉnh** (Linux distribution) được xây dựng trên nền tảng NixOS với sức mạnh của `flake-parts`, thiết kế dành riêng cho người dùng Việt Nam. Không chỉ là một bộ dotfiles cá nhân — BamOS hướng đến việc trở thành một **distro có thể cài đặt từ ISO**, sử dụng hàng ngày, và phân phối rộng rãi đến cộng đồng.

**Triết lý cốt lõi:** *"Cài xong là dùng" (Out-of-the-box. Plug & Play.)* — Mọi thứ hoạt động ngay sau khi cài đặt, không cần mở terminal, không cần tùy biến thủ công.

---

## Problem

Người dùng Việt Nam gặp nhiều rào cản khi sử dụng Linux:

1. **Gõ tiếng Việt phức tạp**: Phải cài đặt và cấu hình thủ công bộ gõ (ibus/fcitx + bamboo/unikey), xử lý biến môi trường, xung đột giữa các ứng dụng GTK/Qt/Electron/Flatpak.

2. **Cấu hình rời rạc, khó tái tạo**: Mỗi lần cài lại hệ điều hành là một lần "hành xác" với hàng giờ cấu hình lại từ đầu. Cấu hình không được quản lý tập trung, dễ bị thất lạc, không thể rollback khi gặp lỗi.

3. **Lo sợ mất dữ liệu khi cài lại OS**: Người dùng phổ thông quen với mô hình "Ổ C — Ổ D" của Windows. Trên Linux, việc cài lại thường đồng nghĩa với xóa sạch phân vùng, gây mất dữ liệu cá nhân.

4. **Thiếu distro Việt hóa chuyên nghiệp**: Các distro Linux phổ biến (Ubuntu, Fedora, Arch) không được tối ưu cho người Việt ngay từ đầu. Người dùng phải tự mày mò, dễ nản và quay lại Windows.

5. **Dependency Hell**: Cài đặt phần mềm `.deb`/`.rpm` trực tiếp lên hệ thống dễ gây xung đột thư viện, hỏng hệ thống, khó gỡ bỏ triệt để.

6. **Thiếu distro chuyên biệt cho từng nhu cầu**: Người dùng phổ thông, developer, gamer, và người làm studio đều bị dồn vào một distro chung chung, phải tự cài đặt thêm hàng tá phần mềm và cấu hình phức tạp.

---

## Solution

BamOS giải quyết triệt để các vấn đề trên bằng **4 trụ cột kiến trúc** + **Ma trận 3×4 Editions**:

### Trụ cột 1 — Lõi Bất Biến (Immutable Core)
- Hệ thống gốc được quản lý declarative qua Nix — không thể bị phá hỏng bởi người dùng cuối.
- Mọi thay đổi đều qua file cấu hình `.nix`, có thể version-control bằng Git.
- **Rollback tức thì**: Chỉ cần reboot và chọn generation cũ từ menu boot. Không cần "cài lại".

### Trụ cột 2 — Btrfs Storage (Ổ C — Ổ D cho Linux)
- Phân vùng Btrfs với subvolumes tách biệt theo mô hình quen thuộc với người Việt:
  - **Ổ C:** `@` → `/` (hệ thống), `@nix` → `/nix` (store), `@home` → `/home` (chỉ config)
  - **Ổ D:** `@data` → `/data` (Documents, Downloads, Pictures, Videos, Music)
- Khi cài lại hoặc rollback, **chỉ Ổ C bị ghi đè**. Ổ D **an toàn tuyệt đối**.
- XDG User Dir redirect: `~/Documents` → `/data/Documents`, `~/Downloads` → `/data/Downloads`, v.v.
- **Calamares partitioner** được cấu hình để tự động tạo subvolume `/data` khi cài đặt.
- Tiết kiệm băng thông: `/nix` được tái sử dụng, không phải tải lại toàn bộ package.

### Trụ cột 3 — App Layer Hiện Đại
- **Nix Declarative**: Ứng dụng lõi được khai báo trong code Nix.
- **GNOME Software / KDE Discover**: Software Center GUI — duyệt, cài, cập nhật Flatpak apps.
- **Flatpak + Flathub**: Ứng dụng phổ thông cài qua Software Center — click là cài.
- **AppImage Support**: Chạy AppImage trực tiếp với `appimage-run` (binfmt). **Gear Lever** (GUI) — kéo-thả, quản lý, tích hợp app menu, cập nhật AppImage.
- **Distrobox/Podman**: Container cho dev tool và ứng dụng đặc thù. App export ra menu desktop.
- **Home Manager integration**: Quản lý user-level apps (Flatpak, dotfiles, GNOME extensions).

### Trụ cột 4 — Trải Nghiệm Bản Địa (OOTB Vietnamese UX)
- **Fcitx5 + Bamboo**: Gõ tiếng Việt Telex, VNI native trên mọi ứng dụng (GTK, Qt, Electron, Flatpak).
- **PipeWire Audio**: Âm thanh hiện đại, hỗ trợ Bluetooth, 32-bit legacy.
- **Dual-Kernel Strategy**:
  - **ISO Live/Installer**: Linux LTS (6.12) — ổn định, tương thích cao, dung lượng nhỏ.
  - **OS sau cài đặt**: Linux Zen (mới nhất) — tối ưu desktop & gaming, tương thích Intel + AMD.
- **Locale & Timezone VN**: Asia/Ho_Chi_Minh, LC_* = vi_VN — tự động sau cài đặt.
- **Factory Reset UI** (tương lai): 1-click khôi phục giao diện về trạng thái nguyên bản.

### Trụ cột 5 — ISO Nhẹ & Tối Ưu (Lightweight ISO)
- **SquashFS + zstd level 22**: Nén tối đa, ISO < 2.5GB — tải nhanh, upload nhanh.
- **LTS Kernel trong ISO**: Giảm kích thước kernel modules, tránh bug kernel mới nhất.
- **Loại bỏ build dependencies**: `includeSystemBuildDependencies = false` — ISO chỉ chứa runtime.
- **Dual-kernel**: LTS (ISO) → Zen (cài xong) — tốt nhất của cả hai thế giới.

### Trụ cột 6 — Binary Cache & Phân Phối (Cachix + Cloudflare R2 + GitHub Releases)
- **Cachix Binary Cache**: Cache tất cả build artifacts lên `bamos.cachix.org` — build nhanh, CI/CD nhanh.
- **GitHub Releases**: ISO artifacts được upload lên GitHub Releases — download miễn phí, không giới hạn bandwidth.
- **Cloudflare R2**: ISOs được deploy lên Cloudflare R2 (S3-compatible) — CDN global, không giới hạn bandwidth.
- **Cosign Signing**: ISO files được ký số với Cosign để xác thực tính toàn vẹn.
- **CI/CD Pipeline (ublue-os pattern)**:
  - 3 workflows riêng biệt theo pattern từ ublue-os (Bazzite):
    - **`ci.yml`** — PR + non-main pushes: check flake, build GNOME ISO, VM smoke test
    - **`release.yml`** — Push to main: build 3 unified ISOs, push Cachix, auto-tag, GitHub Release
    - **`release-cd.yml`** — Tag push v*: deploy ISOs lên Cloudflare R2, Cosign sign, metadata JSON
- **Auto-tag strategy**: `v{VERSION}.{YYYYMMDD}.{BUILD}` (ví dụ: `v4.0.0.20260710.1`)
- **Changelog tự động**: Sinh từ conventional commits qua `generate-changelog.py`
- **Hướng dẫn setup Cachix**:
  ```bash
  nix profile install nixpkgs#cachix        # Cài Cachix CLI
  cachix authtoken <token>                   # Xác thực (lấy từ cachix.org)
  cachix create bamos                        # Tạo cache (chạy 1 lần)
  cachix use bamos                           # Dùng cache (thêm vào nix.conf)
  cachix push bamos ./result                 # Push build result lên cache
  ```
- **GitHub Actions Integration**:
  ```yaml
  - uses: cachix/cachix-action@v15
    with:
      name: bamos
      authToken: '${{ secrets.CACHIX_AUTH_TOKEN }}'
  ```
- **Rebuild từ GitHub (không cần clone)**:
  ```bash
  sudo nixos-rebuild switch --flake github:quocnho/bamos#lg --refresh
  ```
- **Người dùng hưởng lợi**: Khi cài BamOS, `nixos-rebuild` tự động pull từ Cachix cache → không cần build lại từ source.

### Ma Trận Editions: 3 DE × 4 Editions = 12 ISO Variants

BamOS cung cấp **12 phiên bản ISO** khác nhau, tổ hợp từ 3 Desktop Environment và 4 Edition:

|  | **Standard** | **Developers** | **Gaming** | **Studio** |
|---|-------------|---------------|-----------|-----------|
| **GNOME** | ✅ BamOS GNOME Standard | ✅ BamOS GNOME Dev | ✅ BamOS GNOME Gaming | ✅ BamOS GNOME Studio |
| **KDE Plasma** | ✅ BamOS KDE Standard | ✅ BamOS KDE Dev | ✅ BamOS KDE Gaming | ✅ BamOS KDE Studio |
| **COSMIC** | ✅ BamOS COSMIC Standard | ✅ BamOS COSMIC Dev | ✅ BamOS COSMIC Gaming | ✅ BamOS COSMIC Studio |

#### Desktop Environments (DE)

| DE | Đặc điểm | Đối tượng |
|----|---------|-----------|
| **GNOME** | Wayland-native, đơn giản, hiện đại, touch-friendly | Người dùng phổ thông, laptop, touchscreen |
| **KDE Plasma** | Wayland-native, tùy biến cao, nhẹ hơn GNOME, KWin compositor | Power users, desktop, multi-monitor |
| **COSMIC** | Wayland-only, Rust-based, tiling + floating, mới nhất từ System76 | Early adopters, developers thích Rust, tiling WM |

#### Editions

| Edition | Đối tượng | Đặc điểm |
|---------|-----------|---------|
| **Standard** | Người dùng phổ thông, văn phòng, giải trí | Ứng dụng cơ bản: trình duyệt, văn phòng, media, chat. Sẵn sàng dùng ngay. |
| **Developers** | Lập trình viên, DevOps, data scientist | **Devenv** cho môi trường dev (không cài sẵn ngôn ngữ). **Podman** thay Docker. Dev tools: editor, terminal, git, container tools, debugging. |
| **Gaming** | Game thủ, streamer | Tối ưu gaming như **Bazzite OS** + **glf-os.org**: GameScope, MangoHud, Steam, Lutris, Heroic, ProtonGE, OBS Studio, Discord. Game mode session riêng. |
| **Studio** | Nhà sáng tạo nội dung, designer, music producer | Tối ưu studio như **glf-os Studio Pro**: Blender, Kdenlive, GIMP, Inkscape, Ardour, LMMS, OBS Studio, Darktable, Krita, FontForge. Low-latency audio kernel params. |

---

## Target Users

| Phân khúc | Edition | Nhu cầu chính |
|-----------|---------|---------------|
| **Người dùng phổ thông** | Standard | Gõ tiếng Việt, ứng dụng phổ biến, không cần terminal |
| **Sinh viên CNTT** | Standard / Developers | Dev tools, tài liệu tiếng Việt, cộng đồng hỗ trợ |
| **Lập trình viên** | Developers | Môi trường dev reproducible qua devenv, Podman containers |
| **Game thủ** | Gaming | Steam, Proton, GameScope, tối ưu FPS, controller support |
| **Nhà sáng tạo nội dung** | Studio | Blender, Kdenlive, Ardour, low-latency audio, color management |
| **Người dùng máy lắp ráp** | Tất cả | Kernel Zen tương thích rộng, auto-detection hardware |

---

## Tech Stack

- **Language:** Nix (purely functional package management language)
- **Base OS:** NixOS (nixos-unstable channel)
- **Framework:** flake-parts (hercules-ci) — modular flake framework
- **GPU & Đồ hoạ:**
  - **NVIDIA driver**: Chọn driver đóng (proprietary) hoặc mở (open kernel module cho Turing+)
  - **PRIME/Optimus laptop**: 3 chế độ cấu hình — `sync` (ổn định), `async` (cân bằng), `nvidia` (hiệu năng)
  - **Power Management**: RTD3 fine-grained cho laptop tiết kiệm pin
  - **CUDA toolkit**: GPU compute cho AI/data science (Developers edition)
  - **VA-API**: Tăng tốc video encode/decode qua NVIDIA (nvidia-vaapi-driver)
  - **G-Sync**: Adaptive sync qua session variable `__GL_VRR_ALLOWED`
- **Multi-Kernel Strategy:"
  | Kernel | Phiên bản | Dùng cho | Lý do |
  |--------|---------|---------|-------|
  | **Linux LTS 6.12** | `linuxPackages_6_12` | ISO Live/Installer | Ổn định, nhẹ, tương thích ZFS |
  | **Linux Zen** | `linuxPackages_zen` | hosts/lg, Standard/Dev editions | Desktop-optimized (MuQSS/BMQ scheduler), balance features & stability |
  | **Linux XanMod** | `linuxPackages_xanmod` | Gaming editions | Gaming-optimized (TT + BORE scheduler), LTS base, ZFS support |
- **Cơ chế override:** Kernel set tại 3 levels: `modules/system.nix` (Zen default) → `profiles/` (edition-level override) → `hosts/` (host-level `lib.mkForce`).
- **CachyOS:** ⏳ Chưa có trong nixpkgs. XanMod thay thế vì có sẵn, LTS stable, và gaming-optimized scheduler tương đương.
- **Desktop Environments:**
  - GNOME + GDM (Wayland-native)
  - KDE Plasma + SDDM (Wayland-native)
  - COSMIC + cosmic-greeter (Wayland-only, Rust-based)
- **Input Method:** Fcitx5 + Bamboo engine (Telex, VNI)
- **Software Center:**
  - GNOME Software (GTK4 + Flatpak backend) — cho GNOME editions
  - KDE Discover (Qt + PackageKit + Flatpak) — cho KDE editions
  - Flatpak CLI + Flathub — backend cho cả hai
- **AppImage Support:** `appimage-run` + `Gear Lever` (GUI) — chạy và quản lý AppImage không cần terminal
- **Theming (RakuOS GNOME inspired):**
  - DE-specific theme modules: `modules/theming/gnome-theme.nix`, `kde-theme.nix`, `cosmic-theme.nix`
  - GTK Theme: Nordic (~ OrigamiPaper, Nord color scheme)
  - Icon Theme: WhiteSur-dark (from nixpkgs `whitesur-icon-theme`)
  - Cursor Theme: Bibata-Modern-Classic (from nixpkgs `bibata-cursors`)
  - **Font: Inter 11 (UI), Maple Mono NF 11 (monospace)**
  - **GNOME Extensions: dash-to-dock, appindicator, blur-my-shell, no-overview, user-themes**
  - GNOME color scheme: prefer-dark
  - Window buttons: appmenu:minimize,maximize,close
  - Wallpaper: BamOS default (dark/light pair)
  - Plymouth boot splash: logo + spinner
  - **System GTK settings**: `/etc/gtk-3.0/settings.ini` + `/etc/gtk-4.0/settings.ini` — works immediately
  - **One-time gsettings activator**: `bamos-gnome-first-login` — applies theme to existing users
  - **Offline asset downloads**: `assets/fetch-assets.sh` — themes, icons, cursors, fonts vào `assets/`
- **Audio:** PipeWire (ALSA + PulseAudio + 32-bit + JACK compatibility for Studio)
- **Filesystem:** Btrfs (subvolumes: `@`, `@home`, `@nix`)
- **Bootloader:** systemd-boot (UEFI)
- **Partitioning:** Disko (declarative disk layout)
- **Auto-Detect Hardware:**
  - `bamos-detect-hardware` script chạy `nixos-generate-config` + GPU detection (`lspci`)
  - Sinh ra `/etc/bamos/hardware-configuration.nix` + `/etc/bamos/gpu-config.nix`
  - Tự động phát hiện NVIDIA/AMD/Intel GPU, PCI bus IDs, kernel modules
  - Chạy trước mỗi `nixos-rebuild switch` để cập nhật cấu hình hardware chính xác
  - GPU driver chỉ được tải khi phát hiện có GPU tương ứng
- **Dev Environment (Developers Edition):** devenv (không cài sẵn ngôn ngữ/công cụ/môi trường)
- **Container Runtime (Developers Edition):** Podman (thay Docker)
- **Gaming Stack (Gaming Edition):** GameScope, MangoHud, Steam, Lutris, Heroic, ProtonGE
- **Studio Stack (Studio Edition):** Low-latency kernel params, JACK via PipeWire, color management
- **Power Management:** tuned (Red Hat Enterprise) — thay thế PPD/TLP
  - Dynamic tuning: tự động điều chỉnh CPU governor theo load
  - PPD bridge: GNOME Settings → Power vẫn điều khiển được
  - Profile mặc định theo edition: desktop / throughput-performance / latency-performance
  - Battery optimization cho laptop: ASPM powersupersave, WiFi power saving, runtime PM
- **Calamares Unified Installer (GLF-OS pattern):**
  - **Override package** `calamares-nixos-extensions` via `overrideAttrs` + `postInstall` (GLF-OS pattern)
  - **Overlay áp dụng** qua `nixpkgs.overlays` TRONG `nixosSystem` (không phải perSystem) — đảm bảo áp dụng đúng cho ISO config
  - Config files ở `modules/boot/patches/calamares/` (settings.conf + module configs)
  - Custom Python module `bamos-config` (scripts/patches/calamares/bamos-config/main.py)
  - Packagechooser Edition: Standard / Developers / Gaming / Studio
  - Packagechooser Machine Type: Laptop / Desktop / Server
  - **Wayland fix**: `sudo --preserve-env=WAYLAND_DISPLAY,...` trong autostart `.desktop` (GLF-OS pattern)
  - **DPI fix**: `QT_QPA_PLATFORM=wayland;xcb` + `QT_AUTO_SCREEN_SCALE_FACTOR=1`
  - Btrfs mặc định + Ổ D (/data subvolume) trong partition step
  - Branding: Logo BamOS thật từ `assets/logo/bamos-logo.svg`, Nord color palette, slideshow
  - Ổ D drive icon + Nautilus bookmark
  - Post-install /etc/nixos/: flake template chuyên nghiệp với cấu trúc modules/
    - `flake.nix`, `configuration.nix`, `customized.nix`, `modules/`, `customConfig/`, `README.md`, `home.nix`, `secrets/`
    - `customConfig/default.nix` 🛡️ KHÔNG bị ghi đè khi cài lại
- `lib.mkForce` cho `QT_QPA_PLATFORM` để ghi đè giá trị từ `installation-cd-graphical-calamares-gnome.nix`
- **Hardware Detection Tools (mọi edition):**
  - pciutils (lspci), usbutils (lsusb), dmidecode, inxi, mesa-demos (glxinfo)
- **Third-Party Runtime (modules/core/third-party.nix):**
  - AppImage: appimage-run + Gear Lever + binfmt
  - Flatpak: flatpak + xdg-desktop-portal-gtk/kde
  - Container: Podman + Docker compat + Distrobox
  - **Welcome Banner (bam-welcome)**: Hiển thị khi mở terminal — thông tin hệ thống, hướng dẫn bam CLI, thông báo cập nhật. Chạy 1 lần/ngày qua timestamp cache. Tích hợp bash + zsh.
  - **BamOS CLI (bam)**: Universal command manager như dnf/apt
      - `bam install <pkg>` — Cài package (nix profile + flatpak)
      - `bam remove <pkg>` — Gỡ package
      - `bam search <q>` — Tìm trong nixpkgs
      - `bam run <cmd>` — Chạy binary trong FHS env (Ventoy, Zoom, MATLAB)
      - `bam shell <pkg>` — Shell tạm với package
      - `bam switch` — Rebuild system (nixos-rebuild switch alias)
      - `bam switch --test|--boot|--flake` — Test/build/flake options
      - `bam update` — Flake update → rebuild → GC → regen boot
      - `bam info` — System info (CPU, GPU, RAM, Disk, Backups)
      - `bam clean [--keep N]` — Dọn Nix generations + Btrfs snapshots
      - `bam rollback [gen]` — Rollback về generation trước
      - `bam changelog` — Xem changelog các version mới (so sánh local vs GitHub)
      - `bam backup [-s] [-h] [-d]` — Backup system/home/data vào /data/backups/
      - `bam restore [-s] [-h] [-d]` — Restore theo flags hoặc interactive menu
      - `bam restore --list` — Xem danh sách backup
      - `bam iso [variant] [--clean|--vm]` — Build ISO (gnome/kde/cosmic)
      - `bam vm [--disk|--ram|--uefi]` — Chạy VM với ISO
      - `bam usb <device>` — Ghi ISO vào USB
      - `bam snapshot create [name]` — Tạo portable system snapshot
      - `bam snapshot list` — Liệt kê snapshots
      - `bam snapshot restore <name>` — Khôi phục từ snapshot
      - `bam snapshot share <name>` — Đóng gói snapshot để chia sẻ
      - `bam share export` — Xuất /etc/nixos/ dưới dạng portable archive
      - `bam share iso [variant]` — Build custom ISO với user config
    - **Welcome Banner (bam-welcome)**: Hiển thị khi mở terminal — thông tin hệ thống + hướng dẫn các câu lệnh bam CLI cơ bản cho người dùng cuối (cài app, cập nhật, sao lưu)
        - Chạy 1 lần/ngày (dùng timestamp cache)
        - Tích hợp qua `programs.bash.interactiveShellInit` + `programs.zsh.interactiveShellInit`
        - Package: `pkgs/bam-welcome`, Module: `modules/core/welcome.nix`
    - Được build từ pkgs/bam-cli/default.nix + third-party.nix
  - Wine (optional, Gaming edition): wine-wayland, winetricks
  - Codecs: ffmpeg, gstreamer-full, intel-vaapi, nvidia-vaapi
  - Fonts: Noto CJK, Liberation, DejaVu, Inter, Maple Mono
  - Archive: file-roller, 7z, unzip, unrar, zstd
  - Network: curl, wget, openssl, nmap, mtr, wireguard
- **File Manager Integration:**
  - Ổ D (/data) tự động mount + bookmark trong Nautilus sidebar
  - Custom drive icon (SVG) — giống Windows D drive
  - XDG user dirs redirect: ~/Documents → /data/Documents
- **CI/CD:** GitHub Actions (Nix Flakes)
- **Binary Cache:** Cachix (bamos.cachix.org)

---

## Key Features (MVP → Future)

### Phase 1 — Core Foundation ✅ (Hoàn thành)
239. flake-parts foundation với `mkFlake`
240. Zen kernel (`linuxPackages_zen`) — cho OS sau cài đặt
241. GNOME desktop (GDM + Wayland)
242. systemd-boot, EFI support
243. Dev environment (`nix develop`) — nil, nixd, nixpkgs-fmt, deadnix, statix, cachix
244. Custom packages overlay (bamos-branding, bam-cli)

### Phase 2 — Bản địa hóa ✅ (Hoàn thành)
247. Fcitx5 + Bamboo — gõ tiếng Việt Telex, VNI
248. Locale Việt Nam (`Asia/Ho_Chi_Minh`, `vi_VN`)
249. PipeWire audio (ALSA + PulseAudio + 32-bit)
10. Tối ưu dịch vụ (tắt printing, avahi, power-profiles-daemon)
11. Vietnamese fonts (Noto Sans, Fira Code, JetBrains Mono)

### Phase 3 — Distro ISO ✅ (Sprint 1 — Hoàn thành)
12. ISO build infrastructure — `system.build.images` (NixOS 25.05+ native)
13. **GNOME Standard ISO** bootable — `nix build .#iso-gnome-standard`
14. Installer (Calamares) qua `installation-cd-graphical-calamares-gnome.nix`
15. Disko — tự động phân vùng Btrfs subvolumes (`@`, `@home`, `@nix`)
16. Dual-kernel: LTS 6.12 (ISO) → Zen (OS sau cài)
17. Flatpak + Flathub — cài app qua Software Center
18. CI/CD pipeline — GitHub Actions build ISO tự động
19. Binary Cache — Cachix (`bamos.cachix.org`)
20. Project infrastructure — plan/, git workflow, skill system

### Phase 4 — Multi-DE + Standard Apps ✅ (Sprint 2 — Hoàn thành)
21. **KDE Plasma Standard ISO** — `nix build .#iso-kde-standard`
22. SDDM display manager (Wayland)
23. Standard Edition apps (Firefox, LibreOffice, VLC, Discord, Telegram)
24. `mkEdition` helper — tạo edition profile từ DE + edition type
25. Modules refactor: flat → subdirs (`core/`, `boot/`, `desktop/`, ...)
26. GNOME window buttons: Min/Max/Close (dconf)
27. Btrfs Ổ C — Ổ D: `@data` subvolume + XDG redirect
28. Calamares GUI partition: partition.conf + mount.conf override

### Phase 5 — Developers + Gaming Editions ✅ (Sprint 3 — Hoàn thành)
29. **GNOME Developers ISO** — devenv + Podman + dev tools
30. **GNOME Gaming ISO** — GameScope + Steam + Lutris + Heroic + MangoHud
31. **KDE Developers ISO** — KDE + dev tools
32. **KDE Gaming ISO** — KDE + gaming stack
33. **Developer Workstation** — hosts/lg với agenix + home-manager + GNOME extensions
34. NVIDIA GeForce GTX 1650 support — Optimus PRIME + power management
35. Software Center — GNOME Software + Flatpak + Gear Lever (AppImage)

### Phase 6 — COSMIC + Studio Edition ✅ (Sprint 4 — Hoàn thành)
36. **COSMIC desktop** — module + profile (3 editions)
37. **GNOME Studio ISO** — Blender, Kdenlive, GIMP, Ardour, OBS
38. **KDE Studio ISO** — KDE + studio apps, low-latency audio
39. **COSMIC Studio ISO** — Cosmic + studio apps
40. All 12 ISO variants build OK — `nix flake check` pass
41. NVIDIA hardware detection — `bamos-detect-hardware` script
42. Docs website — 32+ trang (bazzite-style)
43. Technical docs — architecture, modules, iso-build, kernel

### Phase 7 — Auto-Detect Hardware + Power Management ✅ (Hoàn thành)
294. `modules/hardware/detect.nix` — auto-detect GPU, PCI bus IDs
295. `pkgs/bamos-detect-hardware.sh` — script quét hardware (lspci)
296. First-boot GPU detection: chạy `sudo bamos-detect-hardware`
297. Tự động sinh bus IDs + NVIDIA stable driver 595.84
298. GPU driver chỉ load khi phát hiện có GPU tương ứng
299. `services.xserver.videoDrivers` fix — kích hoạt hardware.video.nvidia module
300. **tuned** (Red Hat) thay PPD: dynamic_tuning, PPD bridge, profile theo edition
301. **Case study LG Gram**: i5-10210U, GTX 1650, NVMe — CPU governor powersave, ~4W GPU idle
302. **Battery optimization**: ASPM powersupersave, WiFi power save, runtime PM, swap 16GB
303. **Hardware tools**: pciutils, usbutils, dmidecode, inxi, mesa-demos trong mọi edition

### Phase 8 — Btrfs Backup & Restore + Auto Update ✅ (Hoàn thành)
306. **btrbk engine**: snapshot + send/receive cho @home + @data
307. **Retention policy**: 24 hourly, 7 daily, 4 weekly, 3 monthly
308. **Auto snapshot**: systemd timer hourly, pruning tự động
309. **`bam backup [-s] [-h] [-d]`**: backup chọn lọc — system config, home config, data
    - Default: `-s -h` (system + home)
    - Home chỉ backup `.config`, `.local/share`, `.bashrc`, `.profile`, `.ssh`
    - Exclude: `.cache`, `.npm`, `.cargo`, flatpak, Steam, caches
    - Lưu vào `/data/backups/{system,home,data}/`
310. **`bam restore [-s] [-h] [-d]`**: restore chọn lọc theo flags
311. **`bam clean [--keep N]`**: dọn Nix generations + Btrfs snapshots cũ
312. **Auto-upgrade engine** — check-only, interactive apply:
    - **Systemd timer** (`bamos-auto-update`): chạy 1 phút sau boot, lặp lại mỗi 12h
    - **Check-only**: Timer chỉ check VERSION + CHANGELOG từ GitHub và tạo `/etc/bamos/update_change`, KHÔNG tự rebuild
    - **Desktop notification**: Khi có version mới, gửi notify kèm tóm tắt changelog, hướng dẫn chạy `sudo bam update`
    - **`/etc/bamos/update_change`**: File text chứa changelog của tất cả version mới (từ local→remote)
    - **`bamos.update.autoUpgrade`** option (default: true)

313. **`bam update`** — Quy trình update tương tác:
    ```
    sudo bam update         # Check → show changelog → confirm → apply
    sudo bam update --check # Chỉ check, không apply
    ```
    - Bước 1: Đọc `/etc/bamos/version` (local) vs `github.com/quocnho/bamos/main/VERSION` (remote)
    - Bước 2: Nếu có version mới, fetch `CHANGELOG.md` từ GitHub, extract tất cả sections từ local→remote
    - Bước 3: Hiển thị danh sách thay đổi (nếu đã có `/etc/bamos/update_change` từ auto-update timer thì dùng file đó)
    - Bước 4: Hỏi xác nhận: "Apply update vX.Y.Z → vA.B.C now? [Y/n]"
    - Bước 5: Nếu đồng ý:
      a. Ghi `/etc/bamos/update_change` (audit trail)
      b. Download `VERSION` + `CHANGELOG.md` từ GitHub → ghi đè `/etc/bamos/`
      c. `nix flake update --flake /etc/nixos`
      d. `nixos-rebuild switch --flake /etc/nixos`
      e. `nix-collect-garbage --delete-older-than 5d`
      f. `nixos-rebuild boot` (regen boot menu)
    - `bam update` yêu cầu `sudo` (root) để ghi vào `/etc/bamos/` và `/etc/nixos/`

314. **`bam rollback [gen]`**: rollback generation (interactive nếu không có đối số)

315. **`bam changelog`**:
    - Kiểm tra `/etc/bamos/update_change` trước (nếu có update pending từ timer)
    - Nếu không, fetch `CHANGELOG.md` từ GitHub và hiển thị thay đổi từ local→remote

316. **Permission model**:
    - `/etc/bamos/version` — root:root, 644 (environment.etc, chỉ ghi được bởi root)
    - `/etc/bamos/CHANGELOG.md` — root:root, 644
    - `/etc/bamos/update_change` — root:root, 644 (tạo bởi systemd service hoặc `sudo bam update`)
    - `bam update` yêu cầu `sudo` — chạy với quyền root, có thể ghi đè tất cả

317. **VERSION + CHANGELOG lifecycle**:
    - **Source of truth**: `VERSION` + `CHANGELOG.md` trong git repo `github.com/quocnho/bamos`
    - **Build time**: Nix build copies `VERSION` + `CHANGELOG.md` vào `/etc/bamos/` qua `environment.etc`
    - **Runtime**: `sudo bam update` download file mới từ GitHub → ghi đè `/etc/bamos/`
    - **Sau reboot**: File trong `/etc/bamos/` giữ nguyên (không bị reset) vì là file config, không phải store symlink
      (Lưu ý: `/etc/bamos/` được quản lý bởi `environment.etc` nên sẽ bị ghi đè khi `nixos-rebuild switch`. Nếu muốn giữ version mới,
      cần rebuild với flake mới nhất, sau đó file trong `/etc/bamos/` sẽ được cập nhật từ source mới.)

318. **ISO live**: tạo sẵn `/data/backups/{system,home,data}/` cho mọi edition

### Phase 9 — Unified Calamares Installer ✅ (Hoàn thành — Sprint 6-7)
330. ✅ **Unified ISO**: 3 ISOs (GNOME/KDE/COSMIC) thay 12 cũ — edition + machine type chọn khi install
331. ✅ **Edition selector**: packagechooser với 4 edition (Standard/Developers/Gaming/Studio)
332. ✅ **Machine type selector**: Laptop/Desktop/Server — auto power profile
333. ✅ **Ổ D integration**: /data mount + custom drive icon + Nautilus bookmark
334. ✅ **Calamares branding**: Logo, Nord colors, fonts, slideshow (GLF-OS inspired)
335. ✅ **iso-cfg template → /etc/nixos/**:
    - `iso-cfg/flake.nix` — inputs: nixpkgs + github:quocnho/bamos
    - `iso-cfg/configuration.nix` — hostname, locale, user
    - `iso-cfg/customized.nix` — edition + machine type (Calamares điền)
    - `iso-cfg/customConfig/default.nix` — user customization (không bị ghi đè)
336. ✅ **Custom Python module**: bamos-config (trong `modules/boot/patches/calamares/bamos-config/main.py`)
337. ✅ **Override package pattern (GLF-OS)**:
    - `overrideAttrs` + `postInstall` trên `calamares-nixos-extensions`
    - `nixpkgs.overlays` trong nixosSystem (module `calamares-overlay.nix`)
    - Config files ở `modules/boot/patches/calamares/`
    - Wayland autostart: `sudo --preserve-env=WAYLAND_DISPLAY,...`
    - DPI fix: `QT_QPA_PLATFORM=wayland;xcb` + `mkForce`apply selections (`modules/boot/calamares.nix`)
337. **Hardware detect tích hợp**: lspci + dmidecode chạy trong Calamares
338. **Update workflow**: `sudo bam update` — flake update → rebuild → gc → regen boot
339. **Auto update timer**: systemd timer 12h — flake update + boot + gc (`modules/core/update.nix`)
340. **Drive icon SVG → PNG**: cần fix với librsvg (`modules/boot/calamares.nix` L26-47)

### Phase 10 — BamOS CLI Nâng cao 🟡 (Đang phát triển)
348. ✅ `bam switch` — Rebuild system alias (switch/test/boot/flake)
349. ✅ `bam iso [variant]` — Build ISO với auto-clean, --vm option
350. ✅ `bam vm` — QEMU VM runner với disk/RAM/UEFI options
351. ✅ `bam usb <device>` — Write ISO to USB
352. 🟡 `bam snapshot create|list|restore|share` — Portable system snapshot
353. 🟡 `bam share export|iso` — Export config / build custom ISO

### Phase 11 — BamOS Portal (Tương lai)
354. Factory Reset Desktop (1-click restore UI)
355. Driver Manager (NVIDIA, AMD, Intel auto-install)
356. System Info Dashboard
357. Edition Switcher (chuyển edition không cần cài lại)
358. GUI Snapshot Manager (kết hợp với CLI)

### Phase 10 — Hoàn thiện ma trận (Tương lai)
354. Unified ISO cho tất cả DE
355. Testing: QEMU VM + CI/CD tự động test ISO
356. Binary cache đầy đủ — build lần đầu, cache mãi mãi

### Phase 11 — Community (Tương lai)
359. Home Manager integration cho user-level config
360. Custom packages (`pkgs/`) cho phần mềm Việt
361. Overlays (`overlays/`) tùy biến nixpkgs
362. Documentation website + Hướng dẫn tiếng Việt
363. Community modules registry
364. Cộng đồng 500+ người dùng

---

## Success Metrics

1. **ISO có thể boot và cài đặt thành công** trên ít nhất 3 cấu hình phần cứng khác nhau (Intel laptop, AMD desktop, VM).
2. **Gõ tiếng Việt hoạt động ngay sau cài đặt** — không cần bất kỳ bước cấu hình thủ công nào (tất cả editions).
3. **Rollback hoạt động**: Người dùng có thể khôi phục về generation cũ trong < 2 phút.
4. **Flatpak apps hoạt động** với Software Center, cài được ứng dụng phổ biến.
5. **12 ISO variants** được build tự động qua CI/CD, mỗi ISO < 3GB.
6. **Thời gian cài đặt < 30 phút** từ ISO boot đến desktop sẵn sàng sử dụng.
7. **Gaming Edition**: Steam + Proton chạy ít nhất 10 game phổ biến out-of-the-box.
8. **Studio Edition**: Blender, Kdenlive, Ardour hoạt động với low-latency audio.
9. **Tài liệu tiếng Việt đầy đủ** cho người dùng phổ thông (không yêu cầu kiến thức Linux).
10. **100% reproducible**: Mọi bản cài đặt từ cùng một git commit đều giống hệt nhau.

---

## Constraints

### Technical Constraints
- **NixOS learning curve**: Đội ngũ phát triển cần thành thạo Nix language và NixOS module system.
- **flake-parts ecosystem**: Framework còn mới, documentation chưa phong phú như NixOS core.
- **ISO size**: Cần tối ưu để mỗi ISO < 3GB, bao gồm DE + edition packages.
- **COSMIC maturity**: Cosmic DE đang phát triển nhanh nhưng chưa stable như GNOME/KDE. Cần theo dõi sát upstream.
- **Hardware compatibility testing**: Cần CI/CD pipeline test tự động trên đa dạng phần cứng ảo hóa cho cả 12 variants.
- **Build time**: 12 variants × 3 architectures = 36 builds. Cần Cachix cache + distributed builds.

### Resource Constraints
- **Đội ngũ**: Hiện tại là dự án cá nhân (1 developer). Cần mở rộng cộng đồng contributors.
- **Thời gian**: Phát triển ngoài giờ, không có deadline cứng từ tổ chức.
- **Hạ tầng**: Cần Cachix binary cache + GitHub Actions runners đủ mạnh cho build ISO.

### Market Constraints
- **Người dùng Linux Việt Nam**: Thị trường còn nhỏ, cần chiến lược tiếp cận phù hợp.
- **Cạnh tranh**: Ubuntu, Linux Mint đã có cộng đồng lớn. Bazzite OS, Nobara cho gaming.
- **Nhận thức về NixOS**: Còn rất thấp tại Việt Nam. Cần content marketing + hướng dẫn.

---

## Inspirations / References

- [NixOS](https://nixos.org/) — Nền tảng declarative, reproducible OS
- [flake-parts](https://flake.parts/) — Modular flake framework bởi Hercules CI
- [Misterio77/nix-starter-configs](https://github.com/Misterio77/nix-starter-configs) — Cấu trúc tham khảo
- [nixos-generators](https://github.com/nix-community/nixos-generators) — Build ISO từ NixOS config
- [Disko](https://github.com/nix-community/disko) — Declarative disk partitioning
- [Bazzite OS](https://github.com/ublue-os/bazzite) — Gaming-focused immutable OS (Fedora Atomic)
- [GLF-OS](https://framagit.org/gaming-linux-fr/glf-os/glf-os) — Community gaming distro (Pháp). Nguồn cho:
  - Pattern `overrideAttrs` + `postInstall` trên `calamares-nixos-extensions`
  - `nixpkgs.overlays` TRONG nixosSystem (không phải perSystem)
  - Wayland autostart: `sudo --preserve-env=WAYLAND_DISPLAY,...`
  - Custom settings.conf + module configs qua patches/
- [Nobara Project](https://nobara.ml/) — Gaming-optimized Fedora by GloriousEggroll
- [devenv](https://devenv.sh/) — Fast, declarative, reproducible dev environments
- [Podman](https://podman.io/) — Daemonless container engine (Docker alternative)
- [GameScope](https://github.com/ValveSoftware/gamescope) — Micro-compositor for gaming
- [MangoHud](https://github.com/flightlessmango/MangoHud) — Vulkan/OpenGL overlay
- [Distrobox](https://github.com/89luca89/distrobox) — Any Linux distro in terminal
- [Fcitx5](https://fcitx-im.org/) — Universal input method framework
- [Bamboo Engine](https://github.com/BambooEngine/bamboo-engine) — Vietnamese input engine
- [COSMIC DE](https://github.com/pop-os/cosmic-epoch) — Rust-based DE by System76
- [RakuOS](https://gitlab.com/rakuos/images/rakuos-base) — Fedora Atomic image (thèmes OrigamiPaper, Nord palette)
- [RakuOS GNOME](https://gitlab.com/rakuos/images/rakuos-gnome) — GNOME config: Inter font, WhiteSur icons, Bibata cursor, GSconnect extensions
- [Nordic GTK Theme](https://github.com/EliverLara/Nordic) — Nord color scheme (nguồn cảm hứng cho OrigamiPaper)
- [Papirus Icon Theme](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme) — Material-style icons

---

## Project Structure (Restructured)

### Tổ chức theo chuẩn flake-parts + NixOS module system

```
bamos/
├── flake.nix                           # Entry point — flake-parts mkFlake
├── flake.lock                          # Pinned dependency versions
├── README.md                           # Project overview (Vietnamese + English)
├── ARCHITECH.md                        # Architecture design document
├── idea.md                             # This file — project vision & requirements
│
├── lib/                                # 🧠 Thư viện & hàm dùng chung
│   ├── default.nix                     #   Top-level aggregator
│   ├── mkEdition.nix                   #   Hàm tạo edition từ profile + DE
│   ├── mkHost.nix                      #   Hàm tạo nixosConfiguration từ host
│   ├── mkISO.nix                       #   Hàm build ISO từ profile
│   └── utils.nix                       #   Helper functions
│
├── modules/                            # 📦 NixOS modules (khai báo options + implementations)
│   ├── default.nix                     #   Aggregator — imports core + hardware + desktop
│   │
│   ├── core/                           # 🧱 Lõi hệ thống (bắt buộc, mọi edition)
│   │   ├── system.nix                  #     Boot, kernel, hostname, nix settings, cachix, overlays
│   │   ├── locale.nix                  #     VN locale, timezone, default language
│   │   ├── audio.nix                   #     PipeWire (ALSA + PulseAudio + 32-bit)
│   │   ├── input-method.nix            #     Fcitx5 + Bamboo (Telex, VNI, VIQR)
│   │   ├── optimization.nix            #     Tắt dịch vụ không cần, tắt documentation
│   │   ├── packages.nix                #     Common packages cho mọi edition + hardware tools
│   │   ├── fonts.nix                   #     Fonts (Noto, Fira, JetBrains Mono)
│   │   ├── user.nix                    #     Default user (bamos) với bamos.user.* options
│   │   ├── third-party.nix            #     AppImage, Flatpak, FHS, Podman, Wine, codecs, fonts
│   │   ├── version.nix                #     /etc/os-release + /etc/lsb-release branding (BamOS)
│   │   ├── update.nix                 #     Auto-upgrade engine: systemd timer + notify + GC
│   │   └── welcome.nix                #     Welcome banner: system info + bam CLI guide trên terminal
│   │
│   ├── boot/                           # 🚀 Boot & Disk Partitioning
│   │   ├── disko-btrfs.nix             #     Disko declarative partitioning (Ổ C — Ổ D)
│   │   ├── calamares.nix              #     Calamares installer GUI (edition, machine type, iso-cfg)
│   │   ├── calamares-overlay.nix      #     Override calamares-nixos-extensions (GLF-OS pattern)
│   │   └── patches/calamares/         #     Config files: settings.conf, partition.conf, mount.conf, packagechooser-*
│   │
│   ├── desktop/                        # 🖥 Desktop Environments
│   │   ├── gnome.nix                   #     GNOME + GDM + dconf (window buttons)
│   │   ├── kde.nix                     #     KDE Plasma + SDDM + kwinrc
│   │   ├── cosmic.nix                  #     COSMIC + cosmic-greeter
│   │   └── software-center.nix         #     DE-aware Software Center (GNOME/KDE Discover) + Flatpak + AppImage
│   │
│   ├── hardware/                       # 🔧 Phần cứng
│   │   ├── bluetooth.nix               #     Bluetooth + auto power-on
│   │   ├── network.nix                 #     NetworkManager (Wi-Fi + Ethernet)
│   │   ├── nvidia.nix                  #     NVIDIA GPU: driver, Optimus/PRIME, CUDA, PowerMgt
│   │   ├── detect.nix                  #     Auto-detect hardware: GPU, PCI bus IDs, kernel modules
│   │   ├── power-management.nix        #     tuned (Red Hat) + kernel tuning + battery optimization
│   │   └── backup.nix                  #     Btrfs backup engine (btrbk) + auto snapshot timer
│   │
│   ├── editions/                       # 📦 Edition-specific features
│   │   ├── default.nix                 #     Aggregator
│   │   ├── developers.nix              #     Developers: devenv, podman, dev tools
│   │   ├── gaming.nix                  #     Gaming: XanMod kernel, Steam, Lutris, GameScope, MangoHud
│   │   └── studio.nix                  #     Studio: low-latency audio, creative apps
│   │
│   ├── apps/                           # 📱 Ứng dụng theo edition
│   │   └── standard.nix                #     Standard apps: Firefox, Chromium, VLC, MPV
│   │
│   └── theming/                        # 🎨 Giao diện & thương hiệu
│       ├── bamos-branding.nix          #     BamOS branding (wallpaper, logo, plymouth)
│       ├── gtk-theme.nix               #     GTK/icon/cursor theme + font config (Nordic/WhiteSur/Bibata)
│       ├── gnome-theme.nix             #     GNOME Shell theme: dconf, fonts, extensions, GTK settings
│       ├── kde-theme.nix               #     KDE Plasma theme: kvantum, kwinrc
│       └── cosmic-theme.nix            #     COSMIC DE theme: dconf, settings
    ├── gtk-theme.nix              #     GTK/icon/cursor theme + font config (Nordic/WhiteSur/Bibata)
    ├── gnome-theme.nix            #     GNOME Shell theme: dconf, GTK settings, extensions, fonts
    ├── kde-theme.nix              #     KDE Plasma theme: kvantum, kwinrc, kdeglobals, Aurorae
    └── cosmic-theme.nix          #     COSMIC DE theme: dconf, GTK settings, fonts
│
├── profiles/                           # 🎯 Profiles = Tổ hợp modules cho từng edition+DE
│   ├── default.nix                     #   Aggregator
│   ├── gnome-standard.nix              #   GNOME + Standard apps
│   ├── gnome-developers.nix            #   GNOME + Developers apps + devenv + podman
│   ├── gnome-gaming.nix                #   GNOME + Gaming stack
│   ├── gnome-studio.nix                #   GNOME + Studio apps + low-latency
│   ├── kde-standard.nix                #   KDE + Standard apps
│   ├── kde-developers.nix              #   KDE + Developers apps + devenv + podman
│   ├── kde-gaming.nix                  #   KDE + Gaming stack
│   ├── kde-studio.nix                  #   KDE + Studio apps + low-latency
│   ├── cosmic-standard.nix             #   COSMIC + Standard apps
│   ├── cosmic-developers.nix           #   COSMIC + Developers apps + devenv + podman
│   ├── cosmic-gaming.nix               #   COSMIC + Gaming stack
│   └── cosmic-studio.nix               #   COSMIC + Studio apps + low-latency
│
├── hosts/                              # 🖥️ Hosts = Phần cứng cụ thể + tham số
│   ├── default.nix                     #   Aggregator (imports lg + iso + vm)
│   ├── lg/                             #   🖥️ Developer laptop (LG Gram, i5-10210U, GTX 1650)
│   │   ├── default.nix                 #     flake-parts module → nixosConfigurations.lg
│   │   ├── configuration.nix           #     Host-specific config: NVIDIA, power, VM, dev tools
│   │   └── hardware-configuration.nix  #     Auto-generated hardware scan
│   ├── iso/                            #   💿 ISO builder — 12 variants
│   │   ├── default.nix                 #     flake-parts module → mkISOVariant (12 configs)
│   │   ├── configuration.nix           #     GNOME ISO config
│   │   ├── configuration-kde.nix       #     KDE ISO config
│   │   ├── configuration-studio.nix    #     Studio ISO config
│   │   └── customConfig/               #     User customization slot
│   │       └── default.nix
│   └── vm/                             #   🖳️ QEMU test VM
│       └── default.nix
│
├── pkgs/                               # 📦 Custom Nix packages
│   ├── default.nix                     #   ✅ Aggregator (bamos-branding)
│   ├── bam-cli/                        #   BamOS CLI (bam) — FHS env + bam.sh wrapper
│   │   └── default.nix                 #   Commands: install, switch, iso, vm, usb,
│   │                                   #            snapshot, share, backup, update,...
│   ├── bamos-branding/                 #   BamOS branding: logos, wallpapers, GNOME XML
│   │   └── default.nix
│   └── bamos-detect-hardware.sh        #   Hardware detection script (GPU, PCI bus IDs)
│
├── overlays/                           # 🔄 Nixpkgs overlays
│   └── default.nix                     #   ✅ Aggregator
│   # kernel.nix, mesa.nix, wine.nix, packages.nix → ⏳ Sprint 2+
│   # kernel.nix, mesa.nix, wine.nix, packages.nix → ⏳ Sprint 2+
│
├── iso-cfg/                            # 💿 ISO user template (copy vào /etc/nixos/ khi cài)
│   ├── flake.nix                       #   Flake: inputs (nixpkgs + bamos) + outputs
│   ├── configuration.nix               #   Base config (hostname, locale, user)
│   ├── customized.nix                  #   Edition + Machine type config
│   ├── README.md                       #   Hướng dẫn sử dụng cho người dùng cuối
│   ├── modules/                        #   User modules (mở rộng)
│   │   └── default.nix                #     Aggregator
│   ├── customConfig/                   #   🛡️ User customizations (không bị ghi đè!)
│   │   └── default.nix
│   ├── home.nix                        #   Home-manager template (optional)
│   └── secrets/                        #   🔐 Encrypted secrets (optional)
│       └── README.md
│
├── assets/                             # 🎨 Static assets
│   ├── wallpapers/
│   ├── logo/
│   ├── icons/
│   └── plymouth/
│
├── VERSION                             # Phiên bản BamOS hiện tại (2.0.0)
├── CHANGELOG.md                        # Lịch sử thay đổi (Keep a Changelog)
├── ARCHITECH.md                        # Architecture design document
│
├── docs/                               # 📖 Documentation
│   ├── README.md                       #   Navigation hub
│   ├── installation.md                 #   Hướng dẫn cài đặt
│   ├── editions.md                     #   Các phiên bản
│   ├── contributing.md                 #   Hướng dẫn đóng góp
│   ├── technical/                      #   📘 Tài liệu kỹ thuật (Markdown)
│   │   ├── architecture.md            #     Kiến trúc tổng thể
│   │   ├── modules.md                 #     Modules & options
│   │   ├── iso-build.md               #     Build ISO & cache
│   │   ├── kernel.md                  #     Multi-kernel strategy
│   │   └── dev-workstation.md         #     hosts/lg configuration
│   └── user/                           #   🌐 Website người dùng (Bazzite-style, 32+ trang)
│       ├── index.html                  #     🏠 Home — tính năng, tải, links
│       ├── faq.html                    #     ❓ Câu hỏi thường gặp
│       ├── css/
│       │   ├── fonts.css               #     Roboto + Roboto Mono (Google Fonts)
│       │   ├── bazzite-main.min.css    #     Material for MkDocs theme (từ docs.bazzite.gg)
│       │   └── bamos-overrides.css     #     Brand colors, custom components
│       ├── js/
│       │   └── include.js             #     Search, sidebar highlight, hamburger
│       ├── assets/images/
│       │   └── placeholder.svg        #     Placeholder cho screenshots/videos
│       ├── installation/
│       │   ├── guide.html              #     📖 Hướng dẫn cài đặt
│       │   ├── post-install.html       #     🔧 Sau cài đặt
│       │   ├── troubleshoot.html       #     🛠 Xử lý sự cố
│       │   ├── legacy.html             #     💻 Máy cũ (Legacy BIOS)
│       │   └── alternative.html        #     🔄 Phương pháp khác
│       ├── general/
│       │   ├── editions.html           #     📋 12 phiên bản
│       │   ├── comparison.html         #     🔄 So sánh distro
│       │   ├── tweaks.html             #     ⚙ Tinh chỉnh
│       │   ├── vpn.html                #     🔒 VPN
│       │   └── uninstalling.html       #     🗑 Gỡ cài đặt
│       ├── gaming/
│       │   ├── introduction.html       #     🎮 Giới thiệu
│       │   ├── launchers.html          #     🚀 Game launchers
│       │   └── launch-options.html     #     ⚙ Tùy chọn khởi chạy
│       ├── software/
│       │   ├── center.html             #     🖥 Software Center
│       │   ├── flatpak.html            #     📂 Flatpak
│       │   ├── containers.html         #     🐳 Containers
│       │   ├── distrobox.html          #     📦 Distrobox
│       │   ├── appimage.html           #     🗜 AppImage & Gear Lever
│       │   ├── waydroid.html           #     📱 Waydroid (Android)
│       │   └── updates.html            #     🔄 Cập nhật & Rollback
│       ├── advanced/
│       │   ├── cli.html                #     ⌨ CLI & Nix commands
│       │   ├── custom-image.html       #     🛠 Tự build ISO
│       │   └── reset-password.html     #     🔑 Reset mật khẩu
│       ├── community/
│       │   ├── contributing.html       #     🤝 Đóng góp
│       │   ├── bugs.html               #     🐛 Báo lỗi
│       │   └── links.html              #     🔗 Liên kết
│       └── resources/
│           ├── specs.html              #     🔧 Thông số kỹ thuật
│           ├── kernel.html             #     🧠 Kernel strategy
│           ├── cache.html              #     💾 Binary cache
│           └── download.html           #     ⬇ Tải ISO
├── plan/                               # 📋 AI-generated project planning
├── .github/workflows/                  # 🚀 CI/CD pipelines
└── .zed/settings.json                  # Editor config
```

### Giải thích kiến trúc thư mục

| Thư mục | Vai trò | Nội dung |
|---------|---------|----------|
| **`lib/`** | Thư viện & hàm | Các hàm `mkEdition`, `mkHost`, `mkISO` — logic tái sử dụng cao. Không chứa config. |
| **`modules/`** | Khai báo & triển khai | `options.*` + `config.*` cho từng thành phần. Được thiết kế để tổ hợp linh hoạt qua `profiles/`. |
| **`profiles/`** | Tổ hợp modules | Chọn và kết hợp các modules cho từng edition+DE. KHÔNG khai báo options mới — chỉ `imports`. |
| **`hosts/`** | Phần cứng cụ thể | File `hardware-configuration.nix`, tham số riêng (hostname, IP, drives). `imports` profile phù hợp. |
| **`pkgs/`** | Custom packages | Mỗi package trong thư mục riêng với `default.nix`. Gọi qua `callPackage`. |
| **`overlays/`** | Ghi đè nixpkgs | Override package versions, build flags, patches. Áp dụng toàn cục. |

### Nguyên tắc tổ chức

1. **`modules/`** = **KHAI BÁO** (declare): Định nghĩa `options` và `config`. Có thể bật/tắt qua `enable`.
2. **`profiles/`** = **TỔ HỢP** (compose): `imports` các modules cần thiết, set tham số. KHÔNG khai báo options mới.
3. **`hosts/`** = **PHẦN CỨNG** (hardware): File scan tự động + tham số cụ thể. `imports` một profile.
4. **`lib/`** = **HÀM** (functions): Helper functions, builders. Không có side effects.
5. **`pkgs/`** = **PACKAGES** (packages): Mỗi package một thư mục, dùng `callPackage`.
6. **`overlays/`** = **GHI ĐÈ** (overrides): Thay đổi package từ nixpkgs.

### Ví dụ: Profile GNOME Gaming

```nix
# profiles/gnome-gaming.nix
{ inputs, ... }: {
  imports = [
    ../modules/core              # system, locale, audio, input-method, optimization
    ../modules/desktop/gnome     # GNOME + GDM
    ../modules/theming/bamos-branding
    ../modules/theming/gnome-theme
    ../modules/theming/fonts
    ../modules/apps/flatpak
    ../modules/apps/gaming        # Steam, Lutris, Heroic, MangoHud, GameScope
    ../modules/apps/communication # Discord
    ../modules/editions/gaming    # Gaming-specific kernel params, GameScope session
  ];

  # Edition-specific settings
  bamos.edition = "gaming";
  services.flatpak.enable = true;
  programs.steam.enable = true;
  programs.gamemode.enable = true;
}
```

### Host Developer Laptop — hosts/lg (Developer Workstation)

> Máy LG Gram là **developer workstation** chính để xây dựng, tùy biến, phát triển và đóng gói BamOS.
> Cấu hình hosts/lg là blueprint cho mọi developer machine muốn đóng góp vào dự án.

#### 1. Môi trường Phát Triển NixOS

```bash
# Build VM — test thay đổi NixOS trong VM trước khi apply vào máy thật
nix build-vm .#lg          # Build QEMU VM từ cấu hình lg hiện tại
nix build-vm .#iso-gnome-standard  # Test ISO trong VM

# Build thường
nixos-rebuild switch --flake .#lg     # Apply vào LG
nixos-rebuild test --flake .#lg       # Test without reboot
```

**Packages cho Nix development (trong devShell):**
```
nil, nixd              → LSP servers
nixpkgs-fmt            → Formatter
deadnix                → Dead code detection
statix                 → Linter
nix-output-monitor     → Build progress
cachix                 → Binary cache push
```

#### 2. Secret Management — Agenix
- **Secret Management — ragenix**

[ragenix](https://github.com/yorickvP/ragenix) (Rust rewrite của agenix) là tool quản lý secrets cho NixOS:
- Mã hóa file `.age` bằng SSH keys (Ed25519/RSA)
- Decrypt tự động khi build NixOS configuration qua `age.secrets`
- Secrets được commit vào git an toàn (đã mã hóa)
- **Yêu cầu**: `age.identityPaths` phải trỏ tới SSH host keys (ví dụ: `/etc/ssh/ssh_host_ed25519_key`)
- **Yêu cầu**: `services.openssh.enable = true` để sinh SSH host keys (cần cho decrypt)

```nix
# Cấu trúc secrets
secrets/
├── secrets.nix           # Định nghĩa secrets (public key mapping)
├── github-token.age      # GitHub PAT (encrypted)
├── cachix-token.age      # Cachix auth token (encrypted)
├── ssh-keys.age          # SSH private keys (encrypted)
└── wireguard-config.age  # VPN config (encrypted)

# Cách dùng
agenix -e secrets/github-token.age  # Edit/mã hóa
agenix -d secrets/github-token.age  # Decrypt (build tự động)
```

**Setup:**
```nix
# flake.nix — inputs
inputs.agenix.url = "github:ryantm/agenix";

# modules/secrets.nix — NixOS module
{ config, pkgs, ... }: {
  age.secrets.github-token = {
    file = ../secrets/github-token.age;
  };
}
```

#### 3. Home Manager

[Home-manager](https://github.com/nix-community/home-manager) quản lý user-level config:
- Dotfiles (bash/zsh, git, tmux)
- Editor config (VSCode, vim, zed)
- GNOME extensions & settings
- Shell aliases, environment variables

```nix
# profiles/developers.nix — shared dev profile
{ pkgs, ... }: {
  home-manager.users.quocnho = {
    programs.git = {
      enable = true;
      userName = "Nguyen Quoc Nho";
      userEmail = "quocnho@gmail.com";
      signing.key = "ssh-ed25519 ...";
    };
    programs.zsh = {
      enable = true;
      ohMyZsh.enable = true;
    };
    programs.direnv.enable = true;
  };
};
```

#### 4. GNOME Extensions

```nix
# Cấu hình GNOME extensions cho developer
{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    # Essential extensions
    gnomeExtensions.dash-to-dock        # Dock gọn gàng
    gnomeExtensions.vitals              # Hệ thống monitor
    gnomeExtensions.gsconnect           # Kết nối Android
    gnomeExtensions.user-themes         # Custom themes
    gnomeExtensions.clipboard-indicator # Clipboard history
    gnomeExtensions.caffeine            # Tắt screen saver
    gnomeExtensions.gtile              # Window tiling

    # Dev tools
    gnomeExtensions.gnome-shell-screenshot
  ];
};
```

#### 5. Developer Tools

```nix
{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    # Version control
    gh                       # GitHub CLI
    git-crypt                # Git encryption

    # Secret management
    age                      # Age encryption (agenix base)
      ssh-to-age               # Convert SSH → age key

    # Container & VM
    qemu                     # QEMU/KVM cho test VM
    distrobox                # Container-based distro
    podman                   # Docker alternative
    docker                   # Docker (nếu cần)

    # Nix development
    nil nixd nix-tree nix-output-monitor
    nixpkgs-fmt deadnix statix
    cachix

    # Editors
    zed-editor                # Primary editor
    vscode                    # Backup editor
    vim                       # Terminal editor

    # Terminal
    kitty                     # GPU-accelerated terminal
    tmux                      # Terminal multiplexer
    zsh                       # Default shell

    # System tools
    btop htop                 # Process monitor
    iotop                     # Disk I/O
    iperf3                    # Network benchmark
    wireguard-tools           # VPN

    # AI tools
    llm                      # Ollama CLI
  ];
};
```

#### 6. Cấu trúc hosts/lg mới

```
hosts/lg/
├── default.nix              # flake-parts module → nixosConfigurations.lg
├── configuration.nix        # Host-specific config
├── hardware-configuration.nix  # Hardware scan
├── secrets/                 # Encrypted secrets (agenix)
│   ├── secrets.nix          #   Public key mapping
│   └── *.age                #   Encrypted secret files
└── home.nix                 # Home-manager user config
```

#### 7. Tổng kết

| Thành phần | Công cụ | Trạng thái |
|-----------|---------|-----------|
| Nix dev | nil, nixd, nixpkgs-fmt, deadnix, statix | ✅ Có trong devShell |
| Build VM | qemu, nix build-vm | 🟡 Cần cấu hình |
| Secrets | agenix + age | ⏳ Sprint 3 |
| User config | home-manager | ⏳ Sprint 3 |
| GNOME extensions | dash-to-dock, vitals, etc. | ⏳ Sprint 3 |
| GitHub CLI | gh | ⏳ Sprint 3 |

---

## Development Workflow

### Daily Development
```bash
nix develop          # Enter dev shell (nil, nixd, nixpkgs-fmt, deadnix, statix, cachix)
nix fmt              # Format all .nix files
nix flake check --all-systems  # Validate flake (12 ISOs + hosts/lg)
nix flake show       # Show all outputs

# Kiểm tra code
deadnix --fail .     # Dead code check
statix check .       # Static analysis
```

### Hardware Detection Workflow
```bash
# Trước mỗi lần rebuild, quét hardware để lấy GPU bus IDs:
sudo bamos-detect-hardware

# Output:
#   🔍 BamOS Hardware Detection
#   - Detecting GPUs...
#     -> NVIDIA: GA106M [GeForce GTX 1650 Mobile]
#     -> Intel: TigerLake GT2 [Iris Xe Graphics]
#   Config: /etc/bamos/gpu-config.nix
#
#   Bus IDs:
#     nvidiaBusId = "PCI:2:0:0"
#     intelBusId = "PCI:0:2:0"

# Sau đó rebuild với bus IDs chính xác:
sudo nixos-rebuild switch --flake .#lg
```

### Testing on Developer Machine
```bash
# Từ git repo local
sudo nixos-rebuild switch --flake .#lg     # Apply config to current machine
sudo nixos-rebuild test --flake .#lg       # Test without making boot entry

# Từ GitHub trực tiếp (không cần git pull)
sudo nixos-rebuild switch --flake github:quocnho/bamos#lg --refresh

# Hoặc dùng alias trong home.nix:
# nrs = "sudo nixos-rebuild switch --flake /etc/nixos";
```

### Build ISO Variants
```bash
# Build ISO (lưu vào Nix store)
nix build .#iso-gnome-standard --no-link

# Build + copy ISO ra thư mục iso/ để dùng
nix build .#iso-gnome-standard -o result
ISO_FILE=$(readlink -f result/iso/*.iso)
cp "$ISO_FILE" iso/
ls -lh iso/

# Hoặc 1 lệnh:
nix build .#iso-gnome-standard --no-link --print-out-paths | xargs -I{} cp {}/iso/*.iso iso/

# Test ISO in QEMU
qemu-system-x86_64 -enable-kvm -m 4G -cdrom iso/*.iso
```

> **Convention:** Tất cả ISO file được copy ra thư mục `iso/` trong project root.
> Thư mục `iso/` được git ignore — không commit file ISO lớn.

### Binary Cache & Distribution
```bash
# CI tự động push cache (GitHub Actions — .github/workflows/ci.yml)
# - cachix/cachix-action@v15 tự động push build artifacts
# - Không cần làm gì thêm

# Local push (developer machine)
nix build .#iso-gnome-standard --no-link --print-out-paths | xargs -I{} cachix push bamos {}

# Hoặc dùng convenience app:
nix run .#push-cachix

# One-command: build → switch → push cache
nix run .#update

# Upload ISO lên GitHub Releases (CI tự động khi push tag v*)
# ISO file: result/iso/*.iso
# Upload qua CI: gh release create v0.1.0 iso/*.iso

# Deploy lên Cloudflare R2 (CD tự động qua release-cd.yml)
# R2 bucket structure:
#   bamos/releases/v4.0.0.YYYYMMDD.N/
#   ├── bamos-gnome-*.iso
#   ├── bamos-gnome-*.iso.sha256
#   ├── bamos-kde-*.iso
#   ├── bamos-cosmic-*.iso
#   └── release-metadata.json

# GitHub Secrets cần setup:
# - CACHIX_AUTH_TOKEN: Auth token cho Cachix
# - R2_ACCESS_KEY_ID: Cloudflare R2 Access Key
# - R2_SECRET_ACCESS_KEY: Cloudflare R2 Secret Key
# - R2_ENDPOINT: R2 endpoint URL
# - COSIGN_PRIVATE_KEY: (Optional) Cosign key để ký ISO
# - COSIGN_PASSWORD: (Optional) Password cho Cosign key
```

### Cachix Setup (one-time)
```bash
# 1. Cài Cachix
nix profile install nixpkgs#cachix

# 2. Đăng nhập (lấy token từ https://app.cachix.org/personal-auth-tokens)
cachix authtoken <your-auth-token>

# 3. Tạo cache (chạy 1 lần) — output sẽ hiển thị public key
cachix create bamos
# Ghi lại public key (dạng: bamos.cachix.org-1:...)
#    Settings → Secrets and variables → Actions → New repository secret
#    Name: CACHIX_AUTH_TOKEN
#    Value: <your-auth-token>

# 6. Người dùng thêm cache:
cachix use bamos
# Hoặc thêm vào configuration.nix:
# nix.settings.substituters = [ "https://bamos.cachix.org" ];
# nix.settings.trusted-public-keys = [ "bamos.cachix.org-1:<key>" ];
```

### AI-Assisted Development
- Use `/init` to bootstrap the project from this `idea.md`
- Use `/plan` for sprint planning (5-day AI sprints)
- Use `/dev` for implementing NixOS modules
- Use `/devops` for CI/CD pipeline management
- Use `/git` for version control workflow

---

## License

MIT License — Open source, built for the Vietnamese community.
