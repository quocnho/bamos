# modules/boot/calamares.nix
# Calamares installer — Unified Installer + Ổ C — Ổ D + Branding
#
# ═══════════════════════════════════════════════════════════════
# Tích hợp:
#   1. Partition: Btrfs Ổ C — Ổ D  (EFI + @ + @home + @nix + @data)
#   2. Edition selection: Standard/Developers/Gaming/Studio
#   3. Machine type: Laptop/Desktop/Server
#   4. Ổ D icon + Nautilus bookmark (custom drive icon)
#   5. Branding: logo, images, fonts (GLF-OS inspired)
#   6. /iso-cfg: post-install flake template cho updates
# ═══════════════════════════════════════════════════════════════
#
# Calamares config load từ:
#   1. /etc/calamares/modules/*.conf  (cao nhất — override)
#   2. /etc/calamares/bamos-modules/  (custom Python module)
#   3. Package calamares-nixos-extensions (mặc định)

{ config, lib, pkgs, ... }:

let
  # ═══════════════════════════════════════════════════════════
  # Ổ D icon — giống biểu tượng ổ đĩa Windows (D:)
  # Tự động thêm vào Nautilus sidebar sau cài đặt
  # ═══════════════════════════════════════════════════════════
  dataDriveIcon = pkgs.runCommand "data-drive-icon"
    {
      nativeBuildInputs = [ pkgs.librsvg ];
      preferLocalBuild = true;
    } ''
    mkdir -p $out/share/icons/hicolor/scalable/emblems
    mkdir -p $out/share/icons/hicolor/48x48/emblems

    # SVG icon — ổ D với nhãn DATA
    cat > $out/share/icons/hicolor/scalable/emblems/drive-data.svg << 'SVGEOF'
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
      <rect x="4" y="12" width="40" height="28" rx="3" fill="#4A90D9" stroke="#2C5F8A" stroke-width="2"/>
      <rect x="8" y="16" width="32" height="20" rx="2" fill="#E8F0FE"/>
      <text x="24" y="31" font-family="sans-serif" font-size="16" font-weight="bold" fill="#2C5F8A" text-anchor="middle">DATA</text>
    </svg>
    SVGEOF

    # PNG icon 48x48 từ SVG
    rsvg-convert -w 48 -h 48 \
      $out/share/icons/hicolor/scalable/emblems/drive-data.svg \
      -o $out/share/icons/hicolor/48x48/emblems/drive-data.png
  '';

  # ═══════════════════════════════════════════════════════════
  # Calamares branding assets (GLF-OS inspired)
  # ═══════════════════════════════════════════════════════════
  calamaresBranding = pkgs.runCommand "calamares-bamos-branding"
    {
      nativeBuildInputs = [ pkgs.librsvg ];
    } ''
    mkdir -p $out/share/calamares/branding/bamos/images
    mkdir -p $out/share/calamares/branding/bamos/lang

    # Logo
    cp ${pkgs.bamos-branding}/share/icons/hicolor/scalable/apps/bamos-logo.svg \
      $out/share/calamares/branding/bamos/images/bamos-logo.svg

    # Screenshots for packagechooser (placeholder SVGs)
    for img in standard developers gaming studio laptop desktop server; do
      cat > $out/share/calamares/branding/bamos/images/$img.jpg << EOF
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 320 200">
      <rect width="320" height="200" fill="#1a1a2e"/>
      <text x="160" y="100" font-family="sans-serif" font-size="20" fill="#81A1C1" text-anchor="middle">BamOS $img</text>
      <text x="160" y="130" font-family="sans-serif" font-size="12" fill="#5E81AC" text-anchor="middle">Choose this configuration</text>
    </svg>
    EOF
    done

    # Branding descriptor
    cat > $out/share/calamares/branding/bamos/branding.desc << 'EOF'
    ---
    componentName: bamos
    name: BamOS
    version: "0.5.0"
    short: BamOS Linux
    description: A professional NixOS distribution for the Vietnamese community
    author: Nguyen Quoc Nho
    homepage: https://github.com/quocnho/bamos

    # Slideshow
    slideshow: "slideshow"
    slideshowAPI: 2

    # Style
    style:
      sidebarBackground: "#1a1a2e"
      sidebarText: "#ECEFF4"
      sidebarTextSelect: "#81A1C1"
      sidebarHighlight: "#88C0D0"
      headerBackground: "#2E3440"
      headerText: "#ECEFF4"
      headerFont: "Inter 11"
      bodyBackground: "#3B4252"
      bodyText: "#ECEFF4"
      bodyFont: "Inter 11"
      linkColor: "#88C0D0"

    # Strings
    strings:
      productName: BamOS
      shortProductName: BamOS
      version: 0.5.0
      welcomeMessage: "<h1>Welcome to BamOS.</h1><br/>NixOS distribution for the Vietnamese community.<br/>Please choose your language to begin."
      welcomeMessageVn: "<h1>Chào mừng đến với BamOS.</h1><br/>Hệ điều hành NixOS cho cộng đồng Việt Nam.<br/>Vui lòng chọn ngôn ngữ để bắt đầu."
      loadingMessage: "Please wait while BamOS prepares your installation environment..."
      installChoice: "Install BamOS"
      installationPrompt: "BamOS will be installed on your computer. All data on the selected disk will be lost."
      installationPromptVn: "BamOS sẽ được cài đặt trên máy tính của bạn. Toàn bộ dữ liệu trên ổ đĩa đã chọn sẽ bị mất."
    EOF
  '';

  # ═══════════════════════════════════════════════════════════
  # Custom Calamares Python module: bamos-config
  # Sinh edition-config.nix + /iso-cfg để người dùng update sau
  # ═══════════════════════════════════════════════════════════
  bamosCalamaresModule = pkgs.writeTextDir "lib/calamares/modules/bamos-config/module.desc" ''
    ---
    type:       "job"
    name:       "bamos-config"
    interface:  "python"
    script:     "main.py"
  '' // pkgs.writeTextDir "lib/calamares/modules/bamos-config/main.py" ''
        #!/usr/bin/env python3
        # BamOS Calamares module — generates NixOS config + /iso-cfg
        # Reads edition + machine type from packagechooser
        # Writes /etc/nixos/edition-config.nix + /iso-cfg/flake.nix

        import libcalamares
        import os
        import shutil

        def run():
            edition = libcalamares.globalStorage.value("packagechooser_edition") or "standard"
            machine = libcalamares.globalStorage.value("packagechooser_machine") or "desktop"
            hostname = libcalamares.globalStorage.value("hostname") or "bamos"

            root = libcalamares.globalStorage.value("rootMountPoint") or "/mnt"

            # ── 1. Create /etc/nixos/edition-config.nix ──
            config_dir = os.path.join(root, "etc", "nixos")
            os.makedirs(config_dir, exist_ok=True)

            with open(os.path.join(config_dir, "edition-config.nix"), "w") as f:
                f.write('''# Auto-generated by BamOS Calamares installer
    { config, lib, pkgs, ... }:

    {
      imports = [ ''')

                f.write('''./editions/standard.nix''')
                f.write(''' ];

      # Power management based on machine type
      bamos.power-management = {
        enable = true;
        profile = "desktop";
        ppdSupport = true;
        dynamicTuning = true;
        ''' + (
            '''batteryOptimized = true;
        enableSwap = true;
        swapSize = 16384;
        ''' if machine == "laptop" else
            '''batteryOptimized = false;
        profile = "throughput-performance";
        ''' if machine == "server" else
            '''batteryOptimized = false;
        '''
        ) + '''};

      # OC D — data drive icon in file manager
      systemd.tmpfiles.settings."10-bamos-data" = {
        "/data".d = { mode = "0755"; user = "bamos"; group = "users"; };
      };
    }
    ''')

            # ── 2. Create /iso-cfg/ for post-install updates ──
            isocfg_dir = os.path.join(root, "iso-cfg")
            os.makedirs(isocfg_dir, exist_ok=True)

            # flake.nix
            with open(os.path.join(isocfg_dir, "flake.nix"), "w") as f:
                f.write('''{
      description = "BamOS — My Configuration";

      inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
        bamos.url = "github:quocnho/bamos";
      };

      outputs = { self, nixpkgs, bamos, ... }: {
        nixosConfigurations."''' + hostname + '''" = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            ./configuration.nix
            bamos.nixosModules.default
            bamos.nixosModules.''' + edition + '''
            ./hardware-configuration.nix
          ];
        };
      };
    }
    ''')

            # configuration.nix
            with open(os.path.join(isocfg_dir, "configuration.nix"), "w") as f:
                f.write('''{ config, pkgs, lib, ... }:

    {
      networking.hostName = "''' + hostname + '''";
      system.stateVersion = "26.05";
    }

    ''')

            # README
            with open(os.path.join(isocfg_dir, "README.md"), "w") as f:
                f.write('''# BamOS User Configuration

    ## Update your system

    ```bash
    cd /iso-cfg
    sudo nix flake update
    sudo nixos-rebuild switch --flake .#
    ```

    ## Change edition

    Edit `flake.nix` and change `bamos.nixosModules.standard` to:
    - `bamos.nixosModules.developers`
    - `bamos.nixosModules.gaming`
    - `bamos.nixosModules.studio`

    ## Change hostname

    Edit `configuration.nix` and change `networking.hostName`.
    ''')

            return libcalamares.job.succeed(
                "BamOS config generated: edition=%s, machine=%s" % (edition, machine)
            )
  '';

  bamosModulePkg = pkgs.symlinkJoin {
    name = "calamares-bamos-module";
    paths = [ bamosCalamaresModule ];
  };

  # ═══════════════════════════════════════════════════════════
  # Partition layout: EFI + Btrfs Ổ C — Ổ D
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
      name = "root";
      filesystem = "btrfs";
      noEncrypt = false;
      mountPoint = "/";
      size = "100%";
    }];
  };

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
  # Packagechooser: Edition selector
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
        screenshot = "images/standard.jpg";
        packages = [ ];
      }
      {
        id = "developers";
        name = "BamOS Developers";
        description = "<html>Danh cho lap trinh vien — devenv, Podman, Distrobox, dev tools.<br/>Bao gom VM tools, Git, CI/CD tools.</html>";
        screenshot = "images/developers.jpg";
        packages = [ ];
      }
      {
        id = "gaming";
        name = "BamOS Gaming";
        description = "<html>Toi uu cho choi game — Steam, Lutris, Heroic, GameScope, MangoHud.<br/>Kernel XanMod + tuned latency-performance.</html>";
        screenshot = "images/gaming.jpg";
        packages = [ ];
      }
      {
        id = "studio";
        name = "BamOS Studio";
        description = "<html>Danh cho sang tao — Blender, GIMP, Krita, Ardour, OBS.<br/>Low-latency audio + color management.</html>";
        screenshot = "images/studio.jpg";
        packages = [ ];
      }
    ];
  };

  # Packagechooser: Machine type selector
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
        screenshot = "images/laptop.jpg";
        packages = [ ];
      }
      {
        id = "desktop";
        name = "Desktop / PC";
        description = "<html>Cau hinh cho PC ban — hieu nang toi da, khong gioi han nang luong.</html>";
        screenshot = "images/desktop.jpg";
        packages = [ ];
      }
      {
        id = "server";
        name = "Server";
        description = "<html>Khong GUI, throughput-performance, toi uu cho server workload.</html>";
        screenshot = "images/server.jpg";
        packages = [ ];
      }
    ];
  };

  # Override settings.conf — custom sequence
  settingsConf = builtins.toJSON {
    modules-search = [
      "local"
      "/nix/store/1jwbzck0dvj00vqvxnymgpc3s4k8yl2z-calamares-nixos-extensions-0.3.23/lib/calamares/modules"
      "${bamosModulePkg}/lib/calamares/modules"
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
  environment.etc = {
    "calamares/modules/partition.conf".text = partitionConf;
    "calamares/modules/mount.conf".text = mountConf;
    "calamares/modules/packagechooser-edition.conf".text = editionConf;
    "calamares/modules/packagechooser-machine.conf".text = machineConf;
    "calamares/settings.conf".text = settingsConf;
    "calamares/branding/bamos/branding.desc".source = "${calamaresBranding}/share/calamares/branding/bamos/branding.desc";
  };

  environment.systemPackages = with pkgs; [
    bamosModulePkg
    calamaresBranding
    dataDriveIcon
  ];
}
