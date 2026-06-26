# Hướng dẫn Build BamOS ISO & Test VM

> ⚠️ **Môi trường hiện tại**: Laptop chạy **RakuOS** (Fedora Atomic / bootc-based)
> — immutable OS, cài package qua `rakuos install` (overlay) hoặc `rpm-ostree install` (layer).
> Công cụ VM đã được cài sẵn (xem mục 0).

---

## 0. Môi trường đã có sẵn

| Công cụ | Trạng thái | Ghi chú |
|---------|-----------|---------|
| `bluebuild` CLI | ✅ Đã cài | `/usr/local/bin/bluebuild` |
| `podman` | ✅ Có sẵn | Base image |
| `qemu-kvm` | ✅ Đã cài | Qua `rakuos install` |
| `virt-manager` | ✅ Đã cài | GUI tạo VM |
| `virt-install` | ✅ Đã cài | CLI tạo VM |
| `gnome-boxes` | ✅ Đã cài | GUI đơn giản |
| KVM acceleration | ✅ Intel VT-x | `/dev/kvm` available |
| `libvirtd` | ✅ Đã enable | `sudo systemctl enable --now libvirtd` |
| Default network | ✅ Đã autostart | `virsh net-autostart default` |
| Disk space | ~459 GB trên `/var` | Cho VM images |

> **Lưu ý**: Re-login sau khi thêm vào nhóm `libvirt`:
> ```bash
> newgrp libvirt
> ```
> Hoặc đăng xuất / đăng nhập lại.

### Cài thêm công cụ nếu thiếu

```bash
# Trên RakuOS (immutable) — dùng rakuos install (overlay, không cần reboot)
sudo rakuos install qemu-kvm virt-manager virt-install gnome-boxes

# Hoặc dùng rpm-ostree (layer, cần reboot)
sudo rpm-ostree install qemu-kvm virt-manager virt-install gnome-boxes
sudo systemctl reboot
```

---

## 1. Build Image

### Build toàn bộ

```bash
# Build KDE edition (lần đầu mất ~20-40 phút, tuỳ internet)
sudo bluebuild build recipes/bamos-kde.yml

# Build GNOME edition
sudo bluebuild build recipes/bamos-gnome.yml

# Build COSMIC edition
sudo bluebuild build recipes/bamos-cosmic.yml
```

### Build nhanh (skip validation)

```bash
sudo bluebuild build --skip-validation recipes/bamos-kde.yml
```

### Kiểm tra image đã build

```bash
podman images | grep bamos
```

Output mẫu:
```
localhost/bamos-kde          latest     abc1234   5 phút trước   3.21 GB
localhost/bamos-gnome        latest     def5678   10 phút trước  3.45 GB
```

---

## 2. Generate ISO từ Image đã Build

Dùng `bluebuild generate-iso`:

```bash
# ISO từ image đã build local
sudo bluebuild generate-iso \
    --iso-name BamOS-KDE-$(date +%Y%m%d).iso \
    image localhost/bamos-kde:latest

# ISO từ recipe (build + generate cùng lúc)
sudo bluebuild generate-iso \
    --iso-name BamOS-KDE-$(date +%Y%m%d).iso \
    recipe recipes/bamos-kde.yml
```

### Build ISO thủ công (nếu cần chạy configure-iso.sh riêng)

```bash
# Bước 1: Export image
IMAGE_NAME="bamos-kde"
IMAGE_TAG="latest"

# Bước 2: Mount image và chạy configure-iso.sh
CONTAINER=$(sudo podman create localhost/$IMAGE_NAME:$IMAGE_TAG)
sudo podman cp installer $CONTAINER:/tmp/
sudo podman start -a $CONTAINER \
    /tmp/installer/configure-iso.sh
sudo podman commit $CONTAINER $IMAGE_NAME:iso-ready
sudo podman rm $CONTAINER

# Bước 3: Dùng lorax + titanoboa để tạo live ISO
# Tham khảo: https://github.com/ublue-os/titanoboa
```

> **Lưu ý:** `bluebuild generate-iso` tự động chạy `configure-iso.sh`. Chỉ cần dùng phương pháp thủ công nếu bạn muốn custom thêm.

---

## 3. Test ISO trong VM

### Test với GNOME Boxes (đơn giản nhất)

```bash
# Mở Boxes từ menu ứng dụng
# Hoặc chạy từ terminal:
gnome-boxes &

# Chọn ISO → Tạo VM
# Khuyến nghị: 4GB RAM, 2 CPU, 32GB disk
```

### Test với virt-manager (chi tiết hơn)

```bash
# Mở virt-manager
virt-manager &

# Tạo VM mới: File → New VM → Local install media
# Chọn ISO, để lại 4GB RAM, 2 CPU, 32GB disk
```

### Test với virt-install (CLI)

```bash
# Tạo VM từ ISO
sudo virt-install \
    --name bamos-test \
    --memory 4096 \
    --vcpus 2 \
    --disk size=32 \
    --cdrom ./BamOS-KDE-$(date +%Y%m%d).iso \
    --os-variant fedora-unknown
```

### Test với QEMU command-line

```bash
# Tạo disk image
qemu-img create -f qcow2 bamos-test.qcow2 32G

# Boot từ ISO
qemu-system-x86_64 \
    -enable-kvm \
    -m 4096 \
    -smp 2 \
    -drive file=bamos-test.qcow2,format=qcow2 \
    -cdrom BamOS-KDE-$(date +%Y%m%d).iso \
    -cpu host \
    -vga virtio
```

---

## 4. Test Image trực tiếp (Container) — Nhanh nhất

Không cần ISO, chạy thẳng container từ image vừa build:

```bash
# Chạy container tương tác
podman run --rm -it \
    --name bamos-test \
    localhost/bamos-kde:latest \
    /bin/bash

# Trong container, kiểm tra:
cat /etc/os-release
uname -r
rpm -qa | grep -i cachyos
```

---

## 5. Workflow phát triển nhanh (Dev loop)

```bash
# 1. Sửa code
vim files/scripts/00-build-setup.sh

# 2. Build (chỉ rebuild local, không push)
sudo bluebuild build recipes/bamos-kde.yml

# 3. Test nhanh trong container
podman run --rm -it localhost/bamos-kde:latest /bin/bash

# 4. Nếu OK, generate ISO
sudo bluebuild generate-iso \
    --iso-name BamOS-KDE-$(date +%Y%m%d).iso \
    image localhost/bamos-kde:latest

# 5. Test ISO trong VM
sudo virt-install \
    --name bamos-test \
    --memory 4096 \
    --vcpus 2 \
    --disk size=32 \
    --cdrom ./BamOS-KDE-*.iso \
    --os-variant fedora-unknown &

# 6. Commit & push
git add -A
git commit -m "feat: update packages"
git push origin develop
```

---

## 6. Khắc phục sự cố

### Build chậm / hết dung lượng

```bash
# Kiểm tra dung lượng
df -h /var

# Dọn cache podman
podman system prune -af

# Xoá images cũ
podman images | grep bamos | awk '{print $3}' | xargs sudo podman rmi
```

### Lỗi quyền libvirt

```bash
# Nếu virt-manager báo "No KVM"
sudo usermod -aG libvirt,qemu $(whoami)
# Sau đó đăng xuất / đăng nhập lại
```

### Lỗi "Cannot access storage file" (Permission denied)

```bash
# VM images trong /var/lib/libvirt/images cần quyền
sudo chown -R $(whoami):libvirt /var/lib/libvirt/images
```

### Lỗi Anaconda khi generate ISO

```bash
# Cài đủ dependencies (nếu chưa có)
sudo rakuos install lorax-lmc-novirt pykickstart

# Kiểm tra kickstart syntax
ksvalidator installer/shared/usr/share/anaconda/post-scripts/install-flatpaks.ks
```

### Cần xoá VM cũ trước khi tạo lại

```bash
sudo virsh destroy bamos-test 2>/dev/null || true
sudo virsh undefine bamos-test 2>/dev/null || true
sudo rm -f /var/lib/libvirt/images/bamos-test.qcow2
```
