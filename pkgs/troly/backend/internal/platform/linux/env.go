package linux

import (
	"fmt"
	"os"
)

// PreferX11Backend chọn GDK_BACKEND=x11 khi có XWayland.
func PreferX11Backend() {
	if override := os.Getenv("BAMAI_GDK_BACKEND"); override != "" {
		_ = os.Setenv("GDK_BACKEND", override)
		fmt.Printf("[BamAI GUI] GDK_BACKEND=%s (theo BAMAI_GDK_BACKEND)\n", override)
		return
	}
	if current := os.Getenv("GDK_BACKEND"); current != "" {
		fmt.Printf("[BamAI GUI] GDK_BACKEND=%s (đã đặt sẵn)\n", current)
		return
	}
	if os.Getenv("DISPLAY") != "" {
		_ = os.Setenv("GDK_BACKEND", "x11")
		fmt.Println("[BamAI GUI] GDK_BACKEND=x11 (XWayland) — bật ghim cửa sổ & nhớ vị trí")
		return
	}
	fmt.Println("[BamAI GUI] Không có DISPLAY — dùng backend mặc định của GTK (Wayland)")
}

// PreferStableWebKitRendering tắt đường dựng hình tăng tốc / DMA-BUF của WebKitGTK.
func PreferStableWebKitRendering() {
	for _, kv := range [][2]string{
		{"WEBKIT_DISABLE_DMABUF_RENDERER", "1"},
		{"WEBKIT_DISABLE_COMPOSITING_MODE", "1"},
	} {
		if os.Getenv(kv[0]) == "" {
			_ = os.Setenv(kv[0], kv[1])
			fmt.Printf("[BamAI GUI] %s=%s (tránh cửa sổ đen trên XWayland/NVIDIA)\n", kv[0], kv[1])
		}
	}
}
