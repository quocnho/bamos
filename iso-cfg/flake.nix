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
    # ★ ref MAIN — không bỏ phần /main: default branch trên GitHub vẫn là
    #   master (cũ) nên `github:quocnho/bamos` (không ref) sẽ trỏ nhầm.
    #   (GitHub shorthand: github:owner/repo/branch — tương đương ?ref=main;
    #    flake.lock sẽ pin chính xác commit, không fetch cả branch mỗi lần.)
    bamos.url = "github:quocnho/bamos/main";
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
