# Description: System fonts & cấu hình fontconfig ClearType
{ pkgs, localFonts }:

{
  fonts.packages = [
    localFonts
    pkgs.carlito
    pkgs.caladea
    pkgs.corefonts
    pkgs.vista-fonts
    pkgs.symbola
    pkgs.noto-fonts
  ];

  fonts.fontconfig = {
    hinting.enable = true;
    hinting.style = "full";
    subpixel.rgba = "rgb";
    subpixel.lcdfilter = "default";

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

    localConf = ''
      <fontconfig>
        <match target="pattern">
          <test qual="any" name="family"><string>Segoe UI</string></test>
          <edit name="family" mode="prepend" binding="same"><string>Inter</string></edit>
        </match>
        <match target="pattern">
          <test qual="any" name="family"><string>Tahoma</string></test>
          <edit name="family" mode="prepend" binding="same"><string>Verdana</string></edit>
        </match>
      </fontconfig>
    '';
  };
}
