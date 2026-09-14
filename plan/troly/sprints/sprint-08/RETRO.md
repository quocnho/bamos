# SPRINT 08 RETROSPECTIVE: Hybrid Expansion (Autonomous Agent Tools & Desktop Pet Polish)
**Thời gian họp:** 25/12/2026 | **Phiên bản:** `v01.08.00` | **Điều phối:** @PlanAgent

---

## 🌟 1. Điểm Tốt (What Went Well)
- **Mở rộng năng lực Agent Tooling mạnh mẽ:**
  - Tích hợp thành công các công cụ hệ thống Linux (`listDirectory`, `searchInFiles`, `validateNixConfig`) theo kiến trúc Clean Architecture, mở rộng từ `IActionDispatcher` giúp cún con Troly có thể chủ động kiểm tra hệ sinh thái và mã nguồn NixOS.
- **Phản hồi âm thanh Native (Audio Feedback Service):**
  - Thêm âm thanh sủa vui nhộn (`AudioFeedbackService`) không tạo overhead, mang lại cảm xúc sinh động khi người dùng xoa đầu hoặc đánh thức cún cưng.
- **Hoạt ảnh tương tác 3D Mascot mượt mà (Disney Dynamics):**
  - @AnimAgent đã hoàn thành xuất sắc hiệu ứng co giãn Squash & Stretch khi trỏ chuột hover/petting trên `Mascot3DPOC.qml`.
- **Tốc độ kiểm thử CTest ấn tượng:** 7/7 test suites hoàn thành chỉ trong **1.77 giây**, 100% Passed.
- **Đóng gói NixOS trơn tru:** `nix-build default.nix` vượt qua kiểm tra và build thành công ngay trong lần đầu.

---

## 🔍 2. Điểm Cần Cải Thiện (What Could Be Better)
- **Trải nghiệm cửa sổ ứng dụng:**
  - Ứng dụng vẫn chạy trong khuôn khổ cửa sổ hình chữ nhật truyền thống; trải nghiệm Desktop Pet cần được giải phóng hoàn toàn khỏi viền hộp (frameless, transparent background).
- **Vị trí hiển thị cửa sổ:**
  - Cần tự động định vị ở góc dưới bên phải màn hình khi khởi chạy lần đầu và ghi nhớ tọa độ sau khi người dùng kéo thả để tăng tính tự nhiên.
- **Cơ chế nạp Model LLM:**
  - Cần có phương thức tải trực tiếp tệp `.gguf` từ giao diện ứng dụng về thư mục máy nội bộ thay vì yêu cầu người dùng copy tệp thủ công.

---

## 🎯 3. Kế Hoạch Hành Động Cho Sprint 09 (Action Items for Sprint 09)
- [x] Triển khai chế độ cửa sổ vô hình không viền (`frameless`, `color: transparent`) để cún con nổi tự do trên desktop.
- [x] Tự định vị góc dưới phải màn hình và lưu tọa độ `(x, y)` kéo thả qua `QSettings`.
- [x] Thêm hoạt cảnh nhảy mừng rỡ, sủa gâu gâu và bong bóng chat chào hỏi với đại từ xưng hô người dùng (`UserProfile.addressing`).
- [x] Xây dựng `GGUFDownloaderService` bằng `QNetworkAccessManager` (Phương án A) và giao diện tải mô hình LLM trực quan.
