# Description: Systemd services cập nhật hệ thống & thông báo thất bại
{ pkgs, ... }:

{
  environment.etc."bamos/update.sh" = {
    mode = "0755";
    source = ../update/update.sh;
  };

  environment.etc."bamos/update-notify-failure.sh" = {
    mode = "0755";
    source = ../update/update-notify-failure.sh;
  };

  systemd.services."bamos-update" = {
    description = "Bamos auto-update (tự cập nhật hệ thống từ GitHub)";
    wantedBy = [ ];
    path = with pkgs; [
      bash
      nix
      nixos-rebuild
      coreutils
      gawk
      gnugrep
      gnused
      util-linux
      networkmanager
      libnotify
      shadow
      flatpak
    ];
    onFailure = [ "bamos-update-notify-failure.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "/etc/bamos/update.sh";
      KillMode = "process";
      StandardOutput = "journal";
      StandardError = "journal";
    };
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
  };

  systemd.services."bamos-update-notify-failure" = {
    description = "Thông báo khi bamos-update thất bại ngoài dự kiến";
    path = with pkgs; [
      bash
      libnotify
      shadow
      coreutils
      util-linux
    ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "/etc/bamos/update-notify-failure.sh";
      StandardOutput = "journal";
      StandardError = "journal";
    };
  };
}
