#!/usr/bin/env python3
# BamOS Calamares module
# Copies iso-cfg template → /etc/nixos/, applies user selections
# See also: modules/boot/calamares.nix for branding and environment config

import libcalamares
import os
import shutil


def sed_inplace(filename, old, new):
    """Replace text in file (in-place)"""
    with open(filename, "r") as f:
        content = f.read()
    content = content.replace(old, new)
    with open(filename, "w") as f:
        f.write(content)


def run():
    edition = libcalamares.globalStorage.value("packagechooser_edition") or "standard"
    machine = libcalamares.globalStorage.value("packagechooser_machine") or "desktop"
    hostname = libcalamares.globalStorage.value("hostname") or "bamos"
    root = libcalamares.globalStorage.value("rootMountPoint") or "/mnt"

    # Target: installed system's /etc/nixos/
    target = os.path.join(root, "etc", "nixos")
    os.makedirs(target, exist_ok=True)

    # Source: ISO's bundled iso-cfg template (from environment.etc)
    # On the ISO live, these are at /etc/nixos-template/
    template_dir = "/etc/nixos-template"

    if os.path.exists(template_dir):
        for item in os.listdir(template_dir):
            src = os.path.join(template_dir, item)
            dst = os.path.join(target, item)
            if os.path.isdir(src):
                shutil.copytree(src, dst, dirs_exist_ok=True)
            else:
                shutil.copy2(src, dst)

    # Apply user selections to customized.nix
    customized_path = os.path.join(target, "customized.nix")
    if os.path.exists(customized_path):
        edition_map = {
            "standard": "bamos.nixosModules.standard",
            "developers": "bamos.nixosModules.developers",
            "gaming": "bamos.nixosModules.gaming",
            "studio": "bamos.nixosModules.studio",
        }
        if edition in edition_map:
            sed_inplace(customized_path,
                        "bamos.nixosModules.standard",
                        edition_map[edition])

        if machine == "laptop":
            sed_inplace(customized_path,
                        "batteryOptimized = false;",
                        "batteryOptimized = true;")

    # Set hostname in configuration.nix
    config_path = os.path.join(target, "configuration.nix")
    if os.path.exists(config_path):
        sed_inplace(config_path, '"bamos"', '"' + hostname + '"')

    return libcalamares.job.succeed(
        "BamOS config deployed: edition=%s, machine=%s, hostname=%s"
        % (edition, machine, hostname)
    )
