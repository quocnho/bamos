# PRODUCT BACKLOG & MASTER ROADMAP: DỰ ÁN TROLY (NATIVE EDGE AI DESKTOP)

> **Tầm Nhìn Sản Phẩm (Product Vision):**  
> **Troly (Trợ Lý)** là người bạn đồng hành ảo thông minh, nhí nhảnh và an toàn trên Desktop Linux Wayland/NixOS.  
> Được xây dựng với triết lý **100% Air-gapped Cục Bộ**, **Zero Web Overhead (C++20 & Qt6 Native)**, tích hợp trí tuệ nhân tạo biên siêu nhẹ (**llama.cpp**, **Dynamic MoE Router**, **Hybrid Vector RAG**), vòng lặp tự động hóa tác vụ hệ thống **ReAct Actionable Agent**, cơ chế bảo vệ sức khỏe **EyeLeo** và **chú cún ảo Desktop Pet (Mascot)** mang đậm phong cách hoạt hình 12 nguyên tắc Disney.

---

## 🐶 I. BỨC TRANH SẢN PHẨM HOÀN CHỈNH (TARGET PRODUCT BLUEPRINT)

```text
+========================================================================================+
|                             DESKTOP PET & MASCOT COMPANION                             |
|  [Núp Lùm / Thò Đuôi] ──(Click Đuôi)──► [Vồ Chuột & Sủa Gâu Gâu] ──► [Quick Input Box]  |
|  [Squash & Stretch (Disney)] ◄──► [Mascot FSM: GREETING, IDLE, JUMP, DEEP_SLEEP]        |
+========================================================================================+
|                                    NATIVE QT6 UI LAYER                                 |
|  • Floating Glassmorphism Window (Frameless, Translucent, Wayland Client-Side 60fps)    |
|  • Quick Action Menu (⚙️): RAG, LLM, System Inspector, WakaTracker, Profile, EyeLeo    |
|  • Bone Context Bar: Đính kèm file/folder ngữ cảnh tức thì từ Nautilus                 |
|  • Streaming Markdown View: Hiển thị Live Token, Code Highlighting, Copy Button        |
|  • EyeLeo Health Modals: Cảnh báo 30s, Nghỉ ngắn 20s bài tập mắt, Nghỉ dài 5m Strict   |
+========================================================================================+
|                                BUSINESS & USECASES LAYER                               |
|  • Dynamic MoE Router: Phân loại ý định <30ms ➔ Hot-swap model (Text, Code, Vision)   |
|  • Hybrid RAG Engine: FTS5 BM25 + sqlite-vec Cosine Distance (Thuật toán RRF)          |
|  • Action Dispatcher & ReAct Loop: Chạy lệnh shell, đọc ghi tệp, tự phân tích sửa lỗi  |
|  • Safety Guard: Phân loại rủi ro (Low/High), Popup phê duyệt Human-in-the-Loop       |
|  • EyeLeo & WakaTracker Service: Đo nhịp sinh học, nhận diện idle qua D-Bus Mutter    |
+========================================================================================+
|                                INFRASTRUCTURE & ENGINE                                 |
|  • llama.cpp Embedded C++ RAII / Local Server SSE Client (Context Length 4k-8k)        |
|  • SQLite 3.45+ WAL Mode + sqlite-vec Extension (libvec0.so)                          |
|  • Linux QProcess / std::filesystem Sandboxing                                         |
|  • Self-Evolving Hub: Harvesting ChatML ➔ llama-finetune LoRA ➔ Merge & GGUF Quantize |
+========================================================================================+
```

---

## 🏛️ II. NGUYÊN TẮC KIẾN TRÚC & QUY CHUẨN KỸ THUẬT BẮT BUỘC

1. **Phân rã hạt nhỏ nhất (Atomic Granularity):**
   - Mọi thư mục và file được chia tách theo Single Responsibility Principle (Domain Entities, Ports, Usecases, Adapters, QML Components).
   - Nội dung tệp tin luôn giữ ngắn gọn, súc tích để tiết kiệm tối đa AI Context Token.
2. **Đường dẫn tương đối & Khả năng chạy độc lập (Standalone Portability):**
   - Không hardcode đường dẫn tuyệt đối `/etc/nixos/...` vào code C++, QML hay tài liệu nội bộ.
   - Sẵn sàng đóng gói riêng biệt (`default.nix`) hoặc tích hợp vào Flake toplevel (`bam switch`).
3. **Quy chuẩn Git & Versioning (Why - What - Test):**
   - Đánh số phiên bản 3 cấp `vAA.BB.CC`.
   - Mỗi commit bắt buộc cấu trúc: `[WHY / BUSINESS CONTEXT]`, `[WHAT / SCOPE OF CHANGE]`, `[TEST / DEFINITION OF DONE]`.

---

## 🗺️ III. PHÂN KỲ MILESTONE & LỘ TRÌNH SPRINTS (ROADMAP)

| Sprint | Phiên bản | Nhóm tính năng | Mục tiêu trọng tâm | Trạng thái |
|---|---|---|---|---|
| **Sprint 01** | `v01.01.00` | **Core Architecture & Setup** | Dựng khung Clean Arch C++20, DevEnv, Qt6 Skeleton, Flake integration, Antigravity harness | 🟢 DONE |
| **Sprint 02** | `v01.02.00` | **F5: Modern Mascot UI & EyeLeo Native** | Hoàn thiện Desktop Pet tương tác chuột (Peek Tail, Disney FSM), Quick Menu ⚙️, Bộ bảo vệ mắt EyeLeo | 🟡 IN_PROGRESS |
| **Sprint 03** | `v01.03.00` | **F1: Vector RAG & SQLite WAL Engine** | Triển khai SQLite WAL, nạp `sqlite-vec`, Hybrid search BM25 + Cosine RRF, Background chunking | ⚪ PLANNED |
| **Sprint 04** | `v01.04.00` | **F2: Local Inference & Dynamic MoE** | Tích hợp llama.cpp RAII / SSE Client, Intent Classifier <30ms, Hot-swap model không giật GUI | ⚪ PLANNED |
| **Sprint 05** | `v01.05.00` | **F3 & F4: Action ReAct & Safety Guard** | ReAct loop tự sửa lỗi, Linux command dispatcher, popup phê duyệt Human-in-the-Loop, Audit Log | ⚪ PLANNED |
| **Sprint 06** | `v01.06.00` | **System Inspector, WakaTracker & Profile** | Cửa sổ giám sát hệ thống (journalctl, nixos), WakaTracker năng suất, User Profile cá nhân hóa | 🟢 DONE |
| **Sprint 07** | `v01.07.00` | **F7: Self-Evolving Hub & Realtime 3D** | Tự động hóa harvesting ChatML vàng, pipeline train LoRA/merge GGUF, POC Qt Quick 3D mesh | 🟢 DONE |
| **Sprint 08** | `v01.08.00` | **Hybrid Expansion: Agent Tools & Pet Polish** | Mở rộng FS Tools, âm thanh phản hồi Native, vuốt ve 3D Mascot và nghiệm thu toàn hệ thống | 🟢 DONE |

---

## 📋 IV. CHI TIẾT PRODUCT BACKLOG (F1 - F7 & EXPANSION)

### 🐕 F5: Modern Mascot UI & EyeLeo Native (Sprint 02 Focus)
- `TROLY-F5-01`: **Mascot Interaction Controller & Peek Tail:**
  - Cơ chế cún con ẩn mép màn hình, chỉ thò đuôi vẫy (`STATE_PEEK_TAIL`).
  - Xử lý tương tác chuột: click đuôi ➔ cún vồ trỏ chuột (`STATE_PLAYFUL_JUMP`) kèm âm thanh/bong bóng thoại chào hỏi ➔ mở Quick Input Box.
- `TROLY-F5-02`: **Disney 12 Principles & Animation Refining:**
  - Cải tiến squash & stretch khi thở/nhảy, chuyển động tai đuôi có độ trễ quán tính (Secondary Action), 100% Bezier easing (`OutBack`, `InOutQuad`).
- `TROLY-F5-03`: **Quick Navigation Menu & Settings Modals:**
  - Nút bánh răng ⚙️ mở Menu danh mục: RAG, LLM, EyeLeo, System, WakaTracker, Profile, About.
  - Khung giao diện Fluent Glassmorphism cho từng modal cài đặt.
- `TROLY-F5-04`: **Native EyeLeo Health Companion:**
  - `EyeLeoService` đếm chu kỳ: Cảnh báo trước 30s ➔ Nghỉ ngắn 20s (bài tập đảo mắt cùng cún cưng) ➔ Nghỉ dài 5 phút (Overlay toàn màn hình, Strict Mode đếm ngược).
  - Tích hợp theo dõi người dùng không hoạt động (idle detection) qua D-Bus Mutter/XWayland.
- `TROLY-F5-05`: **Bone Context Bar & Live Markdown Stream:**
  - Thanh bối cảnh thư mục ghim dưới input box, hỗ trợ kéo thả tệp/thư mục từ Nautilus.
  - Bộ hiển thị Markdown trực tiếp hỗ trợ code syntax highlight, copy code block, stream từng token mượt mà 60fps.

### 🔍 F1: Quản Trị Tri Thức & Vector RAG (Hybrid Search FTS5 + sqlite-vec)
- `TROLY-F1-01`: **Database DDL & SQLite WAL Migration:**
  - Khởi tạo đầy đủ bảng: `collections`, `documents`, `doc_chunks`, `chunks_fts`, `vec_chunks`, `chat_sessions`, `chat_messages`.
- `TROLY-F1-02`: **sqlite-vec Dynamic Extension Loader:**
  - Nạp an toàn `libvec0.so` trong môi trường NixOS vào kết nối SQLite C++.
- `TROLY-F1-03`: **Hybrid Search Engine & Reciprocal Rank Fusion (RRF):**
  - Thực thi truy vấn song song BM25 (FTS5) và Cosine Distance (`vec0`), trộn điểm theo thuật toán RRF với tham số `k = 60`.
- `TROLY-F1-04`: **Asynchronous Document Ingestion Worker:**
  - Quét thư mục chạy ngầm bằng `std::jthread`, trích xuất text, băm SHA256 chống trùng lặp, chia chunk (500 tokens, overlap 50 tokens).

### 🧠 F2: Suy Luận Cục Bộ (Local Inference Engine: llama.cpp Native RAII)
- `TROLY-F2-01`: **RAII Wrapper cho llama.cpp:**
  - Quản lý bộ nhớ an toàn với `std::unique_ptr` kèm custom deleters cho `llama_model`, `llama_context`.
- `TROLY-F2-02`: **Streaming Inference & Abort Token:**
  - Stream token qua Qt Signal theo cơ chế bất đồng bộ, hỗ trợ `std::stop_token` hủy tác vụ ngay lập tức khi bấm Stop trên UI.
- `TROLY-F2-03`: **GBNF Grammar Constraints:**
  - Ép cấu trúc đầu ra của mô hình tuân thủ tuyệt đối JSON Schema định nghĩa cho các công cụ (Tool Calling).

### ⚡ F3: Điều Phối Tác Vụ (Action Dispatcher & ReAct Loop)
- `TROLY-F3-01`: **Linux Subprocess Execution (`QProcess`):**
  - Điều phối lệnh shell, kiểm tra trạng thái tiến trình, giới hạn timeout và thu thập stdout/stderr.
- `TROLY-F3-02`: **ReAct Self-Correction Cycle:**
  - Vòng lặp Suy luận ➔ Hành động ➔ Quan sát (Reasoning ➔ Acting ➔ Observation). Nếu lệnh shell trả về mã lỗi, nạp lại context để AI tự động phân tích và đưa ra câu lệnh sửa lỗi.
- `TROLY-F3-03`: **NixOS System Integration:**
  - Tích hợp các lệnh đặc thù: `nixos-rebuild dry-build`, `bam dry`, `nix search`, đọc cấu hình flake `/etc/nixos`.

### 🛡️ F4: Cơ Chế An Toàn (Safety Guard & Audit Trail)
- `TROLY-F4-01`: **Risk Analyzer Engine:**
  - Phân tích rủi ro lệnh qua blacklist/regex: lệnh an toàn (đọc tệp, `ls`, `cat`) ➔ tự động duyệt; lệnh nhạy cảm (`rm`, `sudo`, `systemctl`, `nixos-rebuild`) ➔ xếp loại `HIGH_RISK`.
- `TROLY-F4-02`: **Human-in-the-Loop Confirmation Dialog:**
  - Modal QML hiển thị cảnh báo đỏ, hiển thị chính xác câu lệnh sắp chạy và yêu cầu người dùng bấm "Chấp thuận" hoặc "Từ chối".
- `TROLY-F4-03`: **SQLite Audit Log:**
  - Lưu trữ toàn bộ lịch sử thực thi vào bảng `action_logs` để truy vết bảo mật.

### 🔀 F6: Bộ Định Tuyến Động (Dynamic MoE Router)
- `TROLY-F6-01`: **Ultra-fast Intent Classifier (<30ms):**
  - Phân loại ngữ cảnh dựa trên embedding câu hỏi hoặc rule heuristic để xác định domain: Lập trình (Code), Hội thoại (General Text), Thị giác máy tính (Vision/Image).
- `TROLY-F6-02`: **Zero-Latency Model Hot-Swap:**
  - Giải phóng VRAM model cũ và nạp model mới trên worker thread mà không gây đứng hình (freeze) luồng đồ họa Qt Quick.
- `TROLY-F6-03`: **VRAM Budget Supervisor:**
  - Luôn giám sát và đảm bảo tổng mức chiếm dụng VRAM không vượt quá 6GB trên máy người dùng.

### 📊 F8: Tiện Ích Mở Rộng Hệ Thống (System Inspector & WakaTracker)
- `TROLY-F8-01`: **System Inspector (Health Diagnostic):**
  - Đọc và phân tích `journalctl -p err..emerg`, `systemctl --failed`, kiểm tra dung lượng ổ đĩa `/nix/store` và RAM.
- `TROLY-F8-02`: **WakaTracker Productivity Sync:**
  - Đọc nhịp độ lập trình từ WakaTime API / local log, hiển thị biểu đồ thời gian tập trung và năng suất trong ngày.
- `TROLY-F8-03`: **User Profile & Adaptive Persona:**
  - Lưu trữ sở thích cá nhân, phong cách xưng hô của cún cưng và khảo sát trình độ lập trình để AI tinh chỉnh câu trả lời phù hợp.

### 🧬 F7: Trung Tâm Tự Tiến Hóa (Self-Evolving Hub - Air-gapped)
- `TROLY-F7-01`: **Dataset Golden Harvesting:**
  - Bộ lọc tự động trích xuất các phiên chat có kết quả thực thi hoàn hảo (`quality_score >= 1.0`) lưu vào `training_datasets`.
- `TROLY-F7-02`: **Automated LoRA Fine-Tuning Pipeline:**
  - Kịch bản xuất dữ liệu ChatML ➔ gọi `llama-finetune` tối ưu trọng số LoRA trên card đồ họa rời khi máy tính rảnh rỗi ban đêm.
- `TROLY-F7-03`: **Adapter Merge & Quantization:**
  - Tự động dùng `llama-export-lora` ghép LoRA vào base model Qwen2.5 và nén GGUF Q4_K_M, ghi nhận phiên bản mới vào `models_registry`.
- `TROLY-F7-04`: **Qt Quick 3D Stylized Mesh POC:**
  - Thử nghiệm nạp mô hình 3D glTF của cún cưng với Toon Shading và Spring Bone Rigging thay thế dần SVG 2D.
