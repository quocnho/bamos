# SPRINT 09: Standalone 3D Mascot Desktop Pet & GGUF Model Downloader
**Thời gian:** 26/12/2026 - 10/01/2027 | **Trạng thái:** 🟢 COMPLETED | **Phiên bản:** `v01.09.00`

> 🎯 **Mục Tiêu Trọng Tâm Sprint 09:**
> Đưa trải nghiệm người dùng của `troly` lên chuẩn mực Desktop Pet đích thực và tối ưu quy trình quản trị mô hình AI:
> 1. **Khởi tạo lần đầu & Lưu tọa độ kéo thả (Persistence):**
>    - Mặc định khởi động ứng dụng chỉ hiển thị chú cún cưng tại góc dưới bên phải màn hình.
>    - Cho phép nắm kéo thả tự do chú cún đến bất kỳ vị trí nào trên màn hình.
>    - Sử dụng `QSettings` lưu trữ tọa độ `(x, y)` vào cấu hình hệ thống, khôi phục chính xác vị trí trong các lần mở sau.
> 2. **Tạo hình 3D Desktop Pet không viền hộp & Hoạt cảnh Chào hỏi nhí nhảnh:**
>    - Chú cún nổi hoàn toàn tự do (Frameless, Transparent Background) không có viền hộp vuông bao quanh.
>    - Hoạt cảnh xuất hiện: Chú cún nhảy tung tăng (Disney Squash & Stretch), sủa gâu gâu thân thiện (`AudioFeedbackService`).
>    - Bung bong bóng chat (Speech Bubble) trên đầu với nội dung: `Xin chào {Xưng hô}, chúc một ngày vui! Gâu gâu!` (lấy `{Xưng hô}` từ `userProfileVM.addressing`).
> 3. **Tải xuống mô hình GGUF cho LLM (Qt Native Network):**
>    - Xây dựng `GGUFDownloaderService` bằng `QNetworkAccessManager` (Phương án A), tải mô hình GGUF trực tiếp vào `~/.local/share/troly/models/`.
>    - Hiển thị tiến trình tải (%) trực quan trong `LLMSettingsModal.qml`.
> 4. **Kiểm thử tự động & Đóng gói:**
>    - Bổ sung CTest suite `test_gguf_downloader.cpp`, bảo đảm 100% CTest passed (8/8 suites) và đóng gói Nix derivation thành công.

---

## 📋 Bảng Công Việc (Sprint Backlog)

| Task ID | Component | Phân loại | Người nhận | Ước lượng | Trạng thái | Ghi chú kỹ thuật |
|---|---|---|---|---|---|---|
| `TROLY-901` | Window Drag & Position Persistence | `feat` | @DevOptAgent | 5 SP | 🟢 DONE | Tự định vị góc dưới phải, kéo thả lưu tọa độ qua `QSettings` |
| `TROLY-902` | Frameless 3D Mascot & Speech Bubble | `feat` | @AnimAgent, @DevOptAgent | 5 SP | 🟢 DONE | Chú cún 3D không hộp vuông, hoạt cảnh nhảy sủa và bong bóng chào hỏi |
| `TROLY-903` | Qt Native GGUF Downloader Service | `feat` | @DevOptAgent | 5 SP | 🟢 DONE | `GGUFDownloaderService` với `QNetworkAccessManager`, tiến trình % |
| `TROLY-904` | LLM Modal GGUF Download UI | `feat` | @DevOptAgent | 3 SP | 🟢 DONE | Giao diện nhập URL/chọn model, thanh tiến trình tải trong LLM Settings |
| `TROLY-905` | CTest Suite & Nix Packaging | `test` | @DevOptAgent | 3 SP | 🟢 DONE | `test_gguf_downloader.cpp` (8/8 CTest suites passed) & Nix build |

---

## 👥 Ma Trận Phân Vai (RACI Sprint 09)

- **@PlanAgent:** Quản trị Sprint Backlog, nhật ký Daily Scrum và hồ sơ nghiệm thu Sprint 09.
- **@RdAgent:** Đánh giá luồng tải mô hình dung lượng lớn qua Qt Network và cơ chế lưu trữ mô hình cục bộ.
- **@DevOptAgent:** Lập trình C++20 Clean Architecture cho Downloader, tích hợp QSettings và ViewModels.
- **@AnimAgent:** Tạo hình và hoạt cảnh chuyển động 3D không viền hộp, bóng bóng chat phong cách hoạt hình Disney.

---

## 🔗 Liên Kết Hồ Sơ Agile Scrum
- **Chỉ mục kế hoạch tổng quan:** [plan/troly/README.md](file:///etc/nixos/plan/troly/README.md)
- **Master Product Backlog:** [plan/troly/backlog/BACKLOG.md](file:///etc/nixos/plan/troly/backlog/BACKLOG.md)
- **Nhật ký Daily Standup:** [plan/troly/scrum/DAILY_SCRUM.md](file:///etc/nixos/plan/troly/scrum/DAILY_SCRUM.md)
