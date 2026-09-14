package main

import (
	"bufio"
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"regexp"
	"strings"
	"sync"
	"time"
	"unicode/utf8"
)

type AIService struct {
	cfg       Config
	rag       *RAGManager
	fs        *FSTool
	mem       *UserMemory
	cli       *CLIEngine
	inspector *SystemInspector
	waka      *WakaTracker
	profile   *UserProfileManager

	// Chống khởi động trùng llama-server khi nhiều yêu cầu dồn tới.
	startMu  sync.Mutex
	starting bool
}

func NewAIService(cfg Config, rag *RAGManager, fsTool *FSTool, mem *UserMemory, inspector *SystemInspector, waka *WakaTracker, profile *UserProfileManager) *AIService {
	cliEngine := NewCLIEngine(mem)
	return &AIService{
		cfg:       cfg,
		rag:       rag,
		fs:        fsTool,
		mem:       mem,
		cli:       cliEngine,
		inspector: inspector,
		waka:      waka,
		profile:   profile,
	}
}

type ChatMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type ChatCompletionReq struct {
	Model       string        `json:"model"`
	Messages    []ChatMessage `json:"messages"`
	Temperature float32       `json:"temperature"`
	Stream      bool          `json:"stream"`
}

type StreamDelta struct {
	Content string `json:"content"`
}

type StreamChoice struct {
	Delta StreamDelta `json:"delta"`
}

type StreamChunk struct {
	Choices []StreamChoice `json:"choices"`
}

// Biểu thức chính quy dùng chung: biên dịch một lần thay vì mỗi lần gọi.
var (
	webURLRegex   = regexp.MustCompile(`https?://[^\s<>"]+`)
	htmlScriptRe  = regexp.MustCompile(`(?is)<script.*?</script>`)
	htmlStyleRe   = regexp.MustCompile(`(?is)<style.*?</style>`)
	htmlCommentRe = regexp.MustCompile(`(?is)<!--.*?-->`)
	htmlTagRe     = regexp.MustCompile(`<[^>]+>`)
	spaceRunRe    = regexp.MustCompile(`\s{2,}`)
)

// maxWebContextBytes giới hạn lượng nội dung trang web đưa vào ngữ cảnh model.
const maxWebContextBytes = 4000

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

func (s *AIService) AskStream(ctx context.Context, question string, useRAG bool, history []ChatMessage, onChunk func(string), onDone func(), onError func(string)) {
	trimmed := strings.TrimSpace(question)
	lower := strings.ToLower(trimmed)

	// Lấy danh xưng người dùng và ngôi xưng của trợ lý từ hồ sơ cá nhân (fallback sang cấu hình nếu chưa có)
	userAddr := s.cfg.Addressing
	if s.profile != nil && s.profile.Profile.Addressing != "" {
		userAddr = s.profile.Profile.Addressing
	}
	userTitle, botTitle := GetAddressingPronouns(userAddr)

	// Ghi nhận truy vấn vào bộ nhớ thói quen
	if s.mem != nil {
		s.mem.RecordQuery(question)
	}

	// Lấy thư mục bối cảnh hiện tại (nếu có Cục Xương)
	activeDir := ""
	if s.mem != nil {
		activeDir = s.mem.GetActiveDirectory()
	}

	// 0. Nhận diện ý định HỒ SƠ & DANH TÍNH CÁ NHÂN ("tôi tên gì", "tôi là ai", "hồ sơ của tôi", ...)
	isIdentityQuery := strings.Contains(lower, "tôi tên gì") ||
		strings.Contains(lower, "tên tôi là gì") ||
		strings.Contains(lower, "tên của tôi là gì") ||
		strings.Contains(lower, "tôi tên là gì") ||
		strings.Contains(lower, "tên tôi") ||
		strings.Contains(lower, "tôi là ai") ||
		strings.Contains(lower, "hồ sơ của tôi") ||
		strings.Contains(lower, "thông tin cá nhân") ||
		strings.Contains(lower, "thông tin của tôi") ||
		strings.Contains(lower, "tôi bao nhiêu tuổi") ||
		strings.Contains(lower, "email của tôi") ||
		strings.Contains(lower, "số điện thoại của tôi") ||
		strings.Contains(lower, "trình độ của tôi") ||
		strings.Contains(lower, "lộ trình của tôi")

	if isIdentityQuery && s.profile != nil {
		p := s.profile.Profile
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
			sb.WriteString(fmt.Sprintf("⭐ <b>Trình độ chuyên môn:</b> %s", p.CurrentLevel))
			if p.TotalQuiz > 0 {
				sb.WriteString(fmt.Sprintf(" (Đạt %d/%d điểm kiểm tra)", p.QuizScore, p.TotalQuiz))
			}
			sb.WriteString("\n")
		}
		if len(p.Domains) > 0 {
			sb.WriteString(fmt.Sprintf("🎯 <b>3 lĩnh vực quan tâm:</b> %s\n", strings.Join(p.Domains, ", ")))
		}
		if len(p.RoadmapSteps) > 0 {
			sb.WriteString("\n🗺️ <b>Lộ trình nâng cao kiến thức:</b>\n")
			for _, step := range p.RoadmapSteps {
				icon := "⏳"
				if step.Completed {
					icon = "✅"
				}
				sb.WriteString(fmt.Sprintf("- %s <b>%s</b> (%s): %s\n", icon, step.Title, step.Domain, step.Description))
			}
		}
		sb.WriteString(fmt.Sprintf("\n%s đã nạp toàn bộ thông tin này vào cơ sở tri thức RAG để luôn đồng hành và hỗ trợ %s tốt nhất ạ! 🐾", botTitle, userTitle))
		onChunk(sb.String())
		onDone()
		return
	}

	// 0.1 Nhận diện ý định WAKATIME & THỜI GIAN LÀM VIỆC / LỜI NHẮC VIỆC
	if (strings.Contains(lower, "wakatime") || strings.Contains(lower, "thời gian làm việc") || strings.Contains(lower, "năng suất làm việc") || strings.Contains(lower, "hôm nay làm được bao lâu") || strings.Contains(lower, "lời nhắc việc") || strings.Contains(lower, "nhắc việc") || strings.Contains(lower, "việc cần làm")) && s.waka != nil {
		sum := s.waka.GetSummary()
		var sb strings.Builder
		sb.WriteString(fmt.Sprintf("🐶 <b>%s gửi %s báo cáo năng suất WakaTime và công việc ạ:</b>\n\n", botTitle, userTitle))
		sb.WriteString(fmt.Sprintf("⏱️ <b>Thời gian làm việc hôm nay:</b> %s (khoảng %d phút)\n", sum["today_hours_text"], sum["today_total_minutes"]))
		sb.WriteString(fmt.Sprintf("📅 <b>Tổng 7 ngày qua:</b> %s\n", sum["seven_days_hours"]))

		if apps, ok := sum["today_apps"].(map[string]int); ok && len(apps) > 0 {
			sb.WriteString("\n💻 <b>Ứng dụng làm việc nhiều nhất hôm nay:</b>\n")
			for app, sec := range apps {
				if sec >= 60 {
					sb.WriteString(fmt.Sprintf("- <b>%s</b>: %d phút\n", app, sec/60))
				}
			}
		}

		s.waka.mu.RLock()
		rems := s.waka.data.Reminders
		s.waka.mu.RUnlock()

		pendingCount := 0
		for _, r := range rems {
			if !r.Completed {
				pendingCount++
			}
		}

		if pendingCount > 0 {
			sb.WriteString(fmt.Sprintf("\n📝 <b>%s có %d lời nhắc việc chưa hoàn thành:</b>\n", userTitle, pendingCount))
			for _, r := range rems {
				if !r.Completed {
					due := ""
					if r.DueTime != "" {
						due = fmt.Sprintf(" (Hạn: %s)", r.DueTime)
					}
					sb.WriteString(fmt.Sprintf("- 📌 %s%s\n", r.Title, due))
				}
			}
		} else {
			sb.WriteString(fmt.Sprintf("\n✨ %s không còn lời nhắc việc nào tồn đọng. Thật tuyệt vời ạ!\n", userTitle))
		}

		onChunk(sb.String())
		onDone()
		return
	}

	// 0.2 Nhận diện ý định THÔNG TIN HỆ THỐNG & PHẦN CỨNG
	if strings.Contains(lower, "thông tin hệ thống") || strings.Contains(lower, "thông tin máy") || strings.Contains(lower, "cấu hình máy") || strings.Contains(lower, "phần cứng") || strings.Contains(lower, "kiểm tra phần cứng") {
		sys := GetHardwareAndSystemInfo()
		var sb strings.Builder
		sb.WriteString(fmt.Sprintf("🐶 <b>%s gửi %s thông tin hệ thống và phần cứng máy tính ạ:</b>\n\n", botTitle, userTitle))
		sb.WriteString(fmt.Sprintf("💻 <b>Hệ điều hành:</b> %s (Kernel: `%s`)\n", sys.OS, sys.Kernel))
		sb.WriteString(fmt.Sprintf("🏷️ <b>Tên máy:</b> `%s`\n", sys.HostName))
		sb.WriteString(fmt.Sprintf("⚡ <b>Bộ vi xử lý (CPU):</b> %s (%d nhân)\n", sys.CPU, sys.Cores))
		sb.WriteString(fmt.Sprintf("🎮 <b>Đồ họa (GPU):</b> %s\n", sys.GPU))
		sb.WriteString(fmt.Sprintf("🧠 <b>Bộ nhớ RAM:</b> Đang dùng %s / Tổng %s\n", sys.MemoryUsed, sys.MemoryTotal))
		sb.WriteString(fmt.Sprintf("💾 <b>Ổ đĩa gốc (/):</b> %s\n\n", sys.DiskUsage))
		sb.WriteString(fmt.Sprintf("%s có muốn %s tối ưu hoặc dọn dẹp hệ thống không ạ?", userTitle, botTitle))
		onChunk(sb.String())
		onDone()
		return
	}

	// 0.1 Nhận diện ý định KIỂM TRA ỨNG DỤNG ĐANG CHẠY
	if strings.Contains(lower, "đang chạy ứng dụng") || strings.Contains(lower, "ứng dụng đang mở") || strings.Contains(lower, "ứng dụng nào đang chạy") || strings.Contains(lower, "tiến trình đang chạy") || strings.Contains(lower, "process") {
		apps := GetRunningApps()
		var sb strings.Builder
		sb.WriteString(fmt.Sprintf("🐶 <b>%s tìm thấy %d tiến trình nổi bật đang hoạt động trên hệ thống:</b>\n\n", botTitle, len(apps)))
		for i, app := range apps {
			sb.WriteString(fmt.Sprintf("%d. <b>%s</b> (PID: ` %s `) — CPU: ` %s ` • RAM: ` %s `\n", i+1, app.Name, app.PID, app.CPU, app.Memory))
		}
		sb.WriteString(fmt.Sprintf("\n%s có muốn %s tối ưu hóa tiến trình nào không ạ?", userTitle, botTitle))
		onChunk(sb.String())
		onDone()
		return
	}

	// 0.2 Nhận diện ý định THỰC THI LỆNH CLI (Bao gồm Bam CLI và lệnh hệ thống)
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

		// Gửi marker bắt đầu terminal để frontend hiển thị terminal window live
		onChunk(fmt.Sprintf("<terminal cmd=\"%s\">\n", escapeHtmlAttr(cmdStr)))

		res := s.cli.ExecuteCommandStream(ctx, cmdStr, activeDir, true, func(line string) {
			onChunk(line + "\n")
		})

		onChunk("</terminal>\n\n")

		var sb strings.Builder
		if res.ExitCode == 0 {
			sb.WriteString(fmt.Sprintf("✅ <b>Lệnh hoàn tất thành công</b> (thời gian: <code>%s</code>).\n", res.Duration))
		} else {
			sb.WriteString(fmt.Sprintf("⚠️ <b>Lệnh kết thúc với mã thoát: %d</b> (thời gian: <code>%s</code>).\n", res.ExitCode, res.Duration))
		}

		if res.Learned {
			sb.WriteString(fmt.Sprintf("🧠 <i>%s đã tự học và ghi nhớ lệnh này vào sổ tay tri thức của %s rồi ạ!</i>\n", botTitle, userTitle))
		}

		onChunk(sb.String())
		onDone()
		return
	}

	// 0.3 Nhận diện ý định DUYỆT TRANG WEB KHI CÓ LINK (Web Browsing)
	foundUrls := webURLRegex.FindAllString(trimmed, -1)
	var webContext string

	if len(foundUrls) > 0 {
		targetUrl := foundUrls[0]
		onChunk(fmt.Sprintf("🌐 <i>Em đang truy cập và đọc nội dung trang web:</i> <a href=\"%s\" target=\"_blank\">%s</a>...\n\n", targetUrl, targetUrl))

		webBody, err := fetchWebContent(ctx, targetUrl)
		if err == nil && webBody != "" {
			webContext = fmt.Sprintf("=== NỘI DUNG TẢI VỀ TỪ TRANG WEB: %s ===\n%s\n==============================================\n", targetUrl, webBody)
			// Rút ngắn câu hỏi hoặc hướng dẫn tóm tắt
			if strings.TrimSpace(strings.ReplaceAll(trimmed, targetUrl, "")) == "" {
				question = fmt.Sprintf("Hãy tóm tắt và phân tích các nội dung nổi bật nhất của trang web %s mà em vừa tải về.", targetUrl)
			}
		} else {
			onChunk(fmt.Sprintf("⚠️ <i>(Không thể tải trực tiếp trang web: %v, em sẽ trả lời dựa trên hiểu biết của em nhé!)</i>\n\n", err))
		}
	}

	// 0.4 Nhận diện ý định THỐNG KÊ TỆP TIN (File Statistics trong thư mục bối cảnh Cục Xương)
	if strings.Contains(lower, "thống kê") && (strings.Contains(lower, "tập tin") || strings.Contains(lower, "file") || strings.Contains(lower, "số lượng")) {
		ext := ""
		if strings.Contains(lower, "nix") {
			ext = ".nix"
		} else if strings.Contains(lower, "go") {
			ext = ".go"
		} else if strings.Contains(lower, "sh") {
			ext = ".sh"
		} else if strings.Contains(lower, "md") {
			ext = ".md"
		} else if strings.Contains(lower, "json") {
			ext = ".json"
		}

		targetDir := activeDir
		if targetDir == "" {
			targetDir = "/etc/nixos"
		}

		findCmd := fmt.Sprintf("find %s -type f", targetDir)
		if ext != "" {
			findCmd = fmt.Sprintf("find %s -type f -name \"*%s\"", targetDir, ext)
		}
		countCmd := fmt.Sprintf("%s 2>/dev/null | wc -l", findCmd)
		res := s.cli.ExecuteCommand(ctx, countCmd, targetDir, false)

		count := strings.TrimSpace(res.Output)
		var sb strings.Builder
		sb.WriteString(fmt.Sprintf("🐶 <b>Gâu gâu! Em đã thống kê xong trong thư mục ` %s `:</b>\n\n", targetDir))
		if ext != "" {
			sb.WriteString(fmt.Sprintf("📊 Số lượng tệp tin có đuôi <b>`%s`</b>: <b>%s</b> tệp tin.\n", ext, count))
		} else {
			sb.WriteString(fmt.Sprintf("📊 Tổng số lượng tệp tin: <b>%s</b> tệp tin.\n", count))
		}

		// Liệt kê tối đa 5 tệp tiêu biểu
		listCmd := fmt.Sprintf("%s 2>/dev/null | head -n 6", findCmd)
		listRes := s.cli.ExecuteCommand(ctx, listCmd, targetDir, false)
		if listRes.Output != "" {
			sb.WriteString("\n<b>Một số tệp tiêu biểu:</b>\n")
			for _, f := range strings.Split(strings.TrimSpace(listRes.Output), "\n") {
				if f != "" {
					sb.WriteString(fmt.Sprintf("- 📄 `%s`\n", f))
				}
			}
		}
		sb.WriteString("\nChủ nhân cần em đọc hay phân tích nội dung tệp nào thì bảo em nhé! 🐾")
		onChunk(sb.String())
		onDone()
		return
	}

	// 1. Nhận diện ý định TÌM KIẾM TỆP TIN (Filesystem Search)
	if strings.HasPrefix(lower, "tìm file ") || strings.HasPrefix(lower, "tìm tệp ") || strings.HasPrefix(lower, "tìm kiếm file ") || strings.HasPrefix(lower, "find ") {
		query := trimmed
		for _, prefix := range []string{"tìm kiếm file ", "tìm file ", "tìm tệp ", "find "} {
			if strings.HasPrefix(lower, prefix) {
				query = trimmed[len(prefix):]
				break
			}
		}
		query = strings.TrimSpace(query)

		files := s.fs.FindFiles(query, 10)
		if len(files) == 0 {
			onChunk(fmt.Sprintf("Gâu gâu! Em đã đánh hơi khắp các thư mục nhưng không tìm thấy tệp nào khớp với từ khóa \"%s\" ạ. 🐾", query))
			onDone()
			return
		}

		var sb strings.Builder
		sb.WriteString(fmt.Sprintf("Gâu gâu! Em tìm thấy %d tệp tin liên quan đến \"%s\":\n\n", len(files), query))
		for i, f := range files {
			sb.WriteString(fmt.Sprintf("%d. 📄 `%s`\n", i+1, f))
		}
		sb.WriteString("\nChủ nhân có muốn em đọc hoặc tóm tắt nội dung file nào không ạ? (Hãy gõ: *Đọc file [đường dẫn]* nhé!)")
		onChunk(sb.String())
		onDone()
		return
	}

	// 2. Nhận diện ý định TỰ HỌC TÀI LIỆU VÀO RAG
	if strings.HasPrefix(lower, "học file ") || strings.HasPrefix(lower, "nhớ file ") || strings.HasPrefix(lower, "ghi nhớ file ") {
		filePath := trimmed
		for _, prefix := range []string{"ghi nhớ file ", "học file ", "nhớ file "} {
			if strings.HasPrefix(lower, prefix) {
				filePath = strings.TrimSpace(trimmed[len(prefix):])
				break
			}
		}
		filePath = strings.Trim(filePath, "`\"' ")

		content, err := s.fs.ReadDocument(filePath)
		if err != nil {
			onError(fmt.Sprintf("Không thể đọc file để học: %v", err))
			return
		}

		if s.rag != nil {
			id := filepath.Base(filePath) + "_" + fmt.Sprintf("%d", time.Now().Unix())
			err = s.rag.IndexDocument(ctx, id, content, map[string]string{
				"source": filePath,
				"title":  filepath.Base(filePath),
			})
			if err != nil {
				onError(fmt.Sprintf("Lỗi nạp vào RAG: %v", err))
				return
			}
			if s.mem != nil {
				s.mem.RecordFileAccess(filePath)
			}
			onChunk(fmt.Sprintf("Gâu gâu! Em đã đọc và ghi nhớ toàn bộ nội dung của tệp `%s` vào cơ sở tri thức RAG rồi ạ! Lần sau chủ nhân cần hỏi gì về tài liệu này, em sẽ trả lời ngay nhé! 🧠✨", filePath))
			onDone()
			return
		}
	}

	// 3. Nhận diện ý định ĐỌC & TÓM TẮT TÀI LIỆU
	var attachedDocContext string
	if strings.HasPrefix(lower, "đọc file ") || strings.HasPrefix(lower, "xem file ") || strings.HasPrefix(lower, "nội dung file ") || strings.HasPrefix(lower, "tóm tắt file ") {
		filePath := trimmed
		for _, prefix := range []string{"tóm tắt file ", "nội dung file ", "đọc file ", "xem file "} {
			if strings.HasPrefix(lower, prefix) {
				filePath = strings.TrimSpace(trimmed[len(prefix):])
				break
			}
		}
		filePath = strings.Trim(filePath, "`\"' ")

		content, err := s.fs.ReadDocument(filePath)
		if err != nil {
			onError(fmt.Sprintf("Không thể đọc file: %v", err))
			return
		}

		if s.mem != nil {
			s.mem.RecordFileAccess(filePath)
		}

		attachedDocContext = fmt.Sprintf("=== NỘI DUNG TỆP TIN: %s ===\n%s\n=================================\n", filePath, content)
		question = fmt.Sprintf("Hãy tóm tắt và phân tích ngắn gọn nội dung của tệp tin `%s` trên.", filePath)
	}

	// Lấy context từ RAG nếu được bật (cả ở giao diện lẫn trong thiết lập)
	var ragContext string
	if useRAG && s.cfg.EnableRAG && s.rag != nil {
		topK := s.cfg.RAGTopK
		if topK <= 0 {
			topK = 3
		}
		ctxRag, cancel := context.WithTimeout(ctx, 4*time.Second)
		var err error
		ragContext, err = s.rag.RetrieveContext(ctxRag, question, topK)
		cancel()
		if err != nil {
			fmt.Printf("[BamAI] Cảnh báo RAG: %v\n", err)
		}
	}

	// Ghép System Prompt: Giữ phần tĩnh ổn định để llama-server tận dụng KV Prefix Cache (--cache-prompt)
	systemContent := PuppySystemPrompt
	systemContent += addressingRule(userAddr)

	// Tiêm hồ sơ cá nhân (dùng bản Concise gọn gàng để tránh nạp hàng trăm token bảng trắc nghiệm/lộ trình)
	if s.profile != nil {
		profileCtx := s.profile.GetConcisePromptContext()
		if profileCtx != "" {
			systemContent += "\n\n" + profileCtx
		}
	}

	// Chỉ tiêm hoạt động WakaTime khi câu hỏi liên quan đến năng suất/lịch trình/thời gian làm việc
	if s.waka != nil && (strings.Contains(lower, "waka") || strings.Contains(lower, "làm việc") || strings.Contains(lower, "năng suất") || strings.Contains(lower, "thời gian")) {
		wakaCtx := s.waka.GetSummaryContext()
		if wakaCtx != "" {
			systemContent += "\n\n" + wakaCtx
		}
	}

	// Chỉ tiêm thông số phần cứng khi câu hỏi liên quan đến phần cứng/máy móc/hệ thống
	if strings.Contains(lower, "phần cứng") || strings.Contains(lower, "cấu hình") || strings.Contains(lower, "ram") || strings.Contains(lower, "cpu") || strings.Contains(lower, "ổ đĩa") || strings.Contains(lower, "hệ thống") {
		sysCtx := GetSystemPromptContext()
		if sysCtx != "" {
			systemContent += "\n\n" + sysCtx
		}
	}

	if activeDir != "" {
		systemContent += fmt.Sprintf("\n\n=== BỐI CẢNH THƯ MỤC HIỆN TẠI ===\nThư mục đang mở: `%s`", activeDir)
	}
	if attachedDocContext != "" {
		systemContent += "\n\n" + attachedDocContext
	}
	if webContext != "" {
		systemContent += "\n\n" + webContext
	}
	if ragContext != "" {
		systemContent += "\n\n" + ragContext
	}

	messages := []ChatMessage{
		{Role: "system", Content: systemContent},
	}
	// Ngữ cảnh hội thoại phía trên → trả lời tiếp mạch đang trao đổi.
	messages = append(messages, sanitizeHistory(history, maxHistoryMessages)...)
	messages = append(messages, ChatMessage{Role: "user", Content: question})

	endpoint := fmt.Sprintf("%s/v1/chat/completions", s.cfg.LlamaHost)
	modelName := "local-slm"
	authHeader := ""

	if s.cfg.Provider == "deepseek" && s.cfg.DeepSeekKey != "" {
		endpoint = "https://api.deepseek.com/chat/completions"
		modelName = "deepseek-chat"
		authHeader = "Bearer " + s.cfg.DeepSeekKey
	} else if s.cfg.Provider == "openai" && s.cfg.OpenAIKey != "" {
		endpoint = "https://api.openai.com/v1/chat/completions"
		modelName = "gpt-4o-mini"
		authHeader = "Bearer " + s.cfg.OpenAIKey
	} else if s.cfg.Provider == "gemini" && s.cfg.GeminiKey != "" {
		endpoint = "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions"
		modelName = "gemini-1.5-flash"
		authHeader = "Bearer " + s.cfg.GeminiKey
	}

	reqBody, err := json.Marshal(ChatCompletionReq{
		Model:       modelName,
		Messages:    messages,
		Temperature: float32(s.cfg.Temperature),
		Stream:      true,
	})
	if err != nil {
		onError(fmt.Sprintf("Lỗi encode request: %v", err))
		return
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, endpoint, bytes.NewBuffer(reqBody))
	if err != nil {
		onError(fmt.Sprintf("Lỗi tạo request: %v", err))
		return
	}
	req.Header.Set("Content-Type", "application/json")
	if authHeader != "" {
		req.Header.Set("Authorization", authHeader)
	}

	client := &http.Client{Timeout: 60 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		onError(fmt.Sprintf("Không thể kết nối SLM (%s). Hãy bấm vào cún để đánh thức AI hoặc chạy `bam ai start`!", endpoint))
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		onError(fmt.Sprintf("SLM trả về mã lỗi %d: %s", resp.StatusCode, string(body)))
		return
	}

	reader := bufio.NewReader(resp.Body)
	var answer strings.Builder
	for {
		line, err := reader.ReadString('\n')
		if err != nil {
			if err == io.EOF {
				break
			}
			break
		}

		line = strings.TrimSpace(line)
		if !strings.HasPrefix(line, "data: ") {
			continue
		}
		dataStr := strings.TrimPrefix(line, "data: ")
		if dataStr == "[DONE]" {
			break
		}

		var chunk StreamChunk
		if err := json.Unmarshal([]byte(dataStr), &chunk); err == nil {
			if len(chunk.Choices) > 0 {
				delta := chunk.Choices[0].Delta.Content
				if delta != "" {
					answer.WriteString(delta)
					onChunk(delta)
				}
			}
		}
	}

	// Lưu lượt hỏi/đáp vào tri thức RAG (chạy nền) để các câu hỏi sau dựa vào.
	go s.rememberExchange(question, answer.String())

	onDone()
}

// IsAIOffline kiểm tra llama-server (dịch vụ suy luận THỰC TẾ) có sống không.
// RAG của BamAI là chromem-go NHÚNG trong tiến trình này (rag.go) nên chỉ cần
// kiểm tra llama-server — không có dịch vụ RAG riêng nào để kiểm tra.
func (s *AIService) IsAIOffline() bool {
	host := s.cfg.LlamaHost
	if host == "" {
		host = defaultLlamaHost
	}
	client := &http.Client{Timeout: 600 * time.Millisecond}
	resp, err := client.Get(strings.TrimRight(host, "/") + "/health")
	if err != nil {
		return true
	}
	defer resp.Body.Close()
	return resp.StatusCode != http.StatusOK
}

// startAIServer chạy llama-server qua script bamos-ai-server.
// Cố ý KHÔNG gọi `bam ai start` để tránh hỏi sudo (sẽ treo GUI). RAG là
// chromem-go nhúng trong tiến trình này (rag.go) nên không cần dịch vụ ngoài.
func (s *AIService) startAIServer() error {
	server := exec.Command("bamos-ai-server")
	server.Env = s.aiServerEnv(s.cfg.ModelPath)
	return server.Start()
}

// aiServerEnv dựng môi trường cho `bamos-ai-server`.
//
// Quan trọng: gỡ BAMAI_PORT thừa hưởng từ tiến trình cha. Biến này vừa là cổng
// HTTP nội bộ của BamAI vừa là cổng bind của llama-server trong script; nếu để
// lọt sang, llama-server sẽ bind trùng cổng và thoát ngay. Ta đặt lại đúng cổng
// suy ra từ LlamaHost (mặc định 9090).
func (s *AIService) aiServerEnv(modelPath string) []string {
	env := make([]string, 0, len(os.Environ())+2)
	for _, kv := range os.Environ() {
		if strings.HasPrefix(kv, "BAMAI_PORT=") {
			continue
		}
		env = append(env, kv)
	}
	env = append(env, "BAMAI_MODEL_PATH="+modelPath)
	if port := urlPort(s.cfg.LlamaHost); port != "" {
		env = append(env, "BAMAI_PORT="+port)
	}
	return env
}

// urlPort lấy cổng từ một URL (ví dụ http://127.0.0.1:9090 -> "9090").
func urlPort(raw string) string {
	u, err := url.Parse(raw)
	if err != nil {
		return ""
	}
	return u.Port()
}

// waitAIReady chờ llama-server trả /health OK trong tối đa timeout.
func (s *AIService) waitAIReady(timeout time.Duration) bool {
	deadline := time.Now().Add(timeout)
	for time.Now().Before(deadline) {
		if !s.IsAIOffline() {
			return true
		}
		time.Sleep(500 * time.Millisecond)
	}
	return !s.IsAIOffline()
}

// beginStart trả false nếu đang có một lần khởi động dở dang.
func (s *AIService) beginStart() bool {
	s.startMu.Lock()
	defer s.startMu.Unlock()
	if s.starting {
		return false
	}
	s.starting = true
	return true
}

func (s *AIService) endStart() {
	s.startMu.Lock()
	s.starting = false
	s.startMu.Unlock()
}

// EnsureServices đảm bảo toàn bộ dịch vụ AI đang chạy (llama-server).
//
// An toàn khi gọi lặp từ giao diện (mỗi lần mở khung chat):
//   - Dịch vụ đã sống  -> gọi onReady(false) ngay, KHÔNG hiện thông báo rườm rà.
//   - Đang khởi động dở -> bỏ qua yêu cầu mới (không tạo tiến trình trùng).
//   - Đang tắt         -> khởi động rồi gọi onReady(true) khi xong.
func (s *AIService) EnsureServices(onProgress func(string), onReady func(started bool)) {
	if !s.IsAIOffline() {
		if onReady != nil {
			onReady(false)
		}
		return
	}
	if !s.beginStart() {
		return
	}
	if onProgress != nil {
		onProgress("Đang khởi động dịch vụ AI (llama-server)…")
	}
	go func() {
		defer s.endStart()
		if err := s.startAIServer(); err != nil {
			fmt.Printf("[BamAI Power] Không khởi động được llama-server: %v\n", err)
		}
		s.waitAIReady(30 * time.Second)
		if onReady != nil {
			onReady(true)
		}
	}()
}

func (s *AIService) StopAllServices() {
	fmt.Println("[BamAI Power] Đóng dịch vụ AI (llama-server) theo lệnh người dùng...")
	_ = exec.Command("pkill", "-9", "-f", "bamos-ai-server").Run()
	_ = exec.Command("pkill", "-9", "-f", "llama-server").Run()
}

func (s *AIService) EvaluateAndSleepOrStopAI() string {
	hour := time.Now().Hour()
	shouldFullStop := true

	if s.mem != nil {
		var slot string
		switch {
		case hour >= 5 && hour < 12:
			slot = "morning"
		case hour >= 12 && hour < 18:
			slot = "afternoon"
		case hour >= 18 && hour < 23:
			slot = "evening"
		default:
			slot = "night"
		}
		// Nếu khung giờ này có tần suất dùng liên tục cao (> 12 lần), ưu tiên giữ warm
		if s.mem.Data.WorkHours[slot] > 12 {
			shouldFullStop = false
		}
	}

	if shouldFullStop {
		fmt.Println("[BamAI Power] Đã tự động tắt dịch vụ AI (llama-server) để giải phóng tài nguyên.")
		_ = exec.Command("pkill", "-f", "bamos-ai-server").Run()
		_ = exec.Command("pkill", "-f", "llama-server").Run()
		return "stopped"
	}

	fmt.Println("[BamAI Power] Cún tạm ngủ canh nhà (giữ warm dịch vụ AI).")
	return "warm_sleep"
}

// maxHistoryMessages giới hạn số lượt hội thoại gửi kèm để không tràn context.
const maxHistoryMessages = 12

// sanitizeHistory lọc/lược bớt lịch sử hội thoại trước khi đưa vào prompt.
func sanitizeHistory(history []ChatMessage, maxEntries int) []ChatMessage {
	if len(history) == 0 {
		return nil
	}
	if maxEntries > 0 && len(history) > maxEntries {
		history = history[len(history)-maxEntries:]
	}
	out := make([]ChatMessage, 0, len(history))
	for _, m := range history {
		if m.Role != "user" && m.Role != "assistant" {
			continue
		}
		content := strings.TrimSpace(m.Content)
		if content == "" {
			continue
		}
		out = append(out, ChatMessage{Role: m.Role, Content: truncateRunes(content, 4000)})
	}
	return out
}

// truncateRunes cắt chuỗi theo số KÝ TỰ (an toàn với tiếng Việt nhiều byte).
func truncateRunes(s string, max int) string {
	runes := []rune(s)
	if len(runes) <= max {
		return s
	}
	return string(runes[:max]) + "…"
}

// rememberExchange lưu một lượt hỏi/đáp vào tri thức RAG để các câu hỏi sau có
// thể dựa vào ngữ cảnh hội thoại trước đó.
func (s *AIService) rememberExchange(question, answer string) {
	if s.rag == nil || !s.cfg.EnableRAG {
		return
	}
	q := strings.TrimSpace(question)
	a := strings.TrimSpace(answer)
	if len([]rune(q)) < 4 || len([]rune(a)) < 40 {
		return
	}

	content := fmt.Sprintf(
		"=== HỘI THOẠI NGÀY %s ===\nCâu hỏi: %s\nTrả lời: %s",
		time.Now().Format("2006-01-02 15:04"),
		truncateRunes(q, 1200),
		truncateRunes(a, 4000),
	)

	ctx, cancel := context.WithTimeout(context.Background(), 90*time.Second)
	defer cancel()

	id := fmt.Sprintf("hoi-thoai-%d", time.Now().UnixNano())
	if err := s.rag.IndexDocument(ctx, id, content, map[string]string{
		"type":  "conversation",
		"title": truncateRunes(q, 80),
	}); err != nil {
		fmt.Printf("[BamAI RAG] Không lưu được hội thoại: %v\n", err)
	}
}

func escapeHtmlAttr(s string) string {
	s = strings.ReplaceAll(s, "&", "&amp;")
	s = strings.ReplaceAll(s, "\"", "&quot;")
	s = strings.ReplaceAll(s, "<", "&lt;")
	s = strings.ReplaceAll(s, ">", "&gt;")
	return s
}

// addressingRule bổ sung quy tắc xưng hô theo thiết lập của người dùng.
func addressingRule(addressing string) string {
	userTitle, botTitle := GetAddressingPronouns(addressing)
	return fmt.Sprintf("\n- XƯNG HÔ THEO HỒ SƠ: Gọi người dùng là \"%s\" và tự xưng là \"%s\". Tuyệt đối tuân thủ cặp đại từ xưng hô này trong toàn bộ câu trả lời, không dùng đại từ khác.", userTitle, botTitle)
}

// fetchWebContent tải và trích xuất nội dung văn bản chính từ URL trang web
func fetchWebContent(ctx context.Context, rawUrl string) (string, error) {
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, rawUrl, nil)
	if err != nil {
		return "", err
	}
	req.Header.Set("User-Agent", "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.0.0 Safari/537.36 BamAI/1.0")

	client := &http.Client{Timeout: 10 * time.Second}
	resp, err := client.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return "", fmt.Errorf("HTTP status %d", resp.StatusCode)
	}

	bodyBytes, err := io.ReadAll(io.LimitReader(resp.Body, 500*1024)) // Tối đa 500KB
	if err != nil {
		return "", err
	}

	html := string(bodyBytes)
	// Loại bỏ script, style, comment
	cleaned := htmlScriptRe.ReplaceAllString(html, " ")
	cleaned = htmlStyleRe.ReplaceAllString(cleaned, " ")
	cleaned = htmlCommentRe.ReplaceAllString(cleaned, " ")
	cleaned = htmlTagRe.ReplaceAllString(cleaned, " ")
	cleaned = spaceRunRe.ReplaceAllString(cleaned, " ")
	cleaned = strings.TrimSpace(cleaned)

	// Giới hạn độ dài nội dung đưa vào context để tránh tràn token.
	if len(cleaned) > maxWebContextBytes {
		cleaned = truncateUTF8(cleaned, maxWebContextBytes) + "\n...(Nội dung trang web còn tiếp)..."
	}
	return cleaned, nil
}

// truncateUTF8 cắt chuỗi theo số byte nhưng không cắt giữa ký tự UTF-8
// (tiếng Việt dùng nhiều byte cho mỗi ký tự có dấu).
func truncateUTF8(s string, maxBytes int) string {
	if len(s) <= maxBytes {
		return s
	}
	cut := maxBytes
	for cut > 0 && !utf8.RuneStart(s[cut]) {
		cut--
	}
	return s[:cut]
}
