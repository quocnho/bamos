# Hướng dẫn Sử dụng Hệ thống BamAI & RAG Studio trên BamOS 🎋

**BamAI** là hệ thống Trí tuệ nhân tạo cục bộ (Local SLM) và bộ công cụ **RAG (Retrieval-Augmented Generation)** tích hợp native trên hệ điều hành BamOS. Hệ thống hoạt động hoàn toàn bằng **Tiếng Việt**, hỗ trợ lưu trữ vector nhúng cục bộ và cho phép liên thông linh hoạt với các dịch vụ Cloud LLM (như DeepSeek API) để nâng cao chất lượng xử lý dữ liệu.

---

## 1. Tổng quan Kiến trúc & Cổng Mạng (Port Mapping)

```
+---------------------------------------------------------------------------------------+
|                                     Người dùng                                         |
|    (Giao diện Web Tiếng Việt: http://127.0.0.1:8090  hoặc  Terminal: `bam ai/rag`)    |
|    (IDE Code Assistants: Zed Editor, VSCode Continue, Antigravity, Neovim)            |
+------------------------------+------------------------------------+-------------------+
                               |                                    |
            (OpenAI API Port 9090)                 (RAG API / Web UI Port 8090)
                               v                                    v
            +-----------------------------------+   +-----------------------------------+
            |        `BamAI` (llama-server)     |   |       `BamRAG` (Golang Service)   |
            |     Model: Qwen2.5-1.5B (GGUF)    |<--|     Vector Store: chromem-go      |
            |   • Mặc định ngôn ngữ: Tiếng Việt |   |   • Giao diện Web Studio tiếng Việt|
            |   • Cổng: 9090 (Tránh đụng 8080)  |   |   • API nhúng & hỏi đáp RAG       |
            +-----------------------------------+   +-----------------+-----------------+
                                                                      | (Tùy chọn)
                                                                      v
                                                    +-----------------------------------+
                                                    |      Cloud LLM: DeepSeek API      |
                                                    |   • Làm sạch/tóm tắt tài liệu     |
                                                    |   • Suy luận RAG với deepseek-chat|
                                                    +-----------------------------------+
```

* **Quy hoạch cổng tránh xung đột**:
  * **BamAI (`llama-server`)**: Chạy ở cổng **`9090`** (thay vì 8080, tuyệt đối không xung đột với các ứng dụng Web Dev).
  * **BamRAG Web Studio & API**: Chạy ở cổng **`8090`**.
* **Chế độ Tiết kiệm Pin (On-Demand)**:
  * Cả hai dịch vụ mặc định **KHÔNG tự chạy ngầm khi khởi động máy** nhằm giữ GPU NVIDIA GTX 1650 ở chế độ ngủ sâu (RTD3 0W).
  * Chỉ khởi động khi bạn gõ lệnh hoặc bấm chạy. Nếu muốn tự chạy cùng hệ điều hành, chỉ cần đặt `my.ai.autoStart = true;` trong cấu hình host.

---

## 2. Giao diện Web Studio Tiếng Việt (`BamAI Studio`)

BamOS cung cấp sẵn giao diện đồ họa Web hiện đại, trực quan, 100% tiếng Việt:

### Khởi động Web Studio:
```bash
bam rag ui
```
Trình duyệt sẽ tự động mở trang: **`http://127.0.0.1:8090`**

### Các tính năng trên giao diện Web:
1. **Quản lý Khóa API (DeepSeek API Key)**:
   * Cho phép nhập trực tiếp `sk-...` trên giao diện và lưu trữ an toàn.
   * Chuyển đổi linh hoạt giữa việc suy luận bằng **Local Qwen 2.5 (Offline)** hoặc **Cloud DeepSeek (Trí tuệ cao)**.
2. **Nạp dữ liệu vào RAG (Document Ingestion)**:
   * Khung nhập văn bản, tài liệu, quy định, ghi chú.
   * Tùy chọn **"Dùng DeepSeek làm sạch & tóm tắt"**: Khi bật tùy chọn này, dữ liệu thô sẽ được DeepSeek đọc, lọc nhiễu, tóm tắt ý chính trước khi đưa vào lưu trữ trong bộ nhớ vector.
3. **Cửa sổ Chat & Hỏi đáp RAG**:
   * Trò chuyện trực tiếp bằng Tiếng Việt.
   * Tự động hiển thị các trích dẫn tài liệu tham chiếu (Context snippets) bên dưới câu trả lời.

---

## 3. Sử dụng Qua Dòng Lệnh Terminal (CLI)

### A. Quản lý BamAI (Local SLM Qwen2.5-1.5B)
* **Tải model Qwen2.5-1.5B (chỉ cần chạy 1 lần)**:
  ```bash
  bam ai pull
  ```
* **Bật / Tắt dịch vụ**:
  ```bash
  bam ai start    # Khởi động đồng thời cả BamAI (9090) và BamRAG (8090)
  bam ai stop     # Dừng đồng thời cả BamAI và BamRAG (tiết kiệm pin & RAM)
  bam ai status   # Xem trạng thái và cổng kết nối của cả 2 dịch vụ
  ```
* **Chat trực tiếp trên Terminal (Đã cố định tiếng Việt chuẩn)**:
  ```bash
  bam ai chat
  ```
* **Mở Cửa sổ Trợ lý AI nổi (Deepin OS Style - Native Rust + GTK4)**:
  ```bash
  bam ai app
  ```

### B. Quản lý BamRAG (Vector Engine)
* **Bật / Tắt dịch vụ RAG**:
  ```bash
  bam rag start
  bam rag status
  ```
* **Nạp tài liệu bằng CLI**:
  ```bash
  # Nạp văn bản
  bam rag index "BamOS là hệ điều hành Linux dựa trên NixOS dành cho người Việt."

  # Nạp toàn bộ file
  bam rag index-file /duong-dan/tai-lieu.txt
  ```
* **Tra cứu và Hỏi đáp RAG**:
  ```bash
  # Tìm kiếm đoạn văn bản tương đồng
  bam rag query "BamOS là gì?"

  # Hỏi đáp RAG (tổng hợp qua Local Qwen2.5)
  bam rag ask "Hãy tóm tắt các tính năng chính của BamOS?"
  ```

---

## 4. Tích hợp BamAI vào IDE (Zed, VSCode, Neovim)

`llama-server` của BamAI cung cấp API tương thích 100% chuẩn OpenAI tại: **`http://127.0.0.1:9090/v1`**.

### A. Cấu hình Zed Editor (`~/.config/zed/settings.json`)
```json
{
  "language_models": {
    "openai": {
      "version": "1",
      "api_url": "http://127.0.0.1:9090/v1",
      "available_models": [
        {
          "name": "qwen2.5-1.5b",
          "display_name": "BamAI Qwen 2.5",
          "max_tokens": 4096
        }
      ]
    }
  }
}
```

### B. Cấu hình VSCode / Continue.dev (`~/.continue/config.json`)
```json
{
  "models": [
    {
      "title": "BamAI Local",
      "provider": "openai",
      "model": "qwen2.5-1.5b",
      "apiBase": "http://127.0.0.1:9090/v1",
      "apiKey": "dummy"
    }
  ]
}
```

---

## 5. Ứng dụng Trợ lý Cửa sổ nổi Bam Assistant (`BamAI Assistant`)

Ứng dụng **Bam Assistant** được viết bằng Rust + GTK4 / Libadwaita với ngôn ngữ thiết kế kính mờ bo tròn thanh lịch (phong cách Deepin OS):

* **Vị trí hiển thị**: Mặc định bám dính tinh tế ở góc dưới bên phải màn hình làm việc, cho phép nắm thanh tiêu đề để kéo di chuyển thủ công bất kỳ đâu hoặc phóng to thu nhỏ linh hoạt.
* **Icon nhận diện**: Logo NixOS với tâm bộ não AI phát sáng neon cyan/blue, tích hợp sẵn trên **Taskbar Dock** và **Desktop (`~/Desktop/BamAI.desktop`)**.
* **Khởi động nhanh**:
  * Nhấn vào biểu tượng BamAI trên Dock / Desktop.
  * Hoặc chạy từ terminal: `bam ai app` (hoặc `bam ai ui`).
* **2 Tab chức năng chính**:
  1. **Tab Trò chuyện**: Chat trực tiếp bằng tiếng Việt, hỗ trợ giao tiếp với mô hình nội bộ hoặc Cloud LLM, hiển thị trạng thái động và thanh cuộn mượt mà.
  2. **Tab Thiết lập (Settings)**:
     * **Chọn Nhà cung cấp LLM**: Chuyển đổi qua lại giữa `Local AI (Qwen2.5)`, `DeepSeek`, `OpenAI (GPT-4o)`, `Google Gemini`.
     * **Tích hợp API Keys**: Ô nhập khóa bảo mật (có nút ẩn/hiện mật khẩu) cho DeepSeek, OpenAI, Google Gemini. Tự động đồng bộ khóa sang backend RAG.
     * **Bật/Tắt RAG**: Công tắc bật/tắt tính năng tìm kiếm văn bản tương đồng khi trò chuyện.
     * **Nạp tài liệu & Tri thức**: Khung văn bản cho phép thêm nhanh tài liệu, quy chế, ghi chú trực tiếp vào kho vector chromem-go của hệ thống.
     * **Lưu cấu hình**: Nút lưu tức thời và tự động ghi nhớ cấu hình tại `~/.config/bamos/assistant_config.json`.

---

## 6. Tùy biến trong Cấu hình NixOS (`/etc/nixos/hosts/lg.nix`)

```nix
  my.ai = {
    enable = true;
    autoStart = false;   # Đổi thành true nếu muốn tự chạy cùng hệ điều hành
    port = 9090;         # Cổng BamAI
    gpuLayers = 99;      # 99: Dùng toàn bộ GPU NVIDIA, 0: Thuần CPU
  };

  my.rag = {
    enable = true;
    port = 8090;         # Cổng BamRAG Web Studio & API
  };
```
Sau khi sửa cấu hình, áp dụng bằng lệnh:
```bash
bam switch
```
