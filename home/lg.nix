# Home-manager RIÊNG cho host lg (user quocnho) — phần cá nhân của máy dev.
# Kế thừa home/default.nix (dùng chung mọi máy) rồi thêm phần riêng.
{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./default.nix # dùng chung: shell/starship/fzf/zoxide/git/ssh (mọi máy)
    ./dev.nix # developer: nvim + tmux + gh + direnv (máy dev)
  ];

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
