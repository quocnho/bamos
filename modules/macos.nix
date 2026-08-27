# Giao diện GNOME giống macOS nhất (đã tìm hiểu trên không gian mạng):
# WhiteSur GTK theme (vinceliuice — "A macOS like theme for Linux GTK
# Desktops", ~9.2k★ — theme macOS phổ biến nhất, kèm khuyến nghị bộ
# user-themes + dash-to-dock + blur-my-shell) + WhiteSur icons/cursors
# + font Inter (gần giống SF Pro) + dock/menu/panel cách điệu kiểu macOS.
#
# Các extension cần cho giao diện này (dash-to-dock, arcmenu, blur-my-shell)
# được cài + bật trong modules/gnome.nix — module này chỉ lo phần "diện mạo".
{ config, lib, pkgs, ... }:

let
  cfg = config.my.macos;
in
{
  options.my.macos = {
    enable = lib.mkEnableOption "GNOME macOS-like appearance (WhiteSur)";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      whitesur-gtk-theme   # theme GTK kiểu macOS (Big Sur)
      whitesur-icon-theme  # icon kiểu macOS Big Sur
      whitesur-cursors     # con trỏ kiểu macOS
    ];

    programs.dconf.profiles.user.databases = [{
      settings = {
        # Nút cửa sổ kiểu macOS: traffic lights nằm bên TRÁI
        "org/gnome/desktop/wm/preferences" = {
          button-layout = "close,minimize,maximize:";
        };

        "org/gnome/desktop/interface" = {
          gtk-theme = "WhiteSur-Dark-solid";
          icon-theme = "WhiteSur-dark";
          cursor-theme = "WhiteSur-cursors";
          font-name = "Inter 11";
          document-font-name = "Inter 11";
          monospace-font-name = "JetBrainsMono Nerd Font Mono 11";
        };

        # Wallpaper macOS (file cục bộ trong assets/ — cài vào /etc/wallpapers)
        "org/gnome/desktop/background" = {
          color-shading-type = "solid";
          picture-options = "zoom";
          picture-uri = "file:///etc/wallpapers/macos-monterey-dark.jpg";
          picture-uri-dark = "file:///etc/wallpapers/macos-monterey-dark.jpg";
        };

        # Dock macOS: trong suốt, icon ở giữa, không tràn hết màn hình
        "org/gnome/shell/extensions/dash-to-dock" = {
          transparency-mode = "FIXED";
          background-opacity = 0.65;
          height-fraction = 0.75;
          extend-height = false;
        };

        # Menu ứng dụng kiểu Big Sur (bấm biểu tượng trên panel)
        "org/gnome/shell/extensions/arcmenu" = {
          menu-layout = "bigsur";
        };

        # Panel (thanh trên cùng) mờ như macOS
        "org/gnome/shell/extensions/blur-my-shell" = {
          panel = true;
        };
      };
    }];
  };
}
