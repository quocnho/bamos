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

  # nix-ld: cho phép chạy các binary động (prebuilt cho Linux thường) trên NixOS.
  # Cần cho `uv` (Python do uv tự quản lý) và nhiều binary vendor khác.
  # (GLF-OS cũng bật tùy chọn này — xem modules/default/system.nix của họ.)
  programs.nix-ld.enable = true;
}
