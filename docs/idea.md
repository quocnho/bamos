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

**Branding Integration**

| Surface | Implementation |
|---------|---------------|
| **ISO/USB Live** | `branding/logo-bamos.svg` — displayed in live environment (GRUB, desktop background) |
| **OS Release** | `/etc/os-release` — `NAME=BamOS`, `PRETTY_NAME="BamOS 44"`, `HOME_URL`, `LOGO=bamos-logo` |
| **Plymouth Boot Splash** | Custom Plymouth theme with bamboo logo animation, Bamboo Green accent — available in all variants |
| **Fastfetch** | Branded preset at `/usr/share/fastfetch/presets/bamos.jsonc` — shows bamboo logo ASCII + system info |
| **GRUB Menu** | BamOS branding on boot menu entries, separate entries for each deployment |

## Design Philosophy

### Inspired by Universal Blue (Build & Infrastructure)

- **OCI-native**: Images built as OCI containers, pushed to `ghcr.io`, distributed via CDN
- **Atomic updates**: rpm-ostree/bootc with automatic background updates and built-in rollback
- **CI/CD**: GitHub Actions with daily scheduled builds, PR validation, matrix builds, cosign signing
- **Akmods ecosystem**: Pre-built kernel modules via uBlue akmods cache — stable NVIDIA, xone, xpadneo
- **Community governance**: Open source, Apache 2.0, contributor-friendly structure

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
- **`bamos-flatpak-watcher`** — Systemd path watcher that monitors Flatpak installation directories. Automatically regenerates CLI wrappers on `flatpak install`/`uninstall`/`update` events, ensuring wrappers stay in sync with the installed app set.
- **`flatpak-repair.service` + `flatpak-repair.timer`** — Weekly systemd timer that verifies and repairs Flatpak installations, removes stale wrappers, and ensures system consistency.
- **Flatpak fixes** (`flatpak-fixes/`) — Adapted fixes for Firefox (Wayland+VAAPI, native file picker portal) and StreamController (udev rules, plugin permissions).

#### Secure Boot

- **`bamos-enroll-secureboot.service`** — Adapted from `enroll-secureboot-key`. One-shot systemd service that runs on first boot to enroll a Machine Owner Key (MOK) for Secure Boot. Allows loading unsigned kernel modules (NVIDIA, xone, v4l2loopback) on Secure Boot-enabled systems without disabling Secure Boot entirely.

#### AI & Gaming Setup

- **`setup-ollama`** — Adapted from RakuOS `setup-ollama`. Installs Ollama for local AI model inference with GPU acceleration (NVIDIA CUDA / AMD ROCm). Sets up systemd service for Ollama server and configures popular Vietnamese-compatible models (qwen2.5, llama3).
- **`setup-lsfg-vk`** — Adapted from RakuOS `setup-lsfg-vk`. Configures Lossless Scaling Frame Generation (LSFG) via Vulkan layer for gaming. Installs MangoHud, vkBasalt, and configures frame generation profiles for improved gaming performance.

#### System & User Setup

- **`bamos-system-setup`** — Enhanced with RakuOS patterns: Flatpak seeding (pre-install apps from seed list), fish shell migration for new users, GTK/Qt theme synchronization, first-run marker (`/etc/bamos/.first-run`).
- **`bamos-user-setup`** — Enhanced with RakuOS user patterns: automatic theme sync (dark/light toggle), GTK settings watchers, Flatpak permission overrides (filesystem, DBus, Wayland), fish shell migration prompt, starship prompt configuration.
- **`bamos-updater`** — Enhanced with RakuOS notification pattern: uses `notify-send` with reboot action button when system updates require a restart, providing a user-friendly update experience.

#### Shell Configuration

- **`/etc/fish/conf.d/bamos-aliases.fish`** — Fish shell aliases file providing convenient shortcuts for `bamos` CLI commands, package management, and system maintenance. Mirrors the existing bash/zsh aliases pattern from RakuOS.

#### New Systemd Units

| Unit | Type | Function |
|------|------|----------|
| `bamos-enroll-secureboot.service` | oneshot (first-boot) | Enroll MOK for Secure Boot kernel modules |
| `flatpak-repair.service` | oneshot | Repair Flatpak installations |
| `flatpak-repair.timer` | timer (weekly) | Trigger flatpak-repair weekly |
| `bamos-flatpak-watcher.path` | path unit | Watch Flatpak install dirs for changes |
| `bamos-flatpak-watcher.service` | oneshot | Regenerate wrappers on Flatpak changes |

## Technical Architecture

### Base Image

```
FROM ghcr.io/ublue-os/silverblue-main:latest    (GNOME variant)
FROM ghcr.io/ublue-os/kinoite-main:latest        (KDE variant)
```

### Image Variants (4 total)

| Variant | Base | Desktop | GPU | Target |
|---------|------|---------|-----|--------|
| `bamos-gnome` | Silverblue | GNOME + RakuOS theme | Intel/AMD | Office, general use |
| `bamos-kde` | Kinoite | KDE Plasma Win11 | Intel/AMD | Windows migrants |
| `bamos-gnome-nvidia` | Silverblue | GNOME + RakuOS theme | NVIDIA auto-detect | NVIDIA all-gen |
| `bamos-kde-nvidia` | Kinoite | KDE Plasma Win11 | NVIDIA auto-detect | NVIDIA all-gen |

### NVIDIA Architecture (Single Variant, All GPU Generations)

```
Containerfile multi-stage:
  Stage 0: akmods-nvidia + akmods-nvidia-open  ← Cache BOTH driver RPMs
  Stage 1: bamos-base                           ← GNOME/KDE + VN features
  Stage 2: bamos-nvidia (FROM bamos-base)       ← Install nvidia-open (default)
                                                   Cache nvidia-closed RPMs → /opt/bamos/nvidia-closed/

First boot: bamos-nvidia-firstboot.service
  → nvidia-firstboot-setup.sh
  → Detect GPU via PCI ID
  → RTX 20+ (Turing/Ampere/Ada/Blackwell) → keep nvidia-open ✓
  → GTX 900/10 (Maxwell/Pascal)           → rpm-ostree switch to nvidia-closed
  → GTX 600/700 (Kepler)                   → warn EOL, best-effort legacy 470xx
```

| GPU Generation | Products | Driver | Wayland | Auto-detect |
|---------------|----------|--------|---------|:---:|
| Blackwell | RTX 50 series | nvidia-open | ✅ | ✅ |
| Ada Lovelace | RTX 40 series | nvidia-open | ✅ | ✅ |
| Ampere | RTX 30 series | nvidia-open | ✅ | ✅ |
| Turing | RTX 20 / GTX 16 | nvidia-open | ✅ | ✅ |
| Volta/Pascal | GTX 10 / Titan V | nvidia (closed) | ✅ | ✅ auto-switch |
| Maxwell | GTX 900/700 | nvidia (closed) | ✅ | ✅ auto-switch |
| Kepler | GTX 600/700 | Legacy 470xx | ❌ | ⚠️ best-effort |

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

### Directory Structure

```
bamos/
├── 📄 README.md                     ← Lightweight entry, links to docs/
├── 📄 LICENSE                       ← Apache 2.0
├── 📄 Containerfile                 ← Multi-stage OCI image build
├── 📄 Justfile                      ← Dev commands (build, validate, shell)
├── 📄 cosign.pub                    ← Sigstore image signing key
│
├── 📁 docs/                         ← ALL documentation
│   ├── idea.md                      # Vision, architecture, roadmap
│   ├── CONTRIBUTING.md              # Contribution guide (VN + EN)
│   ├── CHANGELOG.md                 # Release history
│   ├── CODE_OF_CONDUCT.md
│   ├── SECURITY.md
│   ├── NVIDIA-COMPATIBILITY.md      # GPU generation matrix
│   └── CACHYOS-INTEGRATION.md       # Kernel tuning architecture
│
├── 📁 build_files/                   ← Build & setup scripts
│   ├── gnome-build.sh               # GNOME DE + extensions + themes
│   ├── kernel-optimize.sh           # CachyOS performance tuning
│   ├── install-wps.sh               # WPS Office installer
│   ├── setup-vn-input.sh            # ibus-bamboo Wayland config
│   ├── setup-fonts.sh               # Font cache + GSsettings
│   ├── setup-fonts-proprietary.sh   # Import VNI/VnTime from Windows
│   ├── setup-fonts-ms.sh            # Download MS Core Fonts
│   ├── setup-printing.sh            # Printer drivers + CUPS
│   ├── setup-token.sh               # USB Token PKCS#11
│   └── setup-zalo.sh                # Zalo (Wine + web fallback)
│
├── 📁 system_files/
│   ├── shared/                      # Shared across ALL variants
│   │   ├── usr/bin/bamos            # Main CLI dispatcher
│   │   ├── usr/libexec/bamos/       # 15 management scripts
│   │   ├── usr/lib/systemd/         # Maintenance timers & services
│   │   ├── usr/lib/udev/rules.d/    # IO scheduler (bfq/kyber/none)
│   │   ├── usr/lib/sysctl.d/        # Kernel tuning (swappiness, BBR)
│   │   ├── usr/share/bamos/         # Packages, docs
│   │   ├── usr/share/fastfetch/     # Branding preset
│   │   └── etc/                     # Shell aliases (bash/fish/zsh)
│   ├── gnome/                       # GNOME-specific
│   │   └── usr/share/glib-2.0/     # GSsettings override (compiled at build)
│   │   └── etc/sudoers.d/           # Passwordless flatpak/bootc
│   ├── kde/                         # KDE Plasma Win11 config
│   ├── nvidia/                      # NVIDIA driver + firstboot auto-detect
│   ├── fonts/                       # Fontconfig VN + README.md
│   ├── input-methods/               # ibus-bamboo setup
│   ├── office/wps-config/          # WPS Office VN config
│   └── webapps/                     # Vietnamese web apps (25+ shortcuts)
│
├── 📁 config/
│   └── recipe.yml                   # BlueBuild recipe
│
├── 📁 branding/
│   ├── logo-bamos.svg               # Main logo (bamboo pattern)
│
├── 📁 .github/
    ├── workflows/build.yml           # CI/CD: matrix build 4 variants
    ├── workflows/validate.yml        # PR validation
    └── ISSUE_TEMPLATE/               # Bug report + Feature request
```

## Core Features

### 1. Vietnamese Language Support

- **Input Method**: ibus-bamboo — fully Wayland-compatible, Telex + VNI methods
- **Configuration**: `Super+Space` toggles EN/VN, pre-configured at build time
- **Spell Check**: hunspell-vi dictionary
- **Locale**: vi_VN.UTF-8 default with English fallback
- **ibus environment**: GTK_IM_MODULE, QT_IM_MODULE, XMODIFIERS set globally

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

### 4. Font Strategy (Three-Tier)

**Tier 1 — Open-Source (RPM, in image)**: Noto Sans/Serif/Mono Vietnamese, Inter (UI), Maple Mono NF (terminal), Liberation Sans/Serif/Mono (MS replacements), Carlito, Caladea

**Tier 2 — Metric-Compatible Replacements**:
| MS Font | Replacement | Notes |
|---------|------------|-------|
| Times New Roman | Liberation Serif | Same metrics |
| Arial | Liberation Sans | Same metrics |
| Courier New | Liberation Mono | Same metrics |
| Calibri | Carlito | Same metrics |

**Tier 3 — Proprietary (user-installed)**:
- `bamos setup-fonts-proprietary` — Auto-detect Windows partition, import VNI/VnTime/MS fonts
- `bamos setup-fonts-ms` — Download Microsoft Core Fonts (cabextract)
- Fontconfig aliases ensure fallback to Noto when proprietary fonts unavailable

### 5. Digital Signature & USB Token Support

- **Middleware**: opensc, pcsc-lite, pcsc-lite-ccid, pcsc-tools, openssl-pkcs11
- **Tokens**: Viettel-CA, BKAV-CA, FPT-CA, VNPT-CA, Gemalto/Thales
- **Browser PKCS#11**: Pre-configured environment variables for Firefox/Chromium
- **Documentation**: Vietnamese guide at `/usr/share/doc/bamos/TOKEN-SETUP.md`
- **Use cases**: Electronic tax declaration, social insurance, customs

### 6. Printer Driver Support

- **CUPS**: Pre-installed and enabled, network discovery on
- **Driver bundles**: hplip, gutenprint, foomatic-db
- **Supported brands**: HP, Canon, Epson, Brother, Samsung/Xerox
- **lpadmin group**: User auto-added for printer management

### 7. Zalo Installation

Primary messaging platform in Vietnam. Two options:
- **Zalo via Wine** (primary): Pre-configured wineprefix in `/opt/zalo`, desktop entry
- **Zalo Web App** (fallback): PWA shortcut to chat.zalo.me

### 8. Desktop Environment Customization

#### GNOME Variant (RakuOS-inspired)

| Element | Value |
|---------|-------|
| Theme | adw-gtk3-dark |
| Icons | WhiteSur-dark |
| Cursors | Bibata-Modern-Classic |
| UI Font | Inter 11 |
| Mono Font | Maple Mono NF 11 |
| Shell Extensions | **5 extensions**: AppIndicator, Dash to Dock, Blur my Shell, No Overview (boot), **Caffeine** |
| Dock | Bottom, auto-hide, semi-transparent |
| Window buttons | macOS-style (close, minimize, maximize left) |
| Keyboard | `Super+Space` VN/EN, `Super+q` close, `Super+t` terminal |
| gnome-extensions-app | ✅ Kept for user customization |
| gnome-tweaks | ✅ Pre-installed |

#### KDE Variant (Windows 11-like)

- Centered taskbar with icon-only task manager
- Start menu with grid layout
- Windows 11 keyboard shortcuts (Meta+D, Alt+F4, Meta+Arrows)
- Bamboo Green accent color throughout
- Breeze application style, bibata cursors
- Font: Noto Sans with Vietnamese support
- Pre-solved icon/font/color issues through image-level config (not post-install scripts)

### 9. bamos CLI (RakuOS-inspired)

```bash
# Package Management
bamos install <pkg...>     # Layer packages via rpm-ostree
bamos remove <pkg...>      # Remove layered packages
bamos update               # Update all (rpm-ostree + flatpak + bootc)
bamos upgrade              # Upgrade base image (bootc)
bamos list                 # List layered packages
bamos search <query>       # Search packages
bamos reset-overlay        # Reset all layered packages

# Setup Wizards
bamos setup-gaming              # Steam, Lutris, Mangohud
bamos setup-virt                # KVM/QEMU, virt-manager
bamos setup-nvidia              # Configure GPU drivers
bamos setup-ollama              # Local AI with Ollama (GPU-accelerated)
bamos setup-lsfg-vk             # Lossless Scaling Frame Gen for gaming
bamos setup-fonts-proprietary   # Import VNI/VnTime from Windows
bamos setup-fonts-ms            # Download MS Core Fonts

# NVIDIA Management
bamos switch-nvidia-legacy      # Switch to closed driver
bamos switch-nvidia-open        # Switch to open driver

# Secure Boot
bamos enroll-secureboot-key     # Enroll MOK for Secure Boot modules

# Flatpak Management
bamos flatpak-wrapper-gen       # Regenerate Flatpak CLI wrappers
```

### 10. Systemd Maintenance Services

**Timers & Scheduled Services**

| Timer | Frequency | Function |
|-------|-----------|----------|
| `bamos-cache-clean.timer` | Weekly | Clean dnf5/rpm-ostree cache |
| `flatpak-cleanup.timer` | Weekly | Remove unused Flatpak runtimes |
| `flatpak-repair.timer` | Weekly | Repair Flatpak installations, remove stale wrappers |
| `podman-prune.timer` | Weekly | Prune containers and images |

**First-boot & One-shot Services**

| Service | Trigger | Function |
|---------|---------|----------|
| `bamos-system-setup.service` | First boot | Flatpak seeding, fish migration, theme sync, first-run marker |
| `bamos-user.service` | First login | Fish shell, starship, fastfetch, git config, GTK watchers |
| `bamos-enroll-secureboot.service` | First boot | Enroll MOK for Secure Boot kernel modules |

**Path-based Watchers**

| Unit | Trigger | Function |
|------|---------|----------|
| `bamos-flatpak-watcher.path` | Flatpak install/uninstall | Regenerate CLI wrappers on app changes |

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
- Containerfile with multi-stage builds
- GitHub Actions CI/CD (4 variants)
- Branding (logo, color scheme)
- GNOME config (RakuOS-inspired GSsettings)
- KDE config (Windows 11 layout)
- bamos CLI + shell aliases + systemd services

### Phase 2: Vietnamese Core ✅
- ibus-bamboo Wayland integration
- Font configuration (Noto + Inter + Maple Mono)
- Vietnamese locale defaults
- Web apps collection (25+ shortcuts)
- Zalo installation solution
- WPS Office pre-configuration
- USB Token/digital signature setup

### Phase 3: NVIDIA & Performance ✅
- Single NVIDIA variant with first-boot auto-detect
- CachyOS performance tuning (scx, ananicy, BBR, IO scheduler)
- NVIDIA Container Toolkit
- Legacy GPU support (Maxwell/Pascal → auto-switch)
- nvidia-firstboot-setup systemd service

### Phase 4: RakuOS Integration & Polish ✅ (Mostly Complete)
- ✅ RakuOS scripts integration (flatpak-wrapper-gen, enroll-secureboot, setup-ollama, setup-lsfg-vk)
- ✅ Flatpak fixes (Firefox Wayland/VAAPI, StreamController udev rules)
- ✅ bamos-system-setup enhanced (flatpak seeding, fish migration, theme sync, first-run marker)
- ✅ bamos-user-setup enhanced (theme sync, GTK watchers, flatpak overrides, shell migration)
- ✅ bamos-updater enhanced (notify-send with reboot action)
- ✅ Fish shell aliases (`/etc/fish/conf.d/bamos-aliases.fish`)
- ✅ New systemd units (enroll-secureboot, flatpak-repair, flatpak-watcher)
- ✅ Branding integration (ISO/USB live, OS release, Plymouth boot splash)
- 🔄 Plymouth theme refinements
- 🔄 Wallpaper collection
- 🔄 Beta testing with Vietnamese community

### Phase 5: Community & Growth (Future)
- ISO generation via bootc-image-builder
- Website / GitHub Pages
- Community Discord/Zalo group
- Documentation translations
- RPM package repository

## Technical Decisions & Rationale

| Decision | Rationale |
|----------|-----------|
| Fedora Atomic 44 as base | Immutable, atomic updates, uBlue ecosystem, latest packages |
| uBlue kernel + CachyOS tuning | Stable akmods + desktop responsiveness without kernel fragility |
| Single NVIDIA variant | Only 4 images to maintain vs 6; auto-detect saves user confusion |
| ibus-bamboo over ibus-unikey | Better Wayland support, more active development |
| WPS Office over LibreOffice | Better compatibility with Vietnamese .doc/.docx files |
| Zalo via Wine over web app | Most feature-complete for Vietnamese users |
| BlueBuild template | Proven CI/CD, community support, clean architecture |
| Apache 2.0 License | Permissive, compatible with uBlue ecosystem |
| English code, bilingual docs | Enables international contribution while serving Vietnamese users |
| WhiteSur + Bibata + Inter theme | Matches RakuOS's proven aesthetic; visually modern |

## Key Differentiators

### vs RakuOS

| Aspect | RakuOS | BamOS |
|--------|--------|-------|
| **Build system** | GitLab CI + Chunkah | GitHub Actions + OCI layers |
| **Kernel** | kernel-cachyos (DKMS) | uBlue kernel (akmods) + CachyOS tuning |
| **Base image** | `fedora-ostree-desktops/base-atomic` | `ublue-os/silverblue-main` |
| **Package model** | OverlayFS on /usr | rpm-ostree atomic layering |
| **NVIDIA** | Separate Containerfile.nvidia | Single variant, auto-detect |
| **ibus** | ibus-unikey | ibus-bamboo (Wayland-focused) |
| **WPS Office** | Not included | Pre-configured with VN fonts |
| **Zalo** | Not included | Wine + web fallback |
| **USB Token** | Not included | PKCS#11 pre-configured |
| **Fonts** | CJK fonts only | Full VN font stack + proprietary import script |

### vs Bazzite

| Aspect | Bazzite | BamOS |
|--------|---------|-------|
| **Target user** | Gamers (Steam Deck, HTPC) | Vietnamese office/government users |
| **Kernel** | bazzite-kernel (ogc) | uBlue kernel + CachyOS tuning |
| **HDR gaming** | ✅ | ❌ (not needed) |
| **Steam Deck** | ✅ Full support | ❌ |
| **WPS Office** | ❌ | ✅ Pre-configured |
| **VN Input** | ❌ | ✅ ibus-bamboo |
| **USB Token** | ❌ | ✅ PKCS#11 + CA Vietnam |
| **VN Web Apps** | ❌ | ✅ 25+ banking/gov shortcuts |
| **Zalo** | ❌ | ✅ Wine + web fallback |
| **Fonts** | CJK only | VN-optimized 3-tier strategy |
| **Printer drivers** | Generic | VN-common printer bundle |
| **NVIDIA variants** | 2 flavors (open + closed) | 1 variant (auto-detect) |
| **CLI** | ujust commands | bamos CLI + shell aliases |

### vs Bluefin/Aurora

| Aspect | Bluefin/Aurora | BamOS |
|--------|---------------|-------|
| **Target** | Developers | Vietnamese office/government |
| **Containers** | Toolbx, dev containers | Distrobox, podman |
| **Kubernetes** | k0s, kind | ❌ |
| **CachyOS tuning** | ❌ | ✅ scx, ananicy, BBR |
| **VN-specific** | ❌ | Complete VN stack |
| **NVIDIA auto-detect** | ❌ | ✅ Single variant all-gen |
