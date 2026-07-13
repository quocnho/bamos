#!/usr/bin/env python3
# BamOS Calamares module
# Copies iso-cfg template → /etc/nixos/, applies user selections
#
# Template structure:
#   /etc/nixos-template/
#   ├── flake.nix
#   ├── configuration.nix
#   ├── customized.nix
#   ├── modules/default.nix
#   ├── customConfig/default.nix  ← NEVER overwritten
#   ├── README.md
#   ├── home.nix
#   └── secrets/README.md

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


def copy_template(target, template_dir):
    """Copy template recursively, preserving customConfig/"""
    custom_config_src = os.path.join(template_dir, "customConfig")
    custom_config_dst = os.path.join(target, "customConfig")
    custom_config_data = None

    # Backup customConfig/ if exists (never overwrite)
    if os.path.exists(custom_config_dst):
        with open(os.path.join(custom_config_dst, "default.nix"), "r") as f:
            custom_config_data = f.read()

    # Copy all template files
    for item in os.listdir(template_dir):
        src = os.path.join(template_dir, item)
        dst = os.path.join(target, item)
        if os.path.isdir(src):
            shutil.copytree(src, dst, dirs_exist_ok=True)
        else:
            shutil.copy2(src, dst)

    # Restore customConfig/ if existed (user customizations preserved)
    if custom_config_data is not None:
        os.makedirs(custom_config_dst, exist_ok=True)
        with open(os.path.join(custom_config_dst, "default.nix"), "w") as f:
            f.write(custom_config_data)


def run():
    edition = libcalamares.globalStorage.value("packagechooser_edition") or "standard"
    machine = libcalamares.globalStorage.value("packagechooser_machine") or "desktop"
    hostname = libcalamares.globalStorage.value("hostname") or "bamos"
    root = libcalamares.globalStorage.value("rootMountPoint") or "/mnt"

    # Target: installed system's /etc/nixos/
    target = os.path.join(root, "etc", "nixos")
    os.makedirs(target, exist_ok=True)

    # Source: ISO's bundled iso-cfg template
    template_dir = "/etc/nixos-template"

    if os.path.exists(template_dir):
        copy_template(target, template_dir)
    else:
        # Fallback: create minimal files
        with open(os.path.join(target, "flake.nix"), "w") as f:
            f.write('''{
  description = "BamOS — My Configuration";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    bamos.url = "github:quocnho/bamos";
  };
  outputs = { self, nixpkgs, bamos, ... }: {
    nixosConfigurations."''' + hostname + '''" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        bamos.nixosModules.default
        bamos.nixosModules."''' + edition + '''"
        ./hardware-configuration.nix
      ];
    };
  };
}''')
        # Create basic configuration.nix
        with open(os.path.join(target, "configuration.nix"), "w") as f:
            f.write('''{ ... }: {
  networking.hostName = "''' + hostname + '''";
  system.stateVersion = "26.05";
}''')

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

    # Create README symlink pointing to user's /etc/nixos/
    readme_path = os.path.join(target, "README.md")
    if os.path.exists(readme_path):
        print("  ✅ README copied")

    return libcalamares.job.succeed(
        "BamOS config deployed: edition=%s, machine=%s, hostname=%s "
        "- /etc/nixos/ structure ready for customization"
        % (edition, machine, hostname)
    )
