# SPRINT 05 RETROSPECTIVE: Action Dispatcher, Safety Guard & ReAct Loop
**Thời gian:** 11/11/2026 | **Phiên bản:** `v01.05.00` | **Điều phối:** @PlanAgent

---

## 🌟 1. Điểm Tốt (What Went Well)
- **Rào chắn an toàn kiên cố (Zero Unintended Destructions):** Ngăn chặn 100% các lệnh phá hủy nguy hiểm thông qua blacklist regex chuẩn xác mà không cần đợi AI phản hồi.
- **Minh bạch hóa dòng lệnh (Human-in-the-loop UX):** `SafetyConfirmationModal.qml` hiển thị đầy đủ ngữ cảnh lệnh sắp chạy, lý do rủi ro và nút từ chối/chấp thuận rõ ràng.
- **Tiến trình đa luồng mượt mà:** Luồng `QProcess` và worker thread `std::thread` không làm đơ giao diện Qt Quick, các token/chunk được bắn về QML qua `QMetaObject::invokeMethod` an toàn luồng.

---

## 🛑 2. Khó Khăn & Vấn Đề Gặp Phải (What Went Wrong / Blockers)
- **Đường dẫn môi trường NixOS:** Tiến trình con cần nạp đủ biến môi trường hệ thống (`QProcessEnvironment::systemEnvironment()`) để có thể tìm thấy các lệnh nằm trong `/run/current-system/sw/bin` hoặc nix profile của người dùng.
- **Xử lý Timeout & Stop Signal:** Khi người dùng hủy lệnh giữa chừng, cần gửi tín hiệu ngắt `SIGTERM` và chờ một khoảng grace period trước khi ép hủy `kill()`.

---

## 💡 3. Bài Học & Hành Động Cải Tiến (Action Items for Sprint 06)
1. **Mở rộng năng lực chẩn đoán hệ thống (Sprint 06):** Kết hợp `LinuxActionDispatcher` để đọc tự động `journalctl` và `systemctl --failed` phục vụ `SystemInspectorModal`.
2. **Theo dõi nhịp độ lập trình WakaTracker:** Tích hợp bộ đọc log hoạt động lập trình để hiển thị dashboard năng suất trong Sprint 06.
3. **Tiếp tục duy trì kỷ luật Why-What-Test:** Đảm bảo tất cả tính năng mới luôn có CTest tự động đi kèm.
