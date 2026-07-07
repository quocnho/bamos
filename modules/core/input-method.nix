{ pkgs, ... }:

{
  # Fcitx5 cho gõ tiếng Việt (Wayland Native)
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-bamboo
      fcitx5-gtk
    ];
  };

  # Biến môi trường cho input method
  environment.sessionVariables = {
    XMODIFIERS = "@im=fcitx";
    QT_IM_MODULE = "fcitx";
    GTK_IM_MODULE = "fcitx";
    NIXOS_OZONE_WL = "1";
  };
}
