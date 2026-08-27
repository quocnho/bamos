# Ngôn ngữ, bộ gõ (fcitx5-unikey) — tham khảo repo bamos (modules/core/locale.nix
# + input-method.nix) của quocnho.
{ config, lib, pkgs, ... }:

{
  # Múi giờ Việt Nam
  time.timeZone = "Asia/Ho_Chi_Minh";

  # Nền locale giữ en_US (tương thích app), riêng các hạng mục LC_* chuyển
  # tiếng Việt → thời gian/ngày tháng hiển thị tiếng Việt (VD đồng hồ GNOME:
  # "Thứ Tư 27 Tháng Tám 14:30"). vi_VN được TỰ ĐỘNG sinh từ extraLocaleSettings
  # (không cần khai báo i18n.supportedLocales — option đó đã deprecated).
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_ADDRESS = "vi_VN";
    LC_IDENTIFICATION = "vi_VN";
    LC_MEASUREMENT = "vi_VN";
    LC_MONETARY = "vi_VN";
    LC_NAME = "vi_VN";
    LC_NUMERIC = "vi_VN";
    LC_PAPER = "vi_VN";
    LC_TELEPHONE = "vi_VN";
    LC_TIME = "vi_VN";
  };

  # ==== Bộ gõ fcitx5 + Unikey (gõ tiếng Việt) ====
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [ qt6Packages.fcitx5-unikey ];

    # Profile khai báo → /etc/xdg/fcitx5/profile: Unikey TỰ ĐỘNG được bật
    # sau khi cài mới/khởi động, không cần vào cấu hình fcitx5 để thêm tay.
    # Lưu ý: ~/.config/fcitx5/profile (nếu có) sẽ ghi đè — trên máy này nó
    # đã khớp đúng nội dung bên dưới.
    fcitx5.settings.inputMethod = {
      "Groups/0" = {
        Name = "Default";
        "Default Layout" = "us";
        DefaultIM = "unikey";
      };
      "Groups/0/Items/0" = { Name = "keyboard-us"; Layout = ""; };
      "Groups/0/Items/1" = { Name = "unikey"; Layout = ""; };
      GroupOrder = { "0" = "Default"; };
    };
  };

  # Electron/Chromium apps (VS Code, Zed...) dùng fcitx5 trên Wayland
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
}
