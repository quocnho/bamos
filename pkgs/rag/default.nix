{
  lib,
  buildGoModule,
}:

buildGoModule rec {
  pname = "bamos-rag";
  version = "0.1.0";

  src = ./.;

  vendorHash = "sha256-hYe2Qa8Bxf9d6is1a+ik4qFJNEIEYMFmDnzdTsbF70s=";

  subPackages = [ "cmd/rag-service" ];

  postInstall = ''
    mv $out/bin/rag-service $out/bin/bamos-rag
  '';

  meta = with lib; {
    description = "BamOS Embedded RAG Service (Golang + chromem-go)";
    license = licenses.mit;
    maintainers = [ ];
    mainProgram = "bamos-rag";
  };
}
