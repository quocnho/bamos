# Tài nguyên cục bộ (offline): fonts + wallpaper.
# Toàn bộ nằm trong ./assets — không phụ thuộc tải từ internet khi build.
{ config, lib, pkgs, ... }:

let
  cfg = config.my.assets;
  localFonts = pkgs.callPackage ../assets/fonts/fonts.nix { };
in
{
  options.my.assets = {
    enable = lib.mkEnableOption "local assets (fonts + wallpapers, offline)";
  };

  config = lib.mkIf cfg.enable {
    # Font cục bộ thay thế nerd-fonts/inter từ nixpkgs
    fonts.packages = [ localFonts ];

    # Wallpaper cài vào /etc/wallpapers (luôn có, không cần mạng)
    environment.etc = {
      "wallpapers/macos-monterey-dark.jpg".source = ../assets/images/macos-monterey-dark.jpg;
      "wallpapers/macos-monterey-light.jpg".source = ../assets/images/macos-monterey-light.jpg;
      "wallpapers/macos-whitesur-dark.jpg".source = ../assets/images/macos-whitesur-dark.jpg;
    };

    # Nền màn hình đăng nhập (GDM) dùng wallpaper macOS — cũng offline
    programs.dconf.profiles.gdm.databases = [{
      settings = {
        "org/gnome/desktop/background" = {
          picture-uri = "file:///etc/wallpapers/macos-monterey-dark.jpg";
          picture-options = "zoom";
        };
      };
    }];
  };
}
