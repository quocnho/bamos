# Developer Workstation — hosts/lg

## Tổng quan

`hosts/lg` là cấu hình NixOS cho laptop developer chính (LG Gram), được thiết kế để phát triển, build, và test BamOS.

## Các thành phần

### 1. Môi trường Phát Triển NixOS

- **Nix development tools**: nil, nixd, nixpkgs-fmt, deadnix, statix
- **Code editors**: VSCode, Vim/Neovim
- **Build tools**: nix-output-monitor (nom), nix-tree
- **VM tools**: QEMU/KVM, libvirt, virt-manager

### 2. Secret Management — Agenix

Dùng agenix để quản lý secrets:

```
secrets/
├── github-token.age      # GitHub Personal Access Token
├── cachix-token.age      # Cachix auth token
└── ssh-key.age           # SSH private key
```

Cấu hình agenix trong hosts/lg:

```nix
age.secrets.github-token = {
  file = ../secrets/github-token.age;
};
```

### 3. Home Manager

User-level configuration với home-manager:

- **Git**: User name, email, signing key, aliases
- **Zsh**: oh-my-zsh, syntax highlighting, autosuggestions
- **direnv**: Tự động load nix shells khi cd vào project

### 4. GNOME Extensions

Extensions phù hợp cho developer:

- dash-to-dock
- appindicator
- blur-my-shell
- gtile (window tiling)
- Vitals (system monitor)

### 5. Developer Tools

Installed packages:

- Git + GitHub CLI (`gh`)
- Podman + Docker-compose
- devenv
- Node.js, Python, Go, Rust
- Database tools: Postgres, SQLite
- Network tools: curl, wget, dig, nmap
- Media tools: ffmpeg, imagemagick

## Cấu trúc hosts/lg

```
hosts/lg/
├── configuration.nix          # Main config
├── hardware-configuration.nix # Hardware detection
└── secrets/                   # Encrypted secrets (agenix)
    ├── github-token.age
    ├── cachix-token.age
    └── ssh-key.age
```

## Commands

```bash
# Apply config
sudo nixos-rebuild switch --flake .#lg

# Build VM (test without applying)
nixos-rebuild build-vm --flake .#lg
./result/bin/run-lg-vm

# Update secrets
agenix -e secrets/github-token.age
```

## Future Improvements

- [ ] Impermanence cho /etc và /var
- [ ] Auto VM testing pipeline
- [ ] Cross-compilation cho ISO build
