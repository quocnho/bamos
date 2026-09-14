# SPRINT RETROSPECTIVE: Sprint 02 - Modern Mascot UI & EyeLeo Native
**Thời gian:** 15/09/2026 - 29/09/2026 | **Điều phối:** @PlanAgent | **Trạng thái:** 🟢 COMPLETED

---

## 1. Điều Đã Làm Tốt (What Went Well)
- **Tốc độ triển khai vượt trội:** Hoàn thành toàn bộ 7 tasks lớn của Sprint 02 trong 1 phiên làm việc tập trung cao độ giữa `@AnimAgent`, `@DevOptAgent` và `@PlanAgent`.
- **Cơ chế Morphing Window thông minh:** Không tạo thêm cửa sổ phụ gây xung đột trên Wayland compositor, tận dụng chuyển đổi kích thước mượt mà `84x120` ➔ `480x680` với đường cong Bezier `Easing.OutBack`.
- **QML Safe Fallbacks:** Đảm bảo mã nguồn QML chạy mượt cả ở chế độ độc lập (`just tp` - Live Preview) lẫn chế độ kết hợp Native C++ (`just tr`).
- **Tự động hóa kiểm thử:** Tích hợp bộ kiểm thử CTest `test_eyeleo.cpp` vào quy trình CMake Ninja, đảm bảo chất lượng kiểm thử liên tục.

---

## 2. Điểm Cần Cải Thiện (What Could Be Improved)
- **Bộ dữ liệu Embedding mẫu:** Cần chuẩn bị sẵn file mô hình embedding GGUF nhỏ gọn (ví dụ: `all-MiniLM-L6-v2.gguf` hoặc `bge-small-en-v1.5`) phục vụ việc test trích xuất vector cho Sprint 03.
- **Tối ưu hóa nạp sqlite-vec:** Cần đóng gói sẵn đường dẫn nạp `libvec0.so` trong môi trường NixOS để `SqliteRAGRepository.cpp` nạp tức thì.

---

## 3. Kế Hoạch Hành Động (Action Items cho Sprint 03)

| STT | Hành động cụ thể | Người phụ trách | Hạn chót | Trạng thái |
|---|---|---|---|---|
| 1 | Khởi tạo bảng DDL chuẩn và nạp động `libvec0.so` cho SQLite WAL | @DevOptAgent | Sprint 03 | ⚪ TODO |
| 2 | Hiện thực hóa thuật toán Hybrid Search RRF (BM25 FTS5 + Cosine sqlite-vec) | @RdAgent, @DevOptAgent | Sprint 03 | ⚪ TODO |
| 3 | Xây dựng bộ quét tệp bất đồng bộ `std::jthread` (Chunking & SHA256 hashing) | @DevOptAgent | Sprint 03 | ⚪ TODO |
| 4 | Kết nối RAG Repository với giao diện tìm kiếm `RAGSettingsModal.qml` | @DevOptAgent | Sprint 03 | ⚪ TODO |
