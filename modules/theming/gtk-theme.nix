# modules/theming/gtk-theme.nix
# GTK theme, icon theme, cursor theme — System-wide options
# Config values read by DE-specific theme modules
#
# RakuOS equivalents:
#   gtkTheme:     Nordic (~ OrigamiPaper)
#   iconTheme:    WhiteSur-dark
#   cursorTheme:  Bibata-Modern-Classic
#   font:         Inter 11
#   monospace:    Maple Mono NF 11
#
{ lib, ... }:

{
  options.bamos.theming = {
    gtkTheme = lib.mkOption {
      type = lib.types.str;
      default = "Nordic";
      description = "GTK theme (RakuOS: OrigamiPaper → Nordic)";
    };
    iconTheme = lib.mkOption {
      type = lib.types.str;
      default = "WhiteSur-dark";
      description = "Icon theme (RakuOS: WhiteSur-dark)";
    };
    cursorTheme = lib.mkOption {
      type = lib.types.str;
      default = "Bibata-Modern-Classic";
      description = "Cursor theme (RakuOS: Bibata-Modern-Classic)";
    };
    font = lib.mkOption {
      type = lib.types.str;
      default = "Inter";
      description = "Default font (RakuOS: Inter 11)";
    };
    fontSize = lib.mkOption {
      type = lib.types.int;
      default = 11;
      description = "Default font size";
    };
    monospaceFont = lib.mkOption {
      type = lib.types.str;
      default = "Maple Mono NF";
      description = "Monospace font (RakuOS: Maple Mono NF 11)";
    };
  };
}
