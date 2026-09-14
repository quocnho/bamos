---
name: daily-kickoff
description: Khởi động ngày làm việc mới (Daily Standup & Kickoff). Quét trạng thái Sprint hiện tại, rà soát nhật ký Daily Scrum, phân tích ticket cần xử lý trong ngày và đề xuất kế hoạch hành động cụ thể cho từng Agent. Kích hoạt khi người dùng mở máy bắt đầu ngày mới, hoặc yêu cầu kiểm tra kế hoạch và công việc hôm nay.
---

# Mục Tiêu
Giúp người dùng (Solo Coder) chỉ cần mở laptop và ra lệnh ngắn gọn (ví dụ: *"@PlanAgent và @DevOptAgent kiểm tra kế hoạch và thực hiện công việc hôm nay"*), hệ thống Multi-Agent sẽ tự động:
1. Đọc trạng thái Sprint hiện tại tại `plan/sprints/sprint-XX/PLAN.md`.
2. Kiểm tra nhật ký hôm trước tại `plan/scrum/DAILY_SCRUM.md`.
3. Phân tích các task ưu tiên cao nhất (`🟡 IN_PROGRESS` hoặc `⚪ TODO`).
4. Đề xuất kế hoạch hành động chi tiết trong ngày (Today's Action Plan) và chủ động bắt tay vào thực hiện sau khi người dùng đồng ý.

> 📦 **Bối Cảnh Flake Cha:** Dự án `troly` là một **package con** của cấu hình NixOS bằng flake tại `/etc/nixos/` (tương tự `/etc/nixos/pkgs/assistant/` và `/etc/nixos/pkgs/bam/`). Khi các task liên quan tới packaging/system integration hoàn tất trong ngày, @DevOptAgent chủ động kiểm thử đóng gói `nix-build` và kiểm thử toàn hệ thống bằng lệnh `bam switch`.
> 
> 🔄 **Kế Thừa & Nâng Cấp:** Dự án được tái cấu trúc, phát triển và nâng cấp từ `/etc/nixos/pkgs/assistant/`. Quy trình Daily Kickoff đảm bảo mọi thành phần cốt lõi của dự án cũ (Menu, Cửa sổ thiết lập, EyeLeo, WakaTracker) được rà soát và chuyển dịch tuần tự sang kiến trúc C++20/Qt6 Native theo [docs/ARCHITECTURE.md](file:///etc/nixos/pkgs/troly/docs/ARCHITECTURE.md).

# Quy Trình Tự Động 4 Bước Khi Kích Hoạt

### Bước 1: Quét Bối Cảnh (Context Scan)
- Đọc [plan/README.md](file:///etc/nixos/pkgs/troly/plan/README.md) để xác định Sprint đang hoạt động (ví dụ: `sprint-01`).
- Đọc file `PLAN.md` của Sprint đó để lấy danh sách tasks, người nhận (@DevOptAgent / @RdAgent / @AnimAgent) và trạng thái.
- Đọc mục mới nhất trong [plan/scrum/DAILY_SCRUM.md](file:///etc/nixos/pkgs/troly/plan/scrum/DAILY_SCRUM.md) để nắm các vướng mắc (blockers) còn tồn đọng từ hôm qua.

### Bước 2: @PlanAgent Phân Tích & Báo Cáo Buổi Sáng (Morning Briefing)
Xuất báo cáo định dạng UI/UX Markdown trực quan:
```markdown
## 🌅 BÁO CÁO KHỞI ĐỘNG NGÀY [YYYY-MM-DD]

### 📊 Trạng Thái Sprint Hiện Tại: [Tên Sprint] (Tiến độ: X/Y tasks - Z%)
- 🟢 **Đã hoàn thành:** [Task ID] - [Tên Task]
- 🟡 **Đang dang dở:** [Task ID] - [Tên Task] (@NgườiNhận)
- ⚪ **Mục tiêu tiếp theo:** [Task ID] - [Tên Task]

### 🎯 Trọng Tâm Hôm Nay (Focus of the Day):
1. **[Task ID]**: [Hành động cụ thể cần làm hôm nay].
2. **Blockers cần gỡ:** [Nếu có].
```

### Bước 3: @DevOptAgent & @RdAgent Đề Xuất Kế Hoạch Kỹ Thuật
- Nếu task cần nghiên cứu kỹ thuật/trade-off: `@RdAgent` chỉ ra interface stubs hoặc POC cần làm trước theo [docs/ARCHITECTURE.md](file:///etc/nixos/pkgs/troly/docs/ARCHITECTURE.md).
- `@DevOptAgent` trình bày các bước lập trình C++20 Clean Architecture hoặc cấu hình build:
  - File header nào cần tạo/sửa trong `src/usecases/` hoặc `src/domain/` (tuân thủ Atomic Granularity).
  - Kiểm thử unit test nào sẽ được viết.

### Bước 4: Tự Động Ghi Nhật Ký Standup & Bắt Tay Thực Hiện
- `@PlanAgent` tự động thêm một mục ngày mới vào [plan/scrum/DAILY_SCRUM.md](file:///etc/nixos/pkgs/troly/plan/scrum/DAILY_SCRUM.md).
- Chuyển trạng thái ticket từ `⚪ TODO` sang `🟡 IN_PROGRESS`.
- `@DevOptAgent` và `@AnimAgent` sẵn sàng nhận lệnh bắt đầu code ngay lập tức!
