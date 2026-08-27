# Aggregator: gom tất cả module NixOS của hệ thống.
# Bật/tắt từng module qua option `my.<module>.enable` trong configuration.nix.
{
  imports = [
    ./boot.nix
    ./gpu.nix
    ./power.nix
    ./gnome.nix
    ./users.nix
    ./i18n.nix
    ./shell.nix
    ./packages.nix
    ./bluetooth.nix
    ./virtualisation.nix
    ./nix.nix
  ];
}
