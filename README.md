# Bamos — NixOS declarative (hosts + profiles + ISO installer)

Cấu hình NixOS bằng Flakes, tách thành **hosts** (máy) + **profiles** (vai trò),
kèm **ISO installer** để cài bamos lên máy người dùng khác — tham khảo sâu
dự án [GLF-OS](https://framagit.org/gaming-linux-fr/glf-os/glf-os).

## Cấu trúc

```
.
├── flake.nix                  # inputs + outputs: profiles, hosts, packages.iso
├── configuration.nix          # shim → hosts/lg.nix (giữ tương thích lệnh cũ)
├── hosts/                     # ★ mỗi máy = 1 file (áp dụng profile + phần riêng)
│   ├── lg.nix                 #   LG laptop: desktop profile + GPU + power + user
│   └── installer.nix          #   ISO LiveCD: profile installer
├── profiles/                  # ★ vai trò dùng chung (có thể ghép nhiều profile)
│   ├── common.nix             #   nền tảng: module chung + audio (mọi máy)
│   ├── desktop.nix            #   GNOME + macOS look + boot + fonts
│   └── installer.nix          #   LiveCD: isoImage + dialog installer + autologin
├── iso-cfg/                   # ★ flake cho /etc/nixos MÁY ĐÍCH (nhúng vào ISO → /iso-cfg)
│   ├── flake.nix              #   input bamos = github:quocnho/bamos (kéo config từ repo)
│   └── customConfig/          #   nơi máy đích thêm cấu hình riêng (không đụng repo)
├── installer/                 # cấu hình Calamares (được nạp vào package qua override)
│   └── calamares/
│       ├── modules/nixos/     #   module Python: sinh config + dò GPU + nixos-install
│       └── config/modules/    #   partition.conf, users.conf, welcome.conf, gpu.conf
├── modules/                   # module dùng chung (my.*, bật qua my.X.enable)
│   ├── default.nix            #   aggregator (không gồm users.nix — chỉ máy LG)
│   ├── users.nix              #   user "quocnho" — import riêng ở hosts/lg.nix
│   └── (boot, gpu, power, audio, gnome, macos, assets, i18n, shell, ...)
├── hardware-configuration.nix # cấu hình phần cứng máy LG (nixos-generate-config)
└── assets/                    # tài nguyên cục bộ (offline): fonts, ảnh, IDE config
```

### Cách dùng hosts + profiles

```nix
# hosts/<máy>.nix — mỗi máy = 1 file import profiles + phần riêng
{ config, lib, ... }:
{
  imports = [
    ../profiles/desktop.nix   # vai trò dùng chung
    ../modules/users.nix      # (vd) user riêng
    ../hardware-configuration.nix
  ];
  networking.hostName = "ten-may";
  my.gpu.enable = true;       # bật module riêng
  my.gpu.intelBusId = "PCI:0:2:0";
}
```

Muốn thêm máy mới: tạo `hosts/<máy>.nix` + thêm 1 entry `nixosConfigurations.<máy>`
trong `flake.nix` (hoặc để ISO cài sẵn — máy đích chạy profile desktop từ repo).

## Build ISO cài đặt (cho người dùng khác)

```bash
nix build .#iso
# ISO nằm ở result/iso/*.iso — ghi ra USB: dd if=result/iso/*.iso of=/dev/sdX bs=4M status=progress
```

Luồng cài (Calamares — tham khảo GLF-OS):

1. Boot USB → đăng nhập GNOME với user `nixos` (mật khẩu trống) → **Calamares** tự chạy
   (đã fix DPI: `QT_SCALE_FACTOR=1.5` — chữ to, dễ đọc).
2. Welcome (kiểm tra mạng/ổ cứng) → locale → bàn phím → **Users** (tên/mật khẩu)
   → **Cấu hình GPU** (Tự động / NVIDIA / Chỉ Intel — module dò bằng `lspci` như GLF-OS)
   → **Phân vùng** (EFI + root, kèm swap tùy chọn) → Summary.
3. Installer (module `nixos` trong `installer/calamares/`): sinh `hardware-configuration.nix`
   bằng `nixos-generate-config`, ghi `configuration.nix` (user + GPU theo lựa chọn),
   copy `iso-cfg/` (flake mẫu + `customConfig/`) vào `/etc/nixos`, pre-lock `flake.lock`,
   rồi `nixos-install --flake <root>/etc/nixos#bamos --no-root-passwd`.

## Sau khi cài xong — máy người dùng

`/etc/nixos` của máy đích chứa **flake cơ bản** gọi cấu hình từ GitHub:

```nix
# /etc/nixos/flake.nix (do installer sinh)
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    bamos.url = "github:quocnho/bamos";          # ★ kéo config từ repo này
    bamos.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { self, nixpkgs, bamos, ... }: {
    nixosConfigurations.bamos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./configuration.nix  bamos.profiles.desktop ];
    };
  };
}
```

Cập nhật máy (mọi cải tiến commit lên repo sẽ lan tới máy đích):

```bash
sudo nix flake update --flake /etc/nixos
sudo nixos-rebuild switch --flake /etc/nixos#bamos
```

Muốn đổi profile (vd máy không có desktop): sửa `modules` trong
`/etc/nixos/flake.nix` → `bamos.profiles.common` (nền tảng trần) hoặc thêm
profile khác.

## Máy chính (LG)

```bash
sw   # sudo env NIXOS_TAG="NixOS-$(date +%y.%m.%d-%H:%M)" nixos-rebuild switch --flake /etc/nixos#lg --impure
bt   # boot thay vì switch (giữ generation cũ)
bu   # build thử không áp dụng
```

- Tag `NixOS-YY.MM.DD-HH:MM` tự gắn mỗi lần switch (xem `hosts/lg.nix`).
- `modules/users.nix` (user `quocnho`) chỉ áp dụng cho host này.

## Tham khảo GLF-OS → bamos

| Tính năng               | GLF-OS                                                      | Bamos                                                                          |
| ----------------------- | ----------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Flake hosts             | 1 `nixosConfiguration` / máy (`glf-installer`, `user-test`) | `hosts/*.nix` + `nixosConfigurations.*`                                        |
| Profiles                | `glf.environment.edition` + `glf.features.*` (catalog)      | `profiles/*.nix` (import thuần, dễ ghép)                                       |
| ISO                     | `installation-cd-graphical-calamares-gnome.nix`             | `installation-cd-graphical-calamares-gnome.nix` (giống GLF-OS)                 |
| ISO                     | `installation-cd-graphical-calamares-gnome.nix`             | `installation-cd-graphical-calamares-gnome.nix` (giống GLF-OS)                 |
| Installer               | Calamares + module Python (sinh config, dò GPU, copy flake) | Calamares + module Python (`installer/calamares/`) + **chọn GPU NVIDIA/Intel** |
| Post-install /etc/nixos | copy `iso-cfg/` (flake input `glf`)                         | copy `iso-cfg/` (flake input `bamos` = github) + `customConfig/`               |
| Update máy đích         | `glf-update` = `nix flake update` + `nixos-rebuild boot`    | `nix flake update` + `nixos-rebuild switch`                                    |

### Lộ trình nâng cấp (tùy chọn)

- **DPI Calamares**: đổi `QT_SCALE_FACTOR` trong `profiles/installer.nix` (overlay
  `makeAutostartItem`) — mặc định `1.5` cho dễ đọc, hạ `1.25` nếu quá to.
- **Branding riêng**: hiện dùng branding `nixos` của package — có thể thêm
  `installer/calamares/branding/bamos/` và đổi `branding:` trong settings.conf.
- **Binary cache (Attic)**: đẩy closure lên cache riêng để `nixos-install` tải nhanh hơn (GLF-OS dùng Attic + CI).

# bamos installer
