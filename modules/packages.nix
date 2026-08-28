# Gói phần mềm CƠ BẢN — cài sẵn trên MỌI máy BamOS (máy dev + máy người dùng cuối).
#
# Nguyên tắc "cài xong là dùng, không cài thêm" (khớp bamos.info):
#   - Chỉ những gì người dùng cuối thực sự cần: công cụ hệ thống, nén, media...
#   - Công cụ PHÁT TRIỂN (Zed, Antigravity, Python, Node, devenv...) nằm ở
#     modules/dev.nix — chỉ bật trên máy dev (my.dev.enable = true).
#   - Ứng dụng văn phòng (LibreOffice + Google Docs...), trình duyệt, Zoom:
#     mặc định trong iso-cfg/customConfig/features.nix của máy đích.
{
  config,
  lib,
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    # BamOS CLI — 1 lệnh `bam` quản lý hệ thống (switch/update/iso/gc/info/doctor...)
    (callPackage ../pkgs/bam { })

    # ---- Công cụ hệ thống (mọi máy) ----
    git # quản lý mã nguồn / lấy config
    vim
    wget
    curl
    unzip
    zip
    unrar
    pciutils # lspci... (dò phần cứng, bam info)
    gparted # chia ổ đĩa
    htop # xem CPU/RAM
    ffmpeg # xử lý âm thanh/video

    # ---- Terminal đẹp & tiện (fzf + starship + zoxide cài qua programs.* ở shell.nix) ----
    fd
    bat
    eza

    # ---- GNOME ----
    gnome-extension-manager # quản lý extension (bản đầy đủ trong modules/gnome.nix)
  ];

  # ==== Firefox (cài qua programs.firefox để kèm policies tối ưu PIN) ====
  # - VAAPI hardware video decode trên Intel iGPU (iHD): xem video tiết kiệm pin
  # - Tự xả tab khi thiếu RAM
  programs.firefox = {
    enable = true;
    policies = {
      Preferences = {
        "media.ffmpeg.vaapi.enabled" = true;
        "media.hardware-video-decoding.enabled" = true;
        "browser.tabs.unloadOnLowMemory" = true;
      };
    };
  };
}
