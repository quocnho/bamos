package sqlite

import (
	"context"
	"encoding/json"
	"fmt"
	"regexp"
	"sort"
	"strings"
)

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
	return dot / (sqrt(normA) * sqrt(normB))
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
		embJSONBytes, _ := json.Marshal(qEmb)
		embJSONStr := string(embJSONBytes)

		if r.vecExt != "" && embJSONStr != "" {
			rows, err := db.QueryContext(ctx, `
				SELECT v.id, d.source, d.title, d.domain, d.content, v.distance
				FROM documents_vec v
				JOIN documents d ON v.id = d.id
				WHERE v.embedding MATCH ? AND k = 30
			`, embJSONStr)
			if err == nil {
				defer rows.Close()
				idx := 1
				for rows.Next() {
					var c KnowledgeChunk
					var dist float64
					if err := rows.Scan(&c.ID, &c.Source, &c.Title, &c.Domain, &c.Content, &dist); err == nil {
						sim := 1.0 - dist
						if sim < 0 {
							sim = 0
						}
						c.VecScore = sim
						c.Similarity = sim
						vecResults[c.ID] = c
						vecRank[c.ID] = idx
						idx++
					}
				}
			}
		}

		if len(vecResults) == 0 {
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
