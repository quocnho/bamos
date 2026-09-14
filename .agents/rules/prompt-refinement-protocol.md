# Quy Trình Tương Tác & Phản Hồi Yêu Cầu (Refine, Reframe & Execution Plan)

Quy chuẩn này là **bắt buộc** đối với AI Agent mỗi khi tiếp nhận yêu cầu từ người dùng (trừ các câu trả lời ngắn mang tính hội thoại thông thường như chào hỏi hoặc xác nhận tức thì).

Mục tiêu: Đảm bảo hiểu đúng 100% bản chất bài toán, bóc tách rành mạch cấu trúc thông tin, đồng thuận giải pháp và kế hoạch thực thi trước khi chạm vào mã nguồn hoặc cấu hình hệ thống.

---

## 1. Cấu Trúc Khung Phản Hồi Chuẩn (4 Trụ Cột)

Trước khi tiến hành thực hiện công việc, AI Agent phải phản hồi và xác nhận lại với người dùng theo bố cục sau:

### 🎯 1. Tái Định Hình Yêu Cầu (Reframe & Scope)
- **Tóm tắt ngắn gọn mục tiêu:** Diễn đạt lại yêu cầu của người dùng bằng ngôn ngữ kỹ thuật chuẩn xác, rõ ràng và cô đọng.
- **Phạm vi tác động (Scope):** Nêu rõ vùng ảnh hưởng (module, package, layer kiến trúc, file cấu hình liên quan).

### 🔍 2. Phân Tích Cấu Trúc Yêu Cầu
- **Ý chính (Core Requirements):** Trọng tâm cốt lõi bắt buộc phải đạt được.
- **Ý phụ (Sub-requirements / Constraints):** Các yêu cầu chi tiết, ràng buộc kỹ thuật (RAII, C++20, NixOS Flake, Clean Architecture, VRAM/RAM, UI/UX, Git Why-What-Test).
- **Ý liên quan (Related Context & Dependencies):** Các thành phần phụ thuộc, tác động gián tiếp, rủi ro tiềm ẩn hoặc các điểm cần lưu ý tương thích ngược.

### 📋 3. Kế Hoạch Thực Hiện (Actionable Execution Plan)
Phân rã thành các bước cụ thể:
1. **Bước 1: Khảo sát & Đánh giá (Research / Inspection):** Xem xét file, trạng thái hiện tại.
2. **Bước 2: Triển khai kỹ thuật (Implementation):** Từng file cần tạo mới/chỉnh sửa, hàm/class cần can thiệp.
3. **Bước 3: Kiểm thử & Nghiệm thu (Verification & Test):** Lệnh build, ctest, `bam dry`/`bam switch`, hoặc kịch bản test thủ công.
4. **Bước 4: Đồng bộ & Bàn giao (Sync & Commit):** Cập nhật docs, backlog/sprint, commit theo chuẩn Why-What-Test.

### ❓ 4. Điểm Cần Làm Rõ / Xác Nhận (Clarifications / Open Questions)
- Nếu có điểm chưa rõ ràng hoặc có nhiều phương án kỹ thuật khác nhau, nêu rõ câu hỏi và phương án đề xuất tối ưu.
- Nếu yêu cầu đã đầy đủ và rõ ràng, xác nhận sẵn sàng bắt tay vào thực thi.

---

## 2. Nguyên Tắc Ứng Xử Kèm Theo
- **Hành văn chuyên nghiệp:** Sử dụng thuật ngữ kỹ thuật chính xác, tone giọng kỹ sư hệ thống/kiến trúc sư phần mềm, mạch lạc, tôn trọng tiêu chuẩn dự án.
- **Không vội vàng hành động ngầm:** Tránh trường hợp sửa code hoặc chạy lệnh làm thay đổi hệ thống trước khi người dùng hiểu rõ phạm vi công việc dự kiến.
