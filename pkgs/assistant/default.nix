{
  lib,
  buildGoModule,
  pkg-config,
  gtk3,
  webkitgtk_4_1,
  wrapGAppsHook3,
}:

buildGoModule rec {
  pname = "bamos-assistant";
  version = "0.2.0";

  src = ./.;

  vendorHash = "sha256-hYe2Qa8Bxf9d6is1a+ik4qFJNEIEYMFmDnzdTsbF70s=";

  nativeBuildInputs = [
    pkg-config
    wrapGAppsHook3
  ];

  buildInputs = [
    gtk3
    webkitgtk_4_1
  ];

  postInstall = ''
    install -Dm644 org.bamos.assistant.desktop $out/share/applications/org.bamos.assistant.desktop
    install -Dm644 ${../../assets/icons/bamai.svg} $out/share/icons/hicolor/scalable/apps/bamos-assistant.svg
  '';

  meta = with lib; {
    description = "BamOS Mascot AI Assistant (Transparent Desktop Pet + RAG + SLM)";
    license = licenses.mit;
    mainProgram = "bamos-assistant";
  };
}
