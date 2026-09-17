package chat

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

	"troly/backend/internal/domain"
	"troly/backend/internal/platform/linux"
	"troly/backend/internal/platform/llm"
	"troly/backend/internal/repository/fs"
	"troly/backend/internal/repository/sqlite"
	"troly/backend/internal/usecase/profile"
	"troly/backend/internal/usecase/waka"
)

var sharedLLMClient = &http.Client{
	Timeout: 120 * time.Second,
	Transport: &http.Transport{
		MaxIdleConns:        10,
		IdleConnTimeout:     90 * time.Second,
		DisableCompression: false,
	},
}

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

	handled, attachedDocContext, revisedQ := u.handleDirectIntents(ctx, trimmed, lower, userTitle, botTitle, activeDir, onChunk, onDone, onError)
	if handled {
		return
	}
	if revisedQ != "" {
		question = revisedQ
	}

	// RAG Retrieval
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

	endpoint, modelName, authHeader := u.resolveLLMEndpoint()

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

	resp, err := sharedLLMClient.Do(req)
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

	u.streamResponse(resp.Body, question, onChunk, onDone)
}

func (u *ChatUsecase) resolveLLMEndpoint() (endpoint, modelName, authHeader string) {
	endpoint = fmt.Sprintf("%s/v1/chat/completions", u.cfg.LlamaHost)
	modelName = "local-slm"

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
	return
}

func (u *ChatUsecase) streamResponse(body io.Reader, question string, onChunk func(string), onDone func()) {
	reader := bufio.NewReader(body)
	var answer strings.Builder
	var chunkBuffer strings.Builder
	lastFlush := time.Now()

	flushBuffer := func() {
		if chunkBuffer.Len() > 0 {
			onChunk(chunkBuffer.String())
			chunkBuffer.Reset()
			lastFlush = time.Now()
		}
	}

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
					chunkBuffer.WriteString(delta)
					if strings.ContainsAny(delta, "\n\r.,!?:;") || chunkBuffer.Len() >= 30 || time.Since(lastFlush) >= 40*time.Millisecond {
						flushBuffer()
					}
				}
			}
		}
	}
	flushBuffer()

	go u.rememberExchange(question, answer.String())
	onDone()
}
