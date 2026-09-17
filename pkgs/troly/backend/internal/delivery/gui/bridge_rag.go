package gui

import (
	"context"
	"encoding/json"
	"fmt"
	"path/filepath"
	"time"
)

func (d *Dispatcher) handleRagStats() {
	cfg := d.cfgStore.LoadConfig()
	count := d.ragRepo.DocumentCount()
	PushJSON("onRagStats", map[string]any{
		"ok":     true,
		"count":  count,
		"path":   cfg.RAGDBPath,
		"top_k":  cfg.RAGTopK,
		"enable": cfg.EnableRAG,
	})
}

func (d *Dispatcher) handleRagAddDocuments(raw json.RawMessage) {
	var req struct {
		Documents []struct {
			Name    string `json:"name"`
			Content string `json:"content"`
		} `json:"documents"`
	}
	if err := json.Unmarshal(raw, &req); err != nil || len(req.Documents) == 0 {
		PushErrorJSON("onRagIndexed", "Không có tài liệu để nạp")
		return
	}
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Minute)
	defer cancel()

	added := 0
	for i, doc := range req.Documents {
		id := fmt.Sprintf("%s_%d", filepath.Base(doc.Name), time.Now().UnixNano())
		err := d.ragRepo.IndexDocument(ctx, id, doc.Content, map[string]string{
			"source": doc.Name,
			"title":  filepath.Base(doc.Name),
		})
		if err == nil {
			added++
		}
		PushJSON("onRagIndexProgress", map[string]any{
			"ok":    true,
			"index": i + 1,
			"total": len(req.Documents),
			"name":  doc.Name,
		})
	}
	PushJSON("onRagIndexed", map[string]any{
		"ok":      true,
		"added":   added,
		"total":   len(req.Documents),
		"count":   d.ragRepo.DocumentCount(),
		"message": fmt.Sprintf("Đã nạp %d/%d tài liệu vào tri thức.", added, len(req.Documents)),
	})
}

func (d *Dispatcher) handleRagClear() {
	if err := d.ragRepo.Reset(); err != nil {
		PushErrorJSON("onRagCleared", err.Error())
		return
	}
	PushJSON("onRagCleared", map[string]any{"ok": true, "message": "Đã xoá toàn bộ tri thức.", "count": 0})
}

func (d *Dispatcher) handleRagListDocuments() {
	docs, err := d.ragRepo.ListDocuments()
	if err != nil {
		PushJSON("onRagDocumentsListed", map[string]any{"ok": false, "documents": []any{}})
		return
	}
	PushJSON("onRagDocumentsListed", map[string]any{"ok": true, "documents": docs})
}

func (d *Dispatcher) handleRagDeleteDoc(raw json.RawMessage) {
	var req struct {
		Source string `json:"source"`
	}
	if err := json.Unmarshal(raw, &req); err != nil || req.Source == "" {
		return
	}
	_ = d.ragRepo.DeleteDocumentBySource(req.Source)
	d.handleRagListDocuments()
}
