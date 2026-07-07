# modules/editions/developers.nix
{ pkgs, ... }: {
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
