package main

import (
	"bufio"
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

type AIService struct {
	cfg Config
	rag *RAGManager
	fs  *FSTool
	mem *UserMemory
	cli *CLIEngine
}

func NewAIService(cfg Config, rag *RAGManager, fsTool *FSTool, mem *UserMemory) *AIService {
	cliEngine := NewCLIEngine(mem)
	return &AIService{
		cfg: cfg,
		rag: rag,
		fs:  fsTool,
		mem: mem,
		cli: cliEngine,
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

const PuppySystemPrompt = `Bạn là BamOS Puppy (Mascot Assistant) - một chú cún cưng AI thông minh, đáng yêu và tận tụy trên hệ điều hành BamOS (NixOS GNOME).
Quy tắc xưng hô và phong cách:
- BẮT BUỘC xưng hô: Luôn luôn gọi người dùng là "Chủ nhân" (hoặc "Chủ nhân ơi", "Chủ nhân ạ"), và tự xưng là "Em". TUYỆT ĐỐI KHÔNG dùng từ "bạn", "người dùng", "tôi".
- Khi chào hỏi hoặc mở đầu, hãy dùng các câu như: "Em chào Chủ nhân ạ!", "Chúc Chủ nhân một ngày làm việc thật vui vẻ và hiệu quả!", "Dạ, em nghe đây ạ!".
- Đôi khi thêm tiếng "Gâu gâu!" vui vẻ ở đầu hoặc cuối câu một cách tự nhiên, đáng yêu.
- Nếu có dữ liệu tri thức nội bộ (RAG), dữ liệu tệp tin hoặc thông tin thói quen, hãy sử dụng để phục vụ Chủ nhân thật chu đáo và chính xác.
- Luôn sẵn sàng hỗ trợ, trả lời ngắn gọn, súc tích, dễ hiểu và lễ phép.`

func (s *AIService) AskStream(ctx context.Context, question string, useRAG bool, onChunk func(string), onDone func(), onError func(string)) {
	trimmed := strings.TrimSpace(question)
	lower := strings.ToLower(trimmed)

	// Ghi nhận truy vấn vào bộ nhớ thói quen
	if s.mem != nil {
		s.mem.RecordQuery(question)
	}

	// Lấy thư mục bối cảnh hiện tại (nếu có Cục Xương)
	activeDir := ""
	if s.mem != nil {
		activeDir = s.mem.GetActiveDirectory()
	}

	// 0. Nhận diện ý định THÔNG TIN HỆ THỐNG & PHẦN CỨNG
	if strings.Contains(lower, "thông tin hệ thống") || strings.Contains(lower, "thông tin máy") || strings.Contains(lower, "cấu hình máy") || strings.Contains(lower, "phần cứng") || strings.Contains(lower, "kiểm tra phần cứng") {
		sys := GetHardwareAndSystemInfo()
		var sb strings.Builder
		sb.WriteString("🐶 <b>Gâu gâu! Em gửi Chủ nhân thông tin hệ thống và phần cứng máy tính ạ:</b>\n\n")
		sb.WriteString(fmt.Sprintf("💻 <b>Hệ điều hành:</b> %s (Kernel: `%s`)\n", sys.OS, sys.Kernel))
		sb.WriteString(fmt.Sprintf("🏷️ <b>Tên máy:</b> `%s`\n", sys.HostName))
		sb.WriteString(fmt.Sprintf("⚡ <b>Bộ vi xử lý (CPU):</b> %s (%d nhân)\n", sys.CPU, sys.Cores))
		sb.WriteString(fmt.Sprintf("🎮 <b>Đồ họa (GPU):</b> %s\n", sys.GPU))
		sb.WriteString(fmt.Sprintf("🧠 <b>Bộ nhớ RAM:</b> Đang dùng %s / Tổng %s\n", sys.MemoryUsed, sys.MemoryTotal))
		sb.WriteString(fmt.Sprintf("💾 <b>Ổ đĩa gốc (/):</b> %s\n\n", sys.DiskUsage))
		sb.WriteString("Chủ nhân có muốn em tối ưu hoặc dọn dẹp hệ thống không ạ?")
		onChunk(sb.String())
		onDone()
		return
	}

	// 0.1 Nhận diện ý định KIỂM TRA ỨNG DỤNG ĐANG CHẠY
	if strings.Contains(lower, "đang chạy ứng dụng") || strings.Contains(lower, "ứng dụng đang mở") || strings.Contains(lower, "ứng dụng nào đang chạy") || strings.Contains(lower, "tiến trình đang chạy") || strings.Contains(lower, "process") {
		apps := GetRunningApps()
		var sb strings.Builder
		sb.WriteString(fmt.Sprintf("🐶 <b>Gâu gâu! Em đang đánh hơi thấy %d ứng dụng và tiến trình nổi bật đang hoạt động:</b>\n\n", len(apps)))
		for i, app := range apps {
			sb.WriteString(fmt.Sprintf("%d. <b>%s</b> (PID: `%s`) — CPU: `%s` | RAM: `%s`\n", i+1, app.Name, app.PID, app.CPU, app.Memory))
		}
		sb.WriteString("\nChủ nhân có muốn em đóng ứng dụng nào để tiết kiệm tài nguyên không ạ?")
		onChunk(sb.String())
		onDone()
		return
	}

	// 0.2 Nhận diện ý định THỰC THI LỆNH CLI (Bao gồm cả sudo)
	if strings.HasPrefix(lower, "chạy lệnh ") || strings.HasPrefix(lower, "thực thi lệnh ") || strings.HasPrefix(lower, "run ") || strings.HasPrefix(lower, "lệnh ") || strings.HasPrefix(lower, "$ ") {
		cmdStr := trimmed
		for _, prefix := range []string{"chạy lệnh ", "thực thi lệnh ", "run ", "lệnh ", "$ "} {
			if strings.HasPrefix(lower, prefix) {
				cmdStr = trimmed[len(prefix):]
				break
			}
		}
		cmdStr = strings.Trim(cmdStr, "`\"' ")

		onChunk(fmt.Sprintf("🐶 Em đang thực thi lệnh: ` %s `...\n\n", cmdStr))
		res := s.cli.ExecuteCommand(ctx, cmdStr, activeDir, true)

		var sb strings.Builder
		if res.ExitCode == 0 {
			sb.WriteString(fmt.Sprintf("✅ <b>Thành công (trong %s):</b>\n", res.Duration))
		} else {
			sb.WriteString(fmt.Sprintf("❌ <b>Lỗi (Mã thoát: %d - trong %s):</b>\n", res.ExitCode, res.Duration))
		}

		if res.Output != "" {
			sb.WriteString(fmt.Sprintf("```bash\n%s\n```\n", res.Output))
		} else {
			sb.WriteString("*(Lệnh đã hoàn thành không có đầu ra)*\n")
		}

		if res.Learned {
			sb.WriteString("🧠 <i>Em đã tự học và ghi nhớ lệnh này vào sổ tay tri thức rồi ạ!</i>")
		}

		onChunk(sb.String())
		onDone()
		return
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

	// Lấy context từ RAG nếu được bật
	var ragContext string
	if useRAG && s.rag != nil {
		ctxRag, cancel := context.WithTimeout(ctx, 4*time.Second)
		var err error
		ragContext, err = s.rag.RetrieveContext(ctxRag, question, 3)
		cancel()
		if err != nil {
			fmt.Printf("[BamAI] Cảnh báo RAG: %v\n", err)
		}
	}

	// Ghép System Prompt + Thói quen + Thư mục bối cảnh Cục Xương + Tài liệu đính kèm + RAG
	systemContent := PuppySystemPrompt
	if activeDir != "" {
		systemContent += fmt.Sprintf("\n\n=== BỐI CẢNH THƯ MỤC HIỆN TẠI (TỪ CỤC XƯƠNG FILE MANAGER) ===\nChủ nhân đang mở và làm việc trong thư mục: `%s`\nMọi yêu cầu thống kê, tìm kiếm, đọc tệp hoặc chạy lệnh của Chủ nhân hãy ưu tiên thực hiện trong thư mục này.\n=============================================================", activeDir)
	}
	if s.mem != nil {
		habit := s.mem.GetHabitContext()
		if habit != "" {
			systemContent += "\n\n" + habit
		}
	}
	if attachedDocContext != "" {
		systemContent += "\n\n" + attachedDocContext
	}
	if ragContext != "" {
		systemContent += "\n\n" + ragContext
	}

	messages := []ChatMessage{
		{Role: "system", Content: systemContent},
		{Role: "user", Content: question},
	}

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
	}

	reqBody, err := json.Marshal(ChatCompletionReq{
		Model:       modelName,
		Messages:    messages,
		Temperature: 0.7,
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
					onChunk(delta)
				}
			}
		}
	}

	onDone()
}

func (s *AIService) IsAIOffline() bool {
	client := &http.Client{Timeout: 600 * time.Millisecond}
	resp, err := client.Get(fmt.Sprintf("%s/health", s.cfg.LlamaHost))
	if err != nil {
		return true
	}
	defer resp.Body.Close()
	return resp.StatusCode != http.StatusOK
}

func (s *AIService) IsRAGOffline() bool {
	client := &http.Client{Timeout: 600 * time.Millisecond}
	resp, err := client.Get("http://127.0.0.1:8090/health")
	if err != nil {
		return true
	}
	defer resp.Body.Close()
	return resp.StatusCode != http.StatusOK
}

func (s *AIService) StartAIServicesOnDemand(onProgress func(string), onReady func()) {
	aiOff := s.IsAIOffline()
	ragOff := s.IsRAGOffline()

	if !aiOff && !ragOff {
		onReady()
		return
	}

	onProgress("Đang đánh thức AI & RAG (bam ai start)...")

	go func() {
		cmd := exec.Command("bam", "ai", "start")
		_ = cmd.Start()

		if s.IsAIOffline() {
			_ = exec.Command("bamos-ai-server").Start()
		}
		if s.IsRAGOffline() {
			ragCmd := exec.Command("bamos-rag")
			ragCmd.Env = append(os.Environ(),
				"PORT=8090",
				"STORAGE_PATH=/var/lib/bamos/rag/knowledge.db",
				"LLAMA_HOST=http://127.0.0.1:9090",
			)
			_ = ragCmd.Start()
		}

		for i := 0; i < 24; i++ {
			time.Sleep(500 * time.Millisecond)
			if !s.IsAIOffline() && !s.IsRAGOffline() {
				break
			}
		}

		onReady()
	}()
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
		fmt.Println("[BamAI Power] Đã tự động tắt dịch vụ AI & RAG để giải phóng 100% tài nguyên.")
		_ = exec.Command("pkill", "-f", "bamos-ai-server").Run()
		_ = exec.Command("pkill", "-f", "llama-server").Run()
		_ = exec.Command("pkill", "-f", "bamos-rag").Run()
		return "stopped"
	}

	fmt.Println("[BamAI Power] Cún tạm ngủ canh nhà (giữ warm dịch vụ AI).")
	return "warm_sleep"
}
