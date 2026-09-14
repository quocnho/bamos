# Hướng Dẫn Thiết Lập Rules, Skills và Tối Ưu Hóa Token (Google Antigravity IDE)

> 🔄 **Bối Cảnh Dự Án:** Dự án `troly` được tái cấu trúc và phát triển từ `/etc/nixos/pkgs/assistant/`. Quy chuẩn Rules và Skills giúp các AI Agent (`@PlanAgent`, `@RdAgent`, `@DevOptAgent`, `@AnimAgent`) đọc hiểu toàn bộ thông tin từ dự án cũ và chuyển dịch hiệu quả các module Menu, Cửa sổ thiết lập, EyeLeo, WakaTracker sang kiến trúc C++20/Qt6 Native.

Tài liệu này cung cấp hướng dẫn toàn diện về cách định hình hành vi Agent, kiểm soát bối cảnh và tối ưu hóa tài nguyên ngữ cảnh (context window / token) khi phát triển dự án trên Google Antigravity IDE.

---

## 1. Tổng Quan: Antigravity IDE vs. Gemini Gem

Trên giao diện web của Google Gemini, **Gem** gom toàn bộ hướng dẫn, vai trò và kiến thức vào một khối System Prompt cố định duy nhất. Cách tiếp cận này có nhược điểm: khi dự án lớn dần, System Prompt bị phình to, gây tốn token cho mỗi lượt chat và dễ dẫn đến tình trạng AI bị "loãng" hoặc bỏ sót chỉ dẫn quan trọng.

Trong **Google Antigravity IDE**, kiến trúc định hướng Agent được phân tách thành hai tầng độc lập:

1. **Rules (`GEMINI.md` / `AGENTS.md`)**: Thiết lập quy chuẩn nền tảng, phong cách làm việc và bối cảnh toàn cục của dự án. Luôn nạp vào ngữ cảnh mọi phiên làm việc.
2. **Skills (`SKILL.md`)**: Đóng gói các kỹ năng, quy trình nghiệp vụ chuyên biệt. Chỉ được nạp vào ngữ cảnh theo nhu cầu (*on-demand*).

### Bảng so sánh Rules và Skills

| Tiêu chí | Rules (`GEMINI.md` / `AGENTS.md`) | Skills (`SKILL.md`) |
| :--- | :--- | :--- |
| **Bản chất** | Tương đương System Prompt nền tảng. | Gói kỹ năng / quy trình mở rộng. |
| **Cơ chế nạp** | **Static / Always-on**: Nạp vào context ở mọi lượt prompt. | **Dynamic / On-demand**: Chỉ nạp chi tiết khi nhiệm vụ kích hoạt mô tả. |
| **Chi phí Token** | Tiêu tốn một lượng token cố định trên mỗi lượt tương tác. | Tiết kiệm vượt trội; ban đầu chỉ tốn token nhỏ cho metadata. |
| **Mục đích sử dụng** | Định hình vai trò kỹ sư, kiến trúc tổng thể, nguyên tắc cấm kỵ. | Hướng dẫn tác vụ cụ thể (viết test, migration DB, format commit). |
| **Phạm vi quản lý** | Toàn bộ repository / workspace. | Theo từng domain hoặc tác vụ chuyên biệt. |

---

## 2. Hướng Dẫn Thiết Lập Rules (`GEMINI.md`)

### 2.1. Vị trí và nguyên tắc thiết kế
- **Vị trí file:** Đặt trực tiếp tại thư mục gốc của dự án (`./GEMINI.md` hoặc `./AGENTS.md`).
- **Nguyên tắc "Lean Prompt":** Giữ file ngắn gọn, tối ưu trong khoảng **40 – 100 dòng**.
- **Chỉ ghi thông tin bất biến:** Tránh đưa tài liệu API chi tiết hoặc code mẫu dài vào Rules vì chúng sẽ nhân bản chi phí token qua mọi câu lệnh.

### 2.2. Cấu trúc chuẩn của file `GEMINI.md` dự án Troly

```markdown
# Tôn chỉ dự án `troly` & Agent Roles
Dự án Native Edge AI Desktop. Tech stack: C++20, Qt6 (Quick/QML), NixOS, devenv, llama.cpp, SQLite WAL (FTS5 + sqlite-vec).

Hệ sinh thái gồm các vai trò chuyên trách (giao tiếp qua @ hoặc cập nhật trực tiếp tài liệu):
1. `@PlanAgent`: Quản lý cây thư mục `/plan/` và `/docs/` bằng Markdown chuẩn Agile Scrum.
2. `@RdAgent`: Phân tích kiến trúc, POC giải pháp kỹ thuật, đánh giá trade-off (VRAM, CPU, latency).
3. `@DevOptAgent`: Kỹ sư lập trình C++20, quản lý RAII, chạy test, commit chuẩn Git (Why-What-Test).
4. `@AnimAgent`: Chuyên gia Hoạt hình & Game 3D Realtime (12 nguyên tắc Disney, FSM, Scene Graph 60fps).

# Nguyên Tắc Clean Architecture & Tối Ưu Token
- Tuyệt đối tuân thủ chia tách 4 tầng: domain/, usecases/, infrastructure/, presentation/.
- Phân rã cấu trúc hạt nhỏ nhất (Atomic Granularity): mỗi file giữ 1 trách nhiệm độc lập.
- Usecases chỉ chứa Header Interfaces ngắn gọn (~50 tokens).
- Không in lại toàn bộ file nếu chỉ sửa vài dòng; ưu tiên trả về partial diffs.
```

---

## 3. Hướng Dẫn Thiết Lập Skills (`SKILL.md`)

### 3.1. Cơ chế Dynamic Context Injection
Skills giúp giải quyết triệt để bài toán tràn bộ nhớ ngữ cảnh. Khi khởi động, Antigravity IDE chỉ đọc phần `description` trong YAML frontmatter của từng skill (chỉ tốn khoảng 20–40 tokens). Khi người dùng hoặc Agent yêu cầu một tác vụ liên quan, Agent quét thấy mô tả phù hợp và mới tiến hành nạp toàn bộ nội dung của skill đó.

### 3.2. Cấu trúc tổ chức Skills
Trong hệ thống NixOS flake tổng thể, các kỹ năng được quản lý tập trung ở thư mục gốc workspace `/etc/nixos/.agents/skills/` để mọi package con (`pkgs/troly/`, `pkgs/assistant/`, `pkgs/bam/`) và toàn bộ hệ thống NixOS dùng chung tối ưu:
```text
/etc/nixos/
├── .agents/skills/
│   ├── mascot-animation-director/
│   │   └── SKILL.md
│   ├── daily-kickoff/
│   │   └── SKILL.md
│   ├── plan-agent-workflow/
│   │   └── SKILL.md
│   ├── rd-agent-research/
│   │   └── SKILL.md
│   ├── devopt-agent-execute/
│   │   └── SKILL.md
│   ├── build-runner/
│   │   └── SKILL.md
│   ├── db-schema-validator/
│   │   └── SKILL.md
│   ├── dynamic-moe-router/
│   │   └── SKILL.md
│   └── self-evolving-hub/
│       └── SKILL.md
└── pkgs/troly/
```

### 3.3. Mẫu cấu trúc chuẩn của một file `SKILL.md`

```markdown
---
name: build-runner
description: "Biên dịch dự án C++20 Qt6 bằng Nix, Ninja, chạy Live Preview QML và debug Wayland. Kích hoạt khi build dự án, cấu hình cmake, hoặc chạy test."
---

# Mục tiêu
Biên dịch dự án tối ưu với Ninja, xem trước giao diện QML tức thì và kiểm thử an toàn bộ nhớ.

# Các bước thực hiện
1. Preview giao diện QML: `qml6 src/presentation/ui/main.qml`.
2. Biên dịch: `cmake -B build -G Ninja && cmake --build build -j$(nproc)`.
3. Kiểm thử: `ctest --test-dir build --output-on-failure`.
```

---

## 4. Chiến Lược Tối Ưu Hóa Token Toàn Diện (Atomic Granularity)

### 4.1. Sử dụng `.antigravityignore` để chặn dữ liệu rác
Agent trong Antigravity IDE thường dùng công cụ tìm kiếm (`grep`, `glob_search`) để quét dự án. Nếu không chặn, các file nhị phân, thư mục build và assets lớn sẽ bị nạp vào context window gây lãng phí hàng chục nghìn tokens.

File `.antigravityignore` tại thư mục gốc:
```text
build/
build-*/
dist/
bin/
result
.cache/
*.gguf
*.bin
*.pt
*.safetensors
models/
*.db
*.db-wal
*.db-shm
*.log
*.png
*.jpg
```

### 4.2. Kỹ thuật "Skeleton / Interface Stubs"
Thay vì yêu cầu Agent nạp toàn bộ file triển khai dài hàng trăm dòng của một module hạ tầng:
- Tách riêng định nghĩa interface thuần ảo vào các file nhẹ trong `src/usecases/*.hpp` (~50 tokens).
- Khi giao việc cho Agent, chỉ định Agent tham chiếu đến file interface `.hpp` thay vì file `.cpp`.

### 4.3. Quản lý phiên làm việc (Session Reset)
- Mỗi tính năng mới hoặc một phiên debug độc lập: Mở một phiên hội thoại mới.
- Khi hoàn thành một mốc công việc (Task): Chạy commit Git và reset session để loại bỏ ngữ cảnh thừa.

### 4.4. Định dạng phản hồi tối thiểu (Minimal Diff Enforcement)
Agent được cấu hình để chỉ đưa ra khối mã nguồn cần chỉnh sửa hoặc dạng git diff/patch, tuyệt đối không viết lại toàn bộ file nếu không cần thiết.

### 4.5. Phân rã cấu trúc hạt nhỏ nhất (Atomic Granularity)
- **Tách nhỏ theo trách nhiệm:** Mỗi tệp C++/QML chỉ đảm nhiệm một entity, value object, interface hoặc component duy nhất.
- **Dễ tìm kiếm & tra cứu:** Tên thư mục và tên file được chuẩn hóa theo danh từ / động từ rõ ràng, phản ánh chính xác nội dung bên trong.
- **Tiết kiệm token tối đa:** Khi cần sửa đổi một chức năng, AI chỉ nạp đúng một tệp vi mô (vài chục dòng), tiết kiệm tới 80-90% dung lượng Context Window so với các file nguyên khối.
