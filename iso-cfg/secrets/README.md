# 🔐 Secrets Management (Optional)

BamOS dùng `ragenix` để quản lý secrets (SSH keys, API tokens, ...).

## Setup

```bash
# Tạo SSH key (nếu chưa có)
ssh-keygen -t ed25519 -C "your@email.com"

# Cài ragenix
nix profile install nixpkgs#ragenix

# Mã hóa file secret
ragenix -e secrets/my-secret.age
```

## Cấu trúc

```
/etc/nixos/secrets/
├── README.md           # File này
├── secrets.nix         # Định nghĩa public keys
└── *.age              # Encrypted secret files
```
