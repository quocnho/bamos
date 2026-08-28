# BamOS — Hệ điều hành cho người Việt Nam 🎋

> Website chính thức: **https://bamos.info/** — "Cài xong là dùng, không cần cài thêm".

BamOS là distro NixOS dành cho người Việt, theo triết lý **"Cây tre trăm đốt"**:
mỗi đốt tre là một module — **độc lập, liên kết, bền chặt**. Gãy một đốt, cây vẫn vững.

Kho code này chứa toàn bộ cấu hình BamOS: **hosts** (máy) + **profiles** (vai trò),
kèm **ISO installer (Calamares)** để cài BamOS lên máy người dùng khác —
tham khảo sâu dự án [GLF-OS](https://framagit.org/gaming-linux-fr/glf-os/glf-os).

## Tính năng mặc định (khớp bamos.info — "Cài xong là dùng")

| Website bamos.info                     | Trạng thái trong BamOS                                                   |
| -------------------------------------- | ------------------------------------------------------------------------ |
| Bộ gõ tiếng Việt (Unikey)              | ✅ fcitx5 + **fcitx5-unikey** mặc định                                   |
| WPS Office (tương thích MS Office)     | ✅ **wpsoffice** cài sẵn                                                 |
| Chrome                                 | ✅ **google-chrome** cài sẵn                                             |
| Zoom                                   | ✅ **zoom-us** cài sẵn                                                   |
| Zalo                                   | ⏳ chưa có package nixpkgs (hướng dẫn trong `customConfig/features.nix`) |
| Chỉnh sửa ảnh & video (GIMP, Kdenlive) | ✅ tùy chọn (bỏ comment trong `features.nix`)                            |
| Driver NVIDIA                          | ✅ màn chọn GPU trong Calamares (auto/nvidia/intel)                      |
| Múi giờ Việt Nam                       | ✅ `Asia/Ho_Chi_Minh` mặc định                                           |
| Không lo virus / Rollback              | ✅ bản chất immutable của NixOS                                          |

## Cấu trúc

```
.
├── flake.nix                  # inputs + outputs: nixosModules, profiles, hosts, packages.iso
├── configuration.nix          # shim → hosts/lg.nix (giữ tương thích lệnh cũ)
├── hosts/                     # ★ mỗi máy = 1 file (áp dụng profile + phần riêng)
│   ├── lg.nix                 #   LG laptop: desktop profile + GPU + power + user
│   └── installer.nix          #   ISO LiveCD: profile installer
├── profiles/                  # ★ vai trò dùng chung (có thể ghép nhiều profile)
│   ├── common.nix             #   nền tảng: module chung + audio (mọi máy)
│   ├── desktop.nix            #   GNOME + macOS look + boot + fonts + networkmanager
│   └── installer.nix          #   LiveCD: isoImage + Calamares override (DPI, GPU, Loại máy)
├── iso-cfg/                   # ★ flake cho /etc/nixos MÁY ĐÍCH (nhúng vào ISO → /iso-cfg)
│   ├── flake.nix              #   input bamos = github:quocnho/bamos/main (kéo config từ repo)
│   └── customConfig/          #   ★ nơi người dùng bật/tắt bằng cách comment
│       ├── default.nix        #     import apps.nix + features.nix
│       ├── apps.nix           #     ứng dụng thêm (comment để bật/tắt)
│       └── features.nix       #     tính năng: timezone VN, fcitx5-unikey, WPS/Chrome/Zoom...
├── installer/                 # cấu hình Calamares (nạp vào package qua override)
│   └── calamares/
│       ├── modules/nixos/     #   module Python: sinh config + dò GPU + nixos-install
│       └── config/modules/    #   partition, users, welcome, gpu (NVIDIA/Intel), device (laptop/desktop)
├── modules/                   # module dùng chung (my.*, bật qua my.X.enable)
│   ├── default.nix            #   aggregator — xuất qua bamos.nixosModules.default
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
# (công cụ khuyên dùng theo bamos.info: Balena Etcher)
```

Luồng cài (Calamares — tham khảo GLF-OS):

1. Boot USB → đăng nhập GNOME với user `nixos` (mật khẩu trống) → **Calamares** tự chạy
   (đã fix DPI: `QT_SCALE_FACTOR=1.5` — chữ to, dễ đọc cho người lớn tuổi).
2. Welcome (kiểm tra mạng/ổ cứng) → locale → bàn phím → **Users** (tên/mật khẩu)
   → **Cấu hình GPU** (Tự động / NVIDIA / Chỉ Intel — dò bằng `lspci` như GLF-OS)
   → **Loại máy** (Laptop: bật TLP/suspend sâu / Desktop: mặc định)
   → **Phân vùng** (EFI + root, kèm swap tùy chọn) → Summary.
3. Installer (module `nixos` trong `installer/calamares/`): sinh `hardware-configuration.nix`
   bằng `nixos-generate-config`, ghi `configuration.nix` (user + GPU + Loại máy theo lựa chọn),
   copy `iso-cfg/` (flake mẫu + `customConfig/`) vào `/etc/nixos`, pre-lock `flake.lock`,
   rồi `nixos-install --flake <root>/etc/nixos#bamos --no-root-passwd`.

## Sau khi cài xong — máy người dùng

`/etc/nixos` của máy đích chứa **flake cơ bản** gọi cấu hình từ GitHub:

```nix
# /etc/nixos/flake.nix (do installer sinh)
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    bamos.url = "github:quocnho/bamos/main";     # ★ ref main (default branch trên GitHub vẫn là master)
    bamos.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs = { self, nixpkgs, bamos, ... }: {
    nixosConfigurations.bamos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [ ./configuration.nix  ./customConfig  bamos.profiles.desktop ];
    };
  };
}
```

> Mẫu website bamos.info dùng `bamos.nixosModules.default` — tương đương, và
> `bamos.nixosModules.default` cũng được xuất từ flake này (xem `flake.nix`).

### Tùy biến máy — chỉ cần comment (#)

Mọi thứ nằm trong `/etc/nixos/customConfig/`:

```bash
sudo nano /etc/nixos/customConfig/apps.nix      # ứng dụng: bỏ # để cài, thêm # để gỡ
sudo nano /etc/nixos/customConfig/features.nix  # tính năng: timezone, bộ gõ, WPS/Chrome/Zoom...
sudo nixos-rebuild switch --flake /etc/nixos#bamos
```

Cập nhật máy (mọi cải tiến commit lên repo sẽ lan tới máy đích):

```bash
sudo nix flake update --flake /etc/nixos
sudo nixos-rebuild switch --flake /etc/nixos#bamos
```

## Máy chính (LG)

```bash
sw   # sudo env NIXOS_TAG="NixOS-$(date +%y.%m.%d-%H:%M)" nixos-rebuild switch --flake /etc/nixos#lg --impure
bt   # boot thay vì switch (giữ generation cũ)
bu   # build thử không áp dụng
```

- Tag `NixOS-YY.MM.DD-HH:MM` tự gắn mỗi lần switch (xem `hosts/lg.nix`).
- User `quocnho` khai báo trực tiếp trong `hosts/lg.nix` (không hardcode trong modules/).

## Tham khảo GLF-OS → BamOS

| Tính năng               | GLF-OS                                                      | BamOS                                                                         |
| ----------------------- | ----------------------------------------------------------- | ----------------------------------------------------------------------------- |
| Flake hosts             | 1 `nixosConfiguration` / máy (`glf-installer`, `user-test`) | `hosts/*.nix` + `nixosConfigurations.*`                                       |
| Profiles                | `glf.environment.edition` + `glf.features.*` (catalog)      | `profiles/*.nix` (import thuần, dễ ghép)                                      |
| ISO                     | `installation-cd-graphical-calamares-gnome.nix`             | `installation-cd-graphical-calamares-gnome.nix` (giống GLF-OS)                |
| Installer               | Calamares + module Python (sinh config, dò GPU, copy flake) | Calamares + module Python (`installer/calamares/`) + **GPU + Laptop/Desktop** |
| Post-install /etc/nixos | copy `iso-cfg/` (flake input `glf`)                         | copy `iso-cfg/` (flake input `bamos` = github) + `customConfig/`              |
| Update máy đích         | `glf-update` = `nix flake update` + `nixos-rebuild boot`    | `nix flake update` + `nixos-rebuild switch`                                   |

## Lộ trình nâng cấp (tùy chọn)

- **Zalo**: chưa có package nixpkgs — thêm vào `features.nix` khi có (hoặc cài AppImage từ zalo.me).
- **Hyprland / KDE Plasma**: website quảng cáo nhiều desktop — hiện BamOS cung cấp GNOME
  (profile desktop); roadmap: thêm option `bamos.desktop = "gnome" | "hyprland" | "kde"`.
- **Edition Minimum/Standard/Studio/Gaming** (theo bamos.info): roadmap — chọn edition lúc cài
  (như GLF-OS `packagechooser`), BamOS hiện là bản "Standard" (GNOME + WPS/Chrome/Zoom).
- **Branding riêng**: hiện dùng branding `nixos` của package — có thể thêm
  `installer/calamares/branding/bamos/` và đổi `branding:` trong settings.conf.
- **Binary cache (Attic)**: đẩy closure lên cache riêng để `nixos-install` tải nhanh hơn (GLF-OS dùng Attic + CI).
