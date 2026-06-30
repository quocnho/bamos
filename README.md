# BamOS — Hệ điều hành Linux cho người Việt

<p align="center">
  <img src="branding/logo-bamos.svg" alt="BamOS Logo" width="180"/>
</p>

<p align="center">
  <strong>Ổn định · Nhẹ nhàng · Việt Nam</strong>
</p>

<p align="center">
  <a href="https://github.com/quocnho/bamos/actions/workflows/build.yml"><img src="https://img.shields.io/github/actions/workflow/status/quocnho/bamos/build.yml?label=build" alt="Build"></a>
  <img src="https://img.shields.io/badge/base-Fedora%20Atomic%2044-blue" alt="Fedora 44">
  <img src="https://img.shields.io/badge/desktop-GNOME%20%7C%20KDE-brightgreen" alt="Desktop">
  <img src="https://img.shields.io/badge/license-Apache%202.0-orange" alt="License">
</p>

---

Cloud-native atomic Linux distribution built for Vietnamese users, based on [Fedora Atomic](https://fedoraproject.org/atomic-desktops/) and [Universal Blue](https://universal-blue.org/).

## ✨ Highlights

- 🇻🇳 **ibus-bamboo** Wayland input · VNI/Times fonts · WPS Office · Zalo
- 🔐 USB Token PKCS#11 (Viettel-CA, BKAV-CA, FPT-CA, VNPT-CA)
- 🖨️ Printer drivers bundle · CUPS pre-configured
- 🎨 GNOME (RakuOS-inspired dark theme) · KDE (Windows 11 layout)
- 🚀 CachyOS tuning (scx scheduler, ananicy, BBR TCP) on stable uBlue kernel
- 🎮 Single NVIDIA variant auto-detects all GPUs (RTX 50 → GTX 600)

## 🚀 Quick Install

```bash
# GNOME variant (recommended)
rpm-ostree rebase ostree-unverified-registry:ghcr.io/quocnho/bamos-gnome:latest

# KDE variant
rpm-ostree rebase ostree-unverified-registry:ghcr.io/quocnho/bamos-kde:latest

# NVIDIA variant (auto-detects open/closed driver)
rpm-ostree rebase ostree-unverified-registry:ghcr.io/quocnho/bamos-gnome-nvidia:latest
```

## 📦 Variants

| Image | Desktop | GPU |
|-------|---------|-----|
| `bamos-gnome` | GNOME + RakuOS theme | Intel/AMD |
| `bamos-kde` | KDE Plasma Win11 | Intel/AMD |
| `bamos-gnome-nvidia` | GNOME + NVIDIA | All NVIDIA |
| `bamos-kde-nvidia` | KDE + NVIDIA | All NVIDIA |

## 🛠️ `bamos` CLI

```bash
bamos install <pkg>    # Layer packages via rpm-ostree
bamos update           # Update system + flatpaks
bamos upgrade          # Upgrade base image (bootc)
bamos setup-gaming     # Install Steam/Lutris
bamos setup-nvidia     # Configure NVIDIA drivers
```

## 📁 Repository Structure

```
├── build_files/       # Build & setup scripts
├── system_files/      # GNOME/KDE/NVIDIA/fonts/input config
├── config/            # BlueBuild recipe
├── docs/              # Full documentation
├── branding/          # Logo, wallpapers, themes
├── .github/           # CI/CD workflows (GitHub Actions)
├── Containerfile      # Multi-stage OCI image build
└── Justfile           # Development commands
```

## 🤝 Contributing

See [`docs/CONTRIBUTING.md`](docs/CONTRIBUTING.md) (Vietnamese + English).

## 📄 License

Apache 2.0 — see [`LICENSE`](LICENSE).
