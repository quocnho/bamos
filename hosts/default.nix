# hosts/default.nix
# Aggregator — import tất cả host definitions
# Mỗi host là một flake-parts module trong thư mục con
{
  imports = [
    ./lg
    ./iso
    # ./vm  # QEMU test VM (Sprint 2+)
  ];
}
