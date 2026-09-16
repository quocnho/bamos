package chat

import (
	"fmt"
	"strings"
	"unicode/utf8"

	"troly/backend/internal/domain"
	"troly/backend/internal/platform/linux"
	"troly/backend/internal/usecase/profile"
	"troly/backend/internal/usecase/waka"
)

const PuppySystemPrompt = "Bạn là BamOS Assistant - trợ lý AI thông minh, tận tụy và lịch thiệp trên hệ điều hành BamOS (NixOS).\n\n" +
	"Quy tắc phong cách và xưng hô:\n" +
	"- Luôn tuân thủ nghiêm ngặt danh xưng của người dùng và ngôi xưng của trợ lý được quy định trong ngữ cảnh hồ sơ người dùng bên dưới.\n" +
	"- Luôn giữ thái độ nhã nhặn, tôn trọng, hữu ích, dễ hiểu và trả lời súc tích.\n\n" +
	"Quy chuẩn hiển thị nội dung tối ưu cho khung chat (độ rộng ~480px):\n" +
	"1. Cấu trúc rõ ràng, dễ đọc: Chia câu trả lời thành các đoạn ngắn (2-4 dòng), dùng tiêu đề phụ (###) và gạch đầu dòng (-) thay vì các khối văn bản liền mạch dài dòng.\n" +
	"2. Nổi bật thông tin: Dùng **chữ in đậm** cho các khái niệm, từ khóa, tham số hoặc số liệu quan trọng.\n" +
	"3. Code & Lệnh: Mọi câu lệnh, tên file, đường dẫn hoặc biến PHẢI đặt trong code block `lệnh` hoặc khối code ```ngôn_ngữ ... ``` có thụt đầu dòng rõ ràng.\n" +
	"4. Bảng biểu & So sánh: Khi so sánh hoặc liệt kê nhiều thuộc tính, hãy dùng bảng Markdown (| Cột 1 | Cột 2 |) để thông tin gọn gàng và dễ nắm bắt.\n" +
	"5. Danh sách từng bước: Nếu hướng dẫn thao tác, hãy đánh số thứ tự (1., 2., 3.) kèm theo giải thích ngắn gọn mỗi bước."

func AddressingRule(addressing string) string {
	userTitle, botTitle := domain.GetAddressingPronouns(addressing)
	return fmt.Sprintf("\n- XƯNG HÔ THEO HỒ SƠ: Gọi người dùng là \"%s\" và tự xưng là \"%s\". Tuyệt đối tuân thủ cặp đại từ xưng hô này trong toàn bộ câu trả lời, không dùng đại từ khác.", userTitle, botTitle)
}

func TruncateRunes(s string, max int) string {
	runes := []rune(s)
	if len(runes) <= max {
		return s
	}
	return string(runes[:max]) + "…"
}

func TruncateUTF8(s string, maxBytes int) string {
	if len(s) <= maxBytes {
		return s
	}
	cut := maxBytes
	for cut > 0 && !utf8.RuneStart(s[cut]) {
		cut--
	}
	return s[:cut]
}

func EscapeHtmlAttr(s string) string {
	s = strings.ReplaceAll(s, "&", "&amp;")
	s = strings.ReplaceAll(s, "\"", "&quot;")
	s = strings.ReplaceAll(s, "<", "&lt;")
	s = strings.ReplaceAll(s, ">", "&gt;")
	return s
}

func SanitizeHistory(history []domain.ChatMessage, maxEntries int) []domain.ChatMessage {
	if len(history) == 0 {
		return nil
	}
	if maxEntries > 0 && len(history) > maxEntries {
		history = history[len(history)-maxEntries:]
	}
	out := make([]domain.ChatMessage, 0, len(history))
	for _, m := range history {
		if m.Role != "user" && m.Role != "assistant" {
			continue
		}
		content := strings.TrimSpace(m.Content)
		if content == "" {
			continue
		}
		out = append(out, domain.ChatMessage{Role: m.Role, Content: TruncateRunes(content, 4000)})
	}
	return out
}

func BuildSystemPrompt(
	addressing string,
	profUc *profile.ProfileUsecase,
	wakaUc *waka.WakaUsecase,
	activeDir string,
	habitContext string,
	attachedDocContext string,
	webContext string,
	ragContext string,
) string {
	sys := PuppySystemPrompt + AddressingRule(addressing)

	if profUc != nil {
		if ctx := profUc.GetPromptContext(); ctx != "" {
			sys += "\n\n" + ctx
		}
	}
	if wakaUc != nil {
		if ctx := wakaUc.GetSummaryContext(); ctx != "" {
			sys += "\n\n" + ctx
		}
	}
	if hwCtx := linux.GetSystemPromptContext(); hwCtx != "" {
		sys += "\n\n" + hwCtx
	}
	if activeDir != "" {
		sys += fmt.Sprintf("\n\n=== BỐI CẢNH THƯ MỤC HIỆN TẠI (TỪ CỤC XƯƠNG FILE MANAGER) ===\nChủ nhân đang mở và làm việc trong thư mục: `%s`\nMọi yêu cầu thống kê, tìm kiếm, đọc tệp hoặc chạy lệnh của Chủ nhân hãy ưu tiên thực hiện trong thư mục này.\n=============================================================", activeDir)
	}
	if habitContext != "" {
		sys += "\n\n" + habitContext
	}
	if attachedDocContext != "" {
		sys += "\n\n" + attachedDocContext
	}
	if webContext != "" {
		sys += "\n\n" + webContext
	}
	if ragContext != "" {
		sys += "\n\n" + ragContext
	}
	return sys
}
