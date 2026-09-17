package sqlite

import (
	"database/sql"
	"fmt"
	"os"
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
