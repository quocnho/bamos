# BamOS — VM Testing Guide

Xem hướng dẫn đầy đủ tại **[ISO-GENERATION.md](./ISO-GENERATION.md)** (mục VM Testing).

## Quick Reference

```bash
# One-time setup
just vm-setup

# Build + ISO + VM (4 lệnh)
sudo -S just build-gnome
sudo -S just iso-gnome
just vm-create gnome
virt-viewer bamos-gnome
```

## All VM Commands

| Command | Action |
|---------|--------|
| `just vm-setup` | Cài KVM/libvirt, start services, tạo network + pool |
| `just vm-create` | Tạo VM từ ISO mới nhất (default: gnome) |
| `just vm-create kde` | Tạo VM từ bamos-kde ISO |
| `just vm-start ` | Start VM |
| `just vm-stop` | Stop VM |
| `just vm-delete` | Xóa VM + disk |
| `just vm-list` | List all VMs |
| `just vm-console` | Mở virt-manager hoặc virt-viewer

## Testing Checklist

- [ ] GRUB boot menu (bilingual VN/EN)
- [ ] Plymouth boot splash (bamboo animation)
- [ ] Desktop hiển thị (GNOME OrigamiPaper / KDE Win11)
- [ ] Vietnamese input (ibus-unikey / fcitx5-unikey, Super+Space)
- [ ] Vietnamese fonts (Noto Sans, Inter)
- [ ] WPS Office (desktop icon)
- [ ] Web apps (banking shortcuts)
- [ ] Portal (auto-launch on first boot)
- [ ] Flatpak + Flathub configured
- [ ] `bamos help` CLI
- [ ] Fastfetch branding
