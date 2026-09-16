package domain

type RAGDocument struct {
	ID        string    `json:"id"`
	Source    string    `json:"source"`
	Title     string    `json:"title"`
	Domain    string    `json:"domain"`
	Content   string    `json:"content"`
	Embedding []float32 `json:"embedding,omitempty"`
}

type RAGResult struct {
	Source   string  `json:"source"`
	Title    string  `json:"title"`
	Snippet  string  `json:"snippet"`
	Score    float64 `json:"score"`
	FTSScore float64 `json:"fts_score"`
	VecScore float64 `json:"vec_score"`
}

type RAGStats struct {
	DocumentCount int `json:"document_count"`
	TotalChunks   int `json:"total_chunks"`
	TotalChars    int `json:"total_chars"`
}
