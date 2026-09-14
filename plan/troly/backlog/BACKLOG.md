# BACKLOG DỰ ÁN TROLY (NATIVE EDGE AI DESKTOP)

Tài liệu quản lý toàn bộ yêu cầu tính năng (Feature Decomposition) cho dự án `troly`, chuyển đổi và nâng cấp từ `pkgs/assistant` sang C++20/Qt6 Native, tuân thủ Clean Architecture và 100% Air-gapped Edge AI.

> 🔄 **Tuyên Bố Kế Thừa & Nâng Cấp Từ `/etc/nixos/pkgs/assistant/`:**
> Dự án `troly` tái cấu trúc và phát triển kế thừa toàn bộ tri thức, luồng nghiệp vụ từ dự án `assistant`. Toàn bộ thông tin từ dự án cũ được đọc và tích hợp, trong đó đặc biệt tận dụng và tái hiện lại trên nền C++20/Qt6:
> 1. **Hệ thống Menu thả nhanh & điều hướng:** Menu thiết lập sổ xuống (RAG, LLM, EyeLeo, System, WakaTracker, Profile, About).
> 2. **Các cửa sổ thiết lập (Settings Windows/Modals):** Thiết lập RAG (FTS5 + vec0 hybrid, chọn file), Thiết lập LLM (cục bộ/cloud, tham số ngữ cảnh), Giám sát hệ thống (System Inspector quét journalctl, /etc/nixos), WakaTracker (nhịp sinh hoạt, thời gian làm việc), Hồ sơ người dùng (User Profile, trắc nghiệm đánh giá năng lực).
> 3. **Cơ chế bảo vệ mắt EyeLeo:** 3 cấp độ nhắc nhở (cảnh báo trước 30s, nghỉ ngắn 8-20s với bài tập mắt và animation cún cưng, nghỉ dài 5 phút overlay glassmorphism kèm strict mode, tự động nhận diện idle qua D-Bus Mutter).
> 4. **Thanh bối cảnh thư mục (Bone Context Bar) & Đính kèm đa phương tiện.**

---

## 0. Quy Chuẩn Cấu Trúc Hệ Thống Tập Tin (Clean Architecture & Atomic Granularity)
- **Xây dựng hệ thống tập tin phân nhỏ nhất có thể:** Mọi chức năng F1 - F7 khi triển khai đều phải phân rã thành các thư mục và tập tin con phù hợp, chuyên nghiệp theo nguyên tắc Single Responsibility.
- **Dễ tìm kiếm thư mục, tập tin:** Tên gọi chuẩn xác, module hóa theo tầng (`domain/models/`, `domain/ports/`, `usecases/<feature>/`, `infrastructure/<adapter>/`, `presentation/viewmodels/`, `presentation/ui/components/`).
- **Nội dung nhỏ nhất khi đọc:** Đảm bảo mỗi file có kích thước tinh gọn tối đa, giúp AI Agent chỉ cần đọc đúng tập tin liên quan để tiết kiệm token tối đa trong quá trình dev.

---

## 1. Bảng Phân Rã Chức Năng Nghiệp Vụ (Functional Decomposition - FD)

### F1: Quản Trị Tri Thức & Vector RAG (Hybrid Search FTS5 + sqlite-vec)
- **Mô tả:** Động cơ tìm kiếm tri thức cục bộ không phụ thuộc đám mây.
- **Tasks:**
  - `TROLY-F1-01`: Thiết kế schema SQLite WAL (`collections`, `documents`, `doc_chunks`) + FTS5 + virtual table `vec_chunks` (`vec0` sqlite-vec).
  - `TROLY-F1-02`: Viết Interface `IRAGService.hpp` và triển khai `SqliteRAGRepository.cpp`.
  - `TROLY-F1-03`: Thuật toán Hybrid Scoring kết hợp BM25 (FTS5) và Cosine Distance (`vec_chunks`) qua công thức Reciprocal Rank Fusion (RRF) hoặc Alpha weighting.
  - `TROLY-F1-04`: Bộ nạp tài liệu nền đa luồng với `std::jthread` (Document Parser & Chunking).

### F2: Suy Luận Cục Bộ (Local Inference Engine: llama.cpp Native RAII)
- **Mô tả:** Động cơ suy luận mô hình ngôn ngữ nhỏ (SLM) trực tiếp trên máy qua llama.cpp nhúng tĩnh.
- **Tasks:**
  - `TROLY-F2-01`: Thiết kế Interface `IInferenceEngine.hpp` với cơ chế Token Streaming và `std::stop_token`.
  - `TROLY-F2-02`: Lớp bọc RAII smart pointers với custom deleters cho `llama_model` và `llama_context`.
  - `TROLY-F2-03`: Context Window Manager và bộ lọc ngữ pháp GBNF Grammar parser đảm bảo output JSON cấu trúc cho Tool Calling.

### F3: Điều Phối Tác Vụ (Action Dispatcher & ReAct Loop)
- **Mô tả:** Tự động hóa tác vụ hệ điều hành NixOS (chạy lệnh shell, đọc ghi tệp, kiểm tra hệ thống).
- **Tasks:**
  - `TROLY-F3-01`: Thiết kế Interface `IActionDispatcher.hpp`.
  - `TROLY-F3-02`: Linux Command Dispatcher an toàn với `QProcess`, hỗ trợ timeout và non-blocking.
  - `TROLY-F3-03`: Vòng lặp ReAct (Reasoning + Acting) tự sửa lỗi: lấy output thực thi phản hồi ngược lại context của AI nếu câu lệnh bị lỗi.

### F4: Cơ Chế An Toàn (Safety Guard & Audit Trail)
- **Mô tả:** Bảo vệ an toàn cho người dùng khi Agent đề xuất lệnh nhạy cảm (sudo, rm, nixos-rebuild).
- **Tasks:**
  - `TROLY-F4-01`: Interface `ISafetyGuard.hpp` kiểm duyệt command regex, blacklist và phân cấp mức độ rủi ro (Low / High).
  - `TROLY-F4-02`: UI Modal phê duyệt Human-in-the-Loop trên QML trước khi thực thi lệnh rủi ro cao.
  - `TROLY-F4-03`: Ghi log kiểm toán (Audit Trail) cục bộ vào bảng SQLite `action_logs`.

### F5: Giao Diện Bản Địa & Desktop Mascot (Qt6 Quick/QML)
- **Mô tả:** Giao diện Desktop Pet trong suốt, tăng tốc phần cứng Wayland native Scene Graph, thay thế WebKitGTK.
- **Tasks:**
  - `TROLY-F5-01`: ViewModel nền tảng (`ChatViewModel`, `SystemMonitorViewModel`, `SettingsViewModel`).
  - `TROLY-F5-02`: Cửa sổ QML trong suốt hỗ trợ XWayland và Wayland native (`Qt.FramelessWindowHint`, `WA_TranslucentBackground`).
  - `TROLY-F5-03`: Tích hợp Mascot Pet Sprite & Animations từ `assets/pet/` (`cho chao.svg`, `cho dung.svg`, `cho nhay.svg`, `cho ngu.svg`).
  - `TROLY-F5-04`: Tích hợp EyeLeo Companion (nhắc nghỉ mắt 20-20-20 & nghỉ dài có animation Mascot).
  - `TROLY-F5-05`: Markdown Live Rendering tốc độ 60fps trên QML với syntax highlighting.

### F6: Bộ Định Tuyến Động (Dynamic MoE Router)
- **Mô tả:** Phân loại ý định siêu nhanh (<30ms) để điều phối sang model chuyên biệt (Text, Code, Vision).
- **Tasks:**
  - `TROLY-F6-01`: Interface `IRouterEngine.hpp` và bảng quản lý `models_registry`.
  - `TROLY-F6-02`: Intent Classifier siêu nhẹ (<30ms) nhận diện kiểu tệp (PNG/JPG ➔ Vision; Shell/Nix/C++ ➔ Coder; Text ➔ Worker Qwen2.5).
  - `TROLY-F6-03`: Cơ chế Hot-Swap giải phóng VRAM model cũ và nạp context mới trên worker thread mà không làm treo GUI.

### F7: Trung Tâm Tự Tiến Hóa (Self-Evolving Hub - Air-gapped)
- **Mô tả:** Thu hoạch dữ liệu chất lượng cao từ phiên làm việc và tự động fine-tune LoRA cục bộ.
- **Tasks:**
  - `TROLY-F7-01`: Schema thu thập bản ghi vàng `training_datasets` có `quality_score >= 1.0`.
  - `TROLY-F7-02`: Pipeline 4 bước: Xuất ChatML `train_data.txt` ➔ `llama-finetune` LoRA ➔ `llama-export-lora` merge ➔ `llama-quantize` Q4_K_M.
  - `TROLY-F7-03`: Tự động đăng ký model GGUF mới vào `models_registry`.

