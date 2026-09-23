# Cài đặt trình quản lý gói Nix (dọn dẹp tự động) + khả năng chạy binary ngoài.
{
  config,
  lib,
  pkgs,
  ...
}:

{
  nix.settings.auto-optimise-store = true;
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };

  # Bật sẵn tính năng thử nghiệm cần thiết cho MỌI máy BamOS:
  #   nix-command → nix build/eval/store... (bam CLI, ISO builder)
  #   flakes      → nixos-rebuild --flake, nix flake update (máy đích kéo config từ GitHub)
  # (NixOS 23.11+ đã bật mặc định, nhưng khai báo tường minh để chắc chắn hệ thống
  #  mới lẫn cũ đều dùng được lệnh `nix ...` không cần cờ --extra-experimental-features.)
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Binary Cache cho BamOS Apps (bam-customizer, ...)
  nix.settings.substituters = [
    "https://cache.nixos.org"
    "https://bamos.cachix.org"
  ];
  nix.settings.trusted-public-keys = [
    "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    "bamos.cachix.org-1:Q3aY2G0xWk+z4w9wV2iO3u4dKjN/7k/p6Y1uI=" # cachix public key placeholder
  ];

  # nix-ld: cho phép chạy các binary động (prebuilt cho Linux thường) trên NixOS.
  # Cần cho `uv` (Python do uv tự quản lý) và nhiều binary vendor khác.
  # (GLF-OS cũng bật tùy chọn này — xem modules/default/system.nix của họ.)
  programs.nix-ld.enable = true;
}
