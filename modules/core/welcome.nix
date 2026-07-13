# modules/core/welcome.nix
# BamOS Welcome Banner — hiển thị khi mở terminal
# Cung cấp: thông tin hệ thống, bam CLI guide, update notification
#
{ config, lib, pkgs, ... }:

let
  welcomePkg = pkgs.bam-welcome;
  inherit (lib) mkIf mkOption types;
  cfg = config.bamos.welcome;
in
{
  options.bamos.welcome = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Hiển thị BamOS welcome banner khi mở terminal";
    };
  };

  config = mkIf cfg.enable {
    # Install welcome banner package
    environment.systemPackages = [ welcomePkg ];

    # Bash: chạy welcome banner khi mở terminal tương tác
    programs.bash.interactiveShellInit = ''
      # BamOS Welcome Banner
      if command -v bam-welcome &>/dev/null; then
        bam-welcome
      fi
    '';

    # Zsh: chạy welcome banner khi mở terminal tương tác
    programs.zsh.interactiveShellInit = ''
      # BamOS Welcome Banner
      if command -v bam-welcome &>/dev/null; then
        bam-welcome
      fi
    '';
  };
}
