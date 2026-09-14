# Home-manager RIÊNG cho host lg (user quocnho) — phần cá nhân của máy dev.
# Kế thừa home/default.nix (dùng chung mọi máy) rồi thêm phần riêng.
{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Cùng một package với cấp hệ thống (modules/ai.nix) → dùng chung store path.
  bamosAssistant = pkgs.callPackage ../pkgs/assistant { };
in
{
  imports = [
    ./default.nix # dùng chung: shell/starship/fzf/zoxide/git/ssh (mọi máy)
    ./dev.nix # developer: nvim + tmux + gh + direnv (máy dev)
  ];


  # ==== BamAI trên THANH TRÊN CÙNG của GNOME Shell ====
  # Extension nhỏ (ESM, GNOME 45+) hiện mục “🐶 BamAI” + menu Hiện/Ẩn/Tắt.
  # Được bật trong modules/gnome.nix (org.gnome.shell enabled-extensions).
  xdg.dataFile = {
    "gnome-shell/extensions/bamai@bamos/metadata.json".source =
      ../assets/gnome-shell-extensions/bamai-bamos/metadata.json;
    "gnome-shell/extensions/bamai@bamos/extension.js".source =
      ../assets/gnome-shell-extensions/bamai-bamos/extension.js;
    "gnome-shell/extensions/bamai@bamos/stylesheet.css".source =
      ../assets/gnome-shell-extensions/bamai-bamos/stylesheet.css;
  };

  # ==== Định danh git cá nhân ====
  # User-level (~/.gitconfig) — thắng /etc/gitconfig cấp hệ thống.
  programs.git = {
    settings.user = {
      name = "quocnho";
      email = "quocnho@gmail.com";
    };
  };

  # ==== (Thêm gói/cấu hình riêng cho quocnho ở đây — vd: ====
  # ====  home.packages = with pkgs; [ pkgs.xxx ];)           ====
}
