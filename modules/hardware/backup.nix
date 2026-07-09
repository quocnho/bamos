# modules/hardware/backup.nix
# Btrfs Backup & Restore — dùng btrbk engine
#
# btrbk là công cụ snapshot/backup chuyên cho Btrfs:
#   - Tạo snapshot local (btrfs subvolume snapshot)
#   - Backup ra USB/SSH (btrfs send/receive)
#   - Incremental: chỉ chép thay đổi
#   - Pruning tự động: giữ N bản theo policy
#
# Tích hợp với bam CLI:
#   bam backup  → btrbk run
#   bam restore → btrbk list + btrbk restore
#   bam clean   → btrbk prune + nix-collect-garbage
#
{ config, pkgs, lib, ... }:

let
  cfg = config.bamos.backup;

  # Thư mục chứa snapshots
  snapshotDir = "/.snapshots";

  # Retention policy
  retain = {
    hourly = cfg.retain.hourly;
    daily = cfg.retain.daily;
    weekly = cfg.retain.weekly;
    monthly = cfg.retain.monthly;
  };

  # btrbk config — backup @home + @data
  btrbkConfig = pkgs.writeText "btrbk.conf" ''
    # BamOS btrbk config
    timestamp_format long
    snapshot_dir ${snapshotDir}
    volume /
      subvolume home
        snapshot_name home
        snapshot_create always
        ${lib.optionalString (retain.hourly > 0) "snapshot_retain_hourly ${toString retain.hourly}"}
        ${lib.optionalString (retain.daily > 0) "snapshot_retain_daily ${toString retain.daily}"}
        ${lib.optionalString (retain.weekly > 0) "snapshot_retain_weekly ${toString retain.weekly}"}
        ${lib.optionalString (retain.monthly > 0) "snapshot_retain_monthly ${toString retain.monthly}"}

      subvolume data
        snapshot_name data
        snapshot_create always
        ${lib.optionalString (retain.hourly > 0) "snapshot_retain_hourly ${toString retain.hourly}"}
        ${lib.optionalString (retain.daily > 0) "snapshot_retain_daily ${toString retain.daily}"}
        ${lib.optionalString (retain.weekly > 0) "snapshot_retain_weekly ${toString retain.weekly}"}
        ${lib.optionalString (retain.monthly > 0) "snapshot_retain_monthly ${toString retain.monthly}"}

    # Target: backup ra /data/backups/ nếu có
    target /data/backups
      volume /
        subvolume home
        subvolume data
  '';
in
{
  options.bamos.backup = {
    enable = lib.mkEnableOption "Btrfs backup (btrbk)" // { default = true; };

    autoSnapshot = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Tự động snapshot theo lịch (systemd timer)";
    };

    snapshotInterval = lib.mkOption {
      type = lib.types.str;
      default = "hourly";
      description = "Chu kỳ snapshot: hourly, daily, weekly";
    };

    retain = {
      hourly = lib.mkOption {
        type = lib.types.int;
        default = 24;
        description = "Số snapshot hourly giữ lại";
      };
      daily = lib.mkOption {
        type = lib.types.int;
        default = 7;
        description = "Số snapshot daily giữ lại";
      };
      weekly = lib.mkOption {
        type = lib.types.int;
        default = 4;
        description = "Số snapshot weekly giữ lại";
      };
      monthly = lib.mkOption {
        type = lib.types.int;
        default = 3;
        description = "Số snapshot monthly giữ lại";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ btrbk ];

    # btrbk config file
    environment.etc."btrbk/btrbk.conf".source = btrbkConfig;

    # Tạo thư mục snapshot + backup directories
    systemd.tmpfiles.settings."10-bamos-backup-dirs" = {
      "${snapshotDir}".d = { mode = "0755"; user = "root"; group = "root"; };
      "/data/backups/system".d = { mode = "0755"; user = "root"; group = "root"; };
      "/data/backups/home".d = { mode = "0755"; user = "root"; group = "root"; };
      "/data/backups/data".d = { mode = "0755"; user = "root"; group = "root"; };
    };

    # Timer: tự động snapshot
    systemd.services.btrbk-snapshot = lib.mkIf cfg.autoSnapshot {
      description = "BamOS Btrfs snapshot (btrbk)";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.btrbk}/bin/btrbk run";
        Nice = 19;
      };
    };

    systemd.timers.btrbk-snapshot = lib.mkIf cfg.autoSnapshot {
      description = "BamOS Btrfs snapshot timer";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = cfg.snapshotInterval;
        Persistent = true;
        RandomizedDelaySec = 300;
      };
    };

    # Tạo thư mục backup target nếu có /data
    systemd.tmpfiles.settings."10-btrbk-backups" = {
      "/data/backups".d = {
        mode = "0755";
        user = "root";
        group = "root";
      };
    };


  };
}
