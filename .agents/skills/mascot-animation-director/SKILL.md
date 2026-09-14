---
name: mascot-animation-director
description: Hướng dẫn tiêu chuẩn chuyên gia cấp cao (Lead 3D & Animation Director) thiết kế nhân vật, biểu cảm, rigging, 12 nguyên tắc hoạt hình Disney, State Machine (FSM), tối ưu render 60fps (Qt6 Scene Graph / Wayland) và lộ trình mở rộng Realtime 3D (glTF / Qt Quick 3D) cho chú cún con Troly.
---

# 🎬 Mascot Animation & 3D Director Skill (`mascot-animation-director`)

Chuyên môn của chuyên gia cấp cao nhiều năm kinh nghiệm trong ngành Hoạt hình Điện ảnh (Feature Animation) và Kỹ thuật Đồ họa Game 3D Realtime (Game Engine Architecture). Định hình linh hồn, tính cách và chuyển động sống động cho chú cún cưng ảo **Troly** trên desktop theo chuẩn kiến trúc tại [docs/ARCHITECTURE.md](file:///etc/nixos/pkgs/troly/docs/ARCHITECTURE.md).

> 🔄 **Kế Thừa & Nâng Cấp:** Dự án được tái cấu trúc, phát triển và nâng cấp từ `/etc/nixos/pkgs/assistant/`. Tận dụng bộ ảnh Mascot Pet và logic tương tác từ `pet.js`, `drag.js` của dự án cũ, nâng cấp lên chuẩn hoạt hình 12 nguyên tắc Disney, máy trạng thái FSM mượt mà và tối ưu hóa Scene Graph 60fps trên Qt6 Native.

---

## 🐶 1. Persona & Thiết Kế Hình Tượng Nhân Vật (Character Design)
- **Tên nhân vật:** Bé Cún Troly (Golden/Corgi puppy hybrid).
- **Tính cách:** Thông minh, trung thành, nhí nhảnh, tò mò, hay nũng nịu nhưng tận tụy bảo vệ hệ thống của chủ nhân.
- **Tỉ lệ nhân vật (Proportions & Appeal):**
  - Đầu to, mắt to tròn biểu cảm (Puppy Eyes), tai cụp hoặc lúc lắc biểu cảm.
  - Thân hình mũm mĩm, 4 chân ngắn thoăn thoắt, chiếc đuôi ngắn bồng bềnh luôn ngoáy tít khi vui mừng.
  - Đường nét mềm mại, silhouette (hình bóng) rõ ràng, dễ nhận diện dù thu nhỏ 64px ở góc màn hình hay phóng to 256px.

---

## 🎞️ 2. Áp Dụng 12 Nguyên Tắc Hoạt Hình Cổ Điển (Disney's 12 Principles) Vào Desktop Mascot

1. **Squash & Stretch (Co giãn khối lượng):**
   - Khi cún tiếp đất sau cú nhảy (`cho nhay.svg`), thân mình ép dẹp xuống (Squash) nhưng bảo toàn thể tích (rộng ra theo chiều ngang).
   - Khi bật nhảy lên đón chuột, thân kéo giãn theo trục tung (Stretch).
2. **Anticipation (Lấy đà):**
   - Trước khi nhảy vồ con trỏ chuột: Nhún 2 chân trước xuống, lắc mông lấy đà trong 4-6 frames rồi mới phóng vút lên.
3. **Staging (Dàn cảnh & Điểm nhìn rõ ràng):**
   - Đảm bảo tư thế rõ ràng (Clear Silhouette) trên mọi nền desktop (sáng/tối).
4. **Follow Through & Overlapping Action (Hành động kế tiếp & Chồng chéo):**
   - Khi cún dừng bước đột ngột, đôi tai mềm và chỏm đuôi vẫn tiếp tục văng về phía trước rồi mới đung đưa hồi vị.
5. **Slow In & Slow Out (Gia tốc Easing):**
   - Không chuyển động tuyến tính (Linear). Mọi tweening đều dùng đường cong Bezier (`Easing.InOutQuad` hoặc `Easing.OutBack` cho cảm giác đàn hồi sống động).
6. **Arcs (Đường cong chuyển động):**
   - Bước chạy, vẫy đuôi, đầu ngước lên theo quỹ đạo vòng cung tự nhiên, tránh chuyển động giật góc nhọn.
7. **Secondary Action (Hành động phụ):**
   - Khi đang đứng canh (`cho dung.svg`), hành động phụ là chớp mắt ngây thơ, tai giật nhẹ khi có tiếng gõ phím.
8. **Timing (Nhịp điệu thời gian):**
   - Đuôi vẫy nhanh khi phát hiện chủ nhân (0.15s/chu kỳ), đuôi phe phẩy chậm khi bình yên (0.8s/chu kỳ).
9. **Exaggeration (Cường điệu hóa):**
   - Khi giật mình ("Núp lùm & Lò đuôi" bị click chuột): 2 mắt mở to trợn tròn, 4 chân bung ra hài hước.
10. **Solid Drawing (Tạo khối vững vàng):**
    - Tư thế 2D SVG hay Model 3D đều giữ đúng giải phẫu khối hộp/khối cầu ba chiều trong không gian.
11. **Appeal (Sức cuốn hút):**
    - Tạo thiện cảm tuyệt đối, mang lại cảm giác xả stress và bình yên cho lập trình viên.

---

## 🕹️ 3. Mô Hình Máy Trạng Thái Hữu Hạn (Mascot Finite State Machine - FSM)

```text
       [Wakeup Click]          [System Idle > 5m]
  +------------------------> IDLE_STAND (cho dung.svg) ------------------------+
  |                                   |  ^                                     |
  |                        [Work Done]|  |[User Types]                         v
SLEEP_DEEP (cho ngu.svg)              v  |                          TIRED_BLINK (EyeLeo Break)
  ^                        HAPPY_JUMP (cho nhay.svg)                           |
  |                                   |                                        |
  +-----------------------------------+----------------------------------------+
                  [Idle > 15m / On-Demand Power Save]
```

### Các trạng thái cốt lõi:
1. **`STATE_GREETING` (`cho chao.svg`):** Khởi động máy, vẫy 2 chân trước chào đón.
2. **`STATE_IDLE_STAND` (`cho dung.svg`):** Đứng bảo vệ, thở nhẹ nhịp nhàng, thỉnh thoảng chớp mắt.
3. **`STATE_INTERACTION_JUMP` (`cho nhay.svg`):** Vui mừng khi người dùng click tương tác hoặc AI hoàn thành tác vụ.
4. **`STATE_DEEP_SLEEP` (`cho ngu.svg`):** Co tròn nằm ngủ khi hệ thống rảnh rỗi hoặc ở chế độ tiết kiệm năng lượng.
5. **`STATE_PEEK_TAIL` (Núp lùm & Lò đuôi):** Trốn ở mép màn hình, chỉ để thò chiếc đuôi vẫy gọi.
6. **`STATE_EYELEO_REMIND`:** Giơ biển nhắc nhở 20-20-20 hoặc dụi mắt đáng yêu.

---

## ⚡ 4. Tối Ưu Hiệu Năng Đồ Họa Realtime (60FPS Wayland / Qt Quick)

- **Vector SVG Caching:**
  - Kích hoạt `sourceSize: Qt.size(w, h)` trên QML `Image` để Qt rasterize SVG ở độ phân giải thực tế màn hình (tránh render lại vector mỗi frame).
  - Tận dụng `QQuickPaintedItem` hoặc Scene Graph texture atlas.
- **Translucent Window Performance:**
  - Sử dụng Native Wayland sub-surfaces (`Qt.FramelessWindowHint`, `Qt.WA_TranslucentBackground`).
  - Hạn chế repaint toàn bộ canvas: Chỉ cập nhật bounding rect của Mascot.
- **Frame Budget:** 
  - Render loop giới hạn < 16.6ms/frame (60fps). 
  - Trạng thái ngủ (`cho ngu.svg`): Giảm tốc độ cập nhật xuống 1-2fps hoặc ngắt timer hoàn toàn để CPU tiêu thụ 0.0%.

---

## 🔮 5. Lộ Trình Tiến Hóa Đồ Họa 3D (Realtime 3D Game Pipeline)

Khi chuyển giao từ 2D SVG sang 3D Realtime Desktop Companion:
1. **Model Pipeline:** 
   - Low-poly mesh cách điệu (Stylized Low-poly ~5k-10k polygons).
   - Định dạng chuẩn: `glTF 2.0 / GLB` (PBR textures, embedded animations).
2. **Rigging & Skinning:**
   - Hệ xương Bone/Joint tinh gọn: Spine (3 đốt), 4 Legs (IK/FK), Tail (4 bones lò xo Spring Bone), Ears (Dynamic Jiggle), Facial blendshapes.
3. **Runtime Engine:**
   - Sử dụng **Qt Quick 3D** (tích hợp trực tiếp C++20 / QML Scene Graph) hoặc nhúng renderer Vulkan native siêu nhẹ.
4. **Shader & Lighting:**
   - Phong cách Toon Shading (Cel Shading) với Rim Light viền sáng nhẹ, bảo đảm phong cách Anime/Cartoon dễ thương đồng bộ với thiết kế 2D ban đầu.
