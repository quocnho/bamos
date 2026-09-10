# Hướng dẫn Sử dụng Hệ thống BamAI & Tri thức RAG trên BamOS 🎋

**BamAI** là trợ lý AI cục bộ (Local SLM) của BamOS, kèm bộ **RAG (Retrieval-Augmented Generation)** tích hợp sẵn _bên trong_ ứng dụng. Hệ thống hoạt động hoàn toàn bằng **Tiếng Việt**, lưu vector nhúng ngay trên máy và có thể liên thông linh hoạt với Cloud LLM (DeepSeek/OpenAI/Gemini).

---

## 1. Tổng quan Kiến trúc & Cổng Mạng (Port Mapping)

```
+-----------------------------------------------------------------+
|                            Người dùng                            |
|  • Trợ lý nổi BamAI: chó mascot + khung chat + các bảng thiết lập |
|  • Menu Thiết lập ⚙ trên thanh trên cùng GNOME Shell             |
|  • IDE: Zed Editor, VSCode Continue, Antigravity, Neovim          |
+--------------------------------+--------------------------------+
                                 |
                     (OpenAI API tương thích — port 9090)
                                 v
             +------------------------------------------+
             |          BamAI (llama-server)             |
             |       Model: Qwen2.5-1.5B (GGUF)          |
             |   • Ngôn ngữ mặc định: Tiếng Việt         |
             |   • Cổng: 9090                            |
             +---------------------+--------------------+
                                   |
             RAG (chromem-go) NHÚNG trong tiến trình BamAI
             • Vector store: /var/lib/bamos/rag/knowledge.db
             • Embedding lấy từ chính llama-server (9090)
             • KHÔNG có dịch vụ / cổng RAG riêng
```

- **Chỉ một cổng duy nhất**: `llama-server` ở **`9090`** (thay cho 8080 để không đụng ứng dụng web dev). RAG chạy **trong chính tiến trình BamAI** nên không mở thêm cổng nào (trước đây có dịch vụ `bamos-rag` ở cổng 8090 — đã bỏ vì dư thừa và gây tranh chấp cùng một file database).
- **Chế độ Tiết kiệm Pin (on-demand)**: dịch vụ mặc định **KHÔNG** tự chạy khi khởi động máy, giữ GPU NVIDIA GTX 1650 ở chế độ ngủ sâu (RTD3 0W). BamAI tự bật `llama-server` khi bạn mở khung chat; muốn chạy sẵn cùng hệ điều hành: đặt `my.ai.autoStart = true;`.
- **Tri thức dùng chung**: nếu bạn từng nạp tài liệu bằng dịch vụ RAG cũ, dữ liệu vẫn còn nguyên trong `knowledge.db` (cùng thư viện chromem-go) — không cần nạp lại.

---

## 2. Quản lý Tri thức RAG (trong ứng dụng BamAI)

RAG **không còn là dịch vụ/web riêng**. Mọi thao tác nằm trong ứng dụng:

1. Bấm icon **⚙** trên thanh tiêu đề khung chat — hoặc **⚙ Thiết lập** trên thanh trên cùng GNOME Shell — rồi chọn **RAG — Tri thức**.
2. Trong bảng thiết lập:
    - **Bật tri thức nội bộ (RAG)**: khi bật, BamAI tra cứu tài liệu của bạn trước khi trả lời.
    - **Cách xưng hô**: `Chủ nhân` / `Anh` / `Chị` / `Bạn` / `Em` hoặc tuỳ chỉnh.
    - **Số đoạn tri thức dùng mỗi câu trả lời**: 1–8 (gợi ý **3–5**).
    - **Tài liệu tri thức**: kéo–thả hoặc bấm để chọn nhiều tệp (`.md`, `.txt`, `.nix`, `.json`, `.csv`, `.log`…) rồi bấm **Nạp vào tri thức**.
    - **Xoá toàn bộ**: đặt lại kho vector.
3. Mỗi lượt hỏi–đáp cũng được ghi lại vào tri thức để các câu hỏi sau có thêm ngữ cảnh.

---

## 3. Sử dụng Qua Dòng Lệnh Terminal (CLI)

### A. Quản lý BamAI (Local SLM Qwen2.5-1.5B)

- **Tải model Qwen2.5-1.5B (chỉ cần chạy 1 lần)**:
    ```bash
    bam ai pull
    ```
- **Bật / Tắt dịch vụ**:
    ```bash
    bam ai start    # Khởi động llama-server (9090) — RAG đã nhúng sẵn trong BamAI
    bam ai stop     # Dừng llama-server (tiết kiệm pin & RAM)
    bam ai status   # Xem trạng thái llama-server
    ```
- **Chat trực tiếp trên Terminal (đã cố định tiếng Việt chuẩn)**:
    ```bash
    bam ai chat
    ```
- **Mở cửa sổ Trợ lý AI nổi**:
    ```bash
    bam ai app
    ```

### B. RAG (tri thức) — dùng trong ứng dụng

Không còn lệnh `bam rag` và không có dịch vụ/port 8090. Mọi thao tác tri thức
(duyệt & nạp tài liệu, xoá tri thức, chọn số đoạn tri thức, xưng hô) thực hiện
trong ứng dụng BamAI: mở khung chat → icon **⚙** → **RAG — Tri thức**.

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

## 5. Ứng dụng Trợ lý Cửa sổ nổi (`BamAI Assistant`)

Ứng dụng **BamAI** viết bằng **Go + GTK3 + WebKit** (giao diện HTML/CSS/JS) với ngôn ngữ thiết kế kính mờ bo tròn:

- **Vị trí hiển thị**: bám ở góc dưới bên phải màn hình; kéo thanh tiêu đề để di chuyển, vị trí được ghi nhớ cho lần chạy sau. Cửa sổ tự co giãn vừa khít nội dung (khung chat + chú cún) và không nhảy vị trí khi mở/đóng bảng thiết lập.
- **Icon nhận diện**: có sẵn trên **Dock** và **Desktop (`~/Desktop/BamAI.desktop`)**, kèm mục **⚙ Thiết lập BamAI** trên thanh trên cùng GNOME Shell (menu: RAG — Tri thức, LLM/SLM, Quản lý nghỉ ngơi, Giới thiệu).
- **Khởi động nhanh**:
    - Nhấn biểu tượng BamAI trên Dock / Desktop.
    - Hoặc chạy từ terminal: `bam ai app` (hoặc `bam ai ui`).
- **Các chức năng chính**:
    1. **Trò chuyện**: chat tiếng Việt với model nội bộ hoặc Cloud LLM; hội thoại nối tiếp theo ngữ cảnh; nút **＋** mở phiên mới và **🕘** xem lại hội thoại gần đây.
    2. **Thiết lập ⚙** (ngay trên thanh tiêu đề khung chat):
        - **RAG — Tri thức**: bật/tắt tri thức, xưng hô, số đoạn, nạp/xoá tài liệu.
        - **LLM / SLM**: chọn `Local (llama-server)`, `DeepSeek`, `OpenAI`, `Google Gemini`; nhập API key; chọn model GGUF, tải model, chỉnh temperature / context / số layer GPU.
        - **Quản lý nghỉ ngơi (EyeLeo)**: nhắc nghỉ mắt 20-20-20 và nghỉ dài.
        - **Giới thiệu**: thông tin ứng dụng + liên kết.
    3. **Cấu hình được lưu** tại `~/.config/bamos/assistant_config.json` (API key, model đang dùng, xưng hô, bật/tắt RAG...).

---

## 6. Tùy biến trong Cấu hình NixOS (`/etc/nixos/hosts/lg.nix`)

```nix
  my.ai = {
    enable = true;
    autoStart = false;   # Đổi thành true nếu muốn tự chạy cùng hệ điều hành
    port = 9090;         # Cổng BamAI (llama-server)
    gpuLayers = 99;      # 99: dùng toàn bộ GPU NVIDIA, 0: thuần CPU
  };
```

Sau khi sửa cấu hình, áp dụng bằng lệnh:

```bash
bam switch
```

> **Ghi chú**: module `my.rag` (dịch vụ `bamos-rag` ở cổng 8090) đã được **loại bỏ** —
> RAG nay nằm trong chính ứng dụng BamAI (`pkgs/assistant/rag.go`).
