{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    curl
    git
    fzf
    ripgrep
    vim
    zed-editor
    bluez
    nil
    nixpkgs-fmt
    nixd
  ];
}
