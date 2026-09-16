package gui

import (
	"encoding/json"
	"fmt"
)

// PushJSON gọi callback JS kèm dữ liệu JSON (đã escape an toàn).
func PushJSON(callback string, payload any) {
	data, err := json.Marshal(payload)
	if err != nil {
		fmt.Printf("[BamAI GUI] Lỗi marshal %s: %v\n", callback, err)
		return
	}
	EvalJS(fmt.Sprintf("window.%s && window.%s(%s);", callback, callback, string(data)))
}

// PushSuccessJSON tiện ích trả kết quả thành công kèm thông điệp
func PushSuccessJSON(callback, message string) {
	PushJSON(callback, map[string]any{"ok": true, "message": message})
}

// PushErrorJSON tiện ích trả kết quả lỗi
func PushErrorJSON(callback, message string) {
	PushJSON(callback, map[string]any{"ok": false, "message": message})
}
