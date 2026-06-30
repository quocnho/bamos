# BamOS — Vietnamese Linux Distribution

## Vision

BamOS is a cloud-native, atomic Linux distribution built specifically for Vietnamese users. It combines the professional CI/CD infrastructure and build methodology of [Universal Blue](https://universal-blue.org/) with the lightweight, beautifully-designed user experience philosophy of [RakuOS](https://gitlab.com/rakuos) to create a stable, optimized, and culturally tailored operating system.

Built on Fedora Atomic Desktops 44 using OCI containers and bootable containers (bootc), BamOS delivers an immutable, self-updating system with zero maintenance overhead — the reliability of a Chromebook with the flexibility of a traditional Linux desktop.

## Name & Branding

| Element | Value |
|---------|-------|
| **Name** | BamOS |
| **Meaning** | "Bam" represents the sacred bamboo tree (cây tre), symbolizing Vietnamese spirit: resilience, simplicity, adaptability |
| **Logo** | Stylized bamboo node combined with a lightning bolt — power + stability + Vietnamese identity |
| **Color Scheme** | Bamboo Green `#4CAF50` · Rice Field Gold `#FFC107` · Deep Earth Brown `#5D4037` |
| **Slogan** | "Ổn định. Nhẹ nhàng. Việt Nam." (Stable. Lightweight. Vietnamese.) |
| **GitHub Org** | `https://github.com/quocnho` |
| **License** | Apache 2.0 |

**Branding Integration**

| Surface | Implementation |
|---------|---------------|
| **ISO/USB Live** | `branding/logo-bamos.svg` + `branding/iso-grub.cfg` + `branding/live-os-release` — bilingual VN/EN GRUB menu with 4 entries |
| **OS Release** | `branding/os-release` — `NAME=BamOS`, `PRETTY_NAME="BamOS 44"`; `branding/system-release` → `/etc/system-release` |
| **Plymouth Boot Splash** | Custom Plymouth theme (`branding/plymouth/bamos.plymouth` + `bamos.script`) — bamboo animation |
| **Fastfetch** | Branded preset at `/usr/share/fastfetch/presets/bamos/bamos-fastfetch.jsonc` — bamboo logo + system info |
| **GRUB Menu** | `branding/iso-grub.cfg` — "Khởi động BamOS (Live)" / "BamOS Live (Basic Video)" / "Cài đặt BamOS vào ổ cứng" |
| **GNOME Backgrounds** | `/usr/share/gnome-background-properties/bamos.xml` — generated at build, bamboo green theme |
| **Secure Boot** | `branding/bamos-mok.cer` — MOK certificate enrolled at first boot via `bamos-enroll-secureboot.service` |

**GitHub Repositories**

| Repo | URL | Description |
|------|-----|-------------|
| **bamos** | [quocnho/bamos](https://github.com/quocnho/bamos) | Main OS image, build scripts, system files, docs (108 files, 56 dirs) |
| **bamportal** | [quocnho/bamportal](https://github.com/quocnho/bamportal) | GTK4 Portal app — forked from ublue-os/yafti-gtk |
| **bamstore** | [quocnho/bamstore](https://github.com/quocnho/bamstore) | GNOME App Store — forked from bazaar-org/bazaar |

## Development Environment

BamOS is developed on a real-world Vietnamese user's laptop, confirming the target hardware and software stack in practice. The development machine doubles as a continuous integration testbed — every feature is verified on actual hardware before release.

| Aspect | Value | BamOS Relevance |
|--------|-------|----------------|
| **Laptop Model** | LG Gram 17U70N-R.AAS7U1 | Lightweight (1.35kg) — typical for Vietnamese mobile workers |
| **CPU** | Intel i5-10210U (Comet Lake, 4C/8T) | CachyOS scx_bpfland scheduler + ananicy-cpp profile active |
| **RAM** | 16GB DDR4 | Target minimum for Vietnamese office + browser + Zalo + WPS Office workflow |
| **GPU 1 (iGPU)** | Intel UHD Graphics (CML GT2) | Wayland + GNOME 50 — daily driver, 100% stable |
| **GPU 2 (dGPU)** | NVIDIA GeForce GTX **1650 (Turing)** | **nvidia-open** driver auto-detect confirmed working; GTX 1650 is the most popular entry-level GPU in Vietnam |
| **Disk** | 512GB NVMe SSD | Enough for dual-boot or single BamOS deployment |
| **Display** | 1920x1080 17" | Fractional scaling (125%) tested with Wayland + GTK4 |
| **Host OS** | RakuOS Linux 44 | Fedora Atomic base (same family as BamOS), CachyOS kernel 7.0.12 |
| **Desktop** | GNOME 50 on Wayland | BamOS targets GNOME 48+; this confirms Wayland + NVIDIA Turing + Vietnamese input work upstream |
| **IDE** | [Zed Editor](https://zed.dev) | Modern Rust-based editor; all BamOS code written in Zed |
| **Package Manager** | RakuOS overlayFS | Development mirrors the atomic upgrade + layered package model BamOS will use |
| **Shell** | Fish | Confirms fish shell alias patterns work correctly on Fedora Atomic |

**Dogfooding**: All BamOS build scripts, CLI commands, and systemd services are tested on this laptop before release. The presence of NVIDIA GTX 1650 (Turing) + Intel UHD dual-GPU confirms the NVIDIA auto-detect logic is correct for the target hardware demographic.

## Design Philosophy

### Inspired by Universal Blue (Build & Infrastructure)

- **OCI-native**: Images built as OCI containers, pushed to `ghcr.io`, distributed via CDN
- **Atomic updates**: rpm-ostree/bootc with automatic background updates and built-in rollback
- **CI/CD**: GitHub Actions with daily scheduled builds, PR validation, matrix builds, cosign signing
- **Akmods ecosystem**: Pre-built kernel modules via uBlue akmods cache — stable NVIDIA, xone, xpadneo
- **Community governance**: Open source, Apache 2.0, contributor-friendly structure
- **Bazzite build patterns adopted**: `finalize.sh` (passwd/group migration), `install-kmods.sh` (controller drivers), `image-info.sh` (OCI metadata), `bamos-mok.cer` (Secure Boot)

### Inspired by RakuOS (User Experience & Optimization)

- **Desktop**: GNOME with RakuOS-inspired dark theme (WhiteSur icons, Bibata cursors, Inter fonts, 5 hand-picked extensions)
- **CLI ecosystem**: `bamos` command dispatcher + shell aliases (bash/fish/zsh) + fastfetch branding
- **Lightweight**: Minimal pre-installed packages, clean system state, maintenance timers
- **Smart package UX**: Sudoers passwordless for flatpak/bootc, `bamos install/remove/update/upgrade`
- **CachyOS tuning**: scx_bpfland scheduler, ananicy-cpp, BBR TCP, IO scheduler per device — on stable uBlue kernel

### RakuOS Scripts Integration

BamOS has integrated and adapted RakuOS's shell scripts ecosystem ([rakuos-scripts](https://gitlab.com/rakuos/images/rakuos-scripts)) to enhance system automation, Flatpak management, Secure Boot, AI/gaming setup, and user experience. All adapted scripts are prefixed `bamos-` and follow BamOS conventions.

#### Flatpak Integration

- **`bamos-flatpak-wrapper-gen`** — Adapted from `flatpak-wrapper-gen`. Generates CLI wrapper scripts in `/usr/local/bin/flatpak/` that symlink Flatpak application binaries, allowing Flatpak apps (Firefox, StreamController, etc.) to be invoked from the terminal as if natively installed.
- **`bamos-flatpak-watcher`** — Systemd path watcher that monitors Flatpak installation directories. Automatically regenerates CLI wrappers on `flatpak install`/`uninstall`/`update` events, ensuring wrappers stay in sync with the installed app set. Also runs per-app fix scripts (`flatpak-fixes/`).
- **`flatpak-repair.service` + `flatpak-repair.timer`** — Weekly systemd timer that verifies and repairs Flatpak installations, removes stale wrappers, and ensures system consistency.
- **Flatpak fixes** (`flatpak-fixes/`) — Adapted fixes for Firefox (Wayland+VAAPI, Vietnamese font access) and StreamController (udev rules, USB permissions).

#### Secure Boot

- **`bamos-enroll-secureboot.service`** — Adapted from `enroll-secureboot-key`. One-shot systemd service that runs on first boot to enroll a Machine Owner Key (MOK) for Secure Boot. Allows loading unsigned kernel modules (NVIDIA, xone, v4l2loopback) on Secure Boot-enabled systems without disabling Secure Boot entirely. Bilingual VN/EN user prompts.

#### AI & Gaming Setup

- **`setup-ollama`** — Adapted from RakuOS `setup-ollama`. Installs Ollama for local AI model inference with GPU acceleration (NVIDIA CUDA / AMD ROCm). Sets up systemd service for Ollama server with popular models.
- **`setup-lsfg-vk`** — Adapted from RakuOS `setup-lsfg-vk`. Configures Lossless Scaling Frame Generation (LSFG) via Vulkan layer for gaming.

#### System & User Setup

- **`bamos-system-setup`** — Enhanced with RakuOS patterns: Flatpak seeding (pre-install apps), fish shell migration, GTK theme synchronization, first-run marker, flatpak-command-overrides.conf generation, home directory creation for UID 1000.
- **`bamos-user-setup`** — Enhanced with RakuOS user patterns: automatic theme sync (dark/light toggle), system themes → user home rsync, GTK4/GTK3 settings watchers, Flatpak permission overrides, fish shell migration, starship prompt, live environment KWallet disable.
- **`bamos-updater`** — Enhanced with RakuOS notification pattern: uses `notify-send` with reboot action button when system updates require a restart, pending notification file for offline users.

#### Shell Configuration

- **`/etc/fish/conf.d/bamos-aliases.fish`** — Fish shell aliases: `bai`/`bar`/`bau` (bamos commands), `fpi`/`fpu`/`fpr` (Flatpak), `srr`/`srp` (systemd), Git shortcuts, ls/lsd, BamOS welcome message, starship+ zoxide integration.

### Bazzite Build Patterns Adopted

| Pattern | Source | Implementation | Purpose |
|---------|--------|---------------|---------|
| **finalize** | Bazzite `build_files/finalize` | `build_files/finalize.sh` | Migrate /etc/passwd→/usr/lib/passwd, clean lock files, temp files, RPM db rebuild — OCI stateless production clean |
| **install-kmods** | Bazzite `build_files/install-kmods` | `build_files/install-kmods.sh` | xone (Xbox USB), xpadneo (Xbox BT), broadcom-wl (Broadcom WiFi), v4l2loopback (virtual camera) |
| **image-info** | Bazzite `build_files/image-info` | `build_files/image-info.sh` | `/usr/share/bamos/image-info.json` with version, commit, build date, OCI labels |
| **MOK cert** | Bazzite `ubmok101.cer`/`ubmok102.cer` | `branding/bamos-mok.cer` | Inline Secure Boot certificate, enrolled at first boot |

### BamOS Portal & BamOS Store

#### BamOS Portal (adapted from Bazzite Portal / yafti-gtk)

A GTK4 Python application providing a tabbed first-boot setup wizard. Uses Bazzite-style YAML format (`screens` with `id`/`title`/`description`/`default`/`status_script`/`options`). Supports "Run All Defaults" for automatic first-boot configuration.

| Tab | Source | Content |
|-----|--------|---------|
| 🏠 **Chào mừng / Welcome** | Bazzite Welcome pattern | BamOS docs, BamStore launch, Portal autostart toggle |
| 🇻🇳 **Tiếng Việt & Văn phòng** | BamOS custom | ibus-bamboo, fonts VN/MS/VNI, WPS Office, Zalo, USB Token, printers (8 actions) |
| 🖥️ **GNOME Desktop** | Bazzite + RakuOS | WhiteSur/Bibata theme, Dash to Dock, Blur my Shell, AppIndicator, Caffeine, Dark Mode, Night Light (5 actions) |
| 🖥️ **KDE Plasma Desktop** | Aurora KDE pattern | Win11 taskbar, Bamboo Green accent, Tela Circle icons, Inter/Maple fonts, Win11 shortcuts (5 actions) |
| ⚙️ **Hệ thống / System** | Bazzite Manage pattern | NVIDIA, Xbox controllers, CachyOS tuning, Secure Boot (4 actions) |
| 🎮 **Giải trí / Gaming** | Bazzite Install pattern | Steam/Lutris, KVM/QEMU, Ollama AI (3 actions) |

**Configuration**: `/usr/share/bamos/portal/portal.yml` (341 lines, 30+ actions)
**Desktop entry**: `/usr/share/applications/io.bamos.Portal.desktop` ("BamOS Portal / Cổng BamOS")
**Metainfo**: `/usr/share/metainfo/io.bamos.Portal.metainfo.xml`
**Python app**: `/usr/libexec/bamos/bamos-portal.py` (365 lines, GTK4 + Adwaita)

#### BamOS Store (adapted from Bazaar)

Modern GNOME app store for discovering and installing applications. Two installation paths:
- **Flatpak** (recommended): `flatpak install flathub io.github.bazaar_org.bazaar`
- **Source build**: `build_files/install-store.sh` — meson/ninja from `/opt/bamos/bamstore`

## Technical Architecture

### Base Image

```
FROM ghcr.io/ublue-os/silverblue-main:latest    (GNOME variant)
FROM ghcr.io/ublue-os/kinoite-main:latest        (KDE variant)
```

### Image Variants (4 total)

| Variant | Stage | Base | Desktop | Input Method | GPU |
|---------|-------|------|--------|-------------|-----|
| `bamos-gnome` | `bamos-gnome` | Silverblue | GNOME + RakuOS theme | **ibus-unikey** | Intel/AMD |
| `bamos-kde` | `bamos-kde` | Kinoite | KDE Plasma Win11 | **fcitx5-unikey** | Intel/AMD |
| `bamos-gnome-nvidia` | `bamos-nvidia-gnome` | ← bamos-gnome | GNOME + RakuOS theme | ibus-unikey (inherited) | NVIDIA (RPM Fusion) |
| `bamos-kde-nvidia` | `bamos-nvidia-kde` | ← bamos-kde | KDE Plasma Win11 | fcitx5-unikey (inherited) | NVIDIA (RPM Fusion) |

### Containerfile Stages (5 stages)

```
  bamos-base              ← Silverblue/Kinoite (NO input method)
  ├── bamos-gnome         ← + ibus-unikey (GNOME)
  ├── bamos-kde           ← + fcitx5-unikey (KDE)
  ├── bamos-nvidia-gnome  ← + NVIDIA + ibus-unikey (GNOME NVIDIA)
  └── bamos-nvidia-kde    ← + NVIDIA + fcitx5-unikey (KDE NVIDIA)
```

### NVIDIA Architecture (RPM Fusion)

**Strategy**: Install NVIDIA drivers directly from RPM Fusion. No akmods cache dependency (Fedora 44 akmods-nvidia not yet published by uBlue).

```
Containerfile:
  bamos-nvidia-gnome (FROM bamos-gnome)
  bamos-nvidia-kde   (FROM bamos-kde)
    → rpm-ostree install kmod-nvidia-open + nvidia-settings + nvidia-container-toolkit
    → First boot: bamos-nvidia-firstboot.service auto-detects GPU generation
    → RTX 20+ (Turing+) → keep nvidia-open
    → GTX 900/10 (Maxwell/Pascal) → rpm-ostree switch to nvidia-closed
    → GTX 600/700 (Kepler) → Legacy 470xx (EOL, best-effort)
```

| GPU Generation | Products | Driver | Source |
|---------------|----------|--------|--------|
| Blackwell | RTX 50 series | nvidia-open | RPM Fusion |
| Ada Lovelace | RTX 40 series | nvidia-open | RPM Fusion |
| Ampere | RTX 30 series | nvidia-open | RPM Fusion |
| Turing | RTX 20 / GTX 16 | nvidia-open | RPM Fusion |
| Volta/Pascal | GTX 10 / Titan V | nvidia (closed) | RPM Fusion |
| Maxwell | GTX 900/700 | nvidia (closed) | RPM Fusion |
| Kepler | GTX 600/700 | Legacy 470xx | RPM Fusion (EOL) |

### Kernel & Performance (CachyOS-inspired, uBlue-stable)

**Strategy**: Keep uBlue kernel (stable akmods) + apply CachyOS userspace tuning

| Component | Source | Function |
|-----------|--------|----------|
| `scx_bpfland` | CachyOS | BPF CPU scheduler — balanced interactive |
| `ananicy-cpp` | CachyOS | Auto-nice foreground processes |
| `bore-sysctl` | CachyOS | BORE scheduler sysctl knobs |
| `cachyos-settings` | CachyOS | Kernel cmdline + udev rules |
| BBR TCP | Kernel | Network congestion control |
| MGLRU | Kernel | Multi-gen LRU page reclaim |
| IO Scheduler | udev rules | bfq (HDD) / kyber (SSD) / none (NVMe) |
| `preempt=full` | Kernel param | Desktop responsiveness |

**Why not replace kernel with CachyOS?** uBlue akmods (NVIDIA, xone, v4l2loopback) are pre-built for Fedora kernel — replacing kernel would require DKMS rebuild on every update, breaking the stable CI/CD model.

### Directory Structure (108 files, 57 directories)

```
bamos/
├── 📄 README.md                     ← Lightweight entry, links to docs/
├── 📄 LICENSE                       ← Apache 2.0
├── 📄 Containerfile                 ← Multi-stage OCI image build (3 stages)
├── 📄 Justfile                      ← Dev commands (build, validate, shell, portal, store)
├── 📄 cosign.pub                    ← Sigstore image signing key
│
├── 📁 docs/                         ← ALL documentation
│   ├── idea.md                      # This file — vision, architecture, roadmap
│   ├── CONTRIBUTING.md              # Contribution guide (VN + EN)
│   ├── CHANGELOG.md                 # Release history
│   ├── CODE_OF_CONDUCT.md
│   ├── SECURITY.md
│   ├── NVIDIA-COMPATIBILITY.md      # GPU generation matrix
│   └── CACHYOS-INTEGRATION.md       # Kernel tuning architecture
│
├── 📁 build_files/                   ← 16 build & setup scripts
│   ├── branding.sh                  # Apply branding (logo, Plymouth, GRUB, wallpapers, fastfetch)
│   ├── finalize.sh                  # Bazzite-style OCI cleanup (passwd/group migration, lock files)
│   ├── gnome-build.sh               # GNOME DE + extensions + WhiteSur icons + themes
│   ├── image-info.sh                # Bazzite-style OCI metadata JSON generation
│   ├── install-kmods.sh             # Bazzite-style kmods (xone, xpadneo, broadcom-wl, v4l2loopback)
│   ├── install-portal.sh            # Install BamOS Portal (Python deps + desktop registration)
│   ├── install-store.sh             # Install BamOS Store (Flatpak or source build)
│   ├── install-wps.sh               # WPS Office installer
│   ├── kernel-optimize.sh           # CachyOS performance tuning
│   ├── setup-fonts.sh               # Font cache + GSsettings
│   ├── setup-fonts-ms.sh            # Download MS Core Fonts
│   ├── setup-fonts-proprietary.sh   # Import VNI/VnTime from Windows
│   ├── setup-printing.sh            # Printer drivers + CUPS
│   ├── setup-token.sh               # USB Token PKCS#11
│   ├── setup-vn-input.sh            # ibus-bamboo Wayland config
│   └── setup-zalo.sh                # Zalo (Wine + web fallback)
│
├── 📁 system_files/
│   ├── shared/                      # Shared across ALL variants
│   │   ├── usr/bin/bamos            # Main CLI dispatcher (150+ lines, 20 commands)
│   │   ├── usr/libexec/bamos/       # 20+ management scripts (CLI + setups)
│   │   │   ├── bamos-{install,remove,update,upgrade,list,search,reset}
│   │   │   ├── bamos-{system-setup,user-setup,updater,cache-clean}
│   │   │   ├── bamos-{flatpak-watcher,flatpak-wrapper-gen,enroll-secureboot}
│   │   │   ├── bamos-setup-{sudo,uutils}
│   │   │   ├── setup-{gaming,virtualization,ollama,lsfg-vk}
│   │   │   ├── bamos-portal.py      # GTK4 Portal app (365 lines)
│   │   │   └── internal/flatpak-fixes/ # Firefox + StreamController fixes
│   │   ├── usr/lib/systemd/system/  # 14 systemd units (13 system + 1 user)
│   │   ├── usr/lib/systemd/user/bamos-user.service
│   │   ├── usr/lib/udev/rules.d/    # IO scheduler (bfq/kyber/none)
│   │   ├── usr/lib/sysctl.d/        # Kernel tuning (swappiness, BBR, MGLRU, fs)
│   │   ├── usr/share/bamos/         # Packages lists, portal config
│   │   │   └── portal/portal.yml    # 6-tab setup wizard (341 lines)
│   │   ├── usr/share/applications/io.bamos.Portal.desktop
│   │   ├── usr/share/metainfo/io.bamos.Portal.metainfo.xml
│   │   ├── usr/share/fastfetch/presets/bamos/
│   │   └── etc/                     # Shell aliases (bash/fish/zsh), sudoers
│   ├── kde/                         # KDE Plasma Win11 config
│   ├── nvidia/                      # NVIDIA driver + firstboot auto-detect
│   ├── fonts/                       # Fontconfig VN + README.md
│   ├── office/wps-config/          # WPS Office VN config
│   └── webapps/                     # Vietnamese web apps (25+ shortcuts)
│
├── 📁 config/
│   └── recipe.yml                   # BlueBuild recipe (4 images, 11 module types)
│
├── 📁 branding/
│   ├── logo-bamos.svg               # Main logo (bamboo pattern)
│   ├── bamos-mok.cer                # Secure Boot MOK certificate
│   ├── os-release / system-release  # OS identity files
│   ├── iso-grub.cfg                 # Bilingual GRUB for ISO/USB
│   ├── live-os-release              # Live environment identity
│   ├── icons/                       # Application icons (Portal, Store)
│   └── plymouth/                    # Boot splash theme
│
├── 📁 .github/
│   ├── workflows/build.yml           # CI/CD: matrix build 4 variants + IMAGE_COMMIT/DATE/REF
│   ├── workflows/validate.yml        # PR validation
│   ├── PULL_REQUEST_TEMPLATE.md      # PR template
│   └── ISSUE_TEMPLATE/               # Bug report + Feature request
│
└── 📁 ~/Projects/ (external repos)
    ├── bamportal/                    # https://github.com/quocnho/bamportal
    └── bamstore/                     # https://github.com/quocnho/bamstore
```

## Core Features

### 1. Vietnamese Language Support

- **Input Method**: GNOME → **ibus-unikey** / KDE → **fcitx5-unikey** — fully Wayland-compatible, Telex + VNI methods
- **Configuration**: `Super+Space` toggles EN/VI, pre-configured at build time
- **Spell Check**: hunspell-vi dictionary
- **Locale**: vi_VN.UTF-8 default with English fallback
- **ibus environment**: GTK_IM_MODULE, QT_IM_MODULE, XMODIFIERS set globally
- **fcitx5 environment**: fcitx5 autostart via Plasma config + `/etc/fcitx5/profile` with EN/VI

### 2. Office Suite (WPS Office)

- WPS Office installed and pre-configured at build time
- Font substitution map: VNI-Times→Noto Serif, .VnTime→Noto Serif, etc.
- Default save format `.docx`, auto-save enabled
- Cloud sync disabled by default (privacy-first)
- Vietnamese document compatibility out of the box

### 3. Web Apps Integration (25+ shortcuts)

Browser-based `.desktop` shortcuts for essential Vietnamese services:

**Banking**: Vietcombank, BIDV, VietinBank, Agribank, MB Bank, Techcombank, ACB, Sacombank, VPBank, TPBank

**Government**: National Public Service Portal (dichvucong.gov.vn), Electronic Tax (thuedientu.gdt.gov.vn), Social Insurance (baohiemxahoi.gov.vn), Customs, Government Portal

**Daily**: Zalo Web, VNExpress, Tuổi Trẻ, Thanh Niên, Weather (nchmf.gov.vn), Grab

**E-Commerce**: Shopee, Lazada, Tiki

### 4. Font Strategy (Three-Tier + Symbol/Dingbat)

**Tier 1 — Open-Source (RPM, in image)**: Noto Sans (full Latin + VN diacritics), Inter (UI), Maple Mono NF (terminal), Liberation Sans/Serif/Mono (MS replacements), Carlito, Caladea, DejaVu Sans/Serif/Mono, OpenSymbol

**Tier 2 — Metric-Compatible Replacements**:
| MS Font | Replacement | Notes |
|---------|------------|-------|
| Times New Roman | Liberation Serif | Same metrics |
| Arial | Liberation Sans | Same metrics |
| Courier New | Liberation Mono | Same metrics |
| Calibri | Carlito | Same metrics |

| Wingdings 1/2/3 | DejaVu Sans | Dingbat/symbol glyphs (for WPS Office) |
| Webdings | DejaVu Sans | Web symbol glyphs |
| MT Extra | DejaVu Sans | MathType/equation symbols |

**DPI Consistency**:
- `etc/profile.d/bamos-dpi.sh` — sets `GDK_DPI_SCALE=1`, `QT_FONT_DPI=96`, `XWAYLAND_FORCE_DPI=96`
- `etc/X11/Xresources/bamos-dpi` — `Xft.dpi: 96`, `Xft.hintstyle: hintslight`
- Fontconfig `<edit name="dpi"><double>96</double></edit>` — prevents "System DPI asymmetric" warnings

**Tier 3 — Proprietary (user-installed)**:
- `bamos setup-fonts-proprietary` — Auto-detect Windows partition, import VNI/VnTime/MS fonts
- `bamos setup-fonts-ms` — Download Microsoft Core Fonts (cabextract)
- Fontconfig aliases ensure fallback to Noto when proprietary fonts unavailable

### 5. Digital Signature & USB Token Support

- **Middleware**: opensc, pcsc-lite, pcsc-lite-ccid, pcsc-tools, openssl-pkcs11
- **Tokens**: Viettel-CA, BKAV-CA, FPT-CA, VNPT-CA, Gemalto/Thales
- **Browser PKCS#11**: Pre-configured environment variables for Firefox/Chromium
- **Use cases**: Electronic tax declaration, social insurance, customs

### 6. Printer Driver Support

- **CUPS**: Pre-installed and enabled, network discovery on
- **Driver bundles**: hplip, gutenprint, foomatic-db
- **Supported brands**: HP, Canon, Epson, Brother, Samsung/Xerox
- **lpadmin group**: User auto-added for printer management

### 7. Zalo Installation

Primary messaging platform in Vietnam. Uses **first-boot installer** pattern (not build-time Wine):
- **First-boot script**: `/usr/libexec/bamos/bamos-install-zalo.sh` — installs Wine + downloads + installs Zalo on first click
- **Desktop entry**: `zalo.desktop` → triggers first-boot installer
- **Web fallback**: `zalo-web.desktop` → opens chat.zalo.me in browser

### 8. Desktop Environment Customization

#### GNOME Variant (RakuOS-inspired)

| Element | Value |
|---------|-------|
| Theme | OrigamiPaper (dark) / OrigamiPaperLight (light) |
| Icons | WhiteSur-dark / WhiteSur-light |
| Cursors | Bibata-Modern-Classic |
| UI Font | Inter 10 |
| Mono Font | Maple Mono 10 |
| Shell Extensions | **5 extensions**: AppIndicator, Dash to Dock, Blur my Shell, Caffeine, No Overview (boot) |
| Dock | Bottom, auto-hide, 48px icons — macOS/RakuOS style |
| Window buttons | close, minimize, maximize (macOS-style left) |
| gnome-extensions-app | ✅ Kept for user customization |
| gnome-tweaks | ✅ Pre-installed |

#### KDE Variant (Windows 11-like, Aurora-inspired)

- Centered taskbar with icon-only task manager (Win11 layout)
- Bamboo Green accent color (`#4CAF50`) throughout
- Tela Circle icon theme (green variant, optional install)
- Fonts: Inter 10 (UI), Maple Mono 10 (terminal)
- Windows 11 shortcuts: Meta+E (Dolphin), Meta+R (KRunner), Meta+L (Lock)
- Breeze application style, bibata cursors
- Pre-solved icon/font/color issues through image-level config (Aurora pattern)

### 9. bamos CLI (RakuOS-inspired)

```bash
# Package Management
bamos install <pkg...>         # Layer packages via rpm-ostree
bamos remove <pkg...>          # Remove layered packages
bamos update                   # Update all (rpm-ostree + flatpak + bootc)
bamos upgrade                  # Upgrade base image (bootc)
bamos list                     # List layered packages
bamos search <query>           # Search packages
bamos reset-overlay            # Reset all layered packages

# Setup Wizards
bamos setup-gaming             # Steam, Lutris, Mangohud
bamos setup-virt               # KVM/QEMU, virt-manager
bamos setup-nvidia             # Configure GPU drivers
bamos setup-ollama             # Local AI with Ollama (GPU-accelerated)
bamos setup-lsfg-vk            # Lossless Scaling Frame Gen for gaming
bamos setup-store              # Install BamOS Store (Flatpak/source)
bamos setup-fonts-proprietary  # Import VNI/VnTime from Windows
bamos setup-fonts-ms           # Download MS Core Fonts

# Applications
bamos portal                   # Launch BamOS Portal (GTK4 setup wizard)
bamos store                    # Launch BamOS Store (app store)

# Configuration
bamos setup-sudo <sudo-rs|sudo|doas|run0>  # Switch privilege escalation
bamos setup-uutils <uutils|gnu>            # Switch Rust/GNU coreutils
bamos shell <fish|bash|zsh>                # Set login shell

# NVIDIA Management
bamos switch-nvidia-legacy     # Switch to closed driver
bamos switch-nvidia-open       # Switch to open driver

# Security & Flatpak
bamos enroll-secureboot-key    # Enroll MOK for Secure Boot modules
bamos flatpak-wrapper-gen      # Regenerate Flatpak CLI wrappers
```

### 10. Systemd Maintenance Services (13 units)

**Timers & Scheduled Services**

| Timer | Frequency | Function |
|-------|-----------|----------|
| `bamos-cache-clean.timer` | Weekly | Clean dnf5/rpm-ostree cache |
| `flatpak-cleanup.timer` | Weekly | Remove unused Flatpak runtimes |
| `flatpak-repair.timer` | Weekly | Repair Flatpak installations, remove stale wrappers |
| `podman-prune.timer` | Weekly | Prune containers and images |
| `bamos-updater.timer` | Daily | Check for bootc system image updates |

**First-boot & One-shot Services**

| Service | Trigger | Function |
|---------|---------|----------|
| `bamos-setup.service` | First boot | Flatpak seeding, fish migration, theme sync, first-run marker |
| `bamos-user.service` | First login | Fish shell, starship, fastfetch, git config, GTK watchers |
| `bamos-enroll-secureboot.service` | First boot | Enroll MOK for Secure Boot kernel modules |
| `bamos-nvidia-firstboot.service` | NVIDIA variants | Detect GPU generation, auto-switch driver |
| `bamos-install-store.service` | First boot (+network) | Install BamOS Store (Bazaar) via Flatpak |

**Path-based Watchers**

| Unit | Trigger | Function |
|------|---------|----------|
| `bamos-flatpak-watcher.service` | Flatpak install/uninstall | Regenerate CLI wrappers + run per-app fixes |

### 11. BamOS Portal (GTK4 First-Boot Setup Wizard)

A GTK4 Python application (`bamos-portal.py`) providing a tabbed setup wizard with:
- **6 tabs**: Welcome, Vietnamese & Office, GNOME Desktop, KDE Desktop, System, Gaming
- **30+ configurable actions** with status indicators (pending/running/pass/fail)
- **"Run All Defaults"** — auto-execute all items marked `default: true`
- **Bazzite-style YAML format**: `id`/`title`/`description`/`default`/`status_script`/`options`
- **Radio button options** for multi-choice actions (e.g., enable/disable autostart)
- **Autostart on first login** via `~/.config/autostart/io.bamos.Portal.desktop`
- **Bilingual VN/EN** throughout

### 12. BamOS Store (GNOME App Store)

Modern app store for discovering and installing Flatpak applications:
- Based on **Bazaar** ([bazaar-org/bazaar](https://github.com/bazaar-org/bazaar)) — 1.5k+ stars
- Available via Flatpak: `flatpak install flathub io.github.bazaar_org.bazaar`
- Source build option via `build_files/install-store.sh` (meson/ninja)
- Launched from Portal tab or `bamos store` command

### 13. Hardware & Kernel Modules (Bazzite-inspired)

Kernel modules use **container-smart installation**:
- **During container build**: Only userspace/firmware packages installed (`xone-firmware`, `xone-kmod-common`, `v4l2loopback-utils`)
- **At first boot**: `/usr/libexec/bamos/bamos-install-kmods-firstboot.sh` installs kmod packages
- Reason: `akmodsbuild` requires a running kernel and doesn't work in containers

Kernel modules available via first-boot script:
- **xone** — Xbox One/Series X|S USB wired + wireless dongle
- **xpadneo** — Xbox One S/X Bluetooth controller
- **broadcom-wl** — Broadcom WiFi chipsets (BCM4311-BCM4321)
- **v4l2loopback** — Virtual video device (OBS Virtual Camera, DroidCam)

## Build & Release Strategy

### Package Management Philosophy

BamOS uses **rpm-ostree** for system package management, following Universal Blue's atomic model — not RakuOS's OverlayFS approach. System packages are layered onto the immutable base image via `rpm-ostree install` (or `bamos install`). This ensures:

- Clean separation between base image and user-installed packages
- Atomic rollback on failure (each layer is a new deployment)
- No direct modification of `/usr` — all changes are transactional
- Compatibility with uBlue's akmods ecosystem and bootc updates

### Build Pipeline (GitHub Actions)

1. **Scheduled**: Daily builds at 06:00 UTC+7 — all 4 variants
2. **Manual trigger**: Select specific variant via workflow_dispatch
3. **PR validation**: Validate Containerfile, YAML, shell scripts on PR
4. **Push to main**: Build and publish on merge
5. **Metadata**: IMAGE_COMMIT, IMAGE_BUILD_DATE, IMAGE_REF passed as build-args (Bazzite pattern)
6. **Cosign signing**: OCI image signing with sigstore/cosign
7. **ISO generation**: Automated via bootc-image-builder — uploads ISO as GitHub artifact (14-day retention)

### Release Channels

| Channel | Frequency | Stability |
|---------|-----------|-----------|
| `latest` | Daily | Latest, bleeding edge |
| `stable` | Weekly (tagged) | Tested for 1 week |
| `gts` | Monthly | Enterprise-grade |

### Versioning

```
YY.MM.DD-SHORTHASH   (e.g., 26.06.30-a1b2c3d)
```

Based on Universal Blue's scheme for easy tracking and rollback.

## Development Roadmap

### Phase 1: Foundation ✅
- Repository structure (BlueBuild pattern)
- Containerfile with multi-stage builds (3 stages)
- GitHub Actions CI/CD (4 variants, cosign signing)
- Branding (logo, color scheme, Plymouth, GRUB, OS release)
- GNOME config (RakuOS-inspired GSsettings)
- KDE config (Windows 11 layout, Aurora-inspired)
- bamos CLI + shell aliases (bash/fish/zsh) + systemd services

### Phase 2: Vietnamese Core ✅
- ibus-bamboo Wayland integration
- Font configuration (Noto + Inter + Maple Mono)
- Vietnamese locale defaults
- Web apps collection (25+ shortcuts)
- Zalo installation solution
- WPS Office pre-configuration
- USB Token/digital signature setup
- Printer driver bundle

### Phase 3: NVIDIA & Performance ✅
- Single NVIDIA variant with first-boot auto-detect
- CachyOS performance tuning (scx_bpfland, ananicy-cpp, BBR, IO scheduler)
- NVIDIA Container Toolkit
- Legacy GPU support (Maxwell/Pascal → auto-switch via rpm-ostree)
- nvidia-firstboot-setup systemd service
- NVIDIA detection helper in Justfile (`nvidia-detect-gen`)

### Phase 4: RakuOS Integration & Polish ✅ (Complete)
- ✅ RakuOS scripts integration (flatpak-wrapper-gen, enroll-secureboot, setup-ollama, setup-lsfg-vk)
- ✅ Flatpak fixes (Firefox Wayland/VAAPI, StreamController udev rules)
- ✅ bamos-system-setup enhanced (flatpak seeding, fish migration, theme sync, first-run marker)
- ✅ bamos-user-setup enhanced (theme sync, GTK watchers, flatpak overrides, shell migration)
- ✅ bamos-updater enhanced (notify-send with reboot action, pending notification)
- ✅ Fish shell aliases (`/etc/fish/conf.d/bamos-aliases.fish`)
- ✅ New systemd units (enroll-secureboot, flatpak-repair, flatpak-watcher)
- ✅ Branding integration complete (ISO/USB GRUB, OS release, Plymouth, wallpapers, fastfetch)
- ✅ Bazzite build patterns adopted (finalize.sh, install-kmods.sh, image-info.sh, bamos-mok.cer)
- ✅ BamOS Portal integrated (GTK4 Python app, 6 tabs, 30+ actions, Bazzite-style YAML)
- ✅ BamOS Store integrated (Bazaar fork, Flatpak + source build)
- ✅ GitHub repos pushed (bamos, bamportal, bamstore)
- ✅ ISO generation implemented (bootc-image-builder, GH Actions workflow)
- ✅ NVIDIA switched to RPM Fusion (no akmods cache dependency)
- ✅ Input method split: GNOME → ibus-unikey / KDE → fcitx5-unikey
- ✅ Containerfile restructured: 5 stages (base, gnome, kde, nvidia-gnome, nvidia-kde)
- ✅ Kernel modules: container-smart (userspace in build, kmods at first boot)
- ✅ Zalo: build-time Wine → first-boot installer
- ✅ DPI/font fixes: Symbol/Wingdings mappings + DPI consistency script
- ✅ Plymouth fixed: installed plugin-script, removed -R flag
- ✅ GNOME schema: removed deprecated `terminal` key (GNOME 48+)
- ✅ VM setup: KVM/libvirt automation scripts
- ✅ BamOS Store auto-install via systemd service (first boot + network)

### Phase 5: Community & Growth (In Progress)
- ✅ ISO generation via bootc-image-builder (implemented in CI/CD)
- ✅ VM testing infrastructure (KVM/libvirt scripts + Justfile targets)
- 🔄 Website / GitHub Pages (landing page)
- Community Discord/Zalo group
- Documentation translations (Vietnamese)
- RPM package repository for custom packages
- BamOS Store Flatpak publishing
- Beta testing with Vietnamese community

### Phase 6: Future Enhancements
- GUI Software Center rewrite (Rust GTK, inspired by rakuos-software)
- Welcome App rewrite (Rust GTK, inspired by rakuos-welcome)
- Installer GUI (Rust, inspired by rakuos-installer)
- Rust rewrite of CLI core (when team grows)
- ARM64/aarch64 support (Apple Silicon, Raspberry Pi 5)
- COSMIC desktop variant

## Optimization & Stability Guide

### Image Size Optimization

| Technique | Applied | Savings |
|-----------|:-------:|---------|
| Split input methods (GNOME→ibus, KDE→fcitx5) | ✅ | ~30 MB (no fcitx5 on GNOME images) |
| First-boot kmod installer (not in image) | ✅ | ~50 MB (no xone/xpadneo kmods in image) |
| First-boot Zalo installer (not in image) | ✅ | ~200 MB (no Wine in image) |
| Bazzite finalize (clean passwd/group/cache) | ✅ | ~20 MB (clean OCI layers) |
| `rpm-ostree cleanup -m` | ✅ | Variable (removes cached metadata) |

**Current image sizes**: GNOME ~3.5 GB / KDE ~3.8 GB / NVIDIA variants ~5.0 GB (includes NVIDIA drivers)

### Boot Time Optimization

| Technique | Applied | Impact |
|-----------|:-------:|--------|
| Plymouth theme (bamboo animation) | ✅ | Visual feedback during boot |
| No initramfs rebuild at build time | ✅ | Faster container build |
| systemd services parallelized | ✅ | Services run when needed |
| `bamos-system-setup.service` runs once | ✅ | First-boot only, then disabled |
| `bamos-install-store.service` runs once | ✅ | First-boot only, then disabled |

### Memory Optimization

| Technique | Applied | Impact |
|-----------|:-------:|--------|
| No fcitx5 on GNOME variants | ✅ | Saves ~50 MB RAM on GNOME |
| No ibus-unikey on KDE variants | ✅ | Saves ~30 MB RAM on KDE |
| CachyOS `ananicy-cpp` auto-nice | ✅ | Foreground gets priority |
| CachyOS `scx_bpfland` scheduler | ✅ | Interactive performance |
| MGLRU page reclaim | ✅ | Better memory management under pressure |
| swappiness=30 | ✅ | Prefer RAM over swap |
| `podman-prune.timer` weekly | ✅ | Clean up unused containers/images |
| `bamos-cache-clean.timer` weekly | ✅ | Clean dnf/rpm-ostree caches |

### Disk Optimization

| Technique | Applied | Impact |
|-----------|:-------:|--------|
| rpm-ostree atomic updates | ✅ | No duplicate package storage |
| One-disk model (no /var separate) | ✅ | Flexible partition |
| `flatpak-cleanup.timer` weekly | ✅ | Remove unused Flatpak runtimes |
| `flatpak-repair.timer` weekly | ✅ | Fix corrupted Flatpak installations |
| `bamos-cache-clean.timer` weekly | ✅ | Prune stale dnf cache |

### Network Optimization

| Technique | Applied | Impact |
|-----------|:-------:|--------|
| BBR TCP congestion control | ✅ | 2-10x throughput improvement |
| TCP Fast Open | ✅ | Faster connection setup |
| Increased network buffer sizes | ✅ | Better throughput on high-latency links |

### Stability Patterns

| Pattern | Applied | Why |
|---------|:-------:|-----|
| uBlue kernel (not kernel-cachyos) | ✅ | akmods pre-built for Fedora kernel — no DKMS rebuilds |
| RPM Fusion NVIDIA (not akmods cache) | ✅ | No dependency on uBlue's NVIDIA image build schedule |
| Container-smart kmod install | ✅ | kernel modules built at first boot, not in container |
| First-boot installer pattern | ✅ | Wine/Zalo/kmods installed on real hardware, not in container |
| Separated input method packages | ✅ | Each variant only has what it needs |
| DPI consistency across toolkits | ✅ | Prevents blurry fonts in XWayland apps (WPS Office) |
| Symbol/Wingdings font mappings | ✅ | Prevents "missing formula symbols" in WPS Office |
| Passwordless sudo for bamos/flatpak/bootc | ✅ | Smooth UX for atomic operations |

### Monitoring & Health

| Service | Frequency | Purpose |
|---------|-----------|---------|
| `bamos-updater.timer` | Daily | Check for bootc image updates |
| `flatpak-repair.timer` | Weekly | Verify Flatpak installations |
| `flatpak-cleanup.timer` | Weekly | Remove unused runtimes |
| `podman-prune.timer` | Weekly | Clean container storage |
| `bamos-cache-clean.timer` | Weekly | Clean dnf/rpm-ostree caches |

### Quick Commands

```bash
# Check system health
bamos info

# Check memory usage
free -h

# Check disk usage
bamos status

# Update everything
bamos update

# Upgrade system image
bamos upgrade

# Clean up
sudo bamos cache-clean
```

## Technical Decisions & Rationale

| Decision | Rationale |
|----------|-----------|
| Fedora Atomic 44 as base | Immutable, atomic updates, uBlue ecosystem, latest packages |
| uBlue kernel + CachyOS tuning | Stable akmods + desktop responsiveness without kernel fragility |
| **4 separate image stages** | Clean separation: base → GNOME/KDE → NVIDIA — each variant has only what it needs |
| **RPM Fusion NVIDIA (not akmods cache)** | No dependency on uBlue's akmods-nvidia image availability (Fedora 44 akmods not yet published) |
| WPS Office over LibreOffice | Better compatibility with Vietnamese .doc/.docx files |
| Zalo via Wine over web app | Most feature-complete for Vietnamese users |
| BlueBuild template | Proven CI/CD, community support, clean architecture |
| Apache 2.0 License | Permissive, compatible with uBlue ecosystem |
| English code, bilingual docs | Enables international contribution while serving Vietnamese users |
| WhiteSur + Bibata + Inter theme | Matches RakuOS's proven aesthetic; visually modern |
| Bash CLI (not Rust) | Simpler, more accessible for contributors; rpm-ostree is simpler than overlayFS |
| Bazzite finalize pattern | OCI stateless best practice — migrate passwd/group to /usr/lib |
| Bazzite install-kmods pattern | Community standard for xone, xpadneo, broadcom-wl, v4l2loopback |
| Bazzite image-info pattern | Full OCI metadata for CI/CD traceability |
| Bazzite Portal format (YAML) | Rich action model with id/title/default/status_script/options |
| Aurora KDE pattern | Numbered build scripts, Win11 layout, bamboo accent consistent with branding |

## Key Differentiators

### vs RakuOS

| Aspect | RakuOS | BamOS |
|--------|--------|-------|
| **Build system** | GitLab CI + Chunkah | GitHub Actions + OCI layers |
| **Kernel** | kernel-cachyos (DKMS) | uBlue kernel (akmods) + CachyOS tuning |
| **Base image** | `fedora-ostree-desktops/base-atomic` | `ublue-os/silverblue-main` |
| **Package model** | OverlayFS on /usr | rpm-ostree atomic layering |
| **NVIDIA** | Separate Containerfile.nvidia | Single variant, auto-detect all GPU gens |
| **ibus** | ibus-bamboo | **GNOME**: ibus-unikey / **KDE**: fcitx5-unikey |
| **WPS Office** | Not included | Pre-configured with VN fonts |
| **Zalo** | Not included | Wine + web fallback |
| **USB Token** | Not included | PKCS#11 + Vietnam CA pre-configured |
| **Fonts** | CJK fonts only | Full VN font stack (3-tier) + proprietary import scripts |
| **CLI** | Rust rewrites (rakuos-core) | Bash (simpler, rpm-ostree native) |
| **Portal** | None | GTK4 Bazzite-style 6-tab setup wizard |
| **Store** | rakuos-software (Rust GTK/COSMIC/QT) | Bazaar fork via Flatpak |
| **KDE theme** | Stock KDE | Win11 layout + Bamboo Green accent |

### vs Bazzite

| Aspect | Bazzite | BamOS |
|--------|---------|-------|
| **Target user** | Gamers (Steam Deck, HTPC) | Vietnamese office/government users |
| **Kernel** | bazzite-kernel (ogc) | uBlue kernel + CachyOS tuning |
| **HDR gaming** | ✅ | ❌ (not needed for target) |
| **Steam Deck** | ✅ Full support | ❌ |
| **WPS Office** | ❌ | ✅ Pre-configured with VN fonts |
| **VN Input** | ❌ | ✅ GNOME: ibus-unikey / KDE: fcitx5-unikey |
| **USB Token** | ❌ | ✅ PKCS#11 + CA Vietnam |
| **VN Web Apps** | ❌ | ✅ 25+ banking/gov shortcuts |
| **Zalo** | ❌ | ✅ Wine + web fallback |
| **Fonts** | CJK only | VN-optimized 3-tier strategy |
| **Printer drivers** | Generic | VN-common printer bundle |
| **NVIDIA variants** | 2 flavors (open + closed) | 1 variant (auto-detect), RPM Fusion |
| **CLI** | ujust commands | bamos CLI (20 commands) + shell aliases |
| **Portal** | Bazzite Portal (yafti-gtk) | BamOS Portal (forked + 6 VN tabs) |
| **Store** | Bazaar (build-in) | BamStore (Flatpak + auto-install at first boot) |
| **Kmods** | install-kmods script | install-kmods.sh (container-smart: kbuild→userspace, runtime→kmods) |
| **Containerfile** | Modular with C preprocessor | Multi-stage with ARGs |

### vs Bluefin/Aurora

| Aspect | Bluefin/Aurora | BamOS |
|--------|---------------|-------|
| **Target** | Developers | Vietnamese office/government |
| **Containers** | Toolbx, dev containers | Distrobox, podman |
| **Kubernetes** | k0s, kind | ❌ |
| **CachyOS tuning** | ❌ | ✅ scx, ananicy, BBR, IO scheduler |
| **VN-specific** | ❌ | Complete VN stack (input, fonts, office, token, zalo) |
| **NVIDIA auto-detect** | ❌ | ✅ Single variant all GPU generations |
| **KDE theme** | Stock KDE (Aurora) | Win11 layout + Bamboo Green (inspired by Aurora numbering) |
| **Portal** | None | 6-tab GTK4 Bazzite-style |
| **Store** | GNOME Software only | BamStore (Bazaar) |
| **Kernel modules** | Standard uBlue | + xone, xpadneo, broadcom-wl, v4l2loopback |
| **Locale support** | Standard | vi_VN.UTF-8 + bilingual strings everywhere |
