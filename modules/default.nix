# Aggregator: gom tất cả module NixOS DÙNG CHUNG của hệ thống.
# Bật/tắt từng module qua option `my.<module>.enable` ở host/profile.
#
# LƯU Ý: modules/users.nix (user "quocnho") KHÔNG nằm ở đây — nó được
# import riêng trong hosts/lg.nix để máy khác (cài qua ISO) tự tạo user.
{
  imports = [
    ./boot.nix
    ./gpu.nix
    ./power.nix
    ./audio.nix
    ./gnome.nix
    ./macos.nix
    ./assets.nix
    ./i18n.nix
    ./shell.nix
    ./packages.nix
    ./dev.nix
    ./update.nix
    ./bluetooth.nix
    ./virtualisation.nix
    ./nix.nix
  ];
}

# bamos installer
