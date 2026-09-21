# Description: Developer environment module (Neovim + tmux + gh + direnv + dev CLIs)
# Giữ file này làm entrypoint tương thích ngược cho flake bamos.homeModules.dev và home/lg.nix
{ ... }:

{
  imports = [
    ./dev/default.nix
  ];
}
