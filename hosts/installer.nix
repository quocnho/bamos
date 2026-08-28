# Host "installer" — ISO LiveCD cài bamos cho người dùng khác.
# flake.nix chồng thêm module installation-cd-minimal.nix của nixpkgs
# (console ISO) + profile installer (isoImage, dialog, autologin root).
{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [ ../profiles/installer.nix ];
}
