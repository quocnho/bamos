# Module RAG (Retrieval-Augmented Generation) cho BamOS sử dụng chromem-go
#
# Cung cấp:
#  - Package bamos-rag (HTTP Service: /index, /query, /ask)
#  - Systemd service on-demand (bamos-rag.service) kết nối tới llama-server (mặc định port 8080)
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.rag;

  bamosRagPkg = pkgs.callPackage ../pkgs/rag { };
in
{
  options.my.rag = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Kích hoạt dịch vụ RAG nhúng (chromem-go + Golang) cho BamOS.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 8090;
      description = "Cổng lắng nghe của bamos-rag service.";
    };

    storagePath = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/bamos/rag/knowledge.db";
      description = "Đường dẫn file database vector chromem-go.";
    };

    llamaHost = lib.mkOption {
      type = lib.types.str;
      default = "http://127.0.0.1:9090";
      description = "Địa chỉ kết nối đến llama-server để lấy embedding và inference.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      bamosRagPkg
    ];

    systemd.tmpfiles.rules = [
      "d /var/lib/bamos/rag 0777 root root -"
    ];

    # Service on-demand (chỉ chạy khi được gọi bằng systemctl start hoặc bam rag start)
    systemd.services.bamos-rag = {
      description = "BamOS Embedded Vector Engine (chromem-go)";
      after = [
        "network.target"
        "bamos-ai.service"
      ];
      environment = {
        PORT = toString cfg.port;
        STORAGE_PATH = cfg.storagePath;
        LLAMA_HOST = cfg.llamaHost;
      };
      serviceConfig = {
        Type = "simple";
        ExecStart = "${bamosRagPkg}/bin/bamos-rag";
        Restart = "on-failure";
        RestartSec = "3s";
      };
    };
  };
}
