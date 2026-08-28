#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# Bamos — module Calamares "nixos"
#
# Trái tim của installer (tham khảo calamares-nixos-extensions của nixpkgs
# + module "nixos" của GLF-OS):
#   1. nixos-generate-config --root <root>            → hardware-configuration.nix
#   2. Ghi configuration.nix (hostname + user + password)
#   3. Copy flake mẫu vào /etc/nixos (input "bamos" = github:quocnho/bamos)
#   4. Pre-generate flake.lock (tránh NAR hash mismatch — bài học GLF-OS)
#   5. nixos-install --flake <root>/etc/nixos#bamos --no-root-passwd
#
# Sau khi cài, máy đích sống bằng config kéo từ github.com/quocnho/bamos.

import libcalamares
import os
import subprocess

# Cấu hình sinh bởi installer — desktop/module thật lấy từ repo bamos qua flake.
CFG_TEMPLATE = """\
# Bamos — cấu hình sinh bởi Calamares (bamos-install).
# Cấu hình thật được kéo từ github.com/quocnho/bamos qua input "bamos" trong flake.nix.
{ config, pkgs, ... }:
{{
  imports = [ ./hardware-configuration.nix ];

  networking.hostName = "{hostname}";

  users.users."{username}" = {{
    isNormalUser = true;
    description = "{fullname}";
    extraGroups = [ "networkmanager" "wheel" ];
    initialPassword = "{password}";
    shell = pkgs.zsh;
  }};

  system.stateVersion = "25.11";
}}
"""

SOURCE_DIR = "/installer"  # nhúng vào ISO qua isoImage.contents
HOSTNAME_DEFAULT = "bamos"


def _write_root(path, content):
    """Ghi file vào hệ thống đích (cần root → pkexec)."""
    tmp = "/tmp/bamos-config-write"
    with open(tmp, "w") as f:
        f.write(content)
    subprocess.check_call(["pkexec", "cp", tmp, path])
    os.unlink(tmp)


def run():
    gs = libcalamares.globalstorage
    root = gs.value("rootMountPoint")
    if not root:
        return ("Không có rootMountPoint", "Phân vùng/mount chưa hoàn tất?")

    username = gs.value("username") or "user"
    fullname = gs.value("fullName") or username
    password = gs.value("userPassword") or ""
    hostname = gs.value("hostname") or HOSTNAME_DEFAULT

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

    # 2) Ghi configuration.nix + 3) copy flake mẫu
    libcalamares.job.setprogress(0.10)
    cfg = CFG_TEMPLATE.format(
        hostname=hostname,
        username=username,
        fullname=fullname,
        password=password,
    )
    try:
        _write_root(os.path.join(nixos_dir, "configuration.nix"), cfg)
        subprocess.check_output(
            ["pkexec", "cp", os.path.join(SOURCE_DIR, "flake.nix"), os.path.join(nixos_dir, "flake.nix")],
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
                "pkexec", "nixos-install",
                "--no-root-passwd",
                "--root", root,
                "--flake", os.path.join(nixos_dir, "#bamos"),
                "--option", "build-users-group", "",
                "--option", "sandbox", "false",
            ],
            stderr=subprocess.STDOUT,
        )
    except subprocess.CalledProcessError as e:
        return ("nixos-install thất bại", e.output.decode("utf8", "replace"))

    libcalamares.job.setprogress(1.0)
    return None
