# Description: Aggregator module cho Developer Environment (Neovim, Tmux, Zed, Dev Tools)
{ ... }:

{
  imports = [
    ./nvim.nix
    ./tmux.nix
    ./zed.nix
    ./tools.nix
  ];
}
