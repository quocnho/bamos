# SPRINT 04 RETROSPECTIVE: Local Inference & Dynamic MoE Router
**Thời gian:** 28/10/2026 | **Phiên bản:** `v01.04.00` | **Điều phối:** @PlanAgent

---

## 🌟 1. Điểm Tốt (What Went Well)
- **Tách bạch kiến trúc MoE & Clean Architecture:** `IIntentClassifier` và `DynamicMoERouter` được trừu tượng hóa rõ ràng trong Domain và UseCases, cho phép chuyển đổi từ Heuristic sang Machine Learning / Embedding Matching mà không ảnh hưởng tới Presentation layer.
- **Tích hợp liền mạch với Sprint 03:** Cơ chế ghép bối cảnh RAG (`searchHybrid`) vào `ChatViewModel` hoạt động trơn tru, giúp cún cưng có thể vừa trả lời tự nhiên vừa tham chiếu tri thức tài liệu có sẵn.
- **Hiệu năng kiểm thử cực nhanh:** Bộ kiểm thử `InferenceTests` chạy tự động mô phỏng SSE streaming và hoàn thành trong chưa đầy 1 giây, giữ chu kỳ CI/CD gọn nhẹ.

---

## 🛑 2. Khó Khăn & Vấn Đề Gặp Phải (What Went Wrong / Blockers)
- **Xung đột từ khóa Qt MOC (`slots`):** Qt định nghĩa macro tiền xử lý `slots` cho signal/slot mechanism. Việc đặt tên biến `auto& slots = ...` trong hàm C++ của một class kế thừa `QObject` (`LLMViewModel`) gây ra lỗi cú pháp biên dịch g++. Cần quy chuẩn đặt tên rõ ràng như `modelSlots` để tránh các từ khóa macro của Qt.
- **Timing trong Async Unit Test:** Khi kiểm thử luồng streaming bất đồng bộ, dùng fixed sleep (`500ms`) có thể gây flaky test nếu CPU bận. Đã cải tiến thành vòng lặp thăm dò (polling loop with timeout) để kiểm tra cờ `completed` an toàn và dứt điểm.

---

## 💡 3. Bài Học & Hành Động Cải Tiến (Action Items for Sprint 05)
1. **Né tránh từ khóa Qt:** Tuyệt đối không đặt tên biến hoặc tham số trùng với `signals`, `slots`, `emit`.
2. **Chuẩn bị cho ReAct Loop (Sprint 05):** Thiết kế `SafetyGuard` để kiểm soát các lệnh shell nguy hiểm (`rm`, `sudo`, `dd`) trước khi chuyển cho `LinuxActionDispatcher` thực thi.
3. **Duy trì nhịp Why-What-Test:** Tiếp tục áp dụng đầy đủ quy chuẩn Git Commit 3 khối và cập nhật nhật ký Daily Scrum.
