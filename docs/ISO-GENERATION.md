# BamOS — ISO & VM Guide

Build bootable ISOs from BamOS OCI images and test them in virtual machines.

## Architecture

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Containerfile   │────▶│  OCI Image (root) │────▶│  Anaconda ISO    │
│  (sudo podman)   │     │  bootc compatible │     │  (bootable USB)  │
└─────────────────┘     └──────────────────┘     └─────────────────┘
         │                        │                        │
    just build-*           sudo podman build       bootc-image-builder
```

**Important**: Images must be built with `sudo podman build` so they're accessible to `bootc-image-builder` (which runs as root inside a container).

## Quick Start

```bash
# One-command: build GNOME image → ISO → VM
just build-iso-gnome
just vm-create gnome
```

## Image Variants

| Variant | Stage | Input Method | GPU | Justfile command |
|---------|-------|-------------|-----|-----------------|
| **bamos-gnome** | `bamos-gnome` | ibus-unikey | Intel/AMD | `just build-gnome` |
| **bamos-kde** | `bamos-kde` | fcitx5-unikey | Intel/AMD | `just build-kde` |
| **bamos-gnome-nvidia** | `bamos-nvidia-gnome` | ibus-unikey | NVIDIA (RPM Fusion) | `just build-gnome-nvidia` |
| **bamos-kde-nvidia** | `bamos-nvidia-kde` | fcitx5-unikey | NVIDIA (RPM Fusion) | `just build-kde-nvidia` |

## Containerfile Stages

```
  bamos-base           ← Silverblue/Kinoite (NO input method)
  ├── bamos-gnome      ← + ibus-unikey (GNOME)
  ├── bamos-kde        ← + fcitx5-unikey (KDE)
  ├── bamos-nvidia-gnome ← + NVIDIA + ibus-unikey (GNOME NVIDIA)
  └── bamos-nvidia-kde   ← + NVIDIA + fcitx5-unikey (KDE NVIDIA)
```

## ISO Commands

| Command | Action | Sudo |
|---------|--------|:----:|
| `just build-gnome` | Build GNOME image | ✅ |
| `just iso-gnome` | Generate GNOME ISO | ✅ |
| `just build-iso-gnome` | Build image + ISO in one step | ✅ |
| `just iso-all` | Generate ISOs for all 4 variants | ✅ |
| `just iso-registry gnome latest` | ISO from ghcr.io (no build needed) | ✅ |

## Build + ISO Flow

```bash
cd ~/Projects/bamos

# Step 1: Build image (requires sudo password)
just build-gnome

# Step 2: Generate ISO (requires sudo password)
just iso-gnome

# Or in one step:
just build-iso-gnome

# For NVIDIA variant:
just build-gnome-nvidia
just iso-gnome-nvidia

# For all variants:
just build-all  # ~1-2 hours total
just iso-all
```

## Boot Menu (Bilingual VN/EN)

The ISO inherits branding from `branding/iso-grub.cfg`:

```
🐉 BamOS 44
─────────────────────────
▶ Khởi động BamOS (Live)
▶ BamOS Live (Basic Video)
▶ Kiểm tra và khởi động BamOS
▶ Cài đặt BamOS vào ổ cứng
▶ Tùy chọn nâng cao (Advanced)
```

## Branding in ISO

| Element | Source | ISO Surface |
|---------|--------|-------------|
| OS Name | `branding/os-release` | Anaconda installer header |
| Logo | `branding/logo-bamos.svg` | Background, about dialog |
| GRUB | `branding/iso-grub.cfg` | Boot menu (bilingual) |
| Plymouth | `branding/plymouth/` | Boot splash animation |
| Wallpaper | `build_files/branding.sh` | Live desktop background |

## VM Testing

### VM Setup (one-time)

```bash
# Option A: Using just
just vm-setup

# Option B: Manual
sudo rakuos install libvirt-daemon-kvm qemu-kvm virt-manager
sudo systemctl enable --now libvirtd
sudo usermod -aG libvirt $USER
newgrp libvirt  # or log out/in
```

### VM Commands

| Command | Action |
|---------|--------|
| `just vm-setup` | Install KVM/libvirt, start services, create network + storage pool |
| `just vm-create gnome` | Create VM from latest GNOME ISO |
| `just vm-create kde` | Create VM from latest KDE ISO |
| `just vm-start` | Start VM (default: bamos-gnome) |
| `just vm-stop` | Stop VM |
| `just vm-delete` | Delete VM + disk |
| `just vm-list` | List all VMs |
| `just vm-console` | Open virt-viewer SPICE console |

### VM Specifications

| Component | Default | Custom |
|-----------|---------|--------|
| RAM | 4096 MB | `RAM=8192 just vm-create gnome` |
| CPU | 4 cores | `CPU=8 just vm-create kde` |
| Disk | 40 GB QCOW2 | `DISK=80 just vm-create gnome` |
| Graphics | SPICE + QXL | Auto |
| Network | NAT (default) | Auto |
| Boot | UEFI | Auto |

### Full Test Flow

```bash
# Build image + ISO + VM in 4 commands
cd ~/Projects/bamos
sudo -S just build-gnome          # Build image (enter password)
sudo -S just iso-gnome            # Generate ISO (enter password)
just vm-create gnome              # Create and boot VM
virt-viewer bamos-gnome           # Connect to console
```

## Custom Anaconda Kickstart

For unattended installations:

```bash
# Create config/bamos.ks:
cat > config/bamos.ks << 'EOF'
lang vi_VN.UTF-8
keyboard us
timezone Asia/Ho_Chi_Minh --isUtc
rootpw --lock --iscrypted locked
user --name=bamos --groups=wheel
autopart --type=thinp
services --enabled=NetworkManager,sshd
%packages
@standard
@hardware-support
%end
EOF

# Use kickstart with bootc-image-builder:
# --config config/bamos.ks
```

## Writing ISO to USB

```bash
# Find USB device
lsblk

# Write ISO (replace /dev/sdX with actual device, e.g., /dev/sda)
sudo dd if=output/bootiso/*.iso of=/dev/sdX bs=4M status=progress conv=fsync

# Alternative: Fedora Media Writer
flatpak run org.fedoraproject.MediaWriter

# Alternative: Ventoy (multi-ISO, just copy .iso)
# https://ventoy.net
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| `PWD: command not found` | Use `sudo podman run` with `-v $$PWD/output:/output` (just syntax) |
| `statfs /output: no such file` | Run from `~/Projects/bamos` or use absolute path |
| `image not known` | Image must be built with `sudo podman build` |
| `Permission denied` | Run with `sudo` |
| `user not in libvirt group` | `sudo usermod -aG libvirt $USER` then `newgrp libvirt` |
| `default network not active` | `sudo virsh net-start default` |
| ISO > 4GB (FAT32 limit) | Use exFAT/Ventoy USB, or NTFS |
| `no space left on device` | `podman system prune -a` |
| NVIDIA akmods cache missing | Not needed — NVIDIA installed from RPM Fusion directly |

## CI/CD (GitHub Actions)

Automated ISO generation is in `.github/workflows/build.yml`:

```yaml
- name: Generate ISO
  run: |
    sudo podman run --rm --privileged \
      -v ${{ github.workspace }}/output:/output \
      quay.io/centos-bootc/bootc-image-builder:latest \
      --type anaconda-iso \
      ${{ env.REGISTRY }}/${{ env.IMAGE_OWNER }}/${{ matrix.variant }}:${{ env.IMAGE_TAG }}

- name: Upload ISO
  uses: actions/upload-artifact@v4
  with:
    name: ${{ matrix.variant }}-iso-${{ env.DATE_TAG }}
    path: ${{ github.workspace }}/output/bootiso/*.iso
    retention-days: 14
```

## References

- [bootc-image-builder](https://github.com/osbuild/bootc-image-builder)
- [CentOS Bootc](https://www.centos.org/centos-bootc/)
- [Universal Blue ISO guide](https://docs.bluebuild.org/guide/iso)
- [RPM Fusion NVIDIA](https://rpmfusion.org/Howto/NVIDIA)
