# Ngôn ngữ và bộ gõ. (Fonts đã chuyển sang modules/assets.nix — offline.)
{ config, lib, pkgs, ... }:

{
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [ qt6Packages.fcitx5-unikey ];
  };
}
