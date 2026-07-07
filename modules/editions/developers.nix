# modules/editions/developers.nix
{ pkgs, lib, ... }: {
  # tuned profile: throughput-performance — tối ưu cho build code
  bamos.power-management.profile = lib.mkDefault "throughput-performance";

  environment.systemPackages = with pkgs; [
    devenv
    podman
    podman-compose
    distrobox
    vscode
    gh
  ];
  virtualisation.podman.enable = true;
}
