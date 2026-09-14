---
name: rd-agent-research
description: Nghiên cứu, đánh giá giải pháp kỹ thuật sâu (POC, Trade-off, VRAM, latency) cho dự án troly trước khi code. Kích hoạt khi cần phân tích giải pháp mới, thuật toán RAG, tích hợp llama.cpp, hoặc MoE router.
---

# Mục Tiêu
Đảm bảo mọi quyết định kỹ thuật đều có phân tích trade-off rõ ràng, tối ưu VRAM/CPU và phù hợp với môi trường NixOS edge desktop theo chuẩn kiến trúc tại [docs/troly/ARCHITECTURE.md](file:///etc/nixos/docs/troly/ARCHITECTURE.md).

> 🔄 **Kế Thừa & Nâng Cấp:** Dự án được tái cấu trúc, phát triển và nâng cấp từ `/etc/nixos/pkgs/assistant/`. Nghiên cứu lại toàn bộ kiến trúc và module của dự án cũ để tái hiện và tối ưu hóa trên C++20/Qt6: Menu tùy chọn, các panel thiết lập, thuật toán EyeLeo (nhắc nghỉ và theo dõi idle Mutter).

# Quy Chuẩn Phân Tích
1. **Bối cảnh & Vấn đề**: Nêu rõ bài toán cần giải quyết (ví dụ: latency của Hybrid Search, VRAM khi chạy llama.cpp song song, hoán đổi mô hình MoE Router <30ms).
2. **Các phương án khả thi**: Tối thiểu 2 phương án so sánh.
3. **Ma trận Trade-off**:
   - Tiêu thụ RAM/VRAM (<6GB cho môi trường Edge)
   - Độ trễ phản hồi (Latency <30ms cho Router, 60fps cho UI)
   - Độ phức tạp mã nguồn (Code complexity) & Dependencies (tuân thủ Pure C++ Domain)
   - Khả năng tương thích trên NixOS và Wayland Compositor
4. **Khuyến nghị & POC**: Đưa ra kết luận và cấu trúc interface header `.hpp` đề xuất cho `@DevOptAgent`.
5. **Đồng bộ tài liệu**: Thông báo `@PlanAgent` cập nhật kết quả vào [docs/troly/ARCHITECTURE.md](file:///etc/nixos/docs/troly/ARCHITECTURE.md).
