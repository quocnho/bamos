# pkgs/bamos-branding/default.nix
# BamOS branding package — logos, wallpapers, GNOME background properties
# Inspired by GLF-OS glfos-branding pattern
#
{ lib, stdenvNoCC, }:

stdenvNoCC.mkDerivation rec {
  pname = "bamos-branding";
  version = "1.0.0";

  src = ../../assets;

  installPhase = ''
        # ═══════════════════════════════════════════════════════════
        # Logo — hicolor icon theme (SVG + PNG placeholders)
        # ═══════════════════════════════════════════════════════════
        mkdir -p $out/share/icons/hicolor/scalable/apps
        cp $src/logo/bamos-logo.svg $out/share/icons/hicolor/scalable/apps/bamos-logo.svg

        for SIZE in 16 32 48 64 128 256; do
          mkdir -p $out/share/icons/hicolor/''${SIZE}x''${SIZE}/apps
          # TODO: replace with actual PNG logos
          cp $src/logo/bamos-logo.svg $out/share/icons/hicolor/''${SIZE}x''${SIZE}/apps/bamos-logo.svg
        done

        # ═══════════════════════════════════════════════════════════
        # Wallpapers
        # ═══════════════════════════════════════════════════════════
        mkdir -p $out/share/backgrounds/gnome
        cp $src/wallpapers/bamos-default.svg    $out/share/backgrounds/gnome/bamos-default.svg
        cp $src/wallpapers/bamos-default-dark.svg $out/share/backgrounds/gnome/bamos-default-dark.svg

        # ═══════════════════════════════════════════════════════════
        # GNOME background properties XML
        # ═══════════════════════════════════════════════════════════
        mkdir -p $out/share/gnome-background-properties

        cat > $out/share/gnome-background-properties/bamos-default.xml << XML
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE wallpapers SYSTEM "gnome-wp-list.dtd">
    <wallpapers>
      <wallpaper deleted="false">
        <name>BamOS Default</name>
        <filename>/run/current-system/sw/share/backgrounds/gnome/bamos-default.svg</filename>
        <filename-dark>/run/current-system/sw/share/backgrounds/gnome/bamos-default-dark.svg</filename-dark>
        <options>zoom</options>
        <shade_type>solid</shade_type>
        <pcolor>#1a1a2e</pcolor>
        <scolor>#000000</scolor>
      </wallpaper>
    </wallpapers>
    XML
  '';

  meta = {
    description = "BamOS branding — logos, wallpapers, and GNOME background properties";
    homepage = "https://github.com/quocnho/bamos";
    license = lib.licenses.mit;
  };
}
