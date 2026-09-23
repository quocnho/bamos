# Socle modulaire của BamOS.
# Tự động sinh options `bam.profile` và `bam.features.<groupe>[.apps.<app>].enable`
# từ ./catalog.nix và xuất ra /etc/bam/customizer/catalog.json cho Bam Customizer.

{
  config,
  lib,
  pkgs,
  ...
}:

let
  catalog = import ./catalog.nix;

  profileNames = builtins.attrNames catalog.profiles;
  currentProfile = config.bam.profile or "standard";
  activeGroups = catalog.profiles.${currentProfile} or [ ];

  appOverrides = catalog.profileAppOverrides.${currentProfile} or { };
  appDefault = groupName: appName: appOverrides.${groupName}.${appName} or true;

  catalogJson = pkgs.writeText "bam-customizer-catalog.json" (builtins.toJSON catalog);

  mkGroupOptions =
    groupName: group:
    {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = lib.elem groupName activeGroups;
        defaultText = lib.literalMD "kích hoạt khi nhóm nằm trong profile hiện tại (`bam.profile`)";
        description = "Bật/tắt nhóm tính năng ${group.label.vi or groupName}.";
      };
    }
    // lib.optionalAttrs (group ? apps) {
      apps = lib.mapAttrs (appName: app: {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = config.bam.features.${groupName}.enable && appDefault groupName appName;
          defaultText = lib.literalMD "theo trạng thái nhóm `bam.features.${groupName}.enable`";
          description = "Bật/tắt ứng dụng ${app.label.vi or appName}.";
        };
      }) group.apps;
    };
in
{
  options.bam.profile = lib.mkOption {
    type = lib.types.enum profileNames;
    default = "standard";
    description = ''
      Profile cài đặt của BamOS: preset các nhóm tính năng `bam.features.*`.
      Các module vẫn có thể được bật/tắt riêng lẻ qua Bam Customizer.
    '';
  };

  options.bam.features = lib.mapAttrs mkGroupOptions catalog.groups;

  config = {
    # Xuất catalogue JSON cho ứng dụng bam-customizer đọc
    environment.etc."bam/customizer/catalog.json".source = catalogJson;
  };
}
