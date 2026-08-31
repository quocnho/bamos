# ============================================================================
#  HOME-MANAGER RIÊNG CỦA MÁY BẠN — BỎ COMMENT (#) đầu dòng để BẬT, THÊM # để TẮT
# ============================================================================
#  Home-manager quản lý cấu hình trong $HOME của user (gói cài riêng, git config,
#  dotfiles...). Mặc định BamOS đã áp sẵn cấu hình DÙNG CHUNG từ repo (home/ —
#  qua bamos.homeModules.default trong flake.nix); file này là nơi bạn THÊM riêng
#  cho máy mình mà không cần đụng repo (giống apps.nix / features.nix).
#
#  File này được import bởi flake.nix cho MỌI user thường của máy (user tạo lúc cài).
#  Sau khi sửa:  bam switch   (home-manager tự kích hoạt qua nixos-rebuild)
# ============================================================================
{
  config,
  lib,
  pkgs,
  ...
}:

{
  # ----------------------------------------------------------------------------
  # ★ BỘ CÔNG CỤ DEVELOPER (Neovim + tmux + gh + direnv...) — bỏ comment dòng dưới
  #   để bật. Cấu hình chi tiết nằm trong repo bamos (home/dev.nix) — mọi cập nhật
  #   từ GitHub sẽ tự về máy qua bam update.
  # ----------------------------------------------------------------------------
  # imports = [ bamos.homeModules.dev ];

  # ---------------- Gói cài riêng cho user (vào ~/.nix-profile) ----------------
  # home.packages = with pkgs; [
  #   vlc
  #   mpv
  # ];

  # ---------------- Định danh git cho lệnh commit (user.name/user.email) ----------------
  # programs.git = {
  #   enable = true;
  #   settings.user = {
  #     name = "Tên của bạn";
  #     email = "email@vi-du.vn";
  #   };
  # };

  # ---------------- Thêm file cấu hình riêng (dotfile) ----------------
  # home.file.".config/myapp/config.toml".text = ''
  #   # nội dung file — ghi đè/backup file cũ (đuôi .hm-bak)
  # '';
}
