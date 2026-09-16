{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "troly-dev";

  nativeBuildInputs = with pkgs; [
    pkg-config
    go
    gopls
  ];

  buildInputs = with pkgs; [
    gtk3
    webkitgtk_4_1
    sqlite
    sqlite-vec
  ];

  shellHook = ''
    export PKG_CONFIG_PATH="${pkgs.lib.makeSearchPathOutput "dev" "lib/pkgconfig" [ pkgs.gtk3 pkgs.webkitgtk_4_1 pkgs.sqlite pkgs.sqlite-vec ]}:$PKG_CONFIG_PATH"
    export CGO_ENABLED=1
  '';
}
