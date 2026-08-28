# BamOS CLI (`bam`) — script bash thuần, không cần build.
#
# Cài vào hệ thống qua environment.systemPackages (modules/packages.nix) hoặc
# build độc lập: `nix build .#bam` → result/bin/bam.
#
# Script gốc: ./bam.sh (sửa ở đó; chạy `bash -n` để kiểm tra cú pháp).
{
  writeShellScriptBin,
}:

writeShellScriptBin "bam" (builtins.readFile ./bam.sh)
