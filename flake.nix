{
  description = "BamOS — NixOS distribution for the Vietnamese community";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";
    agenix.url = "github:ryantm/agenix";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      top@{ self, ... }: {
        systems = [ "x86_64-linux" ];

        # Import internal flake modules (host definitions + ISO)
        imports = [
          ./hosts
        ];

        perSystem =
          { pkgs, system, ... }:
          {
            # Custom packages + ISO builds
            packages =
              (import ./pkgs pkgs)
              // builtins.listToAttrs (map
                (name: {
                  inherit name;
                  value = import ./lib/mkISO.nix {
                    nixosConfiguration = top.self.nixosConfigurations.${name};
                  };
                }) [
                "iso-gnome-standard"
                "iso-gnome-developers"
                "iso-gnome-gaming"
                "iso-gnome-studio"
                "iso-kde-standard"
                "iso-kde-developers"
                "iso-kde-gaming"
                "iso-kde-studio"
                "iso-cosmic-standard"
                "iso-cosmic-developers"
                "iso-cosmic-gaming"
                "iso-cosmic-studio"
              ]);

            # Nix formatter
            formatter = pkgs.nixpkgs-fmt;

            # Dev shell cho Nix development
            devShells.default = pkgs.mkShell {
              packages = with pkgs; [
                nil
                nix-output-monitor
                nixpkgs-fmt
                deadnix
                statix
                nixd
                cachix
              ];
            };

            # Convenience: build ISO + copy to /iso/
            apps.iso-export = {
              type = "app";
              program = builtins.toString
                (pkgs.writeShellApplication {
                  name = "iso-export";
                  text = ''
                    set -euo pipefail
                    VARIANT="''${1:-iso-gnome-standard}"
                    echo "🔨 Building $VARIANT..."
                    OUT="./result-''${VARIANT}"
                    nix build ".#$VARIANT" --out-link "$OUT" 2>&1 | tail -3
                    echo ""
                    echo "📀 Copying ISO to /iso/..."
                    mkdir -p iso
                    ISO_FILE=$(find "$OUT/iso" -name "*.iso" -type f | head -1)
                    if [ -n "$ISO_FILE" ]; then
                      cp "$ISO_FILE" iso/
                      echo "✅ ISO copied: iso/$(basename "$ISO_FILE")"
                      ls -lh "iso/$(basename "$ISO_FILE")"
                    else
                      echo "⚠ No ISO file found in build output"
                    fi
                    ln -sfn "$OUT" result-latest 2>/dev/null || true
                  '';
                }) + "/bin/iso-export";
            };

            # Convenience: push built ISO to Cachix cache
            apps.push-cachix = {
              type = "app";
              program = builtins.toString
                (pkgs.writeShellApplication {
                  name = "push-cachix";
                  runtimeInputs = [ pkgs.cachix ];
                  text = ''
                    set -e
                    echo "Building ISO..."
                    nix build .#iso-gnome-standard --no-link --print-out-paths | while read -r path; do
                      echo "Pushing to Cachix: $path"
                      cachix push bamos "$path"
                    done
                    echo "Done! Cache pushed to https://bamos.cachix.org"
                  '';
                }) + "/bin/push-cachix";
            };

            # One-command: switch + push cache
            apps.update = {
              type = "app";
              program = builtins.toString
                (pkgs.writeShellScriptBin "bamos-update" ''
                  set -e
                  echo "=== 1. Rebuild system ==="
                  sudo nixos-rebuild switch --flake .#
                  echo ""
                  echo "=== 2. Push ISO to Cachix ==="
                  nix run .#push-cachix
                  echo ""
                  echo "✅ Done! System updated + cache pushed."
                '') + "/bin/bamos-update";
            };
          };

        flake = {
          # NixOS modules có thể tái sử dụng
          nixosModules = {
            default = import ./modules;
          };

          # Overlays cho nixpkgs
          overlays = import ./overlays { inherit inputs; };
        };
      }
    );
}
