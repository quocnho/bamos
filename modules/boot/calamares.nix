# modules/boot/calamares.nix
# Calamares installer — cấu hình cho BamOS
# Chỉ chứa cấu hình partition + mount cho Calamares
# Hardware detection được xử lý bởi modules/hardware/detect.nix
#
# Calamares configuration được load từ:
#   1. /etc/calamares/modules/*.conf  (cao nhất — override)
#   2. Package calamares-nixos-extensions (mặc định)
{ config, lib, pkgs, ... }:
let
  # Partition layout: EFI (1GiB) + Root (Btrfs, 100%)
  partitionConf = builtins.toJSON {
    efi = {
      mountPoint = "/boot";
      recommendedSize = "1GiB";
      minimumSize = "32MiB";
      label = "EFI";
    };
    userSwapChoices = [ "none" "small" "suspend" ];
    luksGeneration = "luks2";
    defaultFileSystemType = "btrfs";
    availableFileSystemTypes = [ "ext4" "btrfs" "xfs" "f2fs" ];
    showNotEncryptedBootMessage = false;
    partitionLayout = [
      {
        name = "root";
        filesystem = "btrfs";
        noEncrypt = false;
        mountPoint = "/";
        size = "100%";
      }
    ];
  };

  # Mount config: define Btrfs subvolumes cho Ổ C — Ổ D
  mountConf = builtins.toJSON {
    extraMounts = [
      { device = "proc"; fs = "proc"; mountPoint = "/proc"; }
      { device = "sys"; fs = "sysfs"; mountPoint = "/sys"; }
      { device = "/dev"; mountPoint = "/dev"; options = [ "bind" ]; }
      { device = "tmpfs"; fs = "tmpfs"; mountPoint = "/run"; }
      { device = "/run/udev"; mountPoint = "/run/udev"; options = [ "bind" ]; }
      { device = "efivarfs"; fs = "efivarfs"; mountPoint = "/sys/firmware/efi/efivars"; efi = true; }
    ];
    # ═══════════════════════════════════════════════════════════
    # Btrfs subvolumes — mô hình Ổ C — Ổ D
    # ═══════════════════════════════════════════════════════════
    btrfsSubvolumes = [
      # Ổ C: Hệ thống
      { mountPoint = "/"; subvolume = ""; } # top-level (GRUB compatibility)
      { mountPoint = "/home"; subvolume = "/home"; }
      { mountPoint = "/nix"; subvolume = "/nix"; }
      # Ổ D: Dữ liệu (AN TOÀN khi cài lại)
      { mountPoint = "/data"; subvolume = "/data"; }
    ];
    mountOptions = [
      { filesystem = "efi"; options = [ "fmask=0077" "dmask=0077" ]; }
      { filesystem = "btrfs"; options = [ "compress=zstd" "noatime" ]; }
    ];
  };

in
{
  # ═══════════════════════════════════════════════════════
  # Override Calamares config files để có Ổ D
  # ═══════════════════════════════════════════════════════
  environment.etc = {
    "calamares/modules/partition.conf".text = partitionConf;
    "calamares/modules/mount.conf".text = mountConf;
  };
}
