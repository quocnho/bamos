package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"strings"
	"sync"
	"time"

	"github.com/philippgille/chromem-go"
)

type RAGManager struct {
	mu         sync.RWMutex
	db         *chromem.DB
	collection *chromem.Collection
	llamaHost  string
	dbPath     string
}

func NewRAGManager(dbPath, llamaHost string) *RAGManager {
	rm := &RAGManager{
		dbPath:    dbPath,
		llamaHost: llamaHost,
	}
	rm.initDB()
	return rm
}

func (rm *RAGManager) initDB() {
	rm.mu.Lock()
	defer rm.mu.Unlock()

	var db *chromem.DB
	var err error
	if rm.dbPath != "" {
		db, err = chromem.NewPersistentDB(rm.dbPath, false)
	}
	if err != nil || db == nil {
		db = chromem.NewDB()
	}
	rm.db = db

	col, err := rm.db.GetOrCreateCollection("knowledge", nil, nil)
	if err == nil {
		rm.collection = col
	}
}

type openAIEmbeddingReq struct {
	Input string `json:"input"`
}

type openAIEmbeddingResp struct {
	Data []struct {
		Embedding []float32 `json:"embedding"`
	} `json:"data"`
}

func (rm *RAGManager) getEmbedding(ctx context.Context, text string) ([]float32, error) {
	client := &http.Client{Timeout: 5 * time.Second}
	reqBody, _ := json.Marshal(openAIEmbeddingReq{Input: text})
	url := fmt.Sprintf("%s/v1/embeddings", rm.llamaHost)

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, url, bytes.NewBuffer(reqBody))
	if err != nil {
		return nil, err
	}
	req.Header.Set("Content-Type", "application/json")

	resp, err := client.Do(req)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("embedding status: %d", resp.StatusCode)
	}

	var res openAIEmbeddingResp
	if err := json.NewDecoder(resp.Body).Decode(&res); err != nil {
		return nil, err
	}
	if len(res.Data) == 0 {
		return nil, fmt.Errorf("no embedding returned")
	}
	return res.Data[0].Embedding, nil
}

func (rm *RAGManager) RetrieveContext(ctx context.Context, query string, topK int) (string, error) {
	rm.mu.RLock()
	col := rm.collection
	rm.mu.RUnlock()

	if col == nil {
		return "", fmt.Errorf("collection chưa khởi tạo")
	}

	emb, err := rm.getEmbedding(ctx, query)
	if err != nil {
		return "", fmt.Errorf("không thể lấy embedding: %w", err)
	}

	count := col.Count()
	if count == 0 {
		return "", nil
	}
	if topK > count {
		topK = count
	}

	res, err := col.QueryEmbedding(ctx, emb, topK, nil, nil)
	if err != nil {
		return "", fmt.Errorf("query chromem thất bại: %w", err)
	}

	if len(res) == 0 {
		return "", nil
	}

	var sb strings.Builder
	sb.WriteString("=== THÔNG TIN TRI THỨC NỘI BỘ (RAG) ===\n")
	for i, doc := range res {
		sb.WriteString(fmt.Sprintf("[%d] (Score: %.2f):\n%s\n\n", i+1, doc.Similarity, doc.Content))
	}
	sb.WriteString("=========================================\n")
	return sb.String(), nil
}

func (rm *RAGManager) IndexDocument(ctx context.Context, id, content string, metadata map[string]string) error {
	rm.mu.RLock()
	col := rm.collection
	rm.mu.RUnlock()

	if col == nil {
		return fmt.Errorf("collection chưa khởi tạo")
	}

	emb, err := rm.getEmbedding(ctx, content)
	if err != nil {
		return fmt.Errorf("không thể lấy embedding để học: %w", err)
	}

	doc, err := chromem.NewDocument(ctx, id, metadata, emb, content, nil)
	if err != nil {
		return err
	}

	return col.AddDocument(ctx, doc)
}

// DocumentCount trả về số tài liệu hiện có trong tri thức.
func (rm *RAGManager) DocumentCount() int {
	rm.mu.RLock()
	col := rm.collection
	rm.mu.RUnlock()
	if col == nil {
		return 0
	}
	return col.Count()
}

// Reset xoá toàn bộ tri thức: xoá file database rồi khởi tạo lại.
func (rm *RAGManager) Reset() error {
	rm.mu.Lock()
	path := rm.dbPath
	rm.collection = nil
	rm.db = nil
	rm.mu.Unlock()

	if path != "" {
		if err := os.Remove(path); err != nil && !os.IsNotExist(err) {
			return fmt.Errorf("không xoá được dữ liệu tri thức: %w", err)
		}
	}

	rm.initDB()
	return nil
}
