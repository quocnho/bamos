package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strings"
	"sync"

	"github.com/philippgille/chromem-go"
)

// Cấu hình dịch vụ
type Config struct {
	Port         string
	StoragePath  string
	LlamaHost    string
	EmbedModel   string
	DefaultTopK  int
	DeepSeekKey  string
	DeepSeekHost string
}

type RAGServer struct {
	cfg        Config
	mu         sync.RWMutex
	db         *chromem.DB
	collection *chromem.Collection
}

// Struct cho API
type IndexRequest struct {
	ID       string            `json:"id,omitempty"`
	Content  string            `json:"content"`
	Metadata map[string]string `json:"metadata,omitempty"`
	UseLLM   bool              `json:"use_llm,omitempty"`   // Cho phép dùng DeepSeek/LLM để phân tích & trích xuất trước khi index
}

type QueryRequest struct {
	Query     string    `json:"query,omitempty"`
	Embedding []float32 `json:"embedding,omitempty"`
	TopK      int       `json:"topK,omitempty"`
}

type QueryResponse struct {
	Documents []DocumentResult `json:"documents"`
}

type DocumentResult struct {
	ID       string            `json:"id"`
	Content  string            `json:"content"`
	Metadata map[string]string `json:"metadata,omitempty"`
	Score    float32           `json:"score"`
}

type AskRequest struct {
	Question     string `json:"question"`
	TopK         int    `json:"topK,omitempty"`
	SystemPrompt string `json:"systemPrompt,omitempty"`
	Provider     string `json:"provider,omitempty"` // "local" (mặc định) hoặc "deepseek"
}

type AskResponse struct {
	Answer    string           `json:"answer"`
	Provider  string           `json:"provider"`
	Contexts  []DocumentResult `json:"contexts"`
}

type SetConfigReq struct {
	DeepSeekKey string `json:"deepseek_api_key"`
	LlamaHost   string `json:"llama_host,omitempty"`
}

// OpenAI compatible request & response
type OpenAIEmbeddingReq struct {
	Input string `json:"input"`
	Model string `json:"model,omitempty"`
}

type OpenAIEmbeddingResp struct {
	Data []struct {
		Embedding []float32 `json:"embedding"`
	} `json:"data"`
}

type OpenAIChatReq struct {
	Model       string              `json:"model"`
	Messages    []OpenAIChatMessage `json:"messages"`
	Temperature float32             `json:"temperature"`
}

type OpenAIChatMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}

type OpenAIChatResp struct {
	Choices []struct {
		Message OpenAIChatMessage `json:"message"`
	} `json:"choices"`
}

func getEnv(key, defVal string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return defVal
}

func (s *RAGServer) getEmbedding(ctx context.Context, text string) ([]float32, error) {
	s.mu.RLock()
	llamaHost := s.cfg.LlamaHost
	model := s.cfg.EmbedModel
	s.mu.RUnlock()

	reqBody, _ := json.Marshal(OpenAIEmbeddingReq{
		Input: text,
		Model: model,
	})

	url := fmt.Sprintf("%s/v1/embeddings", llamaHost)
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, url, bytes.NewBuffer(reqBody))
	if err != nil {
		return nil, fmt.Errorf("tạo request embedding thất bại: %w", err)
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("không thể kết nối llama-server (%s): %w", url, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return nil, fmt.Errorf("llama-server trả về mã lỗi %d: %s", resp.StatusCode, string(body))
	}

	var res OpenAIEmbeddingResp
	if err := json.NewDecoder(resp.Body).Decode(&res); err != nil {
		return nil, fmt.Errorf("giải mã dữ liệu embedding thất bại: %w", err)
	}

	if len(res.Data) == 0 {
		return nil, fmt.Errorf("không nhận được vector embedding")
	}

	return res.Data[0].Embedding, nil
}

// Gọi LLM sinh câu trả lời (Hỗ trợ cả Local Qwen qua llama-server và Cloud DeepSeek)
func (s *RAGServer) generateChatAnswer(ctx context.Context, provider, systemPrompt, userPrompt string) (string, error) {
	s.mu.RLock()
	llamaHost := s.cfg.LlamaHost
	deepSeekKey := s.cfg.DeepSeekKey
	deepSeekHost := s.cfg.DeepSeekHost
	s.mu.RUnlock()

	var apiURL, apiKey, modelName string

	if strings.ToLower(provider) == "deepseek" {
		if deepSeekKey == "" {
			return "", fmt.Errorf("chưa cấu hình DEEPSEEK_API_KEY! Hãy nhập API Key trong phần Cài đặt của giao diện Web hoặc qua biến môi trường.")
		}
		apiURL = fmt.Sprintf("%s/chat/completions", deepSeekHost)
		apiKey = deepSeekKey
		modelName = "deepseek-chat"
	} else {
		// Mặc định: Local Qwen2.5 qua llama-server
		apiURL = fmt.Sprintf("%s/v1/chat/completions", llamaHost)
		modelName = "qwen2.5-1.5b"
	}

	reqBody, _ := json.Marshal(OpenAIChatReq{
		Model: modelName,
		Messages: []OpenAIChatMessage{
			{Role: "system", Content: systemPrompt},
			{Role: "user", Content: userPrompt},
		},
		Temperature: 0.3,
	})

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, apiURL, bytes.NewBuffer(reqBody))
	if err != nil {
		return "", err
	}
	req.Header.Set("Content-Type", "application/json")
	if apiKey != "" {
		req.Header.Set("Authorization", "Bearer "+apiKey)
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return "", fmt.Errorf("kết nối tới LLM (%s) thất bại: %w", apiURL, err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		body, _ := io.ReadAll(resp.Body)
		return "", fmt.Errorf("LLM API trả về lỗi (mã %d): %s", resp.StatusCode, string(body))
	}

	var chatResp OpenAIChatResp
	if err := json.NewDecoder(resp.Body).Decode(&chatResp); err != nil {
		return "", err
	}

	if len(chatResp.Choices) == 0 {
		return "", fmt.Errorf("LLM trả về câu trả lời rỗng")
	}

	return chatResp.Choices[0].Message.Content, nil
}

// GET /health - Kiểm tra trạng thái
func (s *RAGServer) handleHealth(w http.ResponseWriter, r *http.Request) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"status":         "ok",
		"service":        "BamAI-RAG",
		"llama_host":     s.cfg.LlamaHost,
		"deepseek_ready": s.cfg.DeepSeekKey != "",
		"collection":     s.collection.Name,
		"doc_count":      s.collection.Count(),
	})
}

// POST /config - Thiết lập API Key và cấu hình qua Web UI
func (s *RAGServer) handleConfig(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost && r.Method != http.MethodGet {
		http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		return
	}

	s.mu.Lock()
	defer s.mu.Unlock()

	if r.Method == http.MethodPost {
		var req SetConfigReq
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
		if req.DeepSeekKey != "" {
			s.cfg.DeepSeekKey = strings.TrimSpace(req.DeepSeekKey)
		}
		if req.LlamaHost != "" {
			s.cfg.LlamaHost = strings.TrimSpace(req.LlamaHost)
		}
	}

	maskedKey := ""
	if len(s.cfg.DeepSeekKey) > 8 {
		maskedKey = s.cfg.DeepSeekKey[:4] + "..." + s.cfg.DeepSeekKey[len(s.cfg.DeepSeekKey)-4:]
	} else if s.cfg.DeepSeekKey != "" {
		maskedKey = "********"
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"status":       "success",
		"llama_host":   s.cfg.LlamaHost,
		"has_deepseek": s.cfg.DeepSeekKey != "",
		"masked_key":   maskedKey,
	})
}

func writeJSONError(w http.ResponseWriter, msg string, code int) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(code)
	_ = json.NewEncoder(w).Encode(map[string]string{"error": msg})
}

// POST /index - Thêm tài liệu vào vector DB
func (s *RAGServer) handleIndex(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeJSONError(w, "Phương thức không được hỗ trợ", http.StatusMethodNotAllowed)
		return
	}

	var req IndexRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSONError(w, "Yêu cầu không hợp lệ: "+err.Error(), http.StatusBadRequest)
		return
	}

	if strings.TrimSpace(req.Content) == "" {
		writeJSONError(w, "Nội dung tài liệu không được để trống", http.StatusBadRequest)
		return
	}

	docID := req.ID
	if docID == "" {
		docID = fmt.Sprintf("doc_%d", s.collection.Count()+1)
	}

	// Nếu yêu cầu dùng LLM (DeepSeek) để tinh chỉnh cấu trúc dữ liệu trước khi index
	finalContent := req.Content
	if req.UseLLM && s.cfg.DeepSeekKey != "" {
		prompt := "Hãy tóm tắt ngắn gọn và trích xuất các ý chính, thực thể, từ khóa quan trọng của đoạn văn bản sau bằng Tiếng Việt để lưu trữ phục vụ truy xuất RAG:\n\n" + req.Content
		if processed, err := s.generateChatAnswer(r.Context(), "deepseek", "Bạn là chuyên gia xử lý dữ liệu cho hệ thống RAG.", prompt); err == nil {
			finalContent = processed
			if req.Metadata == nil {
				req.Metadata = make(map[string]string)
			}
			req.Metadata["processed_by"] = "deepseek"
		}
	}

	// Lấy vector embedding từ llama-server
	emb, err := s.getEmbedding(r.Context(), finalContent)
	if err != nil {
		writeJSONError(w, "Tạo Vector Embedding thất bại (hãy kiểm tra xem BamAI đã chạy chưa): "+err.Error(), http.StatusBadGateway)
		return
	}

	err = s.collection.AddDocument(r.Context(), chromem.Document{
		ID:        docID,
		Metadata:  req.Metadata,
		Embedding: emb,
		Content:   finalContent,
	})
	if err != nil {
		writeJSONError(w, "Lưu tài liệu vào kho vector thất bại: "+err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(map[string]interface{}{
		"status": "success",
		"id":     docID,
		"size":   len(finalContent),
	})
}

// POST /query - Tìm kiếm tài liệu
func (s *RAGServer) handleQuery(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeJSONError(w, "Phương thức không được hỗ trợ", http.StatusMethodNotAllowed)
		return
	}

	var req QueryRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSONError(w, "Yêu cầu không hợp lệ: "+err.Error(), http.StatusBadRequest)
		return
	}

	topK := req.TopK
	if topK <= 0 {
		topK = s.cfg.DefaultTopK
	}

	var emb []float32
	if len(req.Embedding) > 0 {
		emb = req.Embedding
	} else if strings.TrimSpace(req.Query) != "" {
		var err error
		emb, err = s.getEmbedding(r.Context(), req.Query)
		if err != nil {
			writeJSONError(w, "Tạo Embedding cho câu hỏi thất bại: "+err.Error(), http.StatusBadGateway)
			return
		}
	} else {
		writeJSONError(w, "Vui lòng nhập 'query' hoặc cung cấp 'embedding'", http.StatusBadRequest)
		return
	}

	results, err := s.collection.QueryEmbedding(r.Context(), emb, topK, nil, nil)
	if err != nil {
		writeJSONError(w, "Truy vấn Vector thất bại: "+err.Error(), http.StatusInternalServerError)
		return
	}

	var docs []DocumentResult
	for _, res := range results {
		docs = append(docs, DocumentResult{
			ID:       res.ID,
			Content:  res.Content,
			Metadata: res.Metadata,
			Score:    res.Similarity,
		})
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(QueryResponse{Documents: docs})
}

// POST /ask - Full RAG pipeline: Tìm ngữ cảnh và sinh câu trả lời
func (s *RAGServer) handleAsk(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		writeJSONError(w, "Phương thức không được hỗ trợ", http.StatusMethodNotAllowed)
		return
	}

	var req AskRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeJSONError(w, "Yêu cầu không hợp lệ: "+err.Error(), http.StatusBadRequest)
		return
	}

	if strings.TrimSpace(req.Question) == "" {
		writeJSONError(w, "Câu hỏi không được để trống", http.StatusBadRequest)
		return
	}

	topK := req.TopK
	if topK <= 0 {
		topK = s.cfg.DefaultTopK
	}

	provider := req.Provider
	if provider == "" {
		provider = "local"
	}

	// 1. Vectorize câu hỏi
	emb, err := s.getEmbedding(r.Context(), req.Question)
	if err != nil {
		writeJSONError(w, "Tạo embedding thất bại: "+err.Error(), http.StatusBadGateway)
		return
	}

	// 2. Lấy top documents liên quan
	results, err := s.collection.QueryEmbedding(r.Context(), emb, topK, nil, nil)
	if err != nil {
		writeJSONError(w, "Tìm kiếm vector thất bại: "+err.Error(), http.StatusInternalServerError)
		return
	}

	var docs []DocumentResult
	var contextTexts []string
	for _, res := range results {
		docs = append(docs, DocumentResult{
			ID:       res.ID,
			Content:  res.Content,
			Metadata: res.Metadata,
			Score:    res.Similarity,
		})
		contextTexts = append(contextTexts, res.Content)
	}

	// 3. Xây dựng prompt tổng hợp
	systemPrompt := req.SystemPrompt
	if systemPrompt == "" {
		systemPrompt = "Bạn là trợ lý ảo BamAI tích hợp trên hệ điều hành BamOS. " +
			"Hãy luôn trả lời hoàn toàn bằng Tiếng Việt một cách chuẩn xác, tự nhiên, rõ ràng " +
			"dựa trên các thông tin ngữ cảnh được cung cấp. Nếu ngữ cảnh không có thông tin, hãy nói rõ là tài liệu chưa đề cập."
	}

	combinedContext := strings.Join(contextTexts, "\n---\n")
	userPrompt := fmt.Sprintf("--- THÔNG TIN NGỮ CẢNH TÀI LIỆU ---\n%s\n-----------------------------------\nCÂU HỎI: %s\nTRẢ LỜI BẰNG TIẾNG VIỆT:", combinedContext, req.Question)

	// 4. Gọi LLM
	answer, err := s.generateChatAnswer(r.Context(), provider, systemPrompt, userPrompt)
	if err != nil {
		writeJSONError(w, "Sinh câu trả lời từ AI thất bại: "+err.Error(), http.StatusBadGateway)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(AskResponse{
		Answer:   answer,
		Provider: provider,
		Contexts: docs,
	})
}

// Giao diện Web UI tiếng Việt thuần (HTML5 + CSS hiện đại + JS)
func (s *RAGServer) handleUI(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path != "/" {
		http.NotFound(w, r)
		return
	}
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	w.Write([]byte(htmlIndex))
}

func main() {
	cfg := Config{
		Port:         getEnv("PORT", "8090"),
		StoragePath:  getEnv("STORAGE_PATH", "./data/knowledge.db"),
		LlamaHost:    getEnv("LLAMA_HOST", "http://127.0.0.1:9090"),
		EmbedModel:   getEnv("EMBED_MODEL", "qwen2.5"),
		DefaultTopK:  3,
		DeepSeekKey:  getEnv("DEEPSEEK_API_KEY", ""),
		DeepSeekHost: getEnv("DEEPSEEK_HOST", "https://api.deepseek.com/v1"),
	}

	db, err := chromem.NewPersistentDB(cfg.StoragePath, false)
	if err != nil {
		log.Fatalf("Khởi tạo chromem-go thất bại: %v", err)
	}

	collection, err := db.GetOrCreateCollection("enterprise_knowledge", nil, nil)
	if err != nil {
		log.Fatalf("Tạo collection thất bại: %v", err)
	}

	server := &RAGServer{
		cfg:        cfg,
		db:         db,
		collection: collection,
	}

	http.HandleFunc("/", server.handleUI)
	http.HandleFunc("/health", server.handleHealth)
	http.HandleFunc("/config", server.handleConfig)
	http.HandleFunc("/index", server.handleIndex)
	http.HandleFunc("/query", server.handleQuery)
	http.HandleFunc("/ask", server.handleAsk)

	fmt.Printf("🎋 BamAI RAG Web Studio đang lắng nghe tại: http://127.0.0.1:%s\n", cfg.Port)
	fmt.Printf("   Kết nối Local AI: %s\n", cfg.LlamaHost)
	fmt.Printf("   Đường dẫn Vector DB: %s\n", cfg.StoragePath)
	log.Fatal(http.ListenAndServe(":"+cfg.Port, nil))
}

// Giao diện Web App Tiếng Việt hiện đại, tối ưu và thẩm mỹ
const htmlIndex = `<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>BamAI Studio — Trung tâm Local AI & RAG</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap" rel="stylesheet">
  <style>
    :root {
      --bg-main: #0d1117;
      --bg-card: #161b22;
      --border: #30363d;
      --accent: #2ea043;
      --accent-hover: #3fb950;
      --text: #e6edf3;
      --text-muted: #8b949e;
      --tag-bg: #21262d;
      --danger: #f85149;
    }
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: 'Inter', -apple-system, BlinkMacSystemFont, sans-serif;
      background: var(--bg-main);
      color: var(--text);
      line-height: 1.6;
      display: flex;
      flex-direction: column;
      height: 100vh;
      overflow: hidden;
    }
    header {
      background: var(--bg-card);
      border-bottom: 1px solid var(--border);
      padding: 12px 24px;
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    .logo {
      display: flex;
      align-items: center;
      gap: 10px;
      font-weight: 700;
      font-size: 1.15rem;
      color: var(--text);
    }
    .logo span { color: var(--accent); }
    .status-badge {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 4px 12px;
      background: var(--tag-bg);
      border: 1px solid var(--border);
      border-radius: 20px;
      font-size: 0.85rem;
    }
    .dot {
      width: 8px;
      height: 8px;
      border-radius: 50%;
      background: var(--accent);
    }
    .layout {
      display: flex;
      flex: 1;
      overflow: hidden;
    }
    .sidebar {
      width: 320px;
      background: var(--bg-card);
      border-right: 1px solid var(--border);
      padding: 20px;
      display: flex;
      flex-direction: column;
      gap: 20px;
      overflow-y: auto;
    }
    .main-content {
      flex: 1;
      display: flex;
      flex-direction: column;
      padding: 20px 24px;
      gap: 16px;
      overflow-y: auto;
    }
    h3 {
      font-size: 0.95rem;
      text-transform: uppercase;
      letter-spacing: 0.5px;
      color: var(--text-muted);
      margin-bottom: 8px;
    }
    label {
      font-size: 0.85rem;
      font-weight: 500;
      display: block;
      margin-bottom: 6px;
    }
    input, textarea, select {
      width: 100%;
      padding: 10px 12px;
      background: var(--bg-main);
      border: 1px solid var(--border);
      border-radius: 6px;
      color: var(--text);
      font-family: inherit;
      font-size: 0.9rem;
      outline: none;
      transition: border-color 0.2s;
    }
    input:focus, textarea:focus, select:focus {
      border-color: var(--accent);
    }
    button {
      background: var(--accent);
      color: #fff;
      border: none;
      border-radius: 6px;
      padding: 10px 16px;
      font-weight: 600;
      font-size: 0.9rem;
      cursor: pointer;
      display: flex;
      align-items: center;
      justify-content: center;
      gap: 8px;
      transition: background 0.2s;
    }
    button:hover { background: var(--accent-hover); }
    button.secondary {
      background: var(--tag-bg);
      border: 1px solid var(--border);
    }
    button.secondary:hover { background: #30363d; }
    .chat-container {
      flex: 1;
      display: flex;
      flex-direction: column;
      background: var(--bg-card);
      border: 1px solid var(--border);
      border-radius: 8px;
      overflow: hidden;
    }
    .chat-messages {
      flex: 1;
      padding: 20px;
      overflow-y: auto;
      display: flex;
      flex-direction: column;
      gap: 16px;
    }
    .message {
      max-width: 80%;
      padding: 12px 16px;
      border-radius: 8px;
      font-size: 0.95rem;
      white-space: pre-wrap;
    }
    .message.user {
      align-self: flex-end;
      background: #1f6feb;
      color: #fff;
    }
    .message.assistant {
      align-self: flex-start;
      background: var(--tag-bg);
      border: 1px solid var(--border);
    }
    .message .meta {
      font-size: 0.75rem;
      color: var(--text-muted);
      margin-top: 6px;
    }
    .chat-input-bar {
      display: flex;
      padding: 12px;
      gap: 10px;
      background: #0d1117;
      border-top: 1px solid var(--border);
    }
    .chat-input-bar input { flex: 1; }
    .card {
      background: var(--bg-main);
      border: 1px solid var(--border);
      border-radius: 6px;
      padding: 12px;
      font-size: 0.85rem;
    }
    .provider-tag {
      font-size: 0.75rem;
      padding: 2px 6px;
      border-radius: 4px;
      background: #388bfd33;
      color: #58a6ff;
      margin-left: 6px;
    }
  </style>
</head>
<body>
  <header>
    <div class="logo">
      🎋 Bam<span>AI</span> Studio <span style="font-size:0.75rem; background:#30363d; padding:2px 8px; border-radius:12px; color:#c9d1d9;">v1.2</span>
    </div>
    <div style="display:flex; gap:12px; align-items:center;">
      <div class="status-badge" id="aiStatusBadge">
        <span class="dot" id="aiDot"></span> <span id="aiStatusText">Kiểm tra kết nối...</span>
      </div>
      <div class="status-badge" id="docBadge">
        📚 <span id="docCount">0</span> tài liệu
      </div>
    </div>
  </header>

  <div class="layout">
    <!-- Cột trái: Quản lý RAG & Cấu hình LLM Key -->
    <aside class="sidebar">
      <div>
        <h3>⚙️ Cấu hình LLM & API</h3>
        <label>Mô hình xử lý RAG</label>
        <select id="llmProvider">
          <option value="local">Local Qwen 2.5 (1.5B) [Offline]</option>
          <option value="deepseek">DeepSeek AI [Cloud API]</option>
        </select>
        
        <div style="margin-top:12px;">
          <label>DeepSeek API Key (Tùy chọn)</label>
          <input type="password" id="deepseekKey" placeholder="sk-..." />
          <button class="secondary" style="width:100%; margin-top:8px;" onclick="saveConfig()">Lưu Khóa API</button>
        </div>
      </div>

      <hr style="border-color:var(--border);" />

      <div>
        <h3>📥 Nạp Tài liệu vào RAG</h3>
        <label>Nội dung kiến thức / Tài liệu</label>
        <textarea id="docContent" rows="6" placeholder="Dán văn bản, tài liệu, quy định nội bộ hoặc ghi chú dự án vào đây..."></textarea>
        
        <div style="margin-top:8px; display:flex; align-items:center; gap:8px;">
          <input type="checkbox" id="useLLMProcess" style="width:auto;" />
          <label for="useLLMProcess" style="margin:0; font-size:0.8rem;">Dùng DeepSeek làm sạch & tóm tắt</label>
        </div>

        <button style="width:100%; margin-top:12px;" onclick="indexDocument()">+ Nạp vào Bộ Nhớ RAG</button>
      </div>

      <div class="card" id="connInfo">
        <strong>Thông tin hệ thống:</strong>
        <div style="color:var(--text-muted); margin-top:4px;">
          • Lõi Local: <code id="llamaHostLabel">...</code><br>
          • Vector Store: chromem-go<br>
          • Ngôn ngữ mặc định: Tiếng Việt
        </div>
      </div>
    </aside>

    <!-- Khu vực chính: Hỏi đáp & Chat RAG -->
    <main class="main-content">
      <div class="chat-container">
        <div class="chat-messages" id="chatList">
          <div class="message assistant">
            Xin chào! Tôi là <strong>BamAI</strong> — Trợ lý AI tích hợp trên hệ điều hành BamOS 🎋.<br>
            Tôi có thể tìm kiếm dữ liệu từ bộ nhớ vector RAG và trả lời câu hỏi của bạn hoàn toàn bằng <strong>Tiếng Việt</strong>.
            <div class="meta">Hệ thống sẵn sàng</div>
          </div>
        </div>

        <div class="chat-input-bar">
          <input type="text" id="userQuestion" placeholder="Nhập câu hỏi để tra cứu dữ liệu RAG..." onkeydown="if(event.key==='Enter') askRAG()" />
          <button onclick="askRAG()">Gửi câu hỏi</button>
        </div>
      </div>
    </main>
  </div>

  <script>
    async function loadStatus() {
      try {
        const res = await fetch('/health');
        const data = await res.json();
        document.getElementById('docCount').innerText = data.doc_count;
        document.getElementById('llamaHostLabel').innerText = data.llama_host;
        document.getElementById('aiDot').style.background = '#2ea043';
        document.getElementById('aiStatusText').innerText = 'Hệ thống hoạt động';
      } catch (e) {
        document.getElementById('aiDot').style.background = '#f85149';
        document.getElementById('aiStatusText').innerText = 'Local AI chưa mở';
      }

      try {
        const confRes = await fetch('/config');
        const conf = await confRes.json();
        if (conf.has_deepseek) {
          document.getElementById('deepseekKey').placeholder = 'Đã lưu: ' + conf.masked_key;
        }
      } catch(e) {}
    }

    async function saveConfig() {
      const key = document.getElementById('deepseekKey').value.trim();
      if (!key) return alert('Vui lòng nhập API Key!');
      try {
        const res = await fetch('/config', {
          method: 'POST',
          headers: {'Content-Type': 'application/json'},
          body: JSON.stringify({deepseek_api_key: key})
        });
        const d = await res.json();
        alert('Đã lưu DeepSeek API Key thành công!');
        document.getElementById('deepseekKey').value = '';
        document.getElementById('deepseekKey').placeholder = 'Đã lưu: ' + d.masked_key;
      } catch(e) {
        alert('Lỗi lưu cấu hình: ' + e);
      }
    }

    async function indexDocument() {
      const content = document.getElementById('docContent').value.trim();
      if (!content) return alert('Vui lòng nhập nội dung tài liệu!');
      const useLLM = document.getElementById('useLLMProcess').checked;

      const btn = event.target;
      btn.innerText = 'Đang xử lý & tạo Vector...';
      btn.disabled = true;

      try {
        const res = await fetch('/index', {
          method: 'POST',
          headers: {'Content-Type': 'application/json'},
          body: JSON.stringify({content: content, use_llm: useLLM})
        });
        let data = {};
        const text = await res.text();
        try {
          data = JSON.parse(text);
        } catch (_) {
          data = { error: text };
        }
        if (res.ok) {
          alert('Đã nạp tài liệu thành công (ID: ' + data.id + ')');
          document.getElementById('docContent').value = '';
          loadStatus();
        } else {
          alert('Lỗi: ' + (data.error || res.statusText || text));
        }
      } catch (e) {
        alert('Không thể kết nối đến RAG service: ' + e);
      } finally {
        btn.innerText = '+ Nạp vào Bộ Nhớ RAG';
        btn.disabled = false;
      }
    }

    async function askRAG() {
      const input = document.getElementById('userQuestion');
      const question = input.value.trim();
      if (!question) return;

      const provider = document.getElementById('llmProvider').value;
      const chatList = document.getElementById('chatList');

      // Thêm câu hỏi của user
      const userDiv = document.createElement('div');
      userDiv.className = 'message user';
      userDiv.innerText = question;
      chatList.appendChild(userDiv);
      input.value = '';
      chatList.scrollTop = chatList.scrollHeight;

      // Hiển thị trạng thái đang xử lý
      const botDiv = document.createElement('div');
      botDiv.className = 'message assistant';
      botDiv.innerHTML = 'Đang tra cứu vector và suy luận qua AI (' + (provider === 'deepseek' ? 'DeepSeek' : 'Local Qwen') + ')...';
      chatList.appendChild(botDiv);
      chatList.scrollTop = chatList.scrollHeight;

      try {
        const res = await fetch('/ask', {
          method: 'POST',
          headers: {'Content-Type': 'application/json'},
          body: JSON.stringify({question: question, provider: provider, topK: 3})
        });
        let data = {};
        const text = await res.text();
        try {
          data = JSON.parse(text);
        } catch (_) {
          data = { error: text };
        }
        if (res.ok) {
          let contextSnippet = '';
          if (data.contexts && data.contexts.length > 0) {
            contextSnippet = '<br><br><details style="margin-top:6px; font-size:0.8rem; color:var(--text-muted);"><summary>Xem ' + data.contexts.length + ' tài liệu tham chiếu</summary><div style="margin-top:4px; padding:6px; background:#0d1117; border-radius:4px;">' + data.contexts.map(c => '• ' + c.content.substring(0, 150) + '...').join('<br>') + '</div></details>';
          }
          botDiv.innerHTML = data.answer + contextSnippet + '<div class="meta">Nguồn xử lý: <span class="provider-tag">' + data.provider + '</span></div>';
        } else {
          botDiv.innerHTML = '<span style="color:var(--danger)">Lỗi: ' + (data.error || res.statusText || text) + '</span>';
        }
      } catch (e) {
        botDiv.innerHTML = '<span style="color:var(--danger)">Lỗi kết nối tới dịch vụ: ' + e + '</span>';
      }
      chatList.scrollTop = chatList.scrollHeight;
    }

    loadStatus();
  </script>
</body>
</html>
`
