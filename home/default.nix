# Description: Cấu hình Home-Manager dùng chung (MỌI máy BamOS: lg + máy cài từ ISO)
# Xuất qua `bamos.homeModules.default`
{ ... }:

{
  home.stateVersion = "25.11";

  imports = [
    ./programs/default.nix
  ];
}
