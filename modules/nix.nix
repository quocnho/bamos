# Cài đặt trình quản lý gói Nix (dọn dẹp tự động) + khả năng chạy binary ngoài.
{ config, lib, pkgs, ... }:

{
  nix.settings.auto-optimise-store = true;
  nix.gc = { automatic = true; dates = "weekly"; options = "--delete-older-than 7d"; };

  # nix-ld: cho phép chạy các binary động (prebuilt cho Linux thường) trên NixOS.
  # Cần cho `uv` (Python do uv tự quản lý) và nhiều binary vendor khác.
  # (GLF-OS cũng bật tùy chọn này — xem modules/default/system.nix của họ.)
  programs.nix-ld.enable = true;
}
