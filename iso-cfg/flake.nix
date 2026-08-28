# Bamos — flake CƠ BẢN được Calamares copy vào /etc/nixos của máy đích
# (từ /iso-cfg trên LiveCD — xem profiles/installer.nix isoImage.contents).
#
# Toàn bộ cấu hình (modules, profiles) được kéo từ github.com/quocnho/bamos
# qua input `bamos` — máy đích KHÔNG cần tự quản lý config, chỉ cần:
#   sudo nix flake update --flake /etc/nixos
#   sudo nixos-rebuild switch --flake /etc/nixos#bamos
#
# /etc/nixos/configuration.nix do Calamares sinh (user/hostname/hardware).
# Thêm cấu hình riêng của máy vào ./customConfig/default.nix (không đụng repo).
{
  description = "Bamos — NixOS (config kéo từ github.com/quocnho/bamos)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    bamos.url = "github:quocnho/bamos";
    # Dùng chung 1 nixpkgs với bamos → tránh closure chồng chéo
    bamos.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      bamos,
      ...
    }:
    let
      system = "x86_64-linux";
    in
    {
      nixosConfigurations.bamos = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./configuration.nix
          ./customConfig
          bamos.profiles.desktop
        ];
      };
    };
}

# bamos installer
