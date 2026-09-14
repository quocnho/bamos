# Kiến Trúc Hệ Thống Troly (Native Edge AI Desktop)

## 1. Tổng Quan Kiến Trúc & Triết Lý Vận Hành
Dự án `troly` thay thế kiến trúc WebKitGTK + Go trong `pkgs/assistant` bằng kiến trúc **Native Edge C++20 + Qt6/QML**, loại bỏ hoàn toàn web overhead, tối ưu mức tiêu thụ RAM và đạt độ mượt mà 60 FPS trên hệ điều hành NixOS (Wayland/XWayland).

> 📦 **Vị Trí Trong Hệ Thống NixOS (Flake Subpackage):**
> `troly` được cấu trúc như một **package con độc lập** trực thuộc hệ thống cấu hình NixOS dạng Flake tại `/etc/nixos/` (tương tự như `/etc/nixos/pkgs/assistant/` và `/etc/nixos/pkgs/bam/`).
> - Khi dự án lớn `/etc/nixos/` thực hiện `nix build`, hệ thống sẽ đóng gói và xây dựng các packages.
> - Sau khi đóng gói, quy trình kiểm thử và cập nhật toàn hệ điều hành BamOS được thực thi thông qua lệnh `bam switch` (công cụ CLI của package `/etc/nixos/pkgs/bam/`).

> 🔄 **Kế Thừa & Nâng Cấp Toàn Diện Từ `/etc/nixos/pkgs/assistant/`:**
> Hệ thống đọc lại toàn bộ thông tin từ dự án `assistant` và kế thừa trọn vẹn các thành phần cốt lõi để tái hiện và nâng tầm trên nền C++20/Qt6:
> - **Menu thao tác nhanh & Context Menu:** Tái hiện menu thả xuống từ nút ⚙️ (`menu.js`), hỗ trợ mở nhanh các panel chức năng.
> - **Các cửa sổ thiết lập (Settings Modals):** Chuyển dịch toàn bộ các panel `rag-settings.js`, `llm-settings.js`, `system-inspect.js`, `wakatracker-ui.js`, `profile-ui.js` thành các QML Component chuyên dụng kết nối với C++ ViewModel.
> - **Hệ thống bảo vệ mắt EyeLeo:** Tái thiết kế toàn bộ logic từ `eyeleo/controller.js` sang C++ `EyeLeoService`, bao gồm: cảnh báo trước 30s, nhắc nghỉ ngắn 8-20s (kèm bài tập mắt và animation cún cưng), nghỉ dài 5 phút (kèm strict mode), nhận diện máy nghỉ (idle time) qua D-Bus Mutter/XWayland.
> - **Thanh bối cảnh thư mục (Bone Context Bar) & Quản lý đính kèm:** Đọc ngữ cảnh thư mục và đính kèm tài liệu vào phiên hỏi đáp.

### Triết Lý Thiết Kế Cốt Lõi:
1. **Air-gapped 100% Cục Bộ:** Không gửi dữ liệu prompt, embeddings hay telemetry ra ngoài internet.
2. **Zero Web Overhead:** Không Electron, không Node.js, không Python runtime trong môi trường chạy thực tế.
3. **Actionable Agent:** Vòng lặp ReAct (Reasoning + Acting) kết hợp bộ lọc ngữ pháp GBNF Grammar ép định dạng JSON công cụ và cơ chế phê duyệt Human-in-the-Loop.

```text
+-------------------------------------------------------------+
|                    PRESENTATION LAYER                       |
|  - QML Scene Graph (Transparent Window, Mascot Companion)    |
|  - Qt6 ViewModels (ChatViewModel, SystemMonitorViewModel)    |
+------------------------------+------------------------------+
                               |
+------------------------------v------------------------------+
|                     USECASES LAYER                          |
|  - IRAGService (Hybrid Search)                              |
|  - IInferenceEngine (llama.cpp Streaming)                   |
|  - IActionDispatcher (System Execution)                     |
|  - ISafetyGuard (Risk Analysis & Confirmation)              |
+------------------------------+------------------------------+
                               |
+------------------------------v------------------------------+
|                      DOMAIN LAYER                           |
|  - ChatMessage, Config, KnowledgeChunk, CommandResult       |
|  - Pure C++20, Zero external dependencies                   |
+-------------------------------------------------------------+
                               ^
+------------------------------+------------------------------+
|                   INFRASTRUCTURE LAYER                      |
|  - SqliteRAGRepository (FTS5 + vec0 extension, WAL mode)    |
|  - LlamaInferenceEngine (Embedded llama.cpp C++ API)        |
|  - LinuxActionDispatcher (QProcess & std::filesystem)       |
+-------------------------------------------------------------+
```

---

## 2. Phân Rã Chức Năng Nghiệp Vụ (Functional Decomposition - FD)

| Phân hệ | Tên gọi | Chức năng chi tiết (FR) | Đặc tả kỹ thuật (C++20 / Qt6 / llama.cpp) |
| :--- | :--- | :--- | :--- |
| **F1** | **Quản Trị Tri Thức & Vector RAG** | • Quét & lập chỉ mục nền<br>• Phân đoạn văn bản (Chunking)<br>• Trích xuất Vector Embedding<br>• Hybrid Search (FTS5 + vec0) | Sử dụng `std::jthread` quét thư mục bất đồng bộ. Kết hợp bảng ảo `chunks_fts` (BM25) và `vec_chunks` (Cosine) qua thuật toán Reciprocal Rank Fusion (RRF). |
| **F2** | **Suy Luận Cục Bộ (Inference Engine)** | • Quản lý vòng đời GGUF<br>• Stream token thời gian thực<br>• Ràng buộc GBNF Grammar<br>• Dừng khẩn cấp (Abort Task) | Nhúng tĩnh thư viện C++ `llama.cpp`. Quản lý con trỏ RAII smart pointers. Sử dụng `std::stop_token` để hủy lệnh suy luận tức thì từ UI. |
| **F3** | **Điều Phối Tác Vụ (Action Dispatcher)** | • Nhận diện Intent & Phân rã Task<br>• Thao tác tệp (`std::filesystem`)<br>• Chạy lệnh OS qua `QProcess`<br>• Tự sửa lỗi (ReAct Loop) | Phân tích JSON từ LLM, thực thi tác vụ file I/O hoặc CLI subprocess; lấy output thực thi phản hồi ngược lại context của AI để tự sửa lỗi nếu thất bại. |
| **F4** | **Cơ Chế An Toàn (Safety Guard)** | • Phân cấp rủi ro hành động<br>• Phê duyệt Human-in-the-Loop<br>• Nhật ký kiểm toán (Audit Trail) | Ngăn chặn triệt để ảo giác. Các thao tác can thiệp hệ thống tệp tin hoặc lệnh đặc quyền bắt buộc kích hoạt popup phê duyệt trên QML. |
| **F5** | **Giao Diện Bản Địa (Modern GUI & Mascot)** | • Desktop Pet tương tác chuột<br>• Live Markdown & Code Highlighting<br>• Giám sát RAM/VRAM & EyeLeo | Xây dựng trên Qt Quick / QML tăng tốc phần cứng Wayland native client-side rendering. Giao tiếp qua Qt Signals & QueuedConnection. |
| **F6** | **Bộ Định Tuyến (Dynamic MoE Router)** | • Phân loại Domain (Text, Code, Vision)<br>• Điều phối nạp động (Hot-Swap)<br>• Quản lý bộ nhớ đệm VRAM | Intent Classifier siêu nhẹ (<30ms) nhận diện kiểu tệp và yêu cầu để nạp đúng model chuyên biệt vào VRAM cache (<6GB). |
| **F7** | **Tự Tiến Hóa (Self-Evolving Hub)** | • Thu hoạch tương tác chất lượng cao<br>• Đánh giá mẫu vàng (Quality Scoring)<br>• Huấn luyện LoRA (`llama-finetune`)<br>• Hợp nhất và xuất bản GGUF mới | Chưng cất tri thức (Knowledge Distillation) từ các ca giải quyết thành công. Tự động train ngầm ban đêm và merge ra phiên bản GGUF riêng biệt. |

---

## 3. Desktop Mascot Companion & Tiêu Chuẩn Hoạt Hình (Lead 3D & Animation Director)

- **Bộ tài nguyên đồ họa Mascot tại [assets/pet/](file:///etc/nixos/pkgs/troly/assets/pet):**
  - `cho chao.svg`: Chào đón buổi sáng, vẫy đuôi mừng chủ nhân khi khởi động máy (`STATE_GREETING`).
  - `cho dung.svg`: Trạng thái chờ lệnh (Idle/Standby), đứng canh hệ thống (`STATE_IDLE_STAND`).
  - `cho nhay.svg`: Phản hồi tương tác chuột, vui đùa, xử lý yêu cầu thành công (`STATE_PLAYFUL_JUMP`).
  - `cho ngu.svg`: Chế độ tiết kiệm pin/RAM/CPU khi hệ thống rảnh hoặc vào chế độ ngủ sâu (`STATE_DEEP_SLEEP`).
- **12 Nguyên Tắc Hoạt Hình Disney:**
  - **Squash & Stretch:** Co giãn thể tích bảo toàn khi nhún nhảy.
  - **Anticipation:** Lấy đà trước khi vồ tương tác chuột.
  - **Follow Through:** Đôi tai và đuôi có độ trễ tự nhiên theo gia tốc chuyển động.
  - **Bezier Easing:** 100% chuyển động dùng `Easing.OutBack` hoặc `Easing.InOutQuad`, không dùng chuyển động tuyến tính thô cứng.
- **Mascot Finite State Machine (FSM):** Bộ điều khiển trạng thái chuyển động bất đồng bộ, phản hồi trực tiếp sự kiện chuột và trạng thái nạp mô hình AI.
- **Tối ưu năng lượng 0.0% CPU:** Khi ở `STATE_DEEP_SLEEP`, dừng toàn bộ render timer của Scene Graph để bảo toàn tài nguyên máy tính.
- **Lộ trình Mở rộng Realtime 3D Mesh:** Kiến trúc module sẵn sàng chuyển đổi hoặc song hành cùng mô hình 3D Stylized (định dạng `glTF 2.0 / GLB`, Skeletal Rigging, Spring Bones, Toon Shading) qua **Qt Quick 3D**.

---

## 4. Thiết Kế Cơ Sở Dữ Liệu: Lược Đồ ERD & DDL (SQLite WAL + Vector)

```text
+----------------------+         1:N         +-----------------------+
|     COLLECTIONS      |--------------------<|       DOCUMENTS       |
|----------------------|                     |-----------------------|
| PK  id: INTEGER      |                     | PK  id: INTEGER       |
|     name: TEXT       |                     | FK  collection_id: INT|
|     base_path: TEXT  |                     |     file_path: TEXT   |
|     created_at: INT  |                     |     file_hash: TEXT   |
+----------------------+                     |     updated_at: INT   |
                                             +-----------------------+
                                                         | 1:N
                                                         v
+----------------------+         1:N         +-----------------------+
|    CHAT_SESSIONS     |--------------------<|      DOC_CHUNKS       |
|----------------------|                     |-----------------------|
| PK  id: INTEGER      |                     | PK  id: INTEGER       |
|     title: TEXT      |                     | FK  document_id: INT  |
|     created_at: INT  |                     |     chunk_index: INT  |
+----------------------+                     |     content: TEXT     |
           | 1:N                             +-----------------------+
           v                                             | 1:1
+----------------------+                                 v
|    CHAT_MESSAGES     |                     +-----------------------+
|----------------------|                     |   VEC_CHUNKS (VIRT)   |
| PK  id: INTEGER      |                     |-----------------------|
|     role: TEXT       |                     | PK  chunk_id: INTEGER |
|     content: TEXT    |                     |     embedding:FLOAT[] |
|     timestamp: INT   |                     +-----------------------+
+----------------------+                                 
           | 1:N                                         
           v                                             
+----------------------+         1:1         +-----------------------+
|     ACTION_LOGS      |-------------------->|   TRAINING_DATASETS   |
|----------------------|                     |-----------------------|
| PK  id: INTEGER      |                     | PK  id: INTEGER       |
| FK  message_id: INT  |                     |     domain: TEXT      |
|     tool_name: TEXT  |                     |     instruction: TEXT |
|     arguments: JSON  |                     |     target_output: TX |
|     status: TEXT     |                     |     quality_score: FLT|
|     executed_at: INT |                     |     is_trained: BOOL  |
+----------------------+                     +-----------------------+
                                                         ^
                                                         | 1:N
+----------------------+         1:N         +-----------------------+
|   MODELS_REGISTRY    |--------------------<|   LORA_CHECKPOINTS    |
|----------------------|                     |-----------------------|
| PK  id: INTEGER      |                     | PK  id: INTEGER       |
|     name: TEXT       |                     | FK  base_model_id: INT|
|     file_path: TEXT  |                     |     lora_path: TEXT   |
|     vram_bytes: INT  |                     |     merged_gguf: TEXT |
|     is_loaded: BOOL  |                     |     epochs_trained:INT|
+----------------------+                     +-----------------------+
```

### DDL Schema Chuẩn (`src/infrastructure/sqlite/schema.sql`):

```sql
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;

CREATE TABLE IF NOT EXISTS collections (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    base_path TEXT NOT NULL UNIQUE,
    created_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS documents (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    collection_id INTEGER NOT NULL REFERENCES collections(id) ON DELETE CASCADE,
    file_path TEXT NOT NULL UNIQUE,
    file_hash TEXT NOT NULL,
    updated_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS doc_chunks (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    document_id INTEGER NOT NULL REFERENCES documents(id) ON DELETE CASCADE,
    chunk_index INTEGER NOT NULL,
    content TEXT NOT NULL
);

CREATE VIRTUAL TABLE IF NOT EXISTS chunks_fts USING fts5(
    content, content='doc_chunks', content_rowid='id'
);

CREATE VIRTUAL TABLE IF NOT EXISTS vec_chunks USING vec0(
    chunk_id INTEGER PRIMARY KEY,
    embedding FLOAT[384]
);

CREATE TABLE IF NOT EXISTS chat_sessions (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    created_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS chat_messages (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    session_id INTEGER NOT NULL REFERENCES chat_sessions(id) ON DELETE CASCADE,
    role TEXT CHECK(role IN ('user', 'assistant', 'system', 'tool')) NOT NULL,
    content TEXT NOT NULL,
    model_used TEXT,
    timestamp INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS action_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    message_id INTEGER NOT NULL REFERENCES chat_messages(id) ON DELETE CASCADE,
    tool_name TEXT NOT NULL,
    arguments JSON NOT NULL,
    status TEXT CHECK(status IN ('pending', 'approved', 'executed', 'rejected', 'failed')) NOT NULL,
    output TEXT,
    executed_at INTEGER
);

CREATE TABLE IF NOT EXISTS models_registry (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE,
    file_path TEXT NOT NULL,
    model_type TEXT CHECK(model_type IN ('llm', 'vlm', 'audio', 'embedding')) NOT NULL,
    vram_bytes INTEGER NOT NULL,
    context_length INTEGER DEFAULT 4096,
    is_loaded BOOLEAN DEFAULT 0
);

CREATE TABLE IF NOT EXISTS training_datasets (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    domain TEXT NOT NULL,
    instruction TEXT NOT NULL,
    input_context TEXT,
    target_output TEXT NOT NULL,
    source_model TEXT NOT NULL,
    quality_score REAL DEFAULT 1.0,
    is_trained BOOLEAN DEFAULT 0,
    created_at INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS lora_checkpoints (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    base_model_id INTEGER NOT NULL REFERENCES models_registry(id),
    lora_adapter_path TEXT NOT NULL,
    output_merged_gguf TEXT NOT NULL,
    epochs_trained INTEGER NOT NULL,
    loss_val REAL,
    created_at INTEGER NOT NULL
);
```

---

## 5. Biểu Đồ Luồng Dữ Liệu (DFD Level 1) & ReAct Loop

```text
[Người Dùng: Nhập Prompt / Đính Kèm File]
                   │
                   ▼
  (1.0: Intent Router & Modality Detector) ─── Kiểm tra nạp VRAM ───► [models_registry]
                   │
                   ├──── Truy vấn từ khóa FTS5 ────────────► [chunks_fts]
                   └──── Truy vấn vector Cosine ───────────► [vec_chunks]
                   │
                   ▼
  (2.0: Inference Engine: llama.cpp) ◄── Ghép Context RAG & Ràng buộc GBNF Grammar
                   │
                   ├──── Trả lời trực tiếp Stream Token ───► [Giao diện Qt Quick QML]
                   │
                   ▼ (Khi LLM sinh lệnh JSON Tool Calling)
  (3.0: Safety Guard & Human-in-the-Loop)
                   │
            [Xác nhận từ Người Dùng]
                   │
                   ▼
  (4.0: Action Dispatcher) ─── Gọi std::filesystem / QProcess ───► [Hệ Điều Hành Linux]
                   │
                   ├──── Lưu kết quả hành động ────────────► [action_logs]
                   │
                   ▼ (Nếu tác vụ thành công & điểm chất lượng cao)
  (5.0: Data Harvesting Hub) ── Lưu mẫu vàng ──────────────► [training_datasets]
```

---

## 6. Chiến Lược Mô Hình & Quy Trình Tự Tiến Hóa (Self-Evolving Hub)

### 6.1. Lựa chọn dòng mô hình: Tại sao Qwen2.5 là chủ lực?
- **Tokenizer Tiếng Việt:** Tiết kiệm 25-30% context, xử lý dấu mượt mà, hạn chế tối đa việc phân mảnh từ ghép.
- **Dung lượng GGUF Q4_K_M:** Bản 3B chỉ chiếm ~2.1 GB VRAM, cực kỳ lý tưởng cho máy trạm làm việc song song với tác vụ văn phòng và IDE.
- **Function Calling:** Xuất sắc trong việc sinh JSON theo cấu trúc và tuân thủ định dạng chỉ dẫn.

### 6.2. Quy trình 4 bước huấn luyện và lượng hóa mô hình GGUF:
1. **Trích xuất dữ liệu vàng:** Lọc các bản ghi từ SQLite `training_datasets` có `quality_score >= 1.0` sang file ChatML `train_data.txt`.
2. **Huấn luyện LoRA:** Chạy `llama-finetune` với base model `Qwen2.5-3B-Instruct-Q8_0.gguf`.
3. **Hợp nhất trọng số:** Dùng `llama-export-lora` kết hợp adapter vào base model.
4. **Lượng hóa (Quantize):** Nén file bằng `llama-quantize` (Q4_K_M) để tối ưu VRAM và đăng ký vào `models_registry`.

---

## 7. Kỹ Thuật Phân Rã Hạt Nhỏ Nhất (Atomic Granularity) Tối Ưu Token

- **Triết lý Single Responsibility:** Mỗi file chỉ giữ đúng 1 trách nhiệm (1 Entity, 1 Value Object, 1 Interface, 1 QML Component).
- **Interface Isolation:** Thư mục `usecases/` chỉ chứa các file header `.hpp` thuần ảo ngắn gọn (~50 tokens). Khi Agent làm việc, chỉ nạp interface thay vì toàn bộ code thực thi hàng nghìn dòng.
- **Ngăn chặn God Classes:** Không gom chung logic DB và logic AI vào một file nguyên khối.
- **Dễ tìm kiếm & định vị:** Tên thư mục và tệp tin biểu đạt chính xác miền nghiệp vụ, hỗ trợ AI grep/định vị trực tiếp mà không cần đọc rà soát toàn bộ dự án.

---

## 8. Nguyên Tắc Đường Dẫn Tương Đối & Khả Năng Chạy Độc Lập (Standalone Portability)

- **Mục tiêu kiến trúc:** Mọi dự án/package con (như `pkgs/troly`, `pkgs/assistant`, `pkgs/bam`) đều có khả năng chạy độc lập hoặc sẵn sàng tách thành kho lưu trữ (repository) riêng biệt mà không phụ thuộc vào cấu trúc thư mục cha của hệ điều hành NixOS (`/etc/nixos/`).
- **Quy tắc vàng về đường dẫn:**
  - **Mã nguồn (C++, QML, Go, Rust):** Tuyệt đối không hardcode đường dẫn tuyệt đối như `/etc/nixos/pkgs/...`.
  - **Tài nguyên giao diện & Assets:** Phải tham chiếu thông qua Qt Resource System (`qrc:/`) hoặc đường dẫn tương đối tính từ thư mục gốc của nhị phân thực thi (`QCoreApplication::applicationDirPath()`).
  - **Build Systems (CMakeLists.txt, default.nix, shell.nix):** Sử dụng các biến vị trí tương đối (`${CMAKE_CURRENT_SOURCE_DIR}`, `./`) để đảm bảo biên dịch độc lập (standalone build) trên mọi môi trường.
  - **Tài liệu & Kế hoạch (Markdown):** Mọi liên kết chéo nội bộ package phải sử dụng đường dẫn tương đối chuẩn.
