# modules/disko-btrfs.nix
# Declarative disk partitioning với Btrfs subvolumes
# Pattern: "Ổ C — Ổ D cho Linux" (thói quen người dùng Việt Nam)
#
# C: (hệ thống — có thể ghi đè khi cài lại)
#   /         → @         (hệ thống, NixOS config)
#   /nix      → @nix      (Nix store — tái sử dụng, không cần tải lại)
#   /home     → @home     (chỉ config, .config, .local)
#
# D: (dữ liệu — AN TOÀN TUYỆT ĐỐI khi cài lại)
#   /data     → @data     (Documents, Downloads, Pictures, Videos, Music...)
#
# XDG User Dir được redirect từ ~/Documents → /data/Documents, v.v.
#
{ config, lib, ... }:
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        # /dev/sda là default — installer/người dùng sẽ chọn đúng disk
        device = "/dev/sda";
        content = {
          type = "gpt";
          partitions = {
            # EFI System Partition
            ESP = {
              size = "512M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [
                  "fmask=0077"
                  "dmask=0077"
                ];
              };
            };
            # Root partition (Btrfs với subvolumes)
            root = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ]; # Force overwrite
                subvolumes = {
                  # ═══════════════════════════════════════════
                  # Ổ C: — Hệ thống (có thể ghi đè khi cài lại)
                  # ═══════════════════════════════════════════
                  # / — hệ thống, NixOS config, etc
                  "@" = {
                    mountpoint = "/";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  # /nix — Nix store (tái sử dụng giữa các lần cài)
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  # /home — chỉ config cá nhân (~/.config, ~/.local)
                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  # ═══════════════════════════════════════════
                  # Ổ D: — Dữ liệu (AN TOÀN TUYỆT ĐỐI khi cài lại)
                  # ═══════════════════════════════════════════
                  # /data — Documents, Downloads, Pictures, Videos, Music
                  "@data" = {
                    mountpoint = "/data";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                };
              };
            };
          };
        };
      };
    };
  };

  # ═══════════════════════════════════════════════════════
  # XDG User Directory redirect: ~/Documents → /data/Documents
  # Đảm bảo user data hoàn toàn nằm trên "Ổ D"
  # ═══════════════════════════════════════════════════════
  systemd.tmpfiles.settings."10-bamos-data-dirs" = {
    "/data/Desktop".d = {
      mode = "0755";
      user = config.bamos.user.name;
      group = "users";
    };
    "/data/Documents".d = {
      mode = "0755";
      user = config.bamos.user.name;
      group = "users";
    };
    "/data/Downloads".d = {
      mode = "0755";
      user = config.bamos.user.name;
      group = "users";
    };
    "/data/Music".d = {
      mode = "0755";
      user = config.bamos.user.name;
      group = "users";
    };
    "/data/Pictures".d = {
      mode = "0755";
      user = config.bamos.user.name;
      group = "users";
    };
    "/data/Videos".d = {
      mode = "0755";
      user = config.bamos.user.name;
      group = "users";
    };
    "/data/Public".d = {
      mode = "0755";
      user = config.bamos.user.name;
      group = "users";
    };
    "/data/Templates".d = {
      mode = "0755";
      user = config.bamos.user.name;
      group = "users";
    };
  };

  # XDG User Dir config mặc định
  environment.etc = {
    "xdg/user-dirs.defaults" = {
      text = ''
        DESKTOP=Desktop
        DOWNLOAD=Downloads
        DOCUMENTS=Documents
        PICTURES=Pictures
        VIDEOS=Videos
        MUSIC=Music
        PUBLICSHARE=Public
        TEMPLATES=Templates
      '';
    };
  };
}
