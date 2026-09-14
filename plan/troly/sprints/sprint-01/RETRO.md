# SPRINT RETROSPECTIVE: Sprint 01 - Core Architecture & Setup
**Thời gian:** 28/09/2026 | **Điều phối:** @PlanAgent | **Trạng thái:** 🟡 IN_PROGRESS

> 🔄 **Kế thừa & Nâng cấp từ `/etc/nixos/pkgs/assistant/`:** Việc đọc lại và kế thừa trọn vẹn tri thức từ `pkgs/assistant` (Menu, Settings windows, EyeLeo, WakaTracker) giúp định hình chính xác các ViewModel cần thiết trong Qt6 C++20 mà không tốn công thiết kế lại từ đầu.

---

## 1. Điều Đã Làm Tốt (What Went Well)
- **Tối ưu Token & Context Window:** Tách nhỏ Rules ([GEMINI.md](file:///etc/nixos/pkgs/troly/GEMINI.md)) dưới 20 dòng kết hợp 7 on-demand Skills giúp tiết kiệm ~80% token cho mỗi câu lệnh chat.
- **Tái Lập Môi Trường (Reproducibility):** Sử dụng NixOS Flakes và `devenv` loại bỏ hoàn toàn tình trạng xung đột thư viện giữa các máy phát triển.
- **Tổ chức Clean Architecture:** Phân tầng rõ rệt giữa Domain, Usecases, Infrastructure và Presentation, hỗ trợ đắc lực cho AI Agent làm việc độc lập.

---

## 2. Điểm Cần Cải Thiện (What Could Be Improved)
- **Tốc độ khởi động:** Cần kiểm tra kỹ thời gian nạp dynamic model GGUF và sqlite-vec extension để không gây giật lag giao diện QML.
- **Tài liệu hóa Skeleton:** Cần đảm bảo các file `.hpp` luôn có comment Doxygen đầy đủ để Agent đọc hiểu trong thời gian ngắn nhất.

---

## 3. Kế Hoạch Hành Động (Action Items)

| STT | Hành động cụ thể | Người phụ trách | Hạn chót | Trạng thái |
|---|---|---|---|---|
| 1 | Benchmark tốc độ phản hồi intent classifier (<30ms) | @RdAgent | Sprint 02 | ⚪ TODO |
| 2 | Bổ sung Unit Test mẫu với GoogleTest/CTest cho Domain Entities | @DevOptAgent | Sprint 01 | 🟡 IN_PROGRESS |
| 3 | Tự động hóa cập nhật `DAILY_SCRUM.md` sau mỗi phiên làm việc | @PlanAgent | Daily | 🟢 ACTIVE |
| 4 | Phân rã nhỏ nhất có thể các thư mục/tập tin Clean Arch (Atomic Granularity) để tối ưu token khi đọc | @DevOptAgent | Sprint 01 | 🟢 ACTIVE |

