# modules/boot/calamares-overlay.nix
# Overlay cho calamares-nixos-extensions — custom settings, branding, partition
# Áp dụng pattern từ GLF-OS: overrideAttrs với postInstall
#
# Module này được import trong hosts/iso/default.nix như một NixOS module
# để đảm bảo overlay áp dụng đúng trên nixosConfigurations

{ config, pkgs, lib, ... }:

let
  patchDir = ./patches/calamares;

in
{
  # ═══════════════════════════════════════════════════════
  # Overlay Calamares (pattern GLF-OS: nixpkgs.overlays trong nixosSystem)
  # ═══════════════════════════════════════════════════════
  nixpkgs.overlays = [
    (final: super: {
      # Fix autostart cho Wayland:
      #   pkexec strip WAYLAND_DISPLAY/XDG_RUNTIME_DIR → crash
      #   sudo --preserve-env giữ biến Wayland + chạy root (cần cho libparted)
      #   Trên LiveCD, nixos là wheel + NOPASSWD + SETENV → sudo transparent
      makeAutostartItem = args:
        if args.name or "" == "calamares" then
          super.writeTextFile
            {
              name = "autostart-calamares";
              destination = "/etc/xdg/autostart/calamares.desktop";
              text = ''
                [Desktop Entry]
                Type=Application
                Version=1.0
                Name=Cài đặt BamOS
                GenericName=Trình cài đặt hệ thống
                TryExec=calamares
                Exec=sh -c "sudo --preserve-env=WAYLAND_DISPLAY,XDG_RUNTIME_DIR,DISPLAY,QT_QPA_PLATFORM calamares"
                Icon=calamares
                Terminal=false
                StartupNotify=true
                Categories=Qt;System;
              '';
            }
        else
          super.makeAutostartItem args;

      # Override calamares-nixos-extensions với config tùy chỉnh
      calamares-nixos-extensions = super.calamares-nixos-extensions.overrideAttrs (oldAttrs: {
        postInstall = (oldAttrs.postInstall or "") + ''
          # === Copy config files (settings + modules) ===
          mkdir -p $out/etc/calamares/modules

          cp ${patchDir}/settings.conf $out/etc/calamares/settings.conf
          cp ${patchDir}/partition.conf $out/etc/calamares/modules/partition.conf
          cp ${patchDir}/mount.conf $out/etc/calamares/modules/mount.conf
          cp ${patchDir}/packagechooser-edition.conf $out/etc/calamares/modules/packagechooser-edition.conf
          cp ${patchDir}/packagechooser-machine.conf $out/etc/calamares/modules/packagechooser-machine.conf

          # === Copy bamos-config Python module ===
          mkdir -p $out/lib/calamares/modules/bamos-config
          cp ${patchDir}/bamos-config/main.py $out/lib/calamares/modules/bamos-config/main.py

          # === Module descriptor cho bamos-config ===
          cat > $out/lib/calamares/modules/bamos-config/module.desc << DESC_EOF
          ---
          type:       "job"
          name:       "bamos-config"
          interface:  "python"
          script:     "main.py"
          DESC_EOF
        '';
      });
    })
  ];
}
