package api

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"path/filepath"
	"time"

	"troly/backend/internal/repository/sqlite"
)

type RAGHandler struct {
	ragRepo *sqlite.RAGRepo
}

func NewRAGHandler(ragRepo *sqlite.RAGRepo) *RAGHandler {
	return &RAGHandler{ragRepo: ragRepo}
}

func (h *RAGHandler) HandleStats(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		Error(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	count := h.ragRepo.DocumentCount()
	JSON(w, http.StatusOK, map[string]int{
		"doc_count": count,
	})
}

func (h *RAGHandler) HandleListDocs(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodGet {
		Error(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	docs, err := h.ragRepo.ListDocuments()
	if err != nil {
		Error(w, http.StatusInternalServerError, err.Error())
		return
	}
	JSON(w, http.StatusOK, docs)
}

func (h *RAGHandler) HandleIndex(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		Error(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	var req struct {
		Name    string `json:"name"`
		Content string `json:"content"`
	}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil || req.Content == "" {
		Error(w, http.StatusBadRequest, "content is required")
		return
	}

	ctx, cancel := context.WithTimeout(r.Context(), 2*time.Minute)
	defer cancel()

	id := fmt.Sprintf("%s_%d", filepath.Base(req.Name), time.Now().UnixNano())
	err := h.ragRepo.IndexDocument(ctx, id, req.Content, map[string]string{
		"source": req.Name,
		"title":  filepath.Base(req.Name),
	})
	if err != nil {
		Error(w, http.StatusInternalServerError, err.Error())
		return
	}
	JSON(w, http.StatusOK, map[string]string{"status": "indexed", "id": id})
}

func (h *RAGHandler) HandleDeleteDoc(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodDelete && r.Method != http.MethodPost {
		Error(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	source := r.URL.Query().Get("source")
	if source == "" {
		Error(w, http.StatusBadRequest, "source parameter is required")
		return
	}

	if err := h.ragRepo.DeleteDocumentBySource(source); err != nil {
		Error(w, http.StatusInternalServerError, err.Error())
		return
	}
	JSON(w, http.StatusOK, map[string]string{"deleted_source": source})
}

func (h *RAGHandler) HandleClear(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost && r.Method != http.MethodDelete {
		Error(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}
	if err := h.ragRepo.Reset(); err != nil {
		Error(w, http.StatusInternalServerError, err.Error())
		return
	}
	JSON(w, http.StatusOK, map[string]string{"message": "All RAG data cleared"})
}
