# Description: Các công cụ CLI tiện ích cho người dùng (user-level)
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    jq # xử lý JSON
    yq # xử lý YAML
    ripgrep # tìm kiếm nhanh
    tree # xem cây thư mục
    tldr # man ngắn gọn (tealdeer)
    duf # dung lượng ổ đĩa
    ncdu # dọn ổ đĩa tương tác
    btop # theo dõi CPU/RAM
  ];
}
