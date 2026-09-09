{
  lib,
  rustPlatform,
  pkg-config,
  gtk4,
  libadwaita,
  openssl,
  wrapGAppsHook4,
}:

rustPlatform.buildRustPackage {
  pname = "bamos-assistant";
  version = "0.1.0";

  src = ./.;

  cargoLock = {
    lockFile = ./Cargo.lock;
  };

  nativeBuildInputs = [
    pkg-config
    wrapGAppsHook4
  ];

  buildInputs = [
    gtk4
    libadwaita
    openssl
  ];

  postInstall = ''
    install -Dm644 org.bamos.assistant.desktop $out/share/applications/org.bamos.assistant.desktop
    install -Dm644 ${../../assets/icons/bamai.svg} $out/share/icons/hicolor/scalable/apps/bamos-assistant.svg
  '';

  meta = with lib; {
    description = "BamOS Floating AI Assistant (Deepin OS style)";
    license = licenses.mit;
    mainProgram = "bamos-assistant";
  };
}
