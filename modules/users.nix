# Người dùng hệ thống.
{ config, lib, pkgs, ... }:

{
  users.users.quocnho = {
    isNormalUser = true;
    description = "quocnho";
    extraGroups = [ "networkmanager" "wheel" "video" "podman" "input" ];
    initialPassword = "j";
    shell = pkgs.zsh;
  };
}
