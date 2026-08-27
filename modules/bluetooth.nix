# Bluetooth.
{ config, lib, ... }:

{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
  };
}
