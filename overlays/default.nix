# BamOS NixOS overlays.
# Exposes custom packages so they're available as pkgs.* in NixOS modules.

{ ... }:

let
  # ═══════════════════════════════════════════════════════════
  # Calamares config: partition layout — EFI + Btrfs Ổ C — Ổ D
  # ═══════════════════════════════════════════════════════════
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
    partitionLayout = [{
      name = "BamOS (Btrfs)";
      filesystem = "btrfs";
      noEncrypt = false;
      mountPoint = "/";
      size = "100%";
    }];
  };

  # ═══════════════════════════════════════════════════════════
  # mount.conf — Btrfs subvolumes (Ổ C — Ổ D)
  # ═══════════════════════════════════════════════════════════
  mountConf = builtins.toJSON {
    extraMounts = [
      { device = "proc"; fs = "proc"; mountPoint = "/proc"; }
      { device = "sys"; fs = "sysfs"; mountPoint = "/sys"; }
      { device = "/dev"; mountPoint = "/dev"; options = [ "bind" ]; }
      { device = "tmpfs"; fs = "tmpfs"; mountPoint = "/run"; }
      { device = "/run/udev"; mountPoint = "/run/udev"; options = [ "bind" ]; }
      { device = "efivarfs"; fs = "efivarfs"; mountPoint = "/sys/firmware/efi/efivars"; efi = true; }
    ];
    btrfsSubvolumes = [
      { mountPoint = "/"; subvolume = ""; }
      { mountPoint = "/home"; subvolume = "/home"; }
      { mountPoint = "/nix"; subvolume = "/nix"; }
      { mountPoint = "/data"; subvolume = "/data"; }
    ];
    mountOptions = [
      { filesystem = "efi"; options = [ "fmask=0077" "dmask=0077" ]; }
      { filesystem = "btrfs"; options = [ "compress=zstd" "noatime" ]; }
    ];
  };

  # ═══════════════════════════════════════════════════════════
  # Edition selector — Standard / Developers / Gaming / Studio
  # ═══════════════════════════════════════════════════════════
  editionConf = builtins.toJSON {
    mode = "required";
    method = "legacy";
    labels = { step = "Edition"; };
    default = "standard";
    items = [
      {
        id = "standard";
        name = "BamOS Standard";
        description = "<html>Desktop pho thong — browser, office, media.<br/>Phu hop cho nguoi dung van phong, hoc tap, giai tri co ban.</html>";
        screenshot = "images/standard.png";
        packages = [ ];
      }
      {
        id = "developers";
        name = "BamOS Developers";
        description = "<html>Danh cho lap trinh vien — devenv, Podman, Distrobox, dev tools.<br/>Bao gom VM tools, Git, CI/CD tools.</html>";
        screenshot = "images/developers.png";
        packages = [ ];
      }
      {
        id = "gaming";
        name = "BamOS Gaming";
        description = "<html>Toi uu cho choi game — Steam, Lutris, Heroic, GameScope, MangoHud.<br/>Kernel XanMod + tuned latency-performance.</html>";
        screenshot = "images/gaming.png";
        packages = [ ];
      }
      {
        id = "studio";
        name = "BamOS Studio";
        description = "<html>Danh cho sang tao — Blender, GIMP, Krita, Ardour, OBS.<br/>Low-latency audio + color management.</html>";
        screenshot = "images/studio.png";
        packages = [ ];
      }
    ];
  };

  # ═══════════════════════════════════════════════════════════
  # Machine type — Laptop / Desktop / Server
  # ═══════════════════════════════════════════════════════════
  machineConf = builtins.toJSON {
    mode = "required";
    method = "legacy";
    labels = { step = "Machine Type"; };
    default = "desktop";
    items = [
      {
        id = "laptop";
        name = "Laptop";
        description = "<html>Toi uu cho laptop — tiet kiem pin, ASPM powersupersave, WiFi power saving, suspend/hibernate.</html>";
        screenshot = "images/laptop.png";
        packages = [ ];
      }
      {
        id = "desktop";
        name = "Desktop / PC";
        description = "<html>Cau hinh cho PC ban — hieu nang toi da, khong gioi han nang luong.</html>";
        screenshot = "images/desktop.png";
        packages = [ ];
      }
      {
        id = "server";
        name = "Server";
        description = "<html>Khong GUI, throughput-performance, toi uu cho server workload.</html>";
        screenshot = "images/server.png";
        packages = [ ];
      }
    ];
  };

  # ═══════════════════════════════════════════════════════════
  # settings.conf — Custom sequence với Edition + Machine steps
  # ═══════════════════════════════════════════════════════════
  # Lưu ý: calamares-nixos-extensions được thay thế bằng bamos-calamares-config
  # (xem bên dưới), nên path dưới đây trỏ tới package đã override.
  # Dùng prev.calamares-nixos-extensions (original) để tránh circular dependency
  # vì settings.conf được dùng để tạo bamos-calamares-config → calamares-nixos-extensions (override)
  mkSettingsConf = calamaresPkg: builtins.toJSON {
    modules-search = [
      "local"
      "${calamaresPkg}/lib/calamares/modules"
    ];
    instances = [
      { id = "edition"; module = "packagechooser"; config = "packagechooser-edition.conf"; }
      { id = "machine"; module = "packagechooser"; config = "packagechooser-machine.conf"; }
      { id = "unfree"; module = "notesqml"; config = "unfree.conf"; }
      { module = "nixos"; weight = 48; }
      { module = "bamos-config"; weight = 1; }
    ];
    sequence = [
      { show = [ "welcome" "locale" "keyboard" "users" "packagechooser@edition" "packagechooser@machine" "notesqml@unfree" "partition" "summary" ]; }
      { exec = [ "partition" "mount" "bamos-config" "nixos" "users" "umount" ]; }
      { show = [ "finished" ]; }
    ];
    branding = "bamos";
    prompt-install = false;
    dont-chroot = false;
    oem-setup = false;
    disable-cancel = false;
    disable-cancel-during-exec = false;
    quit-at-end = false;
  };

in
{
  # Default overlay — adds BamOS custom packages to nixpkgs
  default = final: prev: {
    bamos-branding = final.callPackage ../pkgs/bamos-branding { };

    # ═══════════════════════════════════════════════════════
    # Override calamares-nixos-extensions với config tùy chỉnh
    # Dùng symlinkJoin để merge:
    #   1. bamos-calamares-config: settings.conf + module configs
    #   2. Original calamares-nixos-extensions: modules, libs
    #
    # symlinkJoin: file nào có ở package (1) trước thì được dùng
    # ═══════════════════════════════════════════════════════
    bamos-calamares-config = final.runCommand "bamos-calamares-config" { } ''
      # --- settings.conf ---
      mkdir -p $out/etc/calamares/modules
      cat > $out/etc/calamares/settings.conf << 'SETTINGSEOF'
      ${mkSettingsConf prev.calamares-nixos-extensions}
      SETTINGSEOF

      # --- partition.conf ---
      cat > $out/etc/calamares/modules/partition.conf << 'PARTEOF'
      ${partitionConf}
      PARTEOF

      # --- mount.conf ---
      cat > $out/etc/calamares/modules/mount.conf << 'MOUNTEOF'
      ${mountConf}
      MOUNTEOF

      # --- packagechooser-edition.conf ---
      cat > $out/etc/calamares/modules/packagechooser-edition.conf << 'EDITEOF'
      ${editionConf}
      EDITEOF

      # --- packagechooser-machine.conf ---
      cat > $out/etc/calamares/modules/packagechooser-machine.conf << 'MACHINEEOF'
      ${machineConf}
      MACHINEEOF

      # --- Custom Python module: bamos-config ---
      # Module descriptor
      mkdir -p $out/lib/calamares/modules/bamos-config
      cat > $out/lib/calamares/modules/bamos-config/module.desc << 'DESCEOF'
      ---
      type:       "job"
      name:       "bamos-config"
      interface:  "python"
      script:     "main.py"
      DESCEOF

      # Python implementation
      cat > $out/lib/calamares/modules/bamos-config/main.py << 'PYEOF'
      #!/usr/bin/env python3
      # BamOS Calamares module
      # Copies iso-cfg template → /etc/nixos/, applies user selections

      import libcalamares
      import os
      import shutil
      import stat

      def sed_inplace(filename, old, new):
          with open(filename, "r") as f:
              content = f.read()
          content = content.replace(old, new)
          with open(filename, "w") as f:
              f.write(content)

      def run():
          edition = libcalamares.globalStorage.value("packagechooser_edition") or "standard"
          machine = libcalamares.globalStorage.value("packagechooser_machine") or "desktop"
          hostname = libcalamares.globalStorage.value("hostname") or "bamos"
          root = libcalamares.globalStorage.value("rootMountPoint") or "/mnt"

          target = os.path.join(root, "etc", "nixos")
          os.makedirs(target, exist_ok=True)

          template_dir = "/etc/nixos-template"
          if os.path.exists(template_dir):
              for item in os.listdir(template_dir):
                  src = os.path.join(template_dir, item)
                  dst = os.path.join(target, item)
                  if os.path.isdir(src):
                      shutil.copytree(src, dst, dirs_exist_ok=True)
                  else:
                      shutil.copy2(src, dst)

          customized_path = os.path.join(target, "customized.nix")
          if os.path.exists(customized_path):
              edition_map = {
                  "standard": "bamos.nixosModules.standard",
                  "developers": "bamos.nixosModules.developers",
                  "gaming": "bamos.nixosModules.gaming",
                  "studio": "bamos.nixosModules.studio",
              }
              if edition in edition_map:
                  sed_inplace(customized_path,
                      "bamos.nixosModules.standard",
                      edition_map[edition])
              if machine == "laptop":
                  sed_inplace(customized_path,
                      "batteryOptimized = false;",
                      "batteryOptimized = true;")

          config_path = os.path.join(target, "configuration.nix")
          if os.path.exists(config_path):
              sed_inplace(config_path, '"bamos"', '"' + hostname + '"')

          return libcalamares.job.succeed(
              "BamOS config deployed: edition=%s, machine=%s, hostname=%s"
              % (edition, machine, hostname)
          )
      PYEOF
    '';

    calamares-nixos-extensions = prev.symlinkJoin {
      name = "calamares-nixos-extensions-bamos";
      paths = [
        # Our custom config takes precedence (đặt trước)
        final.bamos-calamares-config
        # Original package (fallback cho modules, libs)
        prev.calamares-nixos-extensions
      ];
    };
  };
}
