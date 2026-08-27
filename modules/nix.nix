# Cài đặt trình quản lý gói Nix (dọn dẹp tự động).
{ config, lib, ... }:

{
  nix.settings.auto-optimise-store = true;
  nix.gc = { automatic = true; dates = "weekly"; options = "--delete-older-than 7d"; };
}
