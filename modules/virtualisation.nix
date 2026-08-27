# Ảo hóa (podman) & zram.
{ config, lib, ... }:

{
  virtualisation.podman.enable = true;
  virtualisation.podman.dockerCompat = true;
  zramSwap.enable = true;
}
