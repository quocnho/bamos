# Profile GAMING — Dành cho game thủ (Gaming)
# Kế thừa profile desktop + bật Steam, GameMode, MangoHud, tối ưu hóa sysctl
{ config, lib, ... }:

{
  imports = [ ./desktop.nix ];

  # Bật gaming profile
  my.gaming.enable = true;
}
