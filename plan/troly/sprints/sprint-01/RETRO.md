# SPRINT RETROSPECTIVE: Sprint 01 - Core Architecture & Setup
**Thời gian:** 14/09/2026 - 28/09/2026 | **Điều phối:** @PlanAgent | **Trạng thái:** 🟢 COMPLETED

> 🔄 **Kế thừa & Nâng cấp từ `/etc/nixos/pkgs/assistant/`:** Việc đọc lại và kế thừa trọn vẹn tri thức từ `pkgs/assistant` (Menu, Settings windows, EyeLeo, WakaTracker) giúp định hình chính xác các ViewModel cần thiết trong Qt6 C++20 mà không tốn công thiết kế lại từ đầu.

---

## 1. Điều Đã Làm Tốt (What Went Well)
- **Tối ưu Token & Context Window:** Tách nhỏ Rules ([GEMINI.md](file:///etc/nixos/pkgs/troly/GEMINI.md)) dưới 20 dòng kết hợp các on-demand Skills giúp tiết kiệm ~80% token cho mỗi câu lệnh chat.
- **Tái Lập Môi Trường (Reproducibility):** Sử dụng NixOS Flakes và `devenv` loại bỏ hoàn toàn tình trạng xung đột thư viện giữa các máy phát triển.
- **Tổ chức Clean Architecture:** Phân tầng rõ rệt giữa Domain, Usecases, Infrastructure và Presentation theo nguyên tắc phân nhỏ vi mô (Atomic Granularity), hỗ trợ đắc lực cho AI Agent làm việc độc lập.
- **Nghiệm thu trơn tru:** Hoàn thành 100% 6 tasks nền tảng từ biên dịch cục bộ đến đóng gói Flake toplevel.

---

## 2. Điểm Cần Cải Thiện (What Could Be Improved)
- **Tương tác Mascot thực tế:** Cần bổ sung ngay logic xử lý chuột tương tác "Núp lùm thò đuôi" (Peek Tail) để người dùng có thể kích hoạt nhanh từ cạnh màn hình.
- **EyeLeo D-Bus Native:** Cần chuyển đổi toàn bộ logic bắt idle Mutter D-Bus sang C++ service thuần.

---

## 3. Kế Hoạch Hành Động (Action Items cho Sprint 02)

| STT | Hành động cụ thể | Người phụ trách | Hạn chót | Trạng thái |
|---|---|---|---|---|
| 1 | Hoàn thiện Desktop Pet tương tác chuột (Peek Tail & Mouse Click Playful Jump) | @AnimAgent, @DevOptAgent | Sprint 02 | 🟡 IN_PROGRESS |
| 2 | Hoàn thiện tích hợp EyeLeo C++ Service (cảnh báo 30s, nghỉ ngắn 20s, nghỉ dài 5m strict) | @DevOptAgent | Sprint 02 | 🟡 IN_PROGRESS |
| 3 | Tối ưu hóa Quick Menu ⚙️ và các settings modals | @DevOptAgent | Sprint 02 | 🟡 IN_PROGRESS |
| 4 | Cập nhật nhật ký Daily Scrum liên Agent theo đúng nhịp độ | @PlanAgent | Hàng ngày | 🟢 ACTIVE |
