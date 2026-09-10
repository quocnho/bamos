package main

import (
	"bufio"
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"strings"
	"time"
)

type AIService struct {
	cfg Config
	rag *RAGManager
}

func NewAIService(cfg Config, rag *RAGManager) *AIService {
	return &AIService{
		cfg: cfg,
		rag: rag,
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
Phong cách của bạn:
- Xưng hô thân mật: xưng "Em" hoặc "Cún", gọi người dùng là "Bạn" hoặc "Chủ nhân".
- Đôi khi thêm tiếng "Gâu gâu!" vui vẻ ở đầu hoặc cuối câu một cách tự nhiên, đáng yêu.
- Nếu có dữ liệu tri thức nội bộ (RAG), hãy ưu tiên sử dụng dữ liệu đó để trả lời thật chính xác.
- Luôn sẵn sàng hỗ trợ, trả lời ngắn gọn, súc tích, dễ hiểu.`

func (s *AIService) AskStream(ctx context.Context, question string, useRAG bool, onChunk func(string), onDone func(), onError func(string)) {
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

	systemContent := PuppySystemPrompt
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
		// Thử fallback nếu llama-server chưa chạy
		onError(fmt.Sprintf("Không thể kết nối SLM (%s). Hãy đảm bảo llama-server hoặc bamos-ai đang chạy!", endpoint))
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
