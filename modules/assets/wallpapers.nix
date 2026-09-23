# Description: Wallpapers hệ thống & hình nền đăng nhập GDM
{ ... }:

{
  environment.etc = {
    "wallpapers/macos-monterey-dark.jpg".source = ../../assets/images/macos-monterey-dark.jpg;
    "wallpapers/macos-monterey-light.jpg".source = ../../assets/images/macos-monterey-light.jpg;
    "wallpapers/macos-whitesur-dark.jpg".source = ../../assets/images/macos-whitesur-dark.jpg;
  };

  programs.dconf.profiles.gdm.databases = [
    {
      settings = {
        "org/gnome/desktop/background" = {
          picture-uri = "file:///etc/wallpapers/macos-monterey-dark.jpg";
          picture-options = "zoom";
        };
      };
    }
  ];
}
