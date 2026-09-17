{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  name = "troly-dev";

  nativeBuildInputs = with pkgs; [
    pkg-config
    go
    gopls
  ];

  buildInputs = with pkgs; [
    gtk4
    webkitgtk_6_0
    sqlite
    sqlite-vec
  ];

  shellHook = ''
    export PKG_CONFIG_PATH="${pkgs.lib.makeSearchPathOutput "dev" "lib/pkgconfig" [ pkgs.gtk4 pkgs.webkitgtk_6_0 pkgs.sqlite pkgs.sqlite-vec ]}:$PKG_CONFIG_PATH"
    export CGO_ENABLED=1
  '';
}
