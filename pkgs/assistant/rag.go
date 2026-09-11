package main

import (
	"bytes"
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"sync"
	"time"

	"github.com/mattn/go-sqlite3"
)

var (
	registerDriverOnce sync.Once
)

func registerCustomSQLiteDriver(vecPath string) {
	registerDriverOnce.Do(func() {
		sql.Register("sqlite3_custom", &sqlite3.SQLiteDriver{
			ConnectHook: func(conn *sqlite3.SQLiteConn) error {
				if vecPath != "" {
					if err := conn.LoadExtension(vecPath, "sqlite3_vec_init"); err != nil {
						fmt.Printf("[RAGManager] Auto-load vec0 extension (%s) thất bại: %v\n", vecPath, err)
					} else {
						fmt.Printf("[RAGManager] Đã kích hoạt extension sqlite-vec qua ConnectHook thành công: %s\n", vecPath)
					}
				}
				return nil
			},
		})
	})
}

type RAGManager struct {
	mu        sync.RWMutex
	db        *sql.DB
	dbPath    string
	llamaHost string
	vecExt    string
}

type KnowledgeChunk struct {
	ID         string  `json:"id"`
	Source     string  `json:"source"`
	Title      string  `json:"title"`
	Domain     string  `json:"domain"`
	Content    string  `json:"content"`
	Score      float64 `json:"score"`
	FTSScore   float64 `json:"fts_score"`
	VecScore   float64 `json:"vec_score"`
	Similarity float64 `json:"similarity"`
}

type openAIEmbeddingReq struct {
	Input string `json:"input"`
}

type openAIEmbeddingResp struct {
	Data []struct {
		Embedding []float32 `json:"embedding"`
	} `json:"data"`
}

func findVec0Extension() string {
	// Các đường dẫn phổ biến của vec0.so trên NixOS và hệ thống
	candidates := []string{
		os.Getenv("SQLITE_VEC_PATH"),
		"/run/current-system/sw/lib/vec0.so",
		"/usr/lib/vec0.so",
		"/usr/local/lib/vec0.so",
	}

	// Quét trong /nix/store
	matches, _ := filepath.Glob("/nix/store/*-sqlite-vec-*/lib/vec0.so")
	candidates = append(candidates, matches...)

	for _, p := range candidates {
		if p != "" {
			if _, err := os.Stat(p); err == nil {
				return p
			}
		}
	}
	return ""
}

func NewRAGManager(dbPath, llamaHost string) *RAGManager {
	vecExt := findVec0Extension()
	rm := &RAGManager{
		dbPath:    dbPath,
		llamaHost: llamaHost,
		vecExt:    vecExt,
	}
	rm.initDB()
	return rm
}

func (rm *RAGManager) initDB() {
	rm.mu.Lock()
	defer rm.mu.Unlock()

	if rm.dbPath == "" {
		rm.dbPath = ":memory:"
	} else {
		// Kiểm tra nếu thư mục gốc /var/lib/bamos/rag không ghi được do chạy quyền user thông thường,
		// tự động fallback về thư mục cá nhân của người dùng: ~/.local/share/bamos/rag.sqlite
		home, _ := os.UserHomeDir()
		userRAGDir := filepath.Join(home, ".local", "share", "bamos")
		_ = os.MkdirAll(userRAGDir, 0755)

		fi, err := os.Stat(rm.dbPath)
		if err == nil && fi.IsDir() {
			// Thử tạo tệp thử nghiệm trong thư mục này
			testFile := filepath.Join(rm.dbPath, ".write_test")
			if wErr := os.WriteFile(testFile, []byte("ok"), 0644); wErr != nil {
				rm.dbPath = filepath.Join(userRAGDir, "rag_knowledge.sqlite")
			} else {
				_ = os.Remove(testFile)
				rm.dbPath = filepath.Join(rm.dbPath, "rag_knowledge.sqlite")
			}
		} else {
			dir := filepath.Dir(rm.dbPath)
			if err := os.MkdirAll(dir, 0755); err != nil {
				rm.dbPath = filepath.Join(userRAGDir, "rag_knowledge.sqlite")
			}
		}
	}

	// Đăng ký custom driver với extension hook
	driverName := "sqlite3"
	if rm.vecExt != "" {
		registerCustomSQLiteDriver(rm.vecExt)
		driverName = "sqlite3_custom"
	}

	dsn := fmt.Sprintf("%s?_journal_mode=WAL", rm.dbPath)
	db, err := sql.Open(driverName, dsn)
	if err != nil {
		fmt.Printf("[RAGManager] Lỗi mở SQLite: %v\n", err)
		return
	}
	rm.db = db

	// Kiểm tra kết nối
	if err := db.Ping(); err != nil {
		fmt.Printf("[RAGManager] Cảnh báo ping SQLite: %v\n", err)
	}

	// Tạo các bảng dữ liệu
	// 1. Bảng documents chính
	_, _ = db.Exec(`
		CREATE TABLE IF NOT EXISTS documents (
			id TEXT PRIMARY KEY,
			source TEXT,
			title TEXT,
			domain TEXT,
			content TEXT,
			embedding BLOB,
			created_at DATETIME DEFAULT CURRENT_TIMESTAMP
		);
	`)

	// 2. Bảng Full-Text Search FTS5 (unicode61 tokenizer)
	_, _ = db.Exec(`
		CREATE VIRTUAL TABLE IF NOT EXISTS documents_fts USING fts5(
			id UNINDEXED,
			title,
			content,
			tokenize = 'unicode61 remove_diacritics 2'
		);
	`)

	// 3. Virtual table sqlite-vec (nếu extension loaded)
	if rm.vecExt != nilString {
		// Thử tạo bảng vec0 virtual table
		_, err = db.Exec(`
			CREATE VIRTUAL TABLE IF NOT EXISTS documents_vec USING vec0(
				doc_id text partition key,
				embedding float[1024] distance_metric=cosine
			);
		`)
		if err != nil {
			// Một số model embedding có dimension 1536 hoặc 768 hoặc 512, vec0 hỗ trợ dynamic hoặc fixed
			// Nếu lỗi dimension mismatch, fallback dạng vector thô
			_ = err
		}
	}
}

const nilString = ""

func (rm *RAGManager) getEmbedding(ctx context.Context, text string) ([]float32, error) {
	client := &http.Client{Timeout: 8 * time.Second}
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

// splitChunks chia nhỏ nội dung tài liệu thành các đoạn vừa vặn (chunking)
func splitChunks(content string, chunkSize, overlap int) []string {
	content = strings.TrimSpace(content)
	if len(content) <= chunkSize {
		return []string{content}
	}

	var chunks []string
	paragraphs := strings.Split(content, "\n\n")
	var current strings.Builder

	for _, p := range paragraphs {
		p = strings.TrimSpace(p)
		if p == "" {
			continue
		}
		if current.Len()+len(p) > chunkSize && current.Len() > 0 {
			chunks = append(chunks, current.String())
			current.Reset()
		}
		if current.Len() > 0 {
			current.WriteString("\n\n")
		}
		current.WriteString(p)
	}
	if current.Len() > 0 {
		chunks = append(chunks, current.String())
	}
	return chunks
}

func cosineSimilarity(a, b []float32) float64 {
	if len(a) != len(b) || len(a) == 0 {
		return 0
	}
	var dot, normA, normB float64
	for i := range a {
		dot += float64(a[i]) * float64(b[i])
		normA += float64(a[i]) * float64(a[i])
		normB += float64(b[i]) * float64(b[i])
	}
	if normA == 0 || normB == 0 {
		return 0
	}
	return dot / (sqrt(normA) * sqrt(normB))
}

func sqrt(v float64) float64 {
	// Newton's method
	if v <= 0 {
		return 0
	}
	x := v
	for i := 0; i < 15; i++ {
		x = 0.5 * (x + v/x)
	}
	return x
}

// sanitizeFTSQuery chuẩn hoá chuỗi tìm kiếm cho FTS5
func sanitizeFTSQuery(query string) string {
	// Lọc bỏ các ký tự đặc biệt của cú pháp FTS5 như * " : ^ NEAR
	re := regexp.MustCompile(`[^\p{L}\p{N}\s]+`)
	cleaned := re.ReplaceAllString(query, " ")
	words := strings.Fields(cleaned)
	if len(words) == 0 {
		return ""
	}
	// Dùng OR giữa các từ để tối ưu recall
	return strings.Join(words, " OR ")
}

// RetrieveContext thực hiện Hybrid Search (FTS5 + Vector Cosine RRF)
func (rm *RAGManager) RetrieveContext(ctx context.Context, query string, topK int) (string, error) {
	rm.mu.RLock()
	db := rm.db
	rm.mu.RUnlock()

	if db == nil {
		return "", fmt.Errorf("cơ sở dữ liệu RAG chưa khởi tạo")
	}

	chunks, err := rm.HybridSearch(ctx, query, topK, 0.65)
	if err != nil {
		return "", err
	}
	if len(chunks) == 0 {
		return "", nil
	}

	var sb strings.Builder
	sb.WriteString("=== THÔNG TIN TRI THỨC NỘI BỘ (HYBRID RAG: FTS5 + VECTOR) ===\n")
	for i, doc := range chunks {
		sb.WriteString(fmt.Sprintf("[%d] Nguồn: %s | Độ khớp: %.1f%%\n%s\n\n", i+1, doc.Source, doc.Similarity*100, doc.Content))
	}
	sb.WriteString("===============================================================\n")
	return sb.String(), nil
}

// HybridSearch kết hợp FTS5 + Cosine Distance dùng Reciprocal Rank Fusion (RRF)
func (rm *RAGManager) HybridSearch(ctx context.Context, query string, topK int, alpha float64) ([]KnowledgeChunk, error) {
	rm.mu.RLock()
	db := rm.db
	rm.mu.RUnlock()

	if db == nil {
		return nil, fmt.Errorf("database nil")
	}

	// 1. FTS5 Search
	ftsResults := make(map[string]KnowledgeChunk)
	ftsRank := make(map[string]int)

	ftsQuery := sanitizeFTSQuery(query)
	if ftsQuery != "" {
		rows, err := db.QueryContext(ctx, `
			SELECT d.id, d.source, d.title, d.domain, d.content, bm25(documents_fts) as rank
			FROM documents_fts f
			JOIN documents d ON f.id = d.id
			WHERE documents_fts MATCH ?
			ORDER BY rank ASC
			LIMIT 30
		`, ftsQuery)
		if err == nil {
			defer rows.Close()
			idx := 1
			for rows.Next() {
				var c KnowledgeChunk
				var bm25Rank float64
				if err := rows.Scan(&c.ID, &c.Source, &c.Title, &c.Domain, &c.Content, &bm25Rank); err == nil {
					c.FTSScore = bm25Rank
					ftsResults[c.ID] = c
					ftsRank[c.ID] = idx
					idx++
				}
			}
		}
	}

	// 2. Vector Embedding Search
	vecResults := make(map[string]KnowledgeChunk)
	vecRank := make(map[string]int)

	qEmb, embErr := rm.getEmbedding(ctx, query)
	if embErr == nil && len(qEmb) > 0 {
		// Quét tài liệu có embedding để tính Cosine Distance
		rows, err := db.QueryContext(ctx, `SELECT id, source, title, domain, content, embedding FROM documents WHERE embedding IS NOT NULL`)
		if err == nil {
			defer rows.Close()

			type scoredItem struct {
				chunk KnowledgeChunk
				sim   float64
			}
			var scoredList []scoredItem

			for rows.Next() {
				var c KnowledgeChunk
				var embBlob []byte
				if err := rows.Scan(&c.ID, &c.Source, &c.Title, &c.Domain, &c.Content, &embBlob); err == nil {
					if len(embBlob) > 0 {
						var docEmb []float32
						if json.Unmarshal(embBlob, &docEmb) == nil {
							sim := cosineSimilarity(qEmb, docEmb)
							scoredList = append(scoredList, scoredItem{chunk: c, sim: sim})
						}
					}
				}
			}

			// Sắp xếp theo Cosine Similarity giảm dần
			sort.Slice(scoredList, func(i, j int) bool {
				return scoredList[i].sim > scoredList[j].sim
			})

			limit := 30
			if len(scoredList) < limit {
				limit = len(scoredList)
			}
			for i := 0; i < limit; i++ {
				item := scoredList[i]
				item.chunk.VecScore = item.sim
				item.chunk.Similarity = item.sim
				vecResults[item.chunk.ID] = item.chunk
				vecRank[item.chunk.ID] = i + 1
			}
		}
	}

	// 3. Reciprocal Rank Fusion (RRF)
	// Score = (1 - alpha) * 1/(60 + Rank_FTS) + alpha * 1/(60 + Rank_Vec)
	const k = 60.0
	fusedScores := make(map[string]float64)
	allChunks := make(map[string]KnowledgeChunk)

	for id, chunk := range ftsResults {
		allChunks[id] = chunk
		rFTS := ftsRank[id]
		fusedScores[id] += (1.0 - alpha) * (1.0 / (k + float64(rFTS)))
	}

	for id, chunk := range vecResults {
		if existing, ok := allChunks[id]; ok {
			existing.VecScore = chunk.VecScore
			existing.Similarity = chunk.Similarity
			allChunks[id] = existing
		} else {
			allChunks[id] = chunk
		}
		rVec := vecRank[id]
		fusedScores[id] += alpha * (1.0 / (k + float64(rVec)))
	}

	var finalList []KnowledgeChunk
	for id, score := range fusedScores {
		c := allChunks[id]
		c.Score = score
		// Tính tương đối Similarity nếu chưa có
		if c.Similarity == 0 {
			c.Similarity = 0.5 + score*20
			if c.Similarity > 0.95 {
				c.Similarity = 0.95
			}
		}
		finalList = append(finalList, c)
	}

	// Sắp xếp theo Fused Score giảm dần
	sort.Slice(finalList, func(i, j int) bool {
		return finalList[i].Score > finalList[j].Score
	})

	if topK <= 0 {
		topK = 4
	}
	if len(finalList) > topK {
		finalList = finalList[:topK]
	}

	return finalList, nil
}

// IndexDocument nạp tài liệu vào cả FTS5 và SQLite Vector Storage (kèm tự động chia đoạn Chunks)
func (rm *RAGManager) IndexDocument(ctx context.Context, id, content string, metadata map[string]string) error {
	rm.mu.RLock()
	db := rm.db
	rm.mu.RUnlock()

	if db == nil {
		return fmt.Errorf("cơ sở dữ liệu RAG chưa sẵn sàng")
	}

	title := metadata["title"]
	source := metadata["source"]
	domain := metadata["domain"]
	if domain == "" {
		domain = "general"
	}
	if title == "" {
		title = id
	}

	// Chia thành các đoạn chunk từ 600 - 800 ký tự
	chunks := splitChunks(content, 700, 100)

	for i, chunkText := range chunks {
		chunkID := fmt.Sprintf("%s_c%d", id, i+1)
		chunkTitle := fmt.Sprintf("%s (Phần %d/%d)", title, i+1, len(chunks))

		// Lấy embedding cho từng chunk
		var embJSON []byte
		emb, err := rm.getEmbedding(ctx, chunkText)
		if err == nil && len(emb) > 0 {
			embJSON, _ = json.Marshal(emb)
		}

		// Ghi vào bảng documents
		_, err = db.ExecContext(ctx, `
			INSERT OR REPLACE INTO documents (id, source, title, domain, content, embedding, created_at)
			VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
		`, chunkID, source, chunkTitle, domain, chunkText, embJSON)
		if err != nil {
			return err
		}

		// Ghi vào bảng documents_fts
		_, _ = db.ExecContext(ctx, `DELETE FROM documents_fts WHERE id = ?`, chunkID)
		_, _ = db.ExecContext(ctx, `
			INSERT INTO documents_fts (id, title, content)
			VALUES (?, ?, ?)
		`, chunkID, chunkTitle, chunkText)
	}

	return nil
}

// DocumentCount trả về tổng số chunks tài liệu trong tri thức
func (rm *RAGManager) DocumentCount() int {
	rm.mu.RLock()
	db := rm.db
	rm.mu.RUnlock()

	if db == nil {
		return 0
	}

	var count int
	row := db.QueryRow(`SELECT COUNT(*) FROM documents`)
	_ = row.Scan(&count)
	return count
}

// ListDocuments trả về danh sách các tệp/nguồn tri thức đã nạp
func (rm *RAGManager) ListDocuments() ([]map[string]any, error) {
	rm.mu.RLock()
	db := rm.db
	rm.mu.RUnlock()

	if db == nil {
		return nil, fmt.Errorf("database nil")
	}

	rows, err := db.Query(`
		SELECT source, domain, COUNT(*) as chunks, MAX(created_at) as latest
		FROM documents
		GROUP BY source, domain
		ORDER BY latest DESC
	`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var list []map[string]any
	for rows.Next() {
		var source, domain, latest string
		var chunks int
		if err := rows.Scan(&source, &domain, &chunks, &latest); err == nil {
			list = append(list, map[string]any{
				"source":     source,
				"domain":     domain,
				"chunks":     chunks,
				"created_at": latest,
			})
		}
	}
	return list, nil
}

// DeleteDocumentBySource xoá tất cả các chunks của một nguồn tài liệu
func (rm *RAGManager) DeleteDocumentBySource(source string) error {
	rm.mu.Lock()
	defer rm.mu.Unlock()

	if rm.db == nil {
		return fmt.Errorf("database nil")
	}

	// Lấy danh sách ID chunk thuộc source để xoá FTS
	rows, err := rm.db.Query(`SELECT id FROM documents WHERE source = ?`, source)
	if err == nil {
		var ids []string
		for rows.Next() {
			var id string
			if rows.Scan(&id) == nil {
				ids = append(ids, id)
			}
		}
		rows.Close()

		for _, id := range ids {
			_, _ = rm.db.Exec(`DELETE FROM documents_fts WHERE id = ?`, id)
		}
	}

	_, err = rm.db.Exec(`DELETE FROM documents WHERE source = ?`, source)
	return err
}

// Reset xoá toàn bộ tri thức và khởi tạo lại SQLite
func (rm *RAGManager) Reset() error {
	rm.mu.Lock()
	if rm.db != nil {
		_ = rm.db.Close()
		rm.db = nil
	}
	path := rm.dbPath
	rm.mu.Unlock()

	if path != "" && path != ":memory:" {
		_ = os.Remove(path)
		_ = os.Remove(path + "-wal")
		_ = os.Remove(path + "-shm")
	}

	rm.initDB()
	return nil
}
