# Description: Cấu hình đồng bộ cấu hình Zed Editor
{ pkgs, ... }:

{
  systemd.user.services.zed-settings = {
    Unit = {
      Description = "Zed: đồng bộ settings/keymap/skills từ assets/zed";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${pkgs.python3}/bin/python3 ${../../assets/zed/sync.py} ${../../assets/zed}";
    };
    Install = {
      WantedBy = [ "default.target" ];
    };
  };
}
