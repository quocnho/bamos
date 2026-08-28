# Profile INSTALLER — LiveCD cài bamos cho người dùng khác (dùng Calamares).
#
# Tham khảo sâu GLF-OS (framagit.org/gaming-linux-fr/glf-os):
#   - ISO: nixpkgs installation-cd-graphical-calamares-gnome.nix (GNOME LiveCD
#     + calamares autostart + pkexec passwordless cho wheel).
#   - Installer: Calamares + module "nixos" (calamares-nixos-extensions) —
#     override để: sinh configuration.nix (user/hostname), copy flake mẫu
#     (input bamos = github:quocnho/bamos) vào /etc/nixos máy đích, pre-lock
#     flake.lock, rồi nixos-install --flake <root>/etc/nixos#bamos.
#   - Các file Calamares nằm ở installer/calamares/{modules,config}.
{
  config,
  lib,
  pkgs,
  ...
}:

{
  # Override calamares-nixos-extensions: thay module nixos + cấu hình bamos,
  # dùng `prev` (bản gốc chưa overlay) để tránh đệ quy.
  # (settings.conf được sinh kèm $out vì modules-search phải trỏ đúng store path)
  nixpkgs.overlays = [
    (final: prev: {
      calamares-nixos-extensions = prev.calamares-nixos-extensions.overrideAttrs (old: {
        postInstall = (old.postInstall or "") + ''
                    # --- module nixos (sinh config + nixos-install --flake) ---
                    cp ${../installer/calamares/modules/nixos/main.py} $out/lib/calamares/modules/nixos/main.py
                    # --- cấu hình từng module (partition, users, welcome) ---
                    cp ${../installer/calamares/config/modules}/*.conf $out/etc/calamares/modules/
                    # --- settings.conf: sequence bamos (bỏ packagechooser/unfree, không tạo
                    #     user trong chroot — user do configuration.nix tạo ở lần boot đầu) ---
                    cat > $out/etc/calamares/settings.conf <<EOF
          modules-search: [ local, $out/lib/calamares/modules ]

          sequence:
          - show:
            - welcome
            - locale
            - keyboard
            - users
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
    # Nhúng toàn bộ thư mục installer/ vào gốc squashfs → trên LiveCD nằm ở
    # /installer (flake.nix cho máy đích + calamares configs)
    contents = [
      {
        source = ../installer;
        target = "/installer";
      }
    ];
    storeContents = [ config.system.build.toplevel ];
  };
}
