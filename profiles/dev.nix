# Profile DEV — Dành cho lập trình viên (Developer)
# Kế thừa profile desktop + bật công cụ phát triển cấp hệ thống
{ config, lib, ... }:

{
  imports = [ ./desktop.nix ];

  # Bật công cụ phát triển: Zed, Antigravity, devenv, nil language server...
  my.dev.enable = true;

  # Tắt GNOME Software chạy ngầm để tiết kiệm RAM & CPU cho dev
  my.gnome.store = false;
}
