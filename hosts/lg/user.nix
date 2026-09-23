# Description: Khai báo người dùng quocnho cho host LG
{ pkgs, ... }:

{
  users.users.quocnho = {
    isNormalUser = true;
    description = "quocnho";
    extraGroups = [
      "networkmanager"
      "wheel"
      "bluetooth"
      "input"
      "video"
      "audio"
      "render"
      "disk"
      "storage"
      "lp"
      "scanner"
      "power"
      "podman"
    ];
    initialPassword = "j";
    shell = pkgs.zsh;
  };
}
