# Build ISO BamOS

## Yêu cầu

- NixOS với flakes enabled
- ~10GB disk space cho mỗi ISO build
- Internet connection

## Build ISO

### Build một variant cụ thể

```bash
# GNOME Standard (mặc định)
nix build .#iso-gnome-standard

# Các variant khác
nix build .#iso-gnome-developers
nix build .#iso-gnome-gaming
nix build .#iso-gnome-studio
nix build .#iso-kde-standard
nix build .#iso-kde-developers
nix build .#iso-kde-gaming
nix build .#iso-kde-studio
```

Kết quả là ISO trong `result/iso/*.iso`.

### Build tất cả variants

```bash
nix build .#all -j auto
```

## Build ISO với cache

```bash
# Build và push cache lên Cachix
nix run .#push-cachix
```

## Cấu trúc ISO Build

### ISO host definition (`hosts/iso/`)

Mỗi ISO variant có:
- `hosts/iso/<de>-<edition>/configuration.nix` — Import profile tương ứng
- `lib/mkISO.nix` — Sử dụng nixos-generators để build ISO

### Quy trình build

```
flake.nix → hosts/default.nix → mkISO Variant
  → lib/mkEdition.nix
    → profiles/<de>-<edition>.nix
      → nixos-generators -f iso
```

## Binary Cache (Cachix)

### Cache công cộng

Cache ID: `bamos`

```bash
# Cấu hình Cachix cho người dùng
cachix use bamos

# Hoặc thêm vào flake.nix
{
  nix.settings = {
    substituters = [ "https://bamos.cachix.org" "https://cache.nixos.org" ];
    trusted-public-keys = [ "bamos.cachix.org-1:<key>" "cache.nixos.org-1:6NCHDVPiE..." ];
  };
}
```

### Push cache từ CI/CD

GitHub Actions workflow (`.github/workflows/build.yml`):
1. Build ISO
2. Push `/nix/store` paths lên Cachix
3. Upload ISO artifacts lên GitHub Releases

### Push thủ công

```bash
# Set auth token
export CACHIX_AUTH_TOKEN="eyJ..."

# Build + push
nix run .#push-cachix
```

## Optimization

### ISO size optimization

- Sử dụng kernel LTS (nhỏ hơn Zen/XanMod)
- Loại bỏ firmware không cần thiết
- Nén squashfs với zstd

### Build speed

- Binary cache giảm thời gian build từ 2-3 giờ xuống còn 15-30 phút
- GitHub Actions cache cho nix store

## CI/CD Pipeline

Workflow `.github/workflows/build.yml`:

```yaml
- name: Build ISO
  run: nix build .#all -j auto --print-build-logs

- name: Push to Cachix
  uses: cachix/cachix-action@v15
  with:
    name: bamos
    authToken: ${{ secrets.CACHIX_AUTH_TOKEN }}

- name: Upload Release
  uses: softprops/action-gh-release@v2
  with:
    files: result/iso/*.iso
```

## Troubleshooting

### ISO build chậm

- Kiểm tra Cachix config
- Chạy `nix build` với `--print-build-logs` để xem tiến trình
- Dùng `nom` (nix-output-monitor) cho output đẹp hơn

### Lỗi "out of disk space"

```bash
# Dọn garbage collector
sudo nix-collect-garbage -d

# Kiểm tra disk usage
df -h /nix/store
```
