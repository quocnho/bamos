# Description: Các công cụ git, lazygit, direnv và dev CLI packages
{ pkgs, ... }:

{
  # Git tools
  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
  };

  programs.lazygit = {
    enable = true;
  };

  # Direnv
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
  };

  # Dev CLI packages
  home.packages = with pkgs; [
    git-lfs
    just
    ghq
    # ---- BỘ MỞ RỘNG — bỏ comment khi cần ----
    # docker-compose
    # httpie
    # kubectl
    # helm
    # terraform
    # awscli2
    # google-cloud-sdk
    # sqlite
    # postgresql
    # redis
  ];
}
