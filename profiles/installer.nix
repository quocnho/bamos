# Profile INSTALLER — LiveCD cài bamos cho người dùng khác (dùng Calamares).
#
# Tham khảo sâu GLF-OS (framagit.org/gaming-linux-fr/glf-os):
#   - ISO: nixpkgs installation-cd-graphical-calamares-gnome.nix (GNOME LiveCD
#     + calamares autostart + pkexec passwordless cho wheel).
#   - Installer: Calamares + module "nixos" (calamares-nixos-extensions) —
#     override để: sinh configuration.nix (user/hostname/GPU), copy flake mẫu
#     từ /iso-cfg (input bamos = github:quocnho/bamos) vào /etc/nixos máy đích,
#     pre-lock flake.lock, rồi nixos-install --flake <root>/etc/nixos#bamos.
#   - Các file Calamares nằm ở installer/calamares/{modules,config}.
#
# DPI/CHỮ NHỎ: Calamares (Qt5) trên Wayland phân giải phân số kém → cửa sổ/font
# bé tí. Fix: override autostart gán QT_SCALE_FACTOR=1.5 + tắt auto scale để kích
# thước ỔN ĐỊNH, dễ đọc cho người lớn tuổi. Đổi 1.5 → 1.25 nếu muốn nhỏ hơn.
{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Override calamares-nixos-extensions + autostart Calamares.
  # Dùng `prev` (bản gốc chưa overlay) để tránh đệ quy.
  nixpkgs.overlays = [
    (final: prev: {
      calamares-nixos-extensions = prev.calamares-nixos-extensions.overrideAttrs (old: {
        postInstall = (old.postInstall or "") + ''
                    # --- module nixos (sinh config + nixos-install --flake) ---
                    cp ${../installer/calamares/modules/nixos/main.py} $out/lib/calamares/modules/nixos/main.py
                    # --- cấu hình từng module (partition, users, welcome, gpu) ---
                    cp ${../installer/calamares/config/modules}/*.conf $out/etc/calamares/modules/
                    # --- settings.conf: sequence bamos (welcome→…→GPU→partition; không tạo
                    #     user trong chroot — user do configuration.nix tạo ở lần boot đầu) ---
                    cat > $out/etc/calamares/settings.conf <<EOF
          modules-search: [ local, $out/lib/calamares/modules ]

          instances:
          - id: gpu
            module: packagechooser
            config: gpu.conf

          sequence:
          - show:
            - welcome
            - locale
            - keyboard
            - users
            - packagechooser@gpu
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

      # Fix DPI/font Calamares quá nhỏ (như GLF-OS patch autostart):
      #   QT_SCALE_FACTOR=1.5 + tắt auto-scale → UI to, dễ đọc, ổn định.
      makeAutostartItem =
        args:
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

  # LiveCD cần flakes để chạy nixos-install --flake
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # ==== ISO ====
  isoImage = {
    appendToMenuLabel = " Bamos Installer";
    volumeID = "BAMOS-INSTALL";
    # Nén squashfs tối đa cho ISO (bản dev có thể hạ level 1 cho nhanh)
    squashfsCompression = "zstd -Xcompression-level 12";
    # Nhúng iso-cfg/ (flake cho /etc/nixos máy đích) vào gốc squashfs → trên
    # LiveCD nằm ở /iso-cfg — module nixos của Calamares copy từ đây.
    contents = [
      {
        source = ../iso-cfg;
        target = "/iso-cfg";
      }
    ];
    storeContents = [ config.system.build.toplevel ];
  };
}

# bamos installer
