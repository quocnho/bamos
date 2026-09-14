# SPRINT 02: Modern Mascot UI & EyeLeo Native
**Thời gian:** 15/09/2026 - 29/09/2026 | **Trạng thái:** 🟡 IN_PROGRESS | **Phiên bản:** `v01.02.00`

> 🎯 **Mục Tiêu Trọng Tâm Sprint 02:**
> Hiện thực hóa trải nghiệm tương tác trực quan sống động của người dùng với Troly:
> 1. Hoàn thiện Desktop Pet thông minh với cơ chế **Núp lùm & Thò đuôi vẫy (Peek Tail)** ở cạnh màn hình, click chuột để cún vồ trỏ chuột và mở hộp nhập lệnh nhanh.
> 2. Nâng cấp bộ hoạt hình SVG Disney 12 nguyên tắc (Squash & Stretch, Easing Bezier, máy trạng thái Mascot FSM).
> 3. Tích hợp trọn vẹn cơ chế bảo vệ sức khỏe **EyeLeo Native C++** (3 cấp độ nhắc nhở, bài tập mắt cùng cún cưng, overlay nghỉ dài 5 phút kèm Strict Mode, phát hiện máy nghỉ idle qua D-Bus).
> 4. Hoàn thiện hệ thống **Quick Action Menu ⚙️** và các cửa sổ thiết lập kế thừa từ `assistant` (RAG, LLM, System Inspector, WakaTracker, Profile).

---

## 📋 Bảng Công Việc (Sprint Backlog)

| Task ID | Component | Phân loại | Người nhận | Ước lượng | Trạng thái | Ghi chú kỹ thuật |
|---|---|---|---|---|---|---|
| `TROLY-201` | Mascot Interaction & Peek Tail | `feat` | @AnimAgent, @DevOptAgent | 5 SP | 🟡 IN_PROGRESS | Neo cún vào sát mép phải màn hình, thò đuôi vẫy; click chuột kích hoạt wakeup animation |
| `TROLY-202` | Disney Animation & FSM Refining | `feat` | @AnimAgent | 3 SP | 🟡 IN_PROGRESS | Cải tiến Bezier easing, squash & stretch khi thở/nhảy, tối ưu Scene Graph 60fps |
| `TROLY-203` | Native EyeLeo Service & Controller | `feat` | @DevOptAgent | 5 SP | ⚪ TODO | `EyeLeoService.hpp/.cpp`, hẹn giờ 30s cảnh báo, 20s nghỉ ngắn, 5m nghỉ dài, D-Bus idle detector |
| `TROLY-204` | EyeLeo UI Modals & Exercises | `feat` | @DevOptAgent, @AnimAgent | 5 SP | ⚪ TODO | Cửa sổ overlay bán trong suốt, bài tập đảo mắt theo cún con, countdown strict mode |
| `TROLY-205` | Quick Action Menu & Modals Wiring | `feat` | @DevOptAgent | 3 SP | ⚪ TODO | Kết nối nút ⚙️ mở Menu thả xuống, hiển thị đầy đủ các panel thiết lập |
| `TROLY-206` | Bone Context Bar & Nautilus Dnd | `feat` | @DevOptAgent | 3 SP | ⚪ TODO | Thanh ngữ cảnh thư mục, nhận file/folder kéo thả hoặc đọc đường dẫn từ clipboard |
| `TROLY-207` | Unit Test & BAM Switch Verification | `test` | @DevOptAgent | 2 SP | ⚪ TODO | Kiểm thử ctest các logic timer, build derivation và chạy thử nghiệm `bam dry` |

---

## 👥 Ma Trận Phân Vai (RACI Sprint 02)

- **@PlanAgent:** Theo dõi tiến độ Sprint 02, điều phối Daily Scrum, cập nhật Review/Retro khi hoàn thành.
- **@AnimAgent:** Trực tiếp chỉ đạo mỹ thuật chuyển động cún cưng (`STATE_PEEK_TAIL`, `STATE_PLAYFUL_JUMP`), tối ưu SVG vector và timing Bezier.
- **@DevOptAgent:** Lập trình C++20 Clean Architecture, quản lý Qt Signals, viết `EyeLeoService`, kết nối QML ViewModels và thực hiện build test.
- **@RdAgent:** Cung cấp thông số kỹ thuật D-Bus Mutter idle time và chuẩn bị spike cho Sprint 03 (Vector RAG).

---

## 🔗 Liên Kết Hồ Sơ Agile Scrum
- **Chỉ mục kế hoạch tổng quan:** [plan/troly/README.md](file:///etc/nixos/plan/troly/README.md)
- **Master Product Backlog:** [plan/troly/backlog/BACKLOG.md](file:///etc/nixos/plan/troly/backlog/BACKLOG.md)
- **Nhật ký Daily Standup:** [plan/troly/scrum/DAILY_SCRUM.md](file:///etc/nixos/plan/troly/scrum/DAILY_SCRUM.md)
- **Sprint 01 Lưu trữ:** [plan/troly/sprints/sprint-01/PLAN.md](file:///etc/nixos/plan/troly/sprints/sprint-01/PLAN.md)
