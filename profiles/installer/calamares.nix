# Description: Calamares-nixos-extensions overlay & DPI autostart patch
{ lib, ... }:

{
  nixpkgs.overlays = [
    (final: prev: {
      calamares-nixos-extensions = prev.calamares-nixos-extensions.overrideAttrs (old: {
        postInstall = (old.postInstall or "") + ''
          cp ${../../installer/calamares/modules/nixos/main.py} $out/lib/calamares/modules/nixos/main.py
          cp ${../../installer/calamares/config/modules}/*.conf $out/etc/calamares/modules/

          cat > $out/etc/calamares/settings.conf <<EOF
          modules-search: [ local, $out/lib/calamares/modules ]

          instances:
          - id: gpu
            module: packagechooser
            config: gpu.conf
          - id: device
            module: packagechooser
            config: device.conf

          sequence:
          - show:
            - welcome
            - locale
            - keyboard
            - users
            - packagechooser@gpu
            - packagechooser@device
            - partition
            - summary
          - exec:
            - partition
            - mount
            - nixos
            - umount
          - show:
            - finished

          branding: nixos
          prompt-install: false
          dont-chroot: false
          oem-setup: false
          disable-cancel: false
          disable-cancel-during-exec: true
          hide-back-and-next-during-exec: false
          quit-at-end: false
          EOF
        '';
      });

      makeAutostartItem = args:
        if (args.name or "") == "calamares" then
          prev.writeTextFile {
            name = "autostart-calamares";
            destination = "/etc/xdg/autostart/calamares.desktop";
            text = ''
              [Desktop Entry]
              Type=Application
              Name=Calamares
              Comment=Bamos installer
              Exec=sh -c "export QT_AUTO_SCREEN_SCALE_FACTOR=0 QT_SCALE_FACTOR=1.5; exec calamares"
              Icon=calamares
              Terminal=false
              X-GNOME-Autostart-enabled=true
            '';
          }
        else
          prev.makeAutostartItem args;
    })
  ];
}
