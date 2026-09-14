---
name: dynamic-moe-router
description: Phân tích ý định (Intent Classification <30ms) và điều phối nạp động các mô hình chuyên biệt (Text, Code, Vision) trong dự án troly. Kích hoạt khi thiết kế hoặc cấu trúc router, intent classifier, hoặc quản lý nạp/hủy mô hình GGUF.
---

# Mục Tiêu
Đảm bảo định tuyến prompt chính xác vào đúng model chuyên trách (Text, Code, Vision) với độ trễ <30ms và quản lý nạp động (Dynamic Loading) để tối ưu VRAM (<6GB) trên môi trường Edge theo đặc tả tại [docs/troly/ARCHITECTURE.md](file:///etc/nixos/docs/troly/ARCHITECTURE.md).

> 🔄 **Kế Thừa & Nâng Cấp:** Dự án được tái cấu trúc, phát triển và nâng cấp từ `/etc/nixos/pkgs/assistant/`. Nâng cấp cơ chế quản lý model từ `settings.go` và `llm-settings.js` của dự án cũ (danh sách GGUF, chọn provider, tải model) thành Dynamic MoE Router C++ tự động phân loại intent.

# Phân Loại Mô Hình & Vai Trò
1. **General / Reasoning (Mặc định):** Qwen2.5-3B-Instruct (hoặc 7B nếu RAM/VRAM cho phép). Phục vụ hội thoại, tóm tắt, trích xuất thực thể.
2. **Coding / Bash Execution:** Qwen2.5-Coder-3B/7B. Phục vụ sinh mã C++, script Nix/Bash, kiểm thử.
3. **Vision / OCR:** MiniCPM-V hoặc Moondream GGUF (nếu có tác vụ phân tích ảnh).

# Quy Chuẩn Kiến Trúc C++20 & RAII
- **Interface Segregation:** `src/usecases/IModelRouter.hpp`
- **Thực thi Module:** `src/infrastructure/llama/DynamicMoERouter.cpp`
- **RAII Model Lifecycle:**
  - Giữ tối đa 1 model lớn trong VRAM tại một thời điểm nếu VRAM < 6GB.
  - Sử dụng `std::unique_ptr<llama_model, decltype(&llama_free_model)>` với custom deleter.
  - Ngắt context đang chạy bằng `std::stop_token` khi nhận diện ý định mới đòi hỏi switch model.
