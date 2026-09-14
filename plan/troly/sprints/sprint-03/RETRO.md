# SPRINT 03 RETROSPECTIVE: Vector RAG & SQLite WAL Engine
**Thời gian:** 14/10/2026 | **Phiên bản:** `v01.03.00` | **Điều phối:** @PlanAgent

---

## 🌟 1. Điểm Tốt (What Went Well)
- **Tốc độ triển khai vượt trội:** Hoàn thành toàn bộ kiến trúc Vector RAG từ DDL, SQLite WAL, nạp dynamic extension `sqlite-vec` đến thuật toán Hybrid Search RRF chỉ trong 1 chu kỳ Sprint.
- **Tuân thủ Clean Architecture & RAII:** `SqliteRAGRepository` đóng gói trọn vẹn việc quản lý con trỏ `sqlite3*`, câu lệnh `sqlite3_stmt*` và dọn dẹp tài nguyên RAII an toàn, không rò rỉ bộ nhớ.
- **Tiết kiệm Token & Phân rã nhỏ nhất:** Tách bạch `DocumentIngestionWorker.hpp`, `RAGViewModel.hpp/.cpp`, `test_rag.cpp` theo hạt nhỏ nhất (Atomic Granularity), giúp mã nguồn mạch lạc và dễ bảo trì.
- **Tính di động & Standalone Portability:** Nhận diện đường dẫn `libvec0.so` linh hoạt qua biến môi trường hoặc fallback hệ thống, không hardcode path tuyệt đối của Nix store vào mã C++.

---

## 🛑 2. Khó Khăn & Vấn Đề Gặp Phải (What Went Wrong / Blockers)
- **MOC Vtable Linker Error:** Khi bổ sung `RAGViewModel` kế thừa `QObject`, việc ban đầu chỉ khai báo file `.hpp` (header-only) dẫn đến lỗi liên kết thiếu vtable khi Ninja build. Cần luôn tạo file compilation unit `.cpp` đi kèm và khai báo vào cả `SOURCES` lẫn `HEADERS` của CMake.
- **Safe Fallback trong QML Preview:** Việc xem trước giao diện độc lập qua `just tp` (`qml`) không cung cấp sẵn các C++ context properties (`ragVM`, `eyeLeoVM`). Cần liên tục duy trì cơ chế guard `typeof` trong các component QML để tránh vỡ giao diện runtime.

---

## 💡 3. Bài Học & Hành Động Cải Tiến (Action Items for Sprint 04)
1. **Quy chuẩn khai báo ViewModel:** Mọi ViewModel mới kế thừa từ `QObject` bắt buộc phải có đủ cặp file `.hpp` / `.cpp` và đăng ký trong [CMakeLists.txt](file:///etc/nixos/pkgs/troly/CMakeLists.txt) ngay từ đầu.
2. **Mocking sẵn sàng cho CTest:** Tiếp tục duy trì pattern Mock Provider (như `MockEmbeddingGenerator`) khi triển khai Local Inference và Dynamic MoE Router ở Sprint 04, đảm bảo CTest có thể chạy tự động trong CI/CD mà không phụ thuộc vào GPU hay model GGUF dung lượng lớn.
3. **Giữ vững nhịp độ Why-What-Test:** Tiếp tục duy trì quy chuẩn commit 3 khối và đồng bộ tài liệu Markdown UI/UX trong thư mục `/plan/troly/`.
