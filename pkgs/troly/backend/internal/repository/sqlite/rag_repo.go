package sqlite

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"os"
	"regexp"
	"sort"
	"strings"
	"sync"

	"troly/backend/internal/platform/embedding"
)

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

type RAGRepo struct {
	mu     sync.RWMutex
	db     *sql.DB
	dbPath string
	vecExt string
	vecCli *embedding.VectorClient
}

func NewRAGRepo(dbPath, llamaHost string) *RAGRepo {
	db, vecExt, _ := OpenRAGDB(dbPath)
	return &RAGRepo{
		db:     db,
		dbPath: dbPath,
		vecExt: vecExt,
		vecCli: embedding.NewVectorClient(llamaHost),
	}
}

func (r *RAGRepo) SetLlamaHost(host string) {
	r.vecCli.SetHost(host)
}

func (r *RAGRepo) DocumentCount() int {
	r.mu.RLock()
	defer r.mu.RUnlock()
	if r.db == nil {
		return 0
	}
	var count int
	_ = r.db.QueryRow(`SELECT COUNT(*) FROM documents`).Scan(&count)
	return count
}

func (r *RAGRepo) ListDocuments() ([]map[string]any, error) {
	r.mu.RLock()
	defer r.mu.RUnlock()
	if r.db == nil {
		return nil, fmt.Errorf("database nil")
	}

	rows, err := r.db.Query(`
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

func (r *RAGRepo) DeleteDocumentBySource(source string) error {
	r.mu.Lock()
	defer r.mu.Unlock()
	if r.db == nil {
		return fmt.Errorf("database nil")
	}

	rows, err := r.db.Query(`SELECT id FROM documents WHERE source = ?`, source)
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
			_, _ = r.db.Exec(`DELETE FROM documents_fts WHERE id = ?`, id)
		}
	}

	_, err = r.db.Exec(`DELETE FROM documents WHERE source = ?`, source)
	return err
}

func (r *RAGRepo) Reset() error {
	r.mu.Lock()
	if r.db != nil {
		_ = r.db.Close()
		r.db = nil
	}
	path := r.dbPath
	r.mu.Unlock()

	if path != "" && path != ":memory:" {
		_ = os.Remove(path)
		_ = os.Remove(path + "-wal")
		_ = os.Remove(path + "-shm")
	}

	db, vecExt, err := OpenRAGDB(path)
	if err != nil {
		return err
	}
	r.mu.Lock()
	r.db = db
	r.vecExt = vecExt
	r.mu.Unlock()
	return nil
}

func splitChunks(text string, maxChars, overlap int) []string {
	if len(text) <= maxChars {
		return []string{text}
	}
	var chunks []string
	paragraphs := strings.Split(text, "\n\n")
	var current strings.Builder

	for _, p := range paragraphs {
		if current.Len()+len(p) > maxChars && current.Len() > 0 {
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

func (r *RAGRepo) IndexDocument(ctx context.Context, id, content string, metadata map[string]string) error {
	r.mu.RLock()
	db := r.db
	r.mu.RUnlock()
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

	chunks := splitChunks(content, 700, 100)
	for i, chunkText := range chunks {
		chunkID := fmt.Sprintf("%s_c%d", id, i+1)
		chunkTitle := fmt.Sprintf("%s (Phần %d/%d)", title, i+1, len(chunks))

		var embJSON []byte
		emb, err := r.vecCli.GetEmbedding(ctx, chunkText)
		if err == nil && len(emb) > 0 {
			embJSON, _ = json.Marshal(emb)
		}

		_, err = db.ExecContext(ctx, `
			INSERT OR REPLACE INTO documents (id, source, title, domain, content, embedding, created_at)
			VALUES (?, ?, ?, ?, ?, ?, CURRENT_TIMESTAMP)
		`, chunkID, source, chunkTitle, domain, chunkText, embJSON)
		if err != nil {
			return err
		}

		_, _ = db.ExecContext(ctx, `DELETE FROM documents_fts WHERE id = ?`, chunkID)
		_, _ = db.ExecContext(ctx, `
			INSERT INTO documents_fts (id, title, content)
			VALUES (?, ?, ?)
		`, chunkID, chunkTitle, chunkText)
	}

	return nil
}

func sanitizeFTSQuery(query string) string {
	re := regexp.MustCompile(`[^\p{L}\p{N}\s]+`)
	cleaned := re.ReplaceAllString(query, " ")
	words := strings.Fields(cleaned)
	if len(words) == 0 {
		return ""
	}
	return strings.Join(words, " OR ")
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
	x := dot / (sqrt(normA) * sqrt(normB))
	return x
}

func sqrt(v float64) float64 {
	if v <= 0 {
		return 0
	}
	x := v
	for i := 0; i < 15; i++ {
		x = 0.5 * (x + v/x)
	}
	return x
}

func (r *RAGRepo) RetrieveContext(ctx context.Context, query string, topK int) (string, error) {
	chunks, err := r.HybridSearch(ctx, query, topK, 0.65)
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

func (r *RAGRepo) HybridSearch(ctx context.Context, query string, topK int, alpha float64) ([]KnowledgeChunk, error) {
	r.mu.RLock()
	db := r.db
	r.mu.RUnlock()
	if db == nil {
		return nil, fmt.Errorf("database nil")
	}

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

	vecResults := make(map[string]KnowledgeChunk)
	vecRank := make(map[string]int)

	qEmb, embErr := r.vecCli.GetEmbedding(ctx, query)
	if embErr == nil && len(qEmb) > 0 {
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
		if c.Similarity == 0 {
			c.Similarity = 0.5 + score*20
			if c.Similarity > 0.95 {
				c.Similarity = 0.95
			}
		}
		finalList = append(finalList, c)
	}

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
