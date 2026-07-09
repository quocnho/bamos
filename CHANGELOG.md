# Changelog

All notable changes to BamOS will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [4.0.0] - 2026-07-09

### Added
- `bam rollback [gen]` — Rollback to previous generation
- `bam changelog` — View changelog of new versions
- `bam clean [--keep N]` — Clean Nix generations + Btrfs snapshots
- Auto-upgrade engine: systemd timer + notify on success/failure
- Version checking: compare local version vs GitHub, show update notification
- `/etc/os-release` branding: `NAME="BamOS"`, `ID="bamos"`

### Changed
- `bam update` now uses `/etc/nixos` directly (no `/iso-cfg/` fallback)
- `bam backup` stores to `/data/backups/{system,home,data}/`
- `bam update` now regens boot menu after GC (GLF-OS pattern)

### Fixed
- Backward compatibility with NixOS 26.11

## [3.0.0] - 2026-07-08

### Added
- `bam backup [-s] [-h] [-d]` — Selective system/home/data backup
- `bam restore [-s] [-h] [-d]` — Selective restore with interactive menu
- Btrfs snapshot engine via btrbk
- FHS compatibility via `bam run` (buildFHSEnvBubblewrap)
- `bam install/remove/search` — Unified package manager (nix + flatpak)

### Changed
- Renamed `bamos-fhs` to `bam run`

## [2.0.0] - 2026-07-07

### Added
- `bam` CLI tool: `bam info`, `bam run`, `bam install`
- Power management with tuned (Red Hat) replacing PPD
- NVIDIA 595.84 stable driver with PRIME Offload
- RakuOS-inspired theming: WhiteSur icons, Bibata cursors, Nordic GTK
- Calamares Unified Installer with edition + machine type selection
- OC D (/data) with Nautilus bookmark + custom icon

### Changed
- Migrated from `papirus-icon-theme` to `whitesur-icon-theme`
- Switched NVIDIA driver from beta to stable (595.84)

## [1.0.0] - 2026-07-03

### Added
- Initial BamOS release
- Flake-parts framework
- GNOME/KDE/COSMIC desktop environments
- 4 editions: Standard, Developers, Gaming, Studio
- 12 ISO variants
- Fcitx5 + Bamboo Vietnamese input
- PipeWire audio
- NVIDIA Optimus support
- Binary cache at bamos.cachix.org
