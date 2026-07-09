# Technology Assessment: Btrfs Backup & Restore

**Date:** 2026-07-09
**Status:** Draft — chờ xác nhận

## Btrfs Layout hiện tại

| Subvolume | Mount | Dung lượng | Mục đích sao lưu |
|-----------|-------|-----------|-----------------|
| `home` (@home) | /home | ~50GB | ⭐ User config, .config, .local |
| `nix` (@nix) | /nix | ~200GB | ❌ Không cần (Nix store tái tạo được) |
| `data` (@data) | /data | Tuỳ chỉnh | ⭐ Documents, Pictures, Downloads |
| `tmp` | /tmp | — | ❌ Không cần |
| top-level | / | ~70GB | ⭐ /etc/nixos/ (config hệ thống) |

## Candidates

### 1. Snapper (openSUSE)
**Version:** 0.13.1
**NixOS support:** `services.snapper`
**Triết lý:** Timeline-based snapshots, tự động cleanup

| Ưu điểm | Nhược điểm |
|---------|-----------|
| Tích hợp sẵn NixOS module | Phức tạp, nhiều config |
| Tự động snapshot theo giờ/ngày/tuần | Cần cấu hình cho từng subvolume |
| `snapper undochange` — rollback từng file | Không hỗ trợ backup ra ngoài (USB, network) |
| Có GUI (btrfs-assistant) | Nặng (Python + dbus) |

### 2. btrbk
**Version:** 0.32.6
**NixOS support:** `services.btrbk`
**Triết lý:** Backup-focused, `btrfs send/receive`

| Ưu điểm | Nhược điểm |
|---------|-----------|
| **Chuyên cho backup** — send/receive ra USB/SSH | Không có rollback từng file như snapper |
| Cấu hình đơn giản (file .conf) | Dòng lệnh thuần (không GUI) |
| Hỗ trợ incremental backup | |
| Tự động pruning (giữ N bản) | |
| Nhẹ (Perl script, ít dependencies) | |

### 3. Btrfs-assistant
**Version:** 2.2
**Triết lý:** GUI cho snapper (frontend Qt)

### 4. snapborg
Không có trong nixpkgs.

## Decision Matrix

| Tiêu chí | Trọng số | Snapper | btrbk | Tự viết (bash) |
|-----------|---------|---------|-------|----------------|
| Dễ cấu hình NixOS | 20% | 4 | **5** | 3 |
| Backup ra ngoài (USB) | 20% | 1 | **5** | 3 |
| Incremental snapshot | 15% | 4 | **5** | 3 |
| Rollback dễ dàng | 15% | **5** | 3 | 3 |
| Nhẹ, ít dependencies | 10% | 2 | **5** | **5** |
| Tích hợp `bam` CLI | 10% | 3 | 4 | **5** |
| Cộng đồng, bảo trì | 10% | 3 | 3 | 1 |
| **Weighted Score** | **100%** | **3.15** | **4.35** | **3.15** |

## Khuyến nghị

**btrbk** là lựa chọn tốt nhất cho BamOS vì:

1. **Backup-focused**: sinh ra để làm backup, không chỉ snapshot
2. **send/receive**: có thể backup ra USB, SSH, local
3. **Cấu hình đơn giản**: file .conf 20 dòng là chạy được
4. **Nhẹ**: Perl script, không cần dbus/Python
5. **Pruning tự động**: giữ N daily, N weekly, N monthly
6. **Tích hợp `bam` CLI**: `bam backup` gọi `btrbk run`

### Kết hợp

```
btrbk (backup engine) + bam CLI (user interface)

bam backup
  └── btrbk run        → snapshot + send → /data/backups/ hoặc USB

bam restore
  └── btrbk list       → show available snapshots
  └── btrbk restore    → rollback subvolume

bam clean
  └── btrbk prune      → xoá snapshot cũ theo policy
  └── nix-collect-garbage → dọn Nix generations
```

### Retention Policy

| Loại | Giữ | Chu kỳ |
|------|-----|--------|
| **Hourly** | 24 | Mỗi giờ |
| **Daily** | 7 | Mỗi ngày |
| **Weekly** | 4 | Mỗi tuần |
| **Monthly** | 3 | Mỗi tháng |
| **Nix generations** | 5 | Mỗi lần rebuild |
