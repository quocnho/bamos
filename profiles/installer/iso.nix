# Description: Cấu hình ISO image (squashfs, menu label, iso-cfg contents)
{ config, lib, ... }:

{
  image.baseName = lib.mkForce "bamos-gnome-26.11-x86_64-linux";

  isoImage = {
    appendToMenuLabel = " Bamos Installer";
    volumeID = "BAMOS-INSTALL";
    squashfsCompression = "zstd -Xcompression-level 12";
    contents = [
      {
        source = ../../iso-cfg;
        target = "/iso-cfg";
      }
    ];
    storeContents = [ config.system.build.toplevel ];
  };
}
