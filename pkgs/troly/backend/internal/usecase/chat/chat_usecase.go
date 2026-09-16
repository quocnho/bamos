package chat

import (
	"bufio"
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"regexp"
	"strings"
	"time"

	"troly/backend/internal/domain"
	"troly/backend/internal/platform/linux"
	"troly/backend/internal/platform/llm"
	"troly/backend/internal/repository/fs"
	"troly/backend/internal/repository/sqlite"
	"troly/backend/internal/usecase/profile"
	"troly/backend/internal/usecase/waka"
)

var (
	webURLRegex   = regexp.MustCompile(`https?://[^\s<>"]+`)
	htmlScriptRe  = regexp.MustCompile(`(?is)<script.*?</script>`)
	htmlStyleRe   = regexp.MustCompile(`(?is)<style.*?</style>`)
	htmlCommentRe = regexp.MustCompile(`(?is)<!--.*?-->`)
	htmlTagRe     = regexp.MustCompile(`<[^>]+>`)
	spaceRunRe    = regexp.MustCompile(`\s{2,}`)
)

const maxWebContextBytes = 4000

type ChatUsecase struct {
	cfg         domain.Config
	ragRepo     *sqlite.RAGRepo
	memRepo     *sqlite.MemoryRepo
	toolRepo    *fs.ToolRepo
	cliEngine   *linux.CLIEngine
	llamaServer *llm.LlamaServer
	profileUc   *profile.ProfileUsecase
	wakaUc      *waka.WakaUsecase
}

func NewChatUsecase(
	cfg domain.Config,
	ragRepo *sqlite.RAGRepo,
	memRepo *sqlite.MemoryRepo,
	toolRepo *fs.ToolRepo,
	cliEngine *linux.CLIEngine,
	llamaServer *llm.LlamaServer,
	profileUc *profile.ProfileUsecase,
	wakaUc *waka.WakaUsecase,
) *ChatUsecase {
	return &ChatUsecase{
		cfg:         cfg,
		ragRepo:     ragRepo,
		memRepo:     memRepo,
		toolRepo:    toolRepo,
		cliEngine:   cliEngine,
		llamaServer: llamaServer,
		profileUc:   profileUc,
		wakaUc:      wakaUc,
	}
}

func (u *ChatUsecase) UpdateConfig(cfg domain.Config) {
	u.cfg = cfg
}

func (u *ChatUsecase) AskStream(ctx context.Context, question string, useRAG bool, history []domain.ChatMessage, onChunk func(string), onDone func(), onError func(string)) {
	trimmed := strings.TrimSpace(question)
	lower := strings.ToLower(trimmed)

	userAddr := u.cfg.Addressing
	if u.profileUc != nil && u.profileUc.GetProfile().Addressing != "" {
		userAddr = u.profileUc.GetProfile().Addressing
	}
	userTitle, botTitle := domain.GetAddressingPronouns(userAddr)

	if u.memRepo != nil {
		u.memRepo.RecordQuery(question)
	}

	activeDir := ""
	if u.memRepo != nil {
		activeDir = u.memRepo.GetActiveDirectory()
	}

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
		return
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
		return
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
		return
	}

	// 4. Tìm kiếm / Đọc tệp
	var attachedDocContext string
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
		return
	}

	if strings.HasPrefix(lower, "đọc file ") || strings.HasPrefix(lower, "xem file ") {
		filePath := strings.TrimSpace(trimmed[len("đọc file "):])
		filePath = strings.Trim(filePath, "`\"' ")
		content, err := u.toolRepo.ReadDocument(filePath)
		if err != nil {
			onError(fmt.Sprintf("Không thể đọc file: %v", err))
			return
		}
		if u.memRepo != nil {
			u.memRepo.RecordFileAccess(filePath)
		}
		attachedDocContext = fmt.Sprintf("=== NỘI DUNG TỆP TIN: %s ===\n%s\n=================================\n", filePath, content)
		question = fmt.Sprintf("Hãy tóm tắt và phân tích ngắn gọn nội dung của tệp tin `%s` trên.", filePath)
	}

	// 5. RAG Retrieval
	var ragContext string
	if useRAG && u.cfg.EnableRAG && u.ragRepo != nil {
		topK := u.cfg.RAGTopK
		if topK <= 0 {
			topK = 4
		}
		ctxRag, cancel := context.WithTimeout(ctx, 4*time.Second)
		ragContext, _ = u.ragRepo.RetrieveContext(ctxRag, question, topK)
		cancel()
	}

	habitContext := ""
	if u.memRepo != nil {
		habitContext = u.memRepo.GetHabitContext()
	}

	systemContent := BuildSystemPrompt(u.cfg.Addressing, u.profileUc, u.wakaUc, activeDir, habitContext, attachedDocContext, "", ragContext)
	messages := []domain.ChatMessage{
		{Role: "system", Content: systemContent},
	}
	messages = append(messages, SanitizeHistory(history, 12)...)
	messages = append(messages, domain.ChatMessage{Role: "user", Content: question})

	endpoint := fmt.Sprintf("%s/v1/chat/completions", u.cfg.LlamaHost)
	modelName := "local-slm"
	authHeader := ""

	if u.cfg.Provider == "deepseek" && u.cfg.DeepSeekKey != "" {
		endpoint = "https://api.deepseek.com/chat/completions"
		modelName = "deepseek-chat"
		authHeader = "Bearer " + u.cfg.DeepSeekKey
	} else if u.cfg.Provider == "openai" && u.cfg.OpenAIKey != "" {
		endpoint = "https://api.openai.com/v1/chat/completions"
		modelName = "gpt-4o-mini"
		authHeader = "Bearer " + u.cfg.OpenAIKey
	} else if u.cfg.Provider == "gemini" && u.cfg.GeminiKey != "" {
		endpoint = "https://generativelanguage.googleapis.com/v1beta/openai/chat/completions"
		modelName = "gemini-1.5-flash"
		authHeader = "Bearer " + u.cfg.GeminiKey
	}

	reqBody, err := json.Marshal(domain.ChatCompletionReq{
		Model:       modelName,
		Messages:    messages,
		Temperature: float32(u.cfg.Temperature),
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
		var chunk domain.StreamChunk
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

	go u.rememberExchange(question, answer.String())
	onDone()
}

func (u *ChatUsecase) rememberExchange(question, answer string) {
	if u.ragRepo == nil || !u.cfg.EnableRAG {
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
		TruncateRunes(q, 1200),
		TruncateRunes(a, 4000),
	)

	ctx, cancel := context.WithTimeout(context.Background(), 90*time.Second)
	defer cancel()

	id := fmt.Sprintf("hoi-thoai-%d", time.Now().UnixNano())
	_ = u.ragRepo.IndexDocument(ctx, id, content, map[string]string{
		"type":  "conversation",
		"title": TruncateRunes(q, 80),
	})
}
