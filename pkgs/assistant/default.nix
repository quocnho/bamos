{
  lib,
  buildGoModule,
  pkg-config,
  gtk3,
  webkitgtk_4_1,
  wrapGAppsHook3,
  sqlite,
  sqlite-vec,
}:

buildGoModule rec {
  pname = "bamos-assistant";
  version = "0.3.0";

  src = ./.;

  vendorHash = null;

  subPackages = [ "backend/cmd/assistant" ];

  nativeBuildInputs = [
    pkg-config
    wrapGAppsHook3
  ];

  buildInputs = [
    gtk3
    webkitgtk_4_1
    sqlite
    sqlite-vec
  ];

  postInstall = ''
    install -Dm644 org.bamos.assistant.desktop $out/share/applications/org.bamos.assistant.desktop
    install -Dm644 org.bamos.assistant.desktop $out/etc/xdg/autostart/org.bamos.assistant.desktop
    install -Dm644 ${../../assets/icons/bamai.svg} $out/share/icons/hicolor/scalable/apps/bamos-assistant.svg
    install -Dm755 nautilus-bone-context.sh $out/bin/bam-bone-context
    install -Dm755 nautilus-bone-context.sh "$out/share/nautilus/scripts/🍖 Gửi thư mục vào BamAI (Cục Xương)"
  '';

  meta = with lib; {
    description = "BamOS Mascot AI Assistant (Transparent Desktop Pet + RAG + SLM)";
    license = licenses.mit;
    mainProgram = "bamos-assistant";
  };
}
