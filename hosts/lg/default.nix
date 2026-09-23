# Host "lg" — LG laptop (Intel UHD CometLake + NVIDIA GTX 1650) (< 65 dòng)
{ ... }:

{
  imports = [
    ../../profiles/desktop.nix
    ../../hardware-configuration.nix
    ./user.nix
  ];

  networking.hostName = "lg";
  networking.hosts."127.0.0.1" = [ "quocnho.test" ];

  boot.kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = 0;

  # ==== Cấu hình riêng cho máy LG ====
  my.dev.enable = true;
  my.gpu.enable = true;
  my.gpu.intelBusId = "PCI:0:2:0";
  my.gpu.nvidiaBusId = "PCI:2:0:0";

  my.power.enable = true;
  boot.loader.timeout = 0;
  my.boot.kernel = "latest";
  my.studio.enable = true;
  my.gnome.store = false;

  services.journald.settings.Journal = {
    SystemMaxUse = "400M";
    SystemMaxFileSize = "50M";
  };

  system.stateVersion = "25.11";
}
