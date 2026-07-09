# secrets/secrets.nix
# BamOS secret definitions — age public key mapping
# Cách dùng:
#   agenix -e secrets/github-token.age    # Tạo/edit secret
#   agenix -d secrets/github-token.age    # Decrypt để xem
#
# Public keys:
#   - quocnho (LG Gram): ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILtLHChwq5J5sjJEMBqAKAcqGC+fhRNLsz5Y2KVF8NV8
#
let
  # Public keys của admin có thể decrypt
  users = {
    quocnho = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILtLHChwq5J5sjJEMBqAKAcqGC+fhRNLsz5Y2KVF8NV8";
  };

  # Public keys của hệ thống (CI/CD)
  systems = { };
in
{
  # GitHub Personal Access Token — cho nix flakes + cachix
  "github-token.age".publicKeys = [ users.quocnho ];
}
