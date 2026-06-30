# Changelog

## [0.1.0] - 2026-06-30 — Initial Release

### 🏗️ Architecture
- Multi-stage Containerfile: `bamos-base` → `bamos-nvidia` pattern
- BlueBuild recipe in `config/recipe.yml`
- 4 variants: `bamos-gnome`, `bamos-kde`, `bamos-gnome-nvidia`, `bamos-kde-nvidia`
- GitHub Actions CI/CD with daily builds + PR validation + cosign signing
- Clean directory structure: `build_files/`, `system_files/`, `docs/`, `branding/`

### 🇻🇳 Vietnamese Integration
- ibus-bamboo Wayland input method with Telex/VNI support
- Vietnamese font configuration (Noto Sans/Serif, Inter, Maple Mono)
- WPS Office installer with Vietnamese font substitution
- Zalo setup (Wine-based + web app fallback)
- Vietnamese web apps (25+ banking, government, education shortcuts)
- USB Token/digital signature support (Viettel-CA, BKAV-CA, FPT-CA, VNPT-CA)
- Printer driver bundle (HP, Canon, Epson, Brother)
- `glibc-langpack-vi` + `hunspell-vi` pre-installed

### 🎨 Desktop
- **GNOME**: RakuOS-inspired dark theme (WhiteSur icons, Bibata cursors, Inter fonts)
  - 5 extensions: AppIndicator, Dash to Dock, Blur my Shell, No Overview, Caffeine
  - `gnome-extensions-app` kept for user customization
  - `gnome-tweaks` pre-installed
- **KDE Plasma**: Windows 11-like layout (centered taskbar, grid menu, Win11 shortcuts)

### 🎮 NVIDIA (Single variant, all GPU generations)
- Auto-detect GPU at first boot via `bamos-nvidia-firstboot.service`
- `nvidia-open` default (RTX 20+), auto-switch to `nvidia` (Maxwell/Pascal)
- Cached closed-driver RPMs for offline switching
- NVIDIA Container Toolkit pre-installed
- Wayland-ready modeset configuration
- Support matrix: RTX 50 → GTX 600 (Kepler best-effort)

### 🚀 Performance (CachyOS-inspired)
- `scx_bpfland` BPF CPU scheduler (switchable to `scx_lavd` for gaming)
- `ananicy-cpp` process priority daemon
- IO scheduler rules: bfq (HDD) / kyber (SSD) / none (NVMe)
- BBR TCP congestion control
- Kernel parameters: `preempt=full`, MGLRU, zswap (lz4)
- Sysctl tuning: swappiness=30, increased file handles, network buffers

### 🛠️ bamos CLI
- `bamos install/remove/update/upgrade` — package & system management
- `bamos list/search` — package discovery
- `bamos setup-gaming` — Steam/Lutris installer
- `bamos setup-virt` — KVM/QEMU installer
- `bamos switch-nvidia-legacy/open` — driver switching
- Shell aliases for bash, fish, zsh
- Fastfetch branding preset

### 🧹 System Maintenance
- Weekly cache cleanup timer (`bamos-cache-clean.timer`)
- Weekly Flatpak cleanup timer
- Weekly Podman prune timer
- Per-user first-login setup service (`bamos-user.service`)

### 📚 Documentation
- `docs/idea.md` — full vision & design philosophy
- `docs/CONTRIBUTING.md` — contribution guide (VN + EN)
- `docs/NVIDIA-COMPATIBILITY.md` — GPU generation matrix
- `docs/CACHYOS-INTEGRATION.md` — kernel tuning architecture
- `docs/SECURITY.md` — security policy
- `docs/CODE_OF_CONDUCT.md` — community guidelines
- Bilingual `README.md` at root
