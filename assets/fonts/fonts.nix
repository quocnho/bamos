# Derivation cài font CỤC BỘ (không cần internet — không fetch từ nguồn ngoài).
# Nguồn file: assets/fonts/{inter,jetbrainsmono,firacode} (đã lưu trong repo).
# Family được fontconfig nhận diện:
#   - Inter                          → "Inter"           (font UI)
#   - JetBrainsMonoNerdFontMono-*    → "JetBrainsMono Nerd Font Mono"
#   - FiraCodeNerdFontMono-*         → "FiraCode Nerd Font Mono"
{ lib, stdenvNoCC }:

stdenvNoCC.mkDerivation {
  pname = "lg-local-fonts";
  version = "1.0";

  src = ./.; # assets/fonts — chỉ chứa file font + fonts.nix + README

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/fonts/truetype
    cp -r $src/inter         $out/share/fonts/truetype/
    cp -r $src/jetbrainsmono $out/share/fonts/truetype/
    cp -r $src/firacode      $out/share/fonts/truetype/
    runHook postInstall
  '';

  meta = {
    description = "Local fonts for LG laptop (Inter + JetBrainsMono/FiraCode Nerd Font)";
    license = lib.licenses.ofl;
  };
}
