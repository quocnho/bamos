# Module Local AI (SLM) cho BamOS sử dụng llama-server (llama.cpp) & TroLy (Trợ lý ảo)
#
# Cung cấp:
#  - pkgs.llama-cpp (llama-server, llama-cli...)
#  - Script bamos-ai-server (khởi chạy model với các biến môi trường cấu hình linh hoạt)
#  - Package pkgs/troly (ứng dụng Trợ lý Mascot AI độc lập)
#  - Systemd service (bamos-ai.service) ở chế độ on-demand hoặc autoStart
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.my.ai;

  trolyPkg = pkgs.callPackage ../pkgs/troly { };

  # Script khởi chạy llama-server với các tham số tối ưu
  aiServerScript = pkgs.writeShellScriptBin "bamos-ai-server" ''
    set -euo pipefail

    MODEL_DIR="${cfg.modelDir}"
    # Cho phép ứng dụng TroLy ghi đè khi người dùng chọn model / tham số khác trên giao diện
    # (BAMAI_MODEL_PATH, BAMAI_NGL, BAMAI_CTX, BAMAI_PORT).
    MODEL_PATH="''${BAMAI_MODEL_PATH:-${cfg.modelPath}}"
    PORT="''${BAMAI_PORT:-${toString cfg.port}}"
    HOST="${cfg.host}"
    NGL="''${BAMAI_NGL:-${toString cfg.gpuLayers}}"
    CTX="''${BAMAI_CTX:-${toString cfg.contextSize}}"

    # Tạo thư mục model nếu chưa có
    mkdir -p "$MODEL_DIR"

    # Nếu file model chưa tồn tại, thông báo người dùng tải
    if [ ! -f "$MODEL_PATH" ]; then
      echo " [33m[!] Model GGUF không tồn tại tại: $MODEL_PATH [0m"
      echo " [36m==> Bạn có thể tải tự động model Qwen2.5-1.5B bằng lệnh: [0m"
      echo "    bam ai pull"
      echo " [36m==> Hoặc tải trực tiếp từ Bảng thiết lập LLM trong ứng dụng TroLy [0m"
      exit 1
    fi

    echo " [32m[OK] [0m Khởi động Local AI Server (llama-server)..."
    echo "     Model: $MODEL_PATH"
    echo "     Host:  http://$HOST:$PORT"
    echo "     GPU Offload layers (-ngl): $NGL"
    echo "     Context size: $CTX"

    UI_CONFIG="${
      pkgs.writeText "bamai-webui.json" (
        builtins.toJSON {
          system_prompt = "Bạn là Trợ lý AI thông minh trên hệ điều hành BamOS. Hãy luôn trả lời hoàn toàn bằng Tiếng Việt một cách chuẩn xác, tự nhiên, rõ ràng và thân thiện.";
        }
      )
    }"

    exec ${pkgs.llama-cpp}/bin/llama-server \
      --model "$MODEL_PATH" \
      --host "$HOST" \
      --port "$PORT" \
      -ngl "$NGL" \
      -c "$CTX" \
      --embedding \
      --pooling cls \
      --ui-config-file "$UI_CONFIG" \
      --metrics
  '';
in
{
  options.my.ai = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Kích hoạt hạ tầng Local AI (llama-server + SLM) và ứng dụng TroLy cho BamOS.";
    };

    autoStart = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Tự động khởi động llama-server cùng hệ thống. Mặc định tắt để tiết kiệm RAM và pin laptop.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = "Địa chỉ IP bind của llama-server.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 9090;
      description = "Cổng lắng nghe của llama-server (mặc định 9090 để tránh xung đột cổng 8080).";
    };

    modelDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/bamos/models";
      description = "Thư mục lưu trữ các model GGUF.";
    };

    modelPath = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/bamos/models/qwen2.5-1.5b-instruct-q4_k_m.gguf";
      description = "Đường dẫn file GGUF mặc định.";
    };

    gpuLayers = lib.mkOption {
      type = lib.types.int;
      default = 99; # Offload toàn bộ layer lên GPU (GTX 1650 4GB chứa thoải mái Qwen 1.5B)
      description = "Số layer offload lên GPU (-ngl). Đặt 0 để chạy thuần CPU.";
    };

    contextSize = lib.mkOption {
      type = lib.types.int;
      default = 4096;
      description = "Độ dài context window (tokens).";
    };
  };

  config = lib.mkIf cfg.enable {
    # Cài đặt llama-cpp, script bamos-ai-server và ứng dụng TroLy vào hệ thống
    environment.systemPackages = [
      pkgs.llama-cpp
      aiServerScript
      trolyPkg
    ];

    # Tạo thư mục chứa model, RAG vector database và trạng thái với quyền đọc ghi cho user
    systemd.tmpfiles.rules = [
      "d ${cfg.modelDir} 0777 root root -"
      "d /var/lib/bamos 0777 root root -"
      # Thư mục tri thức RAG — dùng bởi RAG (SQLite FTS5 + sqlite-vec) tích hợp trong TroLy
      "d /var/lib/bamos/rag 0777 root root -"
      # Thư mục TRẠNG THÁI: TroLy lưu vị trí pet/cửa sổ tại đây
      "d /var/lib/bamos/state 0777 root root -"
    ];

    # Tự động tạo Shortcut trên màn hình Desktop của người dùng
    systemd.user.tmpfiles.rules = [
      "C %h/Desktop/TroLy.desktop - - - - ${trolyPkg}/share/applications/org.bamos.troly.desktop"
    ];

    # Service systemd: nếu autoStart = true thì chạy cùng hệ thống, ngược lại on-demand
    systemd.services.bamos-ai = {
      description = "BamOS Local AI Server (llama-server)";
      after = [ "network.target" ];
      wantedBy = lib.mkIf cfg.autoStart [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${aiServerScript}/bin/bamos-ai-server";
        Restart = "on-failure";
        RestartSec = "3s";
      };
    };
  };
}
