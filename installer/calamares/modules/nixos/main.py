#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Bamos — module Calamares "nixos"
#
# Trái tim của installer (tham khảo calamares-nixos-extensions của nixpkgs
# + module "nixos" của GLF-OS):
#   1. nixos-generate-config --root <root>            → hardware-configuration.nix
#   2. Ghi configuration.nix (hostname + user + GPU theo lựa chọn)
#   3. Copy flake mẫu (/iso-cfg → /etc/nixos) — input "bamos" = github:quocnho/bamos
#   4. Pre-generate flake.lock (tránh NAR hash mismatch — bài học GLF-OS)
#   5. nixos-install --flake <root>/etc/nixos#bamos --no-root-passwd
#
# Sau khi cài, máy đích sống bằng config kéo từ github.com/quocnho/bamos.

import os
import re
import subprocess

import libcalamares

# Cấu hình sinh bởi installer — desktop/module thật lấy từ repo bamos qua flake.
CFG_TEMPLATE = """\
# Bamos — cấu hình sinh bởi Calamares (bamos-install).
# Cấu hình thật được kéo từ github.com/quocnho/bamos qua input "bamos" trong flake.nix.
{{ config, lib, pkgs, ... }}:
{{
  imports = [ ./hardware-configuration.nix ];

  # Tên máy MẶC ĐỊNH "bamos" — đổi được trong /etc/nixos/customConfig/features.nix
  # (networking.hostName = "...";  sẽ ghi đè mkDefault này).
  networking.hostName = lib.mkDefault "{hostname}";

  users.users."{username}" = {{
    isNormalUser = true;
    description = "{fullname}";
    # extraGroups đầy đủ — đảm bảo wifi (networkmanager), bluetooth, input,
    # video/audio, in ấn (lp/scanner), mount ổ đĩa (disk/storage), sudo (wheel)...
    extraGroups = [ "networkmanager" "wheel" "bluetooth" "input" "video" "audio" "render" "disk" "storage" "lp" "scanner" "power" ];
    initialPassword = "{password}";
    shell = pkgs.zsh;
  }};
{gpu_cfg}{device_cfg}
  system.stateVersion = "25.11";
}}
"""

SOURCE_DIR = "/iso-cfg"  # nhúng vào ISO qua isoImage.contents (profiles/installer.nix)
HOSTNAME_DEFAULT = "bamos"


def _write_root(path, content):
    """Ghi file vào hệ thống đích (cần root → pkexec)."""
    tmp = "/tmp/bamos-config-write"
    with open(tmp, "w") as f:
        f.write(content)
    subprocess.check_call(["pkexec", "cp", tmp, path])
    os.unlink(tmp)


def _detect_gpus():
    """
    Dò GPU bằng lspci (như GLF-OS).
    Trả về {"intel": "PCI:0:2:0", "nvidia": "PCI:1:0:0"} (bỏ số 0 thừa).
    """
    try:
        out = subprocess.check_output(
            ["lspci", "-nn"], stderr=subprocess.STDOUT
        ).decode("utf8", "replace")
    except Exception:
        return {}

    gpus = {}
    for line in out.splitlines():
        m = re.search(
            r"([0-9a-f]{2}):([0-9a-f]{2})\.([0-9a-f]).*?(VGA compatible controller|3D controller)",
            line,
        )
        if not m:
            continue
        bus = "PCI:{}:{}:{}".format(
            int(m.group(1), 16), int(m.group(2), 16), int(m.group(3), 16)
        )
        low = line.lower()
        if "nvidia" in low:
            gpus["nvidia"] = bus
        elif "intel" in low:
            gpus["intel"] = bus
        elif "3d controller" in low:
            gpus["nvidia"] = bus  # card rời không phải Intel → coi như NVIDIA
    return gpus


def _gpu_config(choice, gpus):
    """
    Sinh khối cấu hình GPU (màn "Cấu hình GPU" của Calamares).
    - auto:   dò lspci → NVIDIA Optimus (Intel+NVIDIA) thì bật my.gpu.
    - nvidia: ép bật driver NVIDIA (Optimus nếu có iGPU, else driver đơn).
    - intel:  chỉ dùng iGPU (mặc định kernel) — không thêm gì.
    """
    if choice == "intel":
        return ""

    if choice in ("auto", "nvidia"):
        if gpus.get("intel") and gpus.get("nvidia"):
            return """
  # ==== GPU (Calamares dò: NVIDIA Optimus — Intel + NVIDIA) ====
  my.gpu.enable = true;
  my.gpu.intelBusId = "{intel}";
  my.gpu.nvidiaBusId = "{nvidia}";
""".format(intel=gpus["intel"], nvidia=gpus["nvidia"])
        if gpus.get("nvidia"):
            # NVIDIA-only (desktop, không có iGPU Intel đi kèm)
            return """
  # ==== GPU NVIDIA (không có iGPU Intel) ====
  nixpkgs.config.allowUnfree = true;
  services.xserver.videoDrivers = [ "nvidia" ];
"""
    # auto nhưng không dò được NVIDIA → dùng iGPU/mặc định
    return ""


def _device_config(choice):
    """
    Sinh khối cấu hình theo LOẠI MÁY (màn "Loại máy" của Calamares).
    - laptop:  bật quản lý năng lượng (my.power: TLP + s2idle + thermald + lid).
    - desktop: không cần quản lý pin — dùng mặc định (power-profiles-daemon của GNOME).
    """
    if choice == "laptop":
        return """
  # ==== Máy xách tay: quản lý năng lượng (TLP + s2idle + thermald) ====
  my.power.enable = true;
"""
    return """
  # ==== Máy bàn (desktop): không cần quản lý pin ====
"""


def run():
    gs = libcalamares.globalstorage
    root = gs.value("rootMountPoint")
    if not root:
        return ("Không có rootMountPoint", "Phân vùng/mount chưa hoàn tất?")

    username = gs.value("username") or "user"
    fullname = gs.value("fullName") or username
    password = gs.value("userPassword") or ""
    hostname = gs.value("hostname") or HOSTNAME_DEFAULT
    gpu_choice = gs.value("packagechooser_gpu") or "auto"
    device_choice = gs.value("packagechooser_device") or "desktop"

    if not password:
        return ("Thiếu mật khẩu", "Vui lòng nhập mật khẩu ở bước Users.")

    nixos_dir = os.path.join(root, "etc/nixos")

    # 1) Sinh hardware-configuration.nix (tự dò phần cứng)
    libcalamares.job.setprogress(0.05)
    try:
        subprocess.check_output(
            ["pkexec", "nixos-generate-config", "--root", root],
            stderr=subprocess.STDOUT,
        )
    except subprocess.CalledProcessError as e:
        return ("nixos-generate-config thất bại", e.output.decode("utf8", "replace"))

    # 2) Dò GPU (như GLF-OS) + ghi configuration.nix
    libcalamares.job.setprogress(0.10)
    gpus = _detect_gpus()
    cfg = CFG_TEMPLATE.format(
        hostname=hostname,
        username=username,
        fullname=fullname,
        password=password,
        gpu_cfg=_gpu_config(gpu_choice, gpus),
        device_cfg=_device_config(device_choice),
    )
    try:
        _write_root(os.path.join(nixos_dir, "configuration.nix"), cfg)
        # 3) Copy flake mẫu + customConfig (input bamos = github:quocnho/bamos)
        subprocess.check_output(
            [
                "pkexec",
                "cp",
                os.path.join(SOURCE_DIR, "flake.nix"),
                os.path.join(nixos_dir, "flake.nix"),
            ],
            stderr=subprocess.STDOUT,
        )
        subprocess.check_output(
            ["pkexec", "cp", "-r", os.path.join(SOURCE_DIR, "customConfig"), nixos_dir],
            stderr=subprocess.STDOUT,
        )
    except subprocess.CalledProcessError as e:
        return ("Không ghi được /etc/nixos", e.output.decode("utf8", "replace"))

    # 4) Pre-generate flake.lock (cần mạng; thất bại chỉ cảnh báo — nixos-install tự lock)
    libcalamares.job.setprogress(0.15)
    try:
        subprocess.check_output(
            ["pkexec", "nix", "flake", "lock", "--flake", nixos_dir],
            stderr=subprocess.STDOUT,
            timeout=900,
        )
    except Exception as e:
        libcalamares.utils.warning("nix flake lock thất bại (cần mạng): {}".format(e))

    # 5) nixos-install --flake <root>/etc/nixos#bamos (có thể 15-40 phút)
    libcalamares.job.setprogress(0.20)
    try:
        subprocess.check_output(
            [
                "pkexec",
                "nixos-install",
                "--no-root-passwd",
                "--root",
                root,
                "--flake",
                os.path.join(nixos_dir, "#bamos"),
                "--option",
                "build-users-group",
                "",
                "--option",
                "sandbox",
                "false",
            ],
            stderr=subprocess.STDOUT,
        )
    except subprocess.CalledProcessError as e:
        return ("nixos-install thất bại", e.output.decode("utf8", "replace"))

    libcalamares.job.setprogress(1.0)
    return None
