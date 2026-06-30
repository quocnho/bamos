# BamOS Editions

BamOS offers **4 ISO variants** optimized for different hardware profiles and user preferences. All variants share the same Vietnamese software stack (ibus-bamboo, WPS Office, Zalo, USB Token, printers, fonts) and system services. The differences are limited to desktop environment, GPU drivers, and target hardware.

## Edition Comparison

| Feature | 🖥️ **GNOME** | 🖥️ **KDE** | 🎮 **GNOME NVIDIA** | 🎮 **KDE NVIDIA** |
|---------|:-----------:|:---------:|:-----------------:|:----------------:|
| **ISO File** | `bamos-gnome.iso` | `bamos-kde.iso` | `bamos-gnome-nvidia.iso` | `bamos-kde-nvidia.iso` |
| **Desktop** | GNOME 48+ (RakuOS-style) | KDE Plasma 6 (Windows 11-style) | GNOME 48+ (RakuOS-style) | KDE Plasma 6 (Windows 11-style) |
| **GPU Driver** | Intel/AMD (open-source) | Intel/AMD (open-source) | **NVIDIA auto-detect** | **NVIDIA auto-detect** |
| **RAM Usage (idle)** | ~1.2 GB | ~1.0 GB | ~1.4 GB | ~1.2 GB |
| **ISO Size** | ~3.5 GB | ~3.8 GB | ~5.0 GB | ~5.3 GB |
| **Target User** | Office, general use | Windows migrants | Office + NVIDIA GPU | Windows migrants + NVIDIA |
| **Best for** | Laptops, desktops | Users familiar with Windows | Gaming laptops, workstations | Gaming laptops, Windows users |
| **NVIDIA driver** | ❌ Not included | ❌ Not included | ✅ Pre-installed (open + closed cached) | ✅ Pre-installed (open + closed cached) |
| **Auto-detect GPU** | ❌ | ❌ | ✅ All GPU generations | ✅ All GPU generations |
| **Wayland** | ✅ Default | ✅ Default | ✅ (Intel) / ✅ (NVIDIA Turing+) | ✅ (Intel) / ✅ (NVIDIA Turing+) |

## Edition Details

### bamos-gnome 🖥️

The flagship edition. GNOME desktop with RakuOS-inspired dark theme (OrigamiPaper, WhiteSur icons, Bibata cursors, Inter fonts, 5 hand-picked extensions). Best for most users.

**Desktop theme:**

```
┌─────────────────────────────────────────┐
│  Activities  📂 Files  🌐 Firefox       │
├─────────────────────────────────────────┤
│                                         │
│         WhiteSur-dark theme              │
│         OrigamiPaper GTK                 │
│         Inter UI Font                    │
│                                         │
│  ┌─────────────────────────────────────┐│
│  │  Dash to Dock (bottom, auto-hide)   ││
│  │  📄 💬 🌐 🎮 ⚙️ 🏪                ││
│  └─────────────────────────────────────┘│
└─────────────────────────────────────────┘
```

**Extensions:**
- Dash to Dock (bottom dock, auto-hide, 48px)
- AppIndicator (system tray icons)
- Blur my Shell (transparent panel)
- Caffeine (keep display on)
- No Overview at Login

**Themes & Icons:**
| Element | Value |
|---------|-------|
| GTK Theme | OrigamiPaper (dark) / OrigamiPaperLight (light) |
| Icons | WhiteSur-dark / WhiteSur-light |
| Cursors | Bibata-Modern-Classic |
| UI Font | Inter 10 |
| Mono Font | Maple Mono 10 |

### bamos-kde 🖥️

KDE Plasma configured to look and behave like Windows 11. Best for users migrating from Windows.

**Desktop layout:**

```
┌─────────────────────────────────────────┐
│  📄 💬 🌐 🎮          🔇 🔋 🔒 🕐   │
│  ┌─────────────────────────────────────┐│
│  │             Start Menu               ││
│  │   📄 Files     ⚙️ Settings          ││
│  │   🌐 Firefox   🏪 Store             ││
│  │   💬 Zalo      🎮 Steam             ││
│  └─────────────────────────────────────┘│
│     🪟  Taskbar (Centered, Win11-style) │
└─────────────────────────────────────────┘
```

**Key configurations:**
| Element | Value |
|---------|-------|
| Taskbar | Centered, icon-only, Windows 11 layout |
| Accent Color | Bamboo Green `#4CAF50` |
| Application Style | Breeze |
| UI Font | Inter 10 |
| Mono Font | Maple Mono 10 |
| Icons | Breeze (default) / Tela Circle (optional) |
| Cursors | Bibata-Modern-Classic |
| Shortcuts | Meta+E → Dolphin, Meta+R → KRunner, Meta+L → Lock |

### bamos-gnome-nvidia 🎮

GNOME edition with **NVIDIA GPU support for all generations**. Includes both `nvidia-open` (RTX 20+/Turing/Ampere/Ada/Blackwell) and `nvidia-closed` (GTX 900/10 Maxwell/Pascal) drivers cached in the image. First-boot auto-detection selects the correct driver.

**NVIDIA auto-detect logic:**

```
Boot → bamos-nvidia-firstboot.service
  → Detect GPU via PCI ID
  → RTX 50 (Blackwell)    ─┐
  → RTX 40 (Ada)           ├── keep nvidia-open ✅
  → RTX 30 (Ampere)        │
  → RTX 20 (Turing)        ┘
  → GTX 10 (Pascal)       ─┐
  → GTX 900 (Maxwell)      ├── rpm-ostree switch → nvidia-closed
  → GTX 700 (Maxwell v1)   ┘
  → GTX 600 (Kepler)       ─── warn EOL, legacy 470xx
```

**Includes:**
- NVIDIA Container Toolkit (GPU passthrough to containers)
- nvidia-settings + nvidia-persistenced
- egl-wayland + egl-wayland2
- Prime render offload (Intel + NVIDIA hybrid graphics)

### bamos-kde-nvidia 🎮

KDE Plasma edition with **NVIDIA GPU support for all generations**. Same NVIDIA infrastructure as `bamos-gnome-nvidia`, with KDE's Windows 11-like desktop.

**Best for:** Gamers, office users with NVIDIA GPUs, Windows migrants who need NVIDIA drivers.

## Use Case Matrix

| Use Case | Recommended Edition |
|----------|:------------------:|
| Office work, web browsing, email | **bamos-gnome** |
| Migrating from Windows 10/11 | **bamos-kde** |
| Office + NVIDIA GTX/RTX laptop | **bamos-gnome-nvidia** |
| Gaming on NVIDIA GPU | **bamos-gnome-nvidia** |
| Windows migrant + NVIDIA GPU | **bamos-kde-nvidia** |
| Programming, development | **bamos-gnome** |
| Old laptop with limited RAM | **bamos-kde** (uses ~200MB less RAM) |
| Digital signature, tax declaration | **bamos-gnome** (any variant works) |
| Virtualization, containers | **bamos-gnome** |
| KVM/QEMU host with NVIDIA passthrough | **bamos-gnome-nvidia** |

## System Requirements

| Requirement | GNOME Variants | KDE Variants |
|-------------|:--------------:|:------------:|
| **CPU** | x86_64, dual-core | x86_64, dual-core |
| **RAM** | 4 GB minimum / 8 GB recommended | 4 GB minimum / 8 GB recommended |
| **Disk** | 20 GB minimum / 64 GB recommended | 20 GB minimum / 64 GB recommended |
| **GPU (no NVIDIA)** | Intel / AMD / any | Intel / AMD / any |
| **GPU (NVIDIA)** | GTX 900+ / RTX 20+ | GTX 900+ / RTX 20+ |
| **UEFI** | Recommended | Recommended |
| **Secure Boot** | Supported (MOK enrollment) | Supported (MOK enrollment) |

## Installation Notes

```bash
# Write ISO to USB
sudo dd if=bamos-gnome.iso of=/dev/sdX bs=4M status=progress conv=fsync

# Boot from USB and select:
#   "Khởi động BamOS (Live)"     → Try without installing
#   "Cài đặt BamOS vào ổ cứng"   → Install to disk
```

- **Anaconda installer** — standard Fedora installer with Vietnamese language support
- **Automatic partitioning** — default layout with LVM thin provisioning
- **Manual partitioning** — available for advanced users
- **Encryption** — LUKS supported via installer

## Post-Install: First Boot

After installation, BamOS Portal launches automatically:

1. **Chào mừng / Welcome** — Introduction, docs, Store link
2. **Tiếng Việt & Văn phòng** — ibus-bamboo, fonts, WPS Office, Zalo, USB Token, printers
3. **GNOME Desktop / KDE Desktop** — Apply theme, extensions, shortcuts
4. **Hệ thống / System** — NVIDIA (if applicable), Xbox drivers, CachyOS tuning, Secure Boot
5. **Giải trí / Gaming** — Steam, KVM, Ollama AI

Most items run automatically (marked `default: true`). Click **"Run All Defaults"** to apply everything in one click.
