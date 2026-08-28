# BamOS — Hệ điều hành cho người Việt Nam 🎋

> Website chính thức: **https://bamos.info/** — "Cài xong là dùng, không cần cài thêm".

BamOS là distro NixOS dành cho người Việt, theo triết lý **"Cây tre trăm đốt"**:
mỗi đốt tre là một module — **độc lập, liên kết, bền chặt**. Gãy một đốt, cây vẫn vững.

Kho code này chứa toàn bộ cấu hình BamOS: **hosts** (máy) + **profiles** (vai trò),
kèm **ISO installer (Calamares)** để cài BamOS lên máy người dùng khác —
tham khảo sâu dự án [GLF-OS](https://framagit.org/gaming-linux-fr/glf-os/glf-os).

## Tính năng mặc định (khớp bamos.info — "Cài xong là dùng")

| Website bamos.info                     | Trạng thái trong BamOS                                                             |
| -------------------------------------- | ---------------------------------------------------------------------------------- |
| Bộ gõ tiếng Việt (Unikey)              | ✅ fcitx5 + **fcitx5-unikey** mặc định                                             |
| Văn phòng (tương thích MS Office)      | ✅ **LibreOffice** mặc định + **Google Docs/Sheets/Slides** web apps; WPS tùy chọn |
| Chrome                                 | ✅ **google-chrome** cài sẵn                                                       |
| Zoom                                   | ✅ **zoom-us** cài sẵn                                                             |
| Zalo                                   | ⏳ chưa có package nixpkgs (hướng dẫn trong `customConfig/features.nix`)           |
| Chỉnh sửa ảnh & video (GIMP, Kdenlive) | ✅ tùy chọn (bỏ comment trong `features.nix`)                                      |
| Driver NVIDIA                          | ✅ màn chọn GPU trong Calamares (auto/nvidia/intel)                                |
| Múi giờ Việt Nam                       | ✅ `Asia/Ho_Chi_Minh` mặc định                                                     |
| Không lo virus / Rollback              | ✅ bản chất immutable của NixOS                                                    |

> **Vì sao WPS → LibreOffice + Google?** WPS Office trên Linux hay lỗi font tiếng Việt
> và symbol (ô vuông ☺☻) do thiếu font fallback. BamOS đã cài sẵn font MS (`corefonts`)
>
> - **`symbola`** (fix ô vuông) + `noto-fonts`, và để WPS thành tùy chọn — LibreOffice +
>   Google Docs vừa ổn định font vừa đáp ứng nhu cầu văn phòng.

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
│       └── features.nix       #     tính năng: timezone VN, fcitx5-unikey, LibreOffice + Google Docs...
├── installer/                 # cấu hình Calamares (nạp vào package qua override)
│   └── calamares/
│       ├── modules/nixos/     #   module Python: sinh config + dò GPU + nixos-install
│       └── config/modules/    #   partition, users, welcome, gpu (NVIDIA/Intel), device (laptop/desktop)
├── pkgs/bam/                  # ★ BamOS CLI (`bam`) — script bash thuần (package .#bam)
│   ├── bam.sh                 #   nguồn script (sửa ở đây, chạy `bash -n` để kiểm tra)
│   └── default.nix            #   gói: writeShellScriptBin "bam"
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

## Bam CLI (`bam`)

Mọi thao tác hệ thống gói gọn trong **1 lệnh `bam`** — tiếng Việt, tự dò host
(`lg` trên máy dev / `bamos` trên máy cài từ ISO), tự gắn tag
`NixOS-YY.MM.DD-HH:MM` khi switch/boot. Cài sẵn trên mọi máy dùng BamOS
(qua `modules/packages.nix`) — code tại `pkgs/bam/`.

```bash
bam update [--boot]   # ★ Cập nhật: tải cấu hình mới nhất từ GitHub + rebuild áp dụng ngay
bam switch [-u]       # rebuild + áp dụng ngay (tự gắn tag NixOS-YY.MM.DD-HH:MM)
bam boot [-u]         # rebuild, áp dụng khi khởi động lại (giữ hệ thống đang chạy)
bam build             # build thử, không áp dụng
bam lock              # chỉ cập nhật flake.lock (không rebuild)
bam iso               # build file ISO cài đặt (bamos-gnome-26.11-x86_64-linux.iso)
bam gc 7              # dọn rác /nix/store, giữ generation 7 ngày + đồng bộ boot menu
bam generations       # danh sách generation + khác biệt 2 bản gần nhất
bam rollback          # quay về generation trước
bam info              # thông tin hệ thống (host, kernel, GPU, RAM, disk...)
bam doctor            # kiểm tra sức khỏe (flake, disk, generation, git...)
bam publish "msg"      # (máy dev) commit → merge develop→main → push GitHub
bam help              # hướng dẫn đầy đủ
```

Ghi đè mặc định bằng env: `BAM_FLAKE_DIR` (thư mục flake, mặc định `/etc/nixos`),
`BAM_HOST` (tên host), `NO_COLOR` (tắt màu).

## Build ISO cài đặt (cho người dùng khác)

```bash
nix build .#iso          # hoặc: bam iso
# ISO nằm ở result/iso/*.iso — tên file: bamos-gnome-26.11-x86_64-linux.iso
# Ghi ra USB: dd if=result/iso/*.iso of=/dev/sdX bs=4M status=progress
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
sudo nano /etc/nixos/customConfig/features.nix  # tính năng: timezone, bộ gõ, văn phòng...
bam switch            # áp dụng thay đổi (không cần mạng)
# (tương đương: sudo nixos-rebuild switch --flake /etc/nixos#bamos)
```

### Cập nhật máy từ GitHub — `bam update`

Mọi cải tiến commit lên repo (`bamos` = `github:quocnho/bamos/main`) sẽ lan tới máy
người dùng bằng **1 lệnh** (tự kiểm tra mạng/đĩa, tải config + nixpkgs mới nhất,
rebuild và áp dụng ngay, tự gắn tag):

```bash
bam update            # tải cấu hình + ứng dụng/công cụ/thư viện mới nhất → áp dụng ngay
bam update --boot     # an toàn hơn: chỉ rebuild boot, áp dụng khi khởi động lại
```

Lệnh này cập nhật cả **cấu hình BamOS** (input `bamos` từ GitHub) lẫn **nixpkgs**
(nền tảng gói) — ứng dụng, công cụ, thư viện mới sẽ về máy sau khi rebuild.
Muốn chỉ cập nhật lockfile (không rebuild): `bam lock`.

## Máy chính (LG)

```bash
bam switch        # rebuild + áp dụng ngay (tự gắn tag NixOS-YY.MM.DD-HH:MM)
bam switch -u     # kèm nix flake update
bam boot          # boot thay vì switch (giữ generation cũ)
bam build         # build thử không áp dụng
```

- Alias cũ vẫn còn: `sw` = `bam switch`, `swu` = `bam switch -u`, `bt` = `bam boot`,
  `bu` = `bam build`, `dry` = `bam dry`, `fu` = `bam lock`, `ngc` = `bam gc` (xem `modules/shell.nix`).
- Tag `NixOS-YY.MM.DD-HH:MM` tự gắn mỗi lần switch trên MỌI máy (xem `profiles/common.nix`).
- User `quocnho` khai báo trực tiếp trong `hosts/lg.nix` (không hardcode trong modules/).

## Tham khảo GLF-OS → BamOS

| Tính năng               | GLF-OS                                                          | BamOS                                                                          |
| ----------------------- | --------------------------------------------------------------- | ------------------------------------------------------------------------------ |
| Flake hosts             | 1 `nixosConfiguration` / máy (`glf-installer`, `user-test`)     | `hosts/*.nix` + `nixosConfigurations.*`                                        |
| Profiles                | `glf.environment.edition` + `glf.features.*` (catalog)          | `profiles/*.nix` (import thuần, dễ ghép)                                       |
| ISO                     | `installation-cd-graphical-calamares-gnome.nix`                 | `installation-cd-graphical-calamares-gnome.nix` (giống GLF-OS)                 |
| Installer               | Calamares + module Python (sinh config, dò GPU, copy flake)     | Calamares + module Python (`installer/calamares/`) + **GPU + Laptop/Desktop**  |
| Post-install /etc/nixos | copy `iso-cfg/` (flake input `glf`)                             | copy `iso-cfg/` (flake input `bamos` = github) + `customConfig/`               |
| CLI                     | alias `glf-update/switch/build/clean/history/systeminfo` + `nh` | **`bam`** (1 lệnh, tiếng Việt, tự dò host, tự tag — `pkgs/bam/`)               |
| Update máy đích         | `glf-update` = `nix flake update` + `nixos-rebuild boot`        | `bam update` = flake update (kéo `github:quocnho/bamos/main`) + rebuild switch |

## Lộ trình nâng cấp (tùy chọn)

- **Zalo**: chưa có package nixpkgs — thêm vào `features.nix` khi có (hoặc cài AppImage từ zalo.me).
- **Hyprland / KDE Plasma**: website quảng cáo nhiều desktop — hiện BamOS cung cấp GNOME
  (profile desktop); roadmap: thêm option `bamos.desktop = "gnome" | "hyprland" | "kde"`.
- **Edition Minimum/Standard/Studio/Gaming** (theo bamos.info): roadmap — chọn edition lúc cài
  (như GLF-OS `packagechooser`), BamOS hiện là bản "Standard" (GNOME + LibreOffice + Google/Chrome/Zoom).
- **Branding riêng**: hiện dùng branding `nixos` của package — có thể thêm
  `installer/calamares/branding/bamos/` và đổi `branding:` trong settings.conf.
- **Binary cache (Attic)**: đẩy closure lên cache riêng để `nixos-install` tải nhanh hơn (GLF-OS dùng Attic + CI).
