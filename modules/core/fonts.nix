# modules/fonts.nix
# Vietnamese + developer fonts cho BamOS
{ pkgs
, ...
}:

{
  fonts.packages = with pkgs; [
    # Vietnamese support
    noto-fonts # Noto Sans, Serif, Mono — full VN coverage
    noto-fonts-cjk-sans # CJK cho ký tự Trung/Nhật/Hàn
    noto-fonts-color-emoji # Emoji

    # Developer fonts
    fira-code # Ligatures cho code
    jetbrains-mono # Font chính cho editor/terminal
  ];

  # Font configuration
  fonts.fontconfig.defaultFonts = {
    sansSerif = [ "Noto Sans" ];
    serif = [ "Noto Serif" ];
    monospace = [ "JetBrains Mono" ];
    emoji = [ "Noto Color Emoji" ];
  };
}
