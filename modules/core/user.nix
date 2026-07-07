# modules/user.nix
# Default system user cho BamOS
# Có thể override qua bamos.user.* options
{ config, lib, ... }:

let
  inherit (lib) types mkOption mkIf;
  cfg = config.bamos.user;
in
{
  options.bamos.user = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Tạo user mặc định cho BamOS";
    };
    name = mkOption {
      type = types.str;
      default = "bamos";
      description = "Tên user mặc định";
    };
    description = mkOption {
      type = types.str;
      default = "BamOS for Vietnamese";
      description = "Mô tả user (thường là tên đầy đủ)";
    };
    extraGroups = mkOption {
      type = types.listOf types.str;
      default = [ "networkmanager" "wheel" ];
      description = "Extra groups cho user";
    };
  };

  config = mkIf cfg.enable {
    users.users.${cfg.name} = {
      isNormalUser = true;
      description = cfg.description;
      extraGroups = cfg.extraGroups;
    };
  };
}
