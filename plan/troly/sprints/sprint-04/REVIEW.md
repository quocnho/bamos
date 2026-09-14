# SPRINT 04 REVIEW: Local Inference & Dynamic MoE Router
**Thời gian nghiệm thu:** 28/10/2026 | **Phiên bản:** `v01.04.00` | **Trạng thái:** 🟢 ACCEPTED & RELEASED

---

## 🎯 1. Tóm Tắt Kết Quả Sprint (Executive Summary)
Sprint 04 đã hoàn thành xuất sắc toàn diện 7/7 hạng mục công việc (26/26 Story Points, đạt **100% Sprint Velocity**), mang lại khả năng suy luận cục bộ (Local Inference) linh hoạt và cơ chế chuyển đổi mô hình thông minh (Dynamic Mixture of Experts) cho cún cưng `troly` trên NixOS.

### Các thành quả kỹ thuật nổi bật:
1. **Dynamic MoE Router & Model Slots:** Quản lý danh mục mô hình chuyên biệt (`qwen2.5-3b-chat`, `qwen2.5-coder-7b`, `llama3.2-3b-sys`, `qwen2.5-3b-rag`), phân phối ngữ cảnh tương ứng và tích hợp bộ giám sát VRAM Budget Supervisor (< 6000MB).
2. **Ultra-fast Intent Classifier (<30ms):** Nhận diện 4 nhóm ý định người dùng (`GeneralChat`, `CodeGeneration`, `SystemCommand`, `KnowledgeQuery`) theo quy tắc heuristic tối ưu tốc độ nano-seconds trước khi gửi prompt.
3. **Local Streaming Inference & Abort Token:** Hiện thực `LlamaInferenceEngine` kết nối Server-Sent Events (SSE) `/v1/chat/completions`, streaming từng token mượt mà và ngắt dòng an toàn qua `std::stop_token`.
4. **Context Augmentation với Hybrid RAG:** Tự động tra cứu tri thức liên quan từ `SqliteRAGRepository` (Sprint 03) và bổ sung vào bối cảnh tin nhắn trước khi suy luận.
5. **Giao diện Cấu Hình LLM & MoE (`LLMSettingsModal.qml` + `LLMViewModel`):** Cung cấp giao diện trực quan cho phép người dùng chọn mô hình, xem ý định hiện tại, điều chỉnh số lớp GPU Offload và kiểm tra kết nối với fallback an toàn.
6. **Kiểm thử tự động & Đóng gói NixOS:** Đạt 100% CTest (`EyeLeoTests`, `RAGTests`, `InferenceTests`), `nix-build default.nix` ra store path `/nix/store/icvz0gixaqbmvzcfdd16axsbxdnl9519-troly-0.1.0`, `nix build .#troly --dry-run` hoàn tất sạch sẽ.

---

## 📊 2. Bảng Nghiệm Thu Công Việc (Sprint Backlog Acceptance)

| Task ID | Component / Tính năng | Người thực hiện | Điểm SP | Kết quả kiểm thử | Nghiệm thu |
|---|---|---|---|---|---|
| `TROLY-401` | Llama HTTP/SSE Streaming Client | @DevOptAgent | 5 SP | Stream token mượt mà, abort an toàn | ✅ PASS |
| `TROLY-402` | Ultra-fast Intent Classifier | @RdAgent, @DevOptAgent | 5 SP | Phân loại chính xác 4 intent, độ trễ <1ms | ✅ PASS |
| `TROLY-403` | Dynamic MoE Model Router | @RdAgent, @DevOptAgent | 5 SP | Slot selection chuẩn xác, giám sát VRAM < 6GB | ✅ PASS |
| `TROLY-404` | RAG Context Augmenter | @DevOptAgent | 3 SP | Tự động ghép tri thức RAG vào prompt | ✅ PASS |
| `TROLY-405` | LLM ViewModel & Settings UI | @DevOptAgent | 3 SP | `LLMSettingsModal.qml` binding `llmVM`, safe preview | ✅ PASS |
| `TROLY-406` | CTest Unit Tests for Inference | @DevOptAgent | 3 SP | 100% passed (EyeLeo + RAG + Inference) | ✅ PASS |
| `TROLY-407` | Flake & NixOS Verification | @DevOptAgent | 2 SP | Nix derivation build thành công, dry-run pass | ✅ PASS |

**Tổng điểm SP hoàn thành:** 26 / 26 SP (100%).

---

## 🧪 3. Báo Cáo Kiểm Thử (Verification & DoD)
- **CTest Output:**
  ```text
  1/3 Test #1: EyeLeoTests ......................   Passed    0.00 sec
  2/3 Test #2: RAGTests .........................   Passed    0.05 sec
  3/3 Test #3: InferenceTests ...................   Passed    0.80 sec
  100% tests passed, 0 tests failed out of 3
  ```
- **Nix Build Output:**
  ```text
  /nix/store/icvz0gixaqbmvzcfdd16axsbxdnl9519-troly-0.1.0
  ```
- **Nix Flake Dry-run:**
  ```text
  this derivation will be built:
    /nix/store/87czy2h47bhwzcc9ps0jrnwcnpnffxl2-troly-0.1.0.drv
  ```

---

## 🚀 4. Kế Hoạch Bàn Giao & Bước Tiếp Theo
- Merge toàn bộ mã nguồn Sprint 04 sang nhánh `main`.
- Gắn thẻ phiên bản Git: `v01.04.00`.
- Khởi động **Sprint 05: Action Dispatcher, Safety Guard & ReAct Loop (`v01.05.00`)**.
