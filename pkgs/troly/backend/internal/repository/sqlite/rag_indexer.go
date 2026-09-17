package sqlite

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
)

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

		if r.vecExt != "" && len(emb) > 0 && string(embJSON) != "" {
			_, _ = db.ExecContext(ctx, `DELETE FROM documents_vec WHERE id = ?`, chunkID)
			_, _ = db.ExecContext(ctx, `
				INSERT INTO documents_vec (id, embedding)
				VALUES (?, ?)
			`, chunkID, string(embJSON))
		}
	}

	return nil
}
