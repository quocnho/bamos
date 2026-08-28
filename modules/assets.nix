# Tài nguyên cục bộ (offline): fonts + wallpaper.
# Toàn bộ nằm trong ./assets — không phụ thuộc tải từ internet khi build.
{
  config,
  lib,
  pkgs,
  ...
}:

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
    fonts.packages = [
      localFonts
      pkgs.carlito # thay thế Calibri (metric-compatible, free)
      pkgs.caladea # thay thế Cambria (metric-compatible, free)
      pkgs.corefonts # MS Core Fonts thật: Arial, Times New Roman, Verdana, Georgia, Trebuchet, Impact, Comic Sans, Courier New
      pkgs.vista-fonts # Calibri, Cambria, Consolas, Candara, Constantia, Corbel (bản thật — EULA MS, đã allowUnfree)
      pkgs.symbola # font SYMBOL: fix ô vuông ☺☻ (WPS Office / LibreOffice / văn bản có ký tự đặc biệt)
      pkgs.noto-fonts # bộ font Noto (coverage rộng, có tiếng Việt) — fallback văn bản đa ngôn ngữ
    ];

    # ==== Rendering font kiểu Windows (ClearType) ====
    # Mặc định GNOME/Linux dùng grayscale AA + hinting medium → chữ "nhạt nhẽo",
    # kém đậm nét hơn Windows (subpixel RGB + full hinting + lcd filter).
    # LƯU Ý: subpixel chỉ hợp màn hình LCD thường; nếu dùng OLED/hiDPI >150%
    # mà thấy viền màu → đổi font-antialiasing trong gnome.nix về "grayscale".
    fonts.fontconfig = {
      hinting.enable = true;
      hinting.style = "full"; # giống Windows: nét chữ bám pixel grid
      subpixel.rgba = "rgb"; # subpixel AA kiểu ClearType
      subpixel.lcdfilter = "default";

      # Thứ tự font cho generic family (web/GTK không khai báo font cụ thể)
      defaultFonts = {
        sansSerif = [
          "Inter"
          "Liberation Sans"
          "DejaVu Sans"
        ];
        serif = [
          "Liberation Serif"
          "DejaVu Serif"
        ];
        monospace = [
          "JetBrainsMono Nerd Font Mono"
          "FiraCode Nerd Font Mono"
          "Liberation Mono"
        ];
      };

      # Alias cho font Windows không có bản miễn phí → font gần nhất.
      # (fontconfig 30-metric-aliases đã lo: Arial→Liberation Sans,
      #  Times New Roman→Liberation Serif, Calibri→Carlito, Cambria→Caladea)
      localConf = ''
        <fontconfig>
          <!-- Segoe UI (Win10/11) → Inter: font UI hệ thống, cùng phong cách -->
          <match target="pattern">
            <test qual="any" name="family"><string>Segoe UI</string></test>
            <edit name="family" mode="prepend" binding="same"><string>Inter</string></edit>
          </match>
          <!-- Tahoma → Verdana (không có bản free; Verdana gần nhất, có trong corefonts) -->
          <match target="pattern">
            <test qual="any" name="family"><string>Tahoma</string></test>
            <edit name="family" mode="prepend" binding="same"><string>Verdana</string></edit>
          </match>
        </fontconfig>
      '';
    };

    # Wallpaper cài vào /etc/wallpapers (luôn có, không cần mạng)
    environment.etc = {
      "wallpapers/macos-monterey-dark.jpg".source = ../assets/images/macos-monterey-dark.jpg;
      "wallpapers/macos-monterey-light.jpg".source = ../assets/images/macos-monterey-light.jpg;
      "wallpapers/macos-whitesur-dark.jpg".source = ../assets/images/macos-whitesur-dark.jpg;
    };

    # Nền màn hình đăng nhập (GDM) dùng wallpaper macOS — cũng offline
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
  };
}
