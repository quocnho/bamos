package chat

import (
	"context"
	"fmt"
	"strings"

	"troly/backend/internal/platform/linux"
)

func (u *ChatUsecase) handleDirectIntents(
	ctx context.Context,
	trimmed, lower string,
	userTitle, botTitle string,
	activeDir string,
	onChunk func(string),
	onDone func(),
	onError func(string),
) (handled bool, attachedDoc string, revisedQuestion string) {
	// 1. Nhận diện ý định HỒ SƠ & DANH TÍNH
	if (strings.Contains(lower, "tôi tên gì") || strings.Contains(lower, "tôi là ai") || strings.Contains(lower, "hồ sơ của tôi") || strings.Contains(lower, "thông tin của tôi")) && u.profileUc != nil {
		p := u.profileUc.GetProfile()
		var sb strings.Builder
		sb.WriteString(fmt.Sprintf("🐶 <b>%s chào %s %s ạ! %s luôn ghi nhớ rõ ràng thông tin hồ sơ của %s:</b>\n\n", botTitle, userTitle, p.FullName, botTitle, userTitle))
		sb.WriteString(fmt.Sprintf("👤 <b>Họ và tên:</b> %s\n", p.FullName))
		if p.Age > 0 {
			sb.WriteString(fmt.Sprintf("🎂 <b>Tuổi:</b> %d\n", p.Age))
		}
		if p.Email != "" {
			sb.WriteString(fmt.Sprintf("📧 <b>Email:</b> %s\n", p.Email))
		}
		if p.Phone != "" {
			sb.WriteString(fmt.Sprintf("📱 <b>Số điện thoại:</b> %s\n", p.Phone))
		}
		sb.WriteString(fmt.Sprintf("🤝 <b>Cách xưng hô:</b> Gọi %s là \"%s\", %s tự xưng là \"%s\"\n", userTitle, userTitle, botTitle, botTitle))
		if p.CurrentLevel != "" {
			sb.WriteString(fmt.Sprintf("⭐ <b>Trình độ chuyên môn:</b> %s\n", p.CurrentLevel))
		}
		if len(p.Domains) > 0 {
			sb.WriteString(fmt.Sprintf("🎯 <b>Lĩnh vực quan tâm:</b> %s\n", strings.Join(p.Domains, ", ")))
		}
		onChunk(sb.String())
		onDone()
		return true, "", ""
	}

	// 2. Nhận diện ý định THÔNG TIN HỆ THỐNG
	if strings.Contains(lower, "thông tin hệ thống") || strings.Contains(lower, "cấu hình máy") || strings.Contains(lower, "phần cứng") {
		sys := linux.GetHardwareAndSystemInfo()
		var sb strings.Builder
		sb.WriteString(fmt.Sprintf("🐶 <b>%s gửi %s thông tin hệ thống và phần cứng máy tính ạ:</b>\n\n", botTitle, userTitle))
		sb.WriteString(fmt.Sprintf("💻 <b>Hệ điều hành:</b> %s (Kernel: `%s`)\n", sys.OS, sys.Kernel))
		sb.WriteString(fmt.Sprintf("⚡ <b>CPU:</b> %s (%d nhân)\n", sys.CPU, sys.Cores))
		sb.WriteString(fmt.Sprintf("🧠 <b>RAM:</b> %s / %s\n", sys.MemoryUsed, sys.MemoryTotal))
		sb.WriteString(fmt.Sprintf("💾 <b>Ổ đĩa:</b> %s\n", sys.DiskUsage))
		onChunk(sb.String())
		onDone()
		return true, "", ""
	}

	// 3. Nhận diện ý định THỰC THI LỆNH CLI
	isCliCommand := false
	cmdStr := ""
	if strings.HasPrefix(lower, "bam ") || lower == "bam" {
		isCliCommand = true
		cmdStr = trimmed
	} else {
		for _, prefix := range []string{"chạy lệnh ", "thực thi lệnh ", "run ", "lệnh ", "$ "} {
			if strings.HasPrefix(lower, prefix) {
				isCliCommand = true
				cmdStr = strings.TrimSpace(trimmed[len(prefix):])
				break
			}
		}
	}
	if isCliCommand && cmdStr != "" {
		cmdStr = strings.Trim(cmdStr, "`\"' ")
		onChunk(fmt.Sprintf("🐶 <b>%s đang thực thi lệnh Bam CLI:</b> ` %s `\n\n", botTitle, cmdStr))
		onChunk(fmt.Sprintf("<terminal cmd=\"%s\">\n", EscapeHtmlAttr(cmdStr)))
		res := u.cliEngine.ExecuteCommandStream(ctx, cmdStr, activeDir, true, func(line string) {
			onChunk(line + "\n")
		})
		onChunk("</terminal>\n\n")
		var sb strings.Builder
		if res.ExitCode == 0 {
			sb.WriteString(fmt.Sprintf("✅ <b>Lệnh hoàn tất thành công</b> (thời gian: <code>%s</code>).\n", res.Duration))
		} else {
			sb.WriteString(fmt.Sprintf("⚠️ <b>Lệnh kết thúc với mã thoát: %d</b> (thời gian: <code>%s</code>).\n", res.ExitCode, res.Duration))
		}
		onChunk(sb.String())
		onDone()
		return true, "", ""
	}

	// 4. Tìm kiếm / Đọc tệp
	if strings.HasPrefix(lower, "tìm file ") || strings.HasPrefix(lower, "tìm tệp ") {
		query := strings.TrimSpace(trimmed[len("tìm file "):])
		files := u.toolRepo.FindFiles(query, 10)
		if len(files) == 0 {
			onChunk(fmt.Sprintf("Gâu gâu! Em không tìm thấy tệp nào khớp với từ khóa \"%s\" ạ. 🐾", query))
		} else {
			var sb strings.Builder
			sb.WriteString(fmt.Sprintf("Gâu gâu! Em tìm thấy %d tệp tin liên quan:\n\n", len(files)))
			for i, f := range files {
				sb.WriteString(fmt.Sprintf("%d. 📄 `%s`\n", i+1, f))
			}
			onChunk(sb.String())
		}
		onDone()
		return true, "", ""
	}

	if strings.HasPrefix(lower, "đọc file ") || strings.HasPrefix(lower, "xem file ") {
		filePath := strings.TrimSpace(trimmed[len("đọc file "):])
		filePath = strings.Trim(filePath, "`\"' ")
		content, err := u.toolRepo.ReadDocument(filePath)
		if err != nil {
			onError(fmt.Sprintf("Không thể đọc file: %v", err))
			return true, "", ""
		}
		if u.memRepo != nil {
			u.memRepo.RecordFileAccess(filePath)
		}
		attachedDoc = fmt.Sprintf("=== NỘI DUNG TỆP TIN: %s ===\n%s\n=================================\n", filePath, content)
		revisedQuestion = fmt.Sprintf("Hãy tóm tắt và phân tích ngắn gọn nội dung của tệp tin `%s` trên.", filePath)
		return false, attachedDoc, revisedQuestion
	}

	return false, "", ""
}
