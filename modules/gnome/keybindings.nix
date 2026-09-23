# Description: Phím tắt tùy biến cho GNOME
{ ... }:

{
  programs.dconf.profiles.user.databases = [
    {
      settings = {
        "org/gnome/desktop/wm/keybindings" = {
          switch-to-workspace-left = [ "<Control><Super>Left" ];
          switch-to-workspace-right = [ "<Control><Super>Right" ];
          switch-applications = [
            "<Super>Tab"
            "<Alt>Tab"
          ];
        };
      };
    }
  ];
}
