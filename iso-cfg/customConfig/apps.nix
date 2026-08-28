# ============================================================================
#  ỨNG DỤNG — BỎ COMMENT (#) đầu dòng để BẬT, THÊM # để TẮT
# ============================================================================
#  Sau khi sửa:  sudo nixos-rebuild switch --flake /etc/nixos#bamos
#
#  LƯU Ý: bamos đã cài sẵn nền tảng (GNOME, Firefox policy, công cụ cơ bản...)
#  qua profile desktop — file này chỉ để THÊM thêm theo nhu cầu.
# ============================================================================
{
  config,
  lib,
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    # ---------------- Trình duyệt & liên lạc ----------------
    # firefox          # trình duyệt (đã có sẵn theo mặc định bamos)
    # chromium         # Chromium / Chrome
    # brave            # Brave Browser
    # telegram-desktop # Telegram
    # discord          # Discord

    # ---------------- Văn phòng ----------------
    # libreoffice      # bộ văn phòng đầy đủ
    # onlyoffice-bin   # OnlyOffice (giao diện giống MS Office)

    # ---------------- Đa phương tiện ----------------
    # vlc              # xem phim / nghe nhạc
    # mpv              # player nhẹ
    # gimp             # chỉnh sửa ảnh
    # obs-studio       # quay màn hình / stream

    # ---------------- Công cụ hệ thống ----------------
    # htop             # xem CPU/RAM
    # btop             # htop hiện đại
    # file-roller     # giải nén (GNOME Files đã có sẵn)
    # gnome-tweaks     # tinh chỉnh giao diện GNOME
    # git              # quản lý mã nguồn
    # neovim           # soạn thảo
  ];
}
