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

    # Home-manager — quản lý cấu hình NGƯỜI DÙNG ($HOME) trên máy đích
    # (dùng chung nixpkgs với hệ thống → useGlobalPkgs)
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      bamos,
      home-manager,
      ...
    }:
    let
      system = "x86_64-linux";

      # Dò trước danh sách user THƯỜNG (isNormalUser) để gắn home-manager.
      # Dùng probe NHỎ (chỉ configuration.nix — user duy nhất do Calamares ghi ở
      # đây) chứ KHÔNG đọc config.users.users ngay trong module set: làm vậy sẽ
      # recursion với useUserPackages (home-manager #594).
      userProbe = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          bamos.nixosModules.default
          ./configuration.nix
        ];
      };
      normalUsers = builtins.attrNames (
        nixpkgs.lib.filterAttrs (_: u: u.isNormalUser) userProbe.config.users.users
      );
    in
    {
      nixosConfigurations.bamos = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = { inherit bamos; };
        modules = [
          ./configuration.nix
          ./customConfig
          bamos.profiles.desktop

          # ---- Home-manager: áp cho MỌI user thường (user do Calamares tạo) ----
          # home.username/homeDirectory tự suy từ users.users.<tên> (NixOS module)
          # → không cần khai báo tên user trong home config.
          home-manager.nixosModules.home-manager
          {
            home-manager = {
              useGlobalPkgs = true; # dùng chung nixpkgs với hệ thống
              useUserPackages = true; # gói user vào ~/.nix-profile
              backupFileExtension = "hm-bak"; # file $HOME trùng tên → backup thay vì lỗi
              users = nixpkgs.lib.genAttrs normalUsers (name: {
                imports = [
                  bamos.homeModules.default # cấu hình dùng chung từ repo (home/)
                  ./customConfig/home.nix # phần riêng của máy (user tự sửa)
                ];
              });
            };
          }
        ];
      };
    };
}

# bamos installer
