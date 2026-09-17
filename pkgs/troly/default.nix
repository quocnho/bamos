{
  lib,
  buildGoModule,
  pkg-config,
  gtk4,
  webkitgtk_6_0,
  wrapGAppsHook4,
  sqlite,
  sqlite-vec,
}:

buildGoModule rec {
  pname = "troly";
  version = "0.3.0";

  src = ./.;

  vendorHash = null;

  subPackages = [ "backend/cmd/troly" ];

  nativeBuildInputs = [
    pkg-config
    wrapGAppsHook4
  ];

  buildInputs = [
    gtk4
    webkitgtk_6_0
    sqlite
    sqlite-vec
  ];

  postInstall = ''
    install -Dm644 org.bamos.troly.desktop $out/share/applications/org.bamos.troly.desktop
    install -Dm644 org.bamos.troly.desktop $out/etc/xdg/autostart/org.bamos.troly.desktop
    install -Dm644 ${../../assets/icons/bamai.svg} $out/share/icons/hicolor/scalable/apps/troly.svg
    install -Dm755 nautilus-bone-context.sh $out/bin/bam-bone-context
    install -Dm755 nautilus-bone-context.sh "$out/share/nautilus/scripts/🍖 Gửi thư mục vào Trợ lý (Cục Xương)"
    ln -s $out/bin/troly $out/bin/bamos-assistant
  '';

  meta = with lib; {
    description = "TroLy (Trợ lý) - BamOS Desktop AI Mascot Pet (Wails v3 + WebKitGTK 6.0 + sqlite-vec)";
    license = licenses.mit;
    mainProgram = "troly";
  };
}
