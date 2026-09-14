---
name: self-evolving-hub
description: Quy trình 4 bước thu hoạch dữ liệu chất lượng cao từ SQLite, huấn luyện LoRA cục bộ, merge và lượng hóa GGUF cho mô hình dự án troly. Kích hoạt khi cần tự tiến hóa mô hình, fine-tune LoRA, export hoặc quantize GGUF.
---

# Mục Tiêu
Hiện thực hóa khả năng tự tiến hóa (Self-Evolving) của Edge AI Desktop mà không gửi dữ liệu ra môi trường ngoài (Air-gapped 100%) theo quy chuẩn tại [docs/troly/ARCHITECTURE.md](file:///etc/nixos/docs/troly/ARCHITECTURE.md).

> 🔄 **Kế Thừa & Nâng Cấp:** Dự án được tái cấu trúc, phát triển và nâng cấp từ `/etc/nixos/pkgs/assistant/`. Thu hoạch tương tác vàng từ các phiên hội thoại và thực thi của trợ lý cũ để tinh chỉnh mô hình thích ứng chuyên sâu cho hệ điều hành NixOS.

# Quy Trình 4 Bước Tinh Chỉnh Mô Hình GGUF

### Bước 1: Trích xuất dữ liệu vàng (Dataset Extraction)
- Lọc các bản ghi từ bảng SQLite `training_datasets` có `quality_score >= 1.0` và `is_trained = 0`.
- Format dữ liệu theo chuẩn ChatML template (`<|im_start|>user ... <|im_end|>`) sang file `train_data.txt`.

### Bước 2: Huấn luyện LoRA Cục Bộ (Local LoRA Training)
- Sử dụng công cụ `llama-finetune` (từ nixpkgs / devenv toolchain):
  ```bash
  llama-finetune \
    --model-base ./models/Qwen2.5-3B-Instruct-Q8_0.gguf \
    --train-data ./data/train_data.txt \
    --lora-out ./models/troly-adapter.bin \
    --threads $(nproc) --adam-iter 120 --batch 4 --ctx 2048 --lora-r 16
  ```

### Bước 3: Hợp nhất trọng số (Merge Adapter)
- Sử dụng `llama-export-lora` để merge LoRA adapter vào base model:
  ```bash
  llama-export-lora \
    -m ./models/Qwen2.5-3B-Instruct-Q8_0.gguf \
    -o ./models/troly-merged-f16.gguf \
    --lora ./models/troly-adapter.bin
  ```

### Bước 4: Lượng hóa & Cập nhật Registry (Quantization)
- Lượng hóa về chuẩn `Q4_K_M` để tối ưu VRAM:
  ```bash
  llama-quantize ./models/troly-merged-f16.gguf ./models/troly-v1-q4_k_m.gguf Q4_K_M
  ```
- Cập nhật trạng thái `is_trained = 1` trong `training_datasets` và đăng ký model mới vào cơ sở dữ liệu `models_registry`.
