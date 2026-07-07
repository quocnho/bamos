# modules/editions/gaming.nix
{ pkgs, lib, ... }: {
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };
  programs.gamemode.enable = true;
  programs.gamescope.enable = true;
  environment.systemPackages = with pkgs; [
    # Gaming runtime
    mangohud
    lutris
    heroic
    protonup-ng
    # Streaming
    obs-studio
    discord
    # Controllers
    antimicrox
  ];
  # Kernel XanMod (chỉ override nếu edition gaming)
  boot.kernelPackages = lib.mkIf true pkgs.linuxPackages_xanmod;
}
