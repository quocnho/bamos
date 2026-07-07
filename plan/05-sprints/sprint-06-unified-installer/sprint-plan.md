# Sprint 6: Unified Calamares Installer

**Dates:** 2026-07-07 → TBD
**Branch:** `sprint/06/unified-installer`
**Target:** v0.6.0

## Goal
Unified installer: 3 ISOs (GNOME/KDE/COSMIC) với edition + machine type selector trong Calamares.

## Backlog

### US-06-01: Packagechooser Edition + Machine Type
- [x] `packagechooser-edition.conf` — 4 edition options
- [x] `packagechooser-machine.conf` — 3 machine types

### US-06-02: Custom Python module bamos-config
- [x] Reads edition + machine from globalStorage
- [x] Generates `/etc/nixos/edition-config.nix`
- [x] Generates `/iso-cfg/flake.nix` pointing to `github:quocnho/bamos`

### US-06-03: OC D File Manager Integration
- [x] `/data` bookmark in Nautilus sidebar
- [ ] Custom drive icon (SVG)
- [ ] XDG user dirs redirect → /data

### US-06-04: Calamares Branding
- [x] Custom branding.desc with Nord colors
- [ ] Screenshot images for packagechooser
- [ ] Logo + slideshow
