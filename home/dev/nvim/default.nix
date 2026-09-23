# Description: Entrypoint cấu hình Neovim (< 40 dòng)
# Tham khảo: ray-x/nvim + LazyVim
{ pkgs, ... }:

let
  customPlugins = import ./custom-plugins.nix { inherit pkgs; };
  plugins = import ./plugins.nix { inherit pkgs customPlugins; };
  extraPackages = import ./extra-packages.nix { inherit pkgs; };
in
{
  imports = [ ./links.nix ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
    withPython3 = false;
    withRuby = false;

    inherit plugins extraPackages;

    initLua = ''
      require("bamos")
    '';
  };
}
