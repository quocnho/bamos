{
  lib,
  stdenv,
  cmake,
  ninja,
  pkg-config,
  qt6,
  sqlite,
  sqlite-vec,
}:

stdenv.mkDerivation rec {
  pname = "troly";
  version = "0.1.0";

  src = lib.cleanSourceWith {
    src = ./.;
    filter = path: type:
      let baseName = baseNameOf (toString path);
      in baseName != "build" && baseName != ".git" && baseName != "result";
  };

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
    qt6.wrapQtAppsHook
  ];

  buildInputs = [
    qt6.qtbase
    qt6.qtdeclarative
    sqlite
    sqlite-vec
  ];

  meta = with lib; {
    description = "Troly - Native Edge AI Desktop Companion (C++20, Qt6, Hybrid RAG)";
    homepage = "https://bamos.info";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "troly";
  };
}
