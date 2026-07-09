# pkgs/bamos-branding/default.nix
# BamOS branding package — logos, wallpapers, GNOME background properties
#
# Package này quyết định những gì xuất hiện trong:
#   1. ISO live environment (khi build ISO)
#   2. Hệ thống đã cài đặt (sau khi Calamares copy config)
#
# Logo design: Bamboo hexagonal mosaic (6 segments)
# "Cây tre trăm đốt" — mỗi đốt tre là một module Nix
#
{ lib, stdenvNoCC, }:

stdenvNoCC.mkDerivation {
  pname = "bamos-branding";
  version = "1.0.0";

  src = ../../assets;

  installPhase = ''
        # ═══════════════════════════════════════════════════════════
        # LOGO — Bamboo hexagonal mosaic
        # ═══════════════════════════════════════════════════════════
        # SVG (primary)
        mkdir -p $out/share/icons/hicolor/scalable/apps
        cp $src/logo/bamos-logo.svg $out/share/icons/hicolor/scalable/apps/bamos-logo.svg
        cp $src/logo/bamos-logo-nav.svg $out/share/icons/hicolor/scalable/apps/bamos-logo-nav.svg

        # PNG logos — dark (reference)
        for SIZE in 16 32 48 64 128 256; do
          mkdir -p $out/share/icons/hicolor/''${SIZE}x''${SIZE}/apps

          # Dark logo (fallback: SVG symlink)
          if [ -f "$src/logo/ref/bamos-''${SIZE}.png" ]; then
            cp $src/logo/ref/bamos-''${SIZE}.png \
              $out/share/icons/hicolor/''${SIZE}x''${SIZE}/apps/bamos-logo.png
          else
            # Fallback: symlink to SVG
            ln -sf $out/share/icons/hicolor/scalable/apps/bamos-logo.svg \
              $out/share/icons/hicolor/''${SIZE}x''${SIZE}/apps/bamos-logo.png
          fi
        done

        # Light logo PNGs (cho dark background)
        for SIZE in 16 32 48 64 128 256; do
          mkdir -p $out/share/icons/hicolor/''${SIZE}x''${SIZE}/emblems
          if [ -f "$src/logo/ref/bamos-light-''${SIZE}.png" ]; then
            cp $src/logo/ref/bamos-light-''${SIZE}.png \
              $out/share/icons/hicolor/''${SIZE}x''${SIZE}/emblems/bamos-logo-light.png
          fi
        done

        # ═══════════════════════════════════════════════════════════
        # WALLPAPERS — tất cả background choices
        # ═══════════════════════════════════════════════════════════
        mkdir -p $out/share/backgrounds/gnome

        # Core default wallpapers (BamOS designed)
        cp $src/wallpapers/bamos-default.svg    $out/share/backgrounds/gnome/bamos-default.svg
        cp $src/wallpapers/bamos-default-dark.svg $out/share/backgrounds/gnome/bamos-default-dark.svg

        # Reference wallpapers (có sẵn để chọn trong GNOME Settings → Background)
        for wp in \
          bamos-dalle bamos-dalle-dark \
          bamos-frost-2 bamos-frost-2-dark \
          bamos-frost-4 bamos-frost-4-dark \
          bamos-frost-5 bamos-frost-5-dark \
          bamos-frost-phoenix bamos-frost-phoenix-dark \
          bamos-gaming-light bamos-gaming-dark \
          bamos-leather bamos-leather-dark \
          bamos-mini-light bamos-mini-dark \
          bamos-quasar-light bamos-quasar-dark \
          bamos-solid-light bamos-solid-dark \
          bamos-studio-light bamos-studio-dark \
          bamos-vintage bamos-vintage-dark; do
          if [ -f "$src/wallpapers/ref/$wp.png" ]; then
            cp "$src/wallpapers/ref/$wp.png" "$out/share/backgrounds/gnome/$wp.png"
          fi
          if [ -f "$src/wallpapers/ref/$wp.jpg" ]; then
            cp "$src/wallpapers/ref/$wp.jpg" "$out/share/backgrounds/gnome/$wp.jpg"
          fi
        done

        # ═══════════════════════════════════════════════════════════
        # GNOME BACKGROUND PROPERTIES — để GNOME Settings phát hiện
        # ═══════════════════════════════════════════════════════════
        mkdir -p $out/share/gnome-background-properties

        # 1. BamOS Default
        cat > $out/share/gnome-background-properties/bamos-default.xml << XML
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE wallpapers SYSTEM "gnome-wp-list.dtd">
    <wallpapers>
      <wallpaper deleted="false">
        <name>BamOS Mặc định</name>
        <filename>/run/current-system/sw/share/backgrounds/gnome/bamos-default.svg</filename>
        <filename-dark>/run/current-system/sw/share/backgrounds/gnome/bamos-default-dark.svg</filename-dark>
        <options>zoom</options>
        <shade_type>solid</shade_type>
        <pcolor>#1a1a2e</pcolor>
        <scolor>#000000</scolor>
      </wallpaper>
    </wallpapers>
    XML

        # 2. Dalle
        cat > $out/share/gnome-background-properties/bamos-dalle.xml << XML
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE wallpapers SYSTEM "gnome-wp-list.dtd">
    <wallpapers>
      <wallpaper deleted="false">
        <name>BamOS Dalle</name>
        <filename>/run/current-system/sw/share/backgrounds/gnome/bamos-dalle.png</filename>
        <filename-dark>/run/current-system/sw/share/backgrounds/gnome/bamos-dalle-dark.png</filename-dark>
        <options>zoom</options>
        <shade_type>solid</shade_type>
        <pcolor>#ffffff</pcolor>
        <scolor>#000000</scolor>
      </wallpaper>
    </wallpapers>
    XML

        # 3. Leather
        cat > $out/share/gnome-background-properties/bamos-leather.xml << XML
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE wallpapers SYSTEM "gnome-wp-list.dtd">
    <wallpapers>
      <wallpaper deleted="false">
        <name>BamOS Leather</name>
        <filename>/run/current-system/sw/share/backgrounds/gnome/bamos-leather.png</filename>
        <filename-dark>/run/current-system/sw/share/backgrounds/gnome/bamos-leather-dark.png</filename-dark>
        <options>zoom</options>
        <shade_type>solid</shade_type>
        <pcolor>#ffffff</pcolor>
        <scolor>#000000</scolor>
      </wallpaper>
    </wallpapers>
    XML

        # 4. Vintage
        cat > $out/share/gnome-background-properties/bamos-vintage.xml << XML
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE wallpapers SYSTEM "gnome-wp-list.dtd">
    <wallpapers>
      <wallpaper deleted="false">
        <name>BamOS Vintage</name>
        <filename>/run/current-system/sw/share/backgrounds/gnome/bamos-vintage.png</filename>
        <filename-dark>/run/current-system/sw/share/backgrounds/gnome/bamos-vintage-dark.png</filename-dark>
        <options>zoom</options>
        <shade_type>solid</shade_type>
        <pcolor>#ffffff</pcolor>
        <scolor>#000000</scolor>
      </wallpaper>
    </wallpapers>
    XML

        # 5. Frost Phoenix
        cat > $out/share/gnome-background-properties/bamos-frost-phoenix.xml << XML
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE wallpapers SYSTEM "gnome-wp-list.dtd">
    <wallpapers>
      <wallpaper deleted="false">
        <name>BamOS Frost Phoenix</name>
        <filename>/run/current-system/sw/share/backgrounds/gnome/bamos-frost-phoenix.png</filename>
        <filename-dark>/run/current-system/sw/share/backgrounds/gnome/bamos-frost-phoenix-dark.png</filename-dark>
        <options>zoom</options>
        <shade_type>solid</shade_type>
        <pcolor>#ffffff</pcolor>
        <scolor>#000000</scolor>
      </wallpaper>
    </wallpapers>
    XML

        # 6. Gaming
        cat > $out/share/gnome-background-properties/bamos-gaming.xml << XML
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE wallpapers SYSTEM "gnome-wp-list.dtd">
    <wallpapers>
      <wallpaper deleted="false">
        <name>BamOS Gaming</name>
        <filename>/run/current-system/sw/share/backgrounds/gnome/bamos-gaming-light.png</filename>
        <filename-dark>/run/current-system/sw/share/backgrounds/gnome/bamos-gaming-dark.png</filename-dark>
        <options>zoom</options>
        <shade_type>solid</shade_type>
        <pcolor>#ffffff</pcolor>
        <scolor>#000000</scolor>
      </wallpaper>
    </wallpapers>
    XML

        # 7. Mini
        cat > $out/share/gnome-background-properties/bamos-mini.xml << XML
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE wallpapers SYSTEM "gnome-wp-list.dtd">
    <wallpapers>
      <wallpaper deleted="false">
        <name>BamOS Mini</name>
        <filename>/run/current-system/sw/share/backgrounds/gnome/bamos-mini-light.png</filename>
        <filename-dark>/run/current-system/sw/share/backgrounds/gnome/bamos-mini-dark.png</filename-dark>
        <options>zoom</options>
        <shade_type>solid</shade_type>
        <pcolor>#ffffff</pcolor>
        <scolor>#000000</scolor>
      </wallpaper>
    </wallpapers>
    XML

        # 8. Studio
        cat > $out/share/gnome-background-properties/bamos-studio.xml << XML
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE wallpapers SYSTEM "gnome-wp-list.dtd">
    <wallpapers>
      <wallpaper deleted="false">
        <name>BamOS Studio</name>
        <filename>/run/current-system/sw/share/backgrounds/gnome/bamos-studio-light.png</filename>
        <filename-dark>/run/current-system/sw/share/backgrounds/gnome/bamos-studio-dark.png</filename-dark>
        <options>zoom</options>
        <shade_type>solid</shade_type>
        <pcolor>#ffffff</pcolor>
        <scolor>#000000</scolor>
      </wallpaper>
    </wallpapers>
    XML

        # 9. Quasar
        cat > $out/share/gnome-background-properties/bamos-quasar.xml << XML
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE wallpapers SYSTEM "gnome-wp-list.dtd">
    <wallpapers>
      <wallpaper deleted="false">
        <name>BamOS Quasar</name>
        <filename>/run/current-system/sw/share/backgrounds/gnome/bamos-quasar-light.png</filename>
        <filename-dark>/run/current-system/sw/share/backgrounds/gnome/bamos-quasar-dark.png</filename-dark>
        <options>zoom</options>
        <shade_type>solid</shade_type>
        <pcolor>#ffffff</pcolor>
        <scolor>#000000</scolor>
      </wallpaper>
    </wallpapers>
    XML

        # 10. Solid
        cat > $out/share/gnome-background-properties/bamos-solid.xml << XML
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE wallpapers SYSTEM "gnome-wp-list.dtd">
    <wallpapers>
      <wallpaper deleted="false">
        <name>BamOS Solid</name>
        <filename>/run/current-system/sw/share/backgrounds/gnome/bamos-solid-light.jpg</filename>
        <filename-dark>/run/current-system/sw/share/backgrounds/gnome/bamos-solid-dark.jpg</filename-dark>
        <options>zoom</options>
        <shade_type>solid</shade_type>
        <pcolor>#ffffff</pcolor>
        <scolor>#000000</scolor>
      </wallpaper>
    </wallpapers>
    XML

        # 11. Frost 2
        cat > $out/share/gnome-background-properties/bamos-frost-2.xml << XML
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE wallpapers SYSTEM "gnome-wp-list.dtd">
    <wallpapers>
      <wallpaper deleted="false">
        <name>BamOS Frost 2</name>
        <filename>/run/current-system/sw/share/backgrounds/gnome/bamos-frost-2.png</filename>
        <filename-dark>/run/current-system/sw/share/backgrounds/gnome/bamos-frost-2-dark.png</filename-dark>
        <options>zoom</options>
        <shade_type>solid</shade_type>
        <pcolor>#ffffff</pcolor>
        <scolor>#000000</scolor>
      </wallpaper>
    </wallpapers>
    XML

        # 12. Frost 4
        cat > $out/share/gnome-background-properties/bamos-frost-4.xml << XML
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE wallpapers SYSTEM "gnome-wp-list.dtd">
    <wallpapers>
      <wallpaper deleted="false">
        <name>BamOS Frost 4</name>
        <filename>/run/current-system/sw/share/backgrounds/gnome/bamos-frost-4.png</filename>
        <filename-dark>/run/current-system/sw/share/backgrounds/gnome/bamos-frost-4-dark.png</filename-dark>
        <options>zoom</options>
        <shade_type>solid</shade_type>
        <pcolor>#ffffff</pcolor>
        <scolor>#000000</scolor>
      </wallpaper>
    </wallpapers>
    XML

        # 13. Frost 5
        cat > $out/share/gnome-background-properties/bamos-frost-5.xml << XML
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE wallpapers SYSTEM "gnome-wp-list.dtd">
    <wallpapers>
      <wallpaper deleted="false">
        <name>BamOS Frost 5</name>
        <filename>/run/current-system/sw/share/backgrounds/gnome/bamos-frost-5.png</filename>
        <filename-dark>/run/current-system/sw/share/backgrounds/gnome/bamos-frost-5-dark.png</filename-dark>
        <options>zoom</options>
        <shade_type>solid</shade_type>
        <pcolor>#ffffff</pcolor>
        <scolor>#000000</scolor>
      </wallpaper>
    </wallpapers>
    XML
  '';

  meta = {
    description = "BamOS branding — bamboo logos, wallpapers, and GNOME background properties";
    homepage = "https://github.com/quocnho/bamos";
    license = lib.licenses.mit;
  };
}
