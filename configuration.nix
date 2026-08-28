# Cấu hình host mặc định (LG laptop).
#
# Cấu trúc đã tách thành hosts/ + profiles/:
#   hosts/lg.nix       ← cấu hình thật của máy LG (host)
#   profiles/*.nix     ← profile dùng chung (common, desktop, installer)
#
# File này giữ lại để tương thích các lệnh kiểu
#   nixos-rebuild build-vm -I nixos-config=./configuration.nix
# và làm lối vào duy nhất cho host lg (flake.nix dùng ./configuration.nix).
{
  imports = [ ./hosts/lg.nix ];
}
