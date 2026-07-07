# Hướng dẫn đóng góp

## Yêu cầu

- Nix (nixos-unstable channel)
- Kiến thức cơ bản về NixOS và Nix language

## Môi trường phát triển

```bash
# Clone dự án
git clone https://github.com/quocnho/bamos.git
cd bamos

# Vào dev shell (LSP servers + formatter + linters)
nix develop

# Kiểm tra flake
nix flake check

# Build ISO
nix build .#iso-gnome-standard
```

## Cấu trúc dự án

```
hosts/       - Host definitions (lg, iso, vm)
modules/     - NixOS modules (core, desktop, editions, apps, theming)
profiles/    - 12 profiles (3 DE × 4 Editions)
lib/         - Helper functions (mkISO, mkHost, mkEdition)
plan/        - Project planning (Lean Canvas, roadmap, backlog)
docs/        - Documentation
```

## Quy trình đóng góp

1. Fork repository
2. Tạo branch: `sprint/NN/mo-ta`
3. Code + kiểm tra: `nix flake check`
4. Commit theo format: `feat(scope): message`
5. Tạo Pull Request

## Kiểm tra

```bash
# Validate
nix flake check

# Format code
nix fmt

# Phân tích tĩnh
nix-shell -p deadnix --run 'deadnix --fail .'
nix-shell -p statix --run 'statix check .'

# Build ISO cụ thể
nix build .#iso-gnome-standard --no-link
```
