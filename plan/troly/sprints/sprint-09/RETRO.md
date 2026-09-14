# SPRINT 09 RETROSPECTIVE: Standalone 3D Mascot Desktop Pet & GGUF Model Downloader
**Thời gian họp:** 10/01/2027 | **Phiên bản:** `v01.09.00` | **Điều phối:** @PlanAgent

---

## 🌟 1. Điểm Tốt Cốt Lõi (What Went Well)
- **Đột phá trải nghiệm Desktop Pet đích thực:**
  - Loại bỏ hoàn toàn cảm giác một cửa sổ phần mềm cứng nhắc: Chú cún Troly hiển thị tự do không viền hộp, nền trong suốt (`color: transparent`, `frameless`), tự động xuất hiện ở góc dưới bên phải màn hình khi khởi chạy lần đầu.
  - Khả năng kéo thả tự do mọi vị trí trên desktop và ghi nhớ tọa độ `(x, y)` qua `QSettings` mang lại trải nghiệm tiện nghi, thân thiện tuyệt đối.
- **Hoạt cảnh chào hỏi cá nhân hóa & 12 nguyên tắc Disney:**
  - Hoạt cảnh `initialJumpAnim` kết hợp Squash & Stretch, tiếng sủa gâu gâu thân thiện và bong bóng thoại dạng mây nhí nhảnh `"Xin chào {addressing}, chúc một ngày vui! Gâu gâu! 🐾"` lấy trực tiếp từ `UserProfile.addressing`.
- **Tự chủ hoàn toàn trong tải và quản lý mô hình LLM:**
  - `GGUFDownloaderService` sử dụng Native Qt Network (`QNetworkAccessManager`), độc lập 100% không phụ thuộc `curl`/`wget` hệ thống, cập nhật tiến trình % theo thời gian thực và tự động lưu vào `~/.local/share/troly/models/`.
- **Tốc độ thực thi CTest siêu việt:** 8/8 test suites hoàn thành chỉ trong **1.47 giây**, 100% Passed.
- **Đóng gói NixOS Flake hoàn hảo:** Build thành công ra derivation `/nix/store/mx8gs6bp84lnxc776nyjfahs4l8mk5bj-troly-0.1.0`.

---

## 🔍 2. Điểm Cần Cải Thiện & Bài Học Kinh Nghiệm (What Could Be Better)
- **CMake Automoc & Tách tệp Header/Source:**
  - Ban đầu `GGUFDownloaderService` được viết inline hoàn toàn trong file header `.hpp`. Khi test suite `test_gguf_downloader.cpp` được biên dịch thành target riêng biệt, CMake automoc không sinh moc vtable dẫn đến lỗi linker.
  - **Bài học rút ra:** Đối với bất kỳ class nào kế thừa `QObject` có `Q_OBJECT` macro và signals/slots, bắt buộc phải tách riêng file header `.hpp` và implementation `.cpp`, đồng thời đăng ký cả hai vào `SOURCES`/`HEADERS` của `CMakeLists.txt` để đảm bảo tương thích hoàn hảo với CMake MOC và các test executable độc lập.
- **Mở rộng giao thức tải:**
  - Hiện tại mới hỗ trợ giao thức HTTP/HTTPS trực tiếp. Trong các phiên bản tương lai có thể bổ sung kiểm tra mã băm SHA256 để xác thực tính toàn vẹn của tệp mô hình GGUF sau khi tải xong.

---

## 🎯 3. Kế Hoạch Định Hướng Tương Lai (Next Horizon & Future Enhancements)
- [ ] Bổ sung kiểm tra Checksum SHA256 cho tệp mô hình GGUF sau khi hoàn tất tải.
- [ ] Mở rộng cơ chế Multi-Screen / Multi-Monitor detection để hỗ trợ người dùng có nhiều màn hình tự do chọn màn hình hiển thị cún cưng.
- [ ] Tích hợp hỗ trợ thêm các cử chỉ vuốt chạm nâng cao và tương tác voice (STT/TTS Native).
