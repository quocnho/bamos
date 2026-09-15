# default.nix — Cung cấp khả năng tương thích ngược cho lệnh `nix-build` cổ điển
# Dự án BamOS sử dụng Nix Flakes làm chuẩn. File này ủy quyền vào Flake hoặc gọi trực tiếp package.
let
  flake = builtins.getFlake (toString ./.);
  pkgs = import <nixpkgs> {};
in
{
  # Các gói phần mềm
  assistant = flake.packages.${pkgs.system}.assistant or (pkgs.callPackage ./pkgs/assistant {});
  troly = flake.packages.${pkgs.system}.troly or (pkgs.callPackage ./pkgs/troly {});
  bam = flake.packages.${pkgs.system}.bam or (pkgs.callPackage ./pkgs/bam {});

  # Mặc định build assistant khi chạy `nix-build` không tham số
  default = flake.packages.${pkgs.system}.assistant or (pkgs.callPackage ./pkgs/assistant {});
}
