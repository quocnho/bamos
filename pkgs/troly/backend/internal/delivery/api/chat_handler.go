package api

import (
	"encoding/json"
	"fmt"
	"net/http"
	"strings"

	"troly/backend/internal/domain"
	"troly/backend/internal/usecase/chat"
)

type ChatHandler struct {
	chatUc *chat.ChatUsecase
}

func NewChatHandler(chatUc *chat.ChatUsecase) *ChatHandler {
	return &ChatHandler{chatUc: chatUc}
}

type AskRequest struct {
	Prompt    string               `json:"prompt"`
	UseRAG    bool                 `json:"use_rag"`
	Directory string               `json:"directory"`
	History   []domain.ChatMessage `json:"history"`
	Stream    bool                 `json:"stream"`
}

func (h *ChatHandler) HandleAsk(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		Error(w, http.StatusMethodNotAllowed, "Method not allowed")
		return
	}

	var req AskRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		Error(w, http.StatusBadRequest, "Invalid request body")
		return
	}

	if strings.TrimSpace(req.Prompt) == "" {
		Error(w, http.StatusBadRequest, "Prompt is required")
		return
	}

	if req.Stream {
		h.handleStreamAsk(w, r, req)
		return
	}

	h.handleSyncAsk(w, r, req)
}

func (h *ChatHandler) handleStreamAsk(w http.ResponseWriter, r *http.Request, req AskRequest) {
	flusher, ok := w.(http.Flusher)
	if !ok {
		Error(w, http.StatusInternalServerError, "Streaming not supported")
		return
	}

	w.Header().Set("Content-Type", "text/event-stream")
	w.Header().Set("Cache-Control", "no-cache")
	w.Header().Set("Connection", "keep-alive")

	ctx := r.Context()
	h.chatUc.AskStream(ctx, req.Prompt, req.UseRAG, req.History,
		func(chunk string) {
			data, _ := json.Marshal(map[string]string{"delta": chunk})
			_, _ = fmt.Fprintf(w, "data: %s\n\n", string(data))
			flusher.Flush()
		},
		func() {
			_, _ = fmt.Fprint(w, "data: [DONE]\n\n")
			flusher.Flush()
		},
		func(errMsg string) {
			data, _ := json.Marshal(map[string]string{"error": errMsg})
			_, _ = fmt.Fprintf(w, "data: %s\n\n", string(data))
			flusher.Flush()
		},
	)
}

func (h *ChatHandler) handleSyncAsk(w http.ResponseWriter, r *http.Request, req AskRequest) {
	var fullAnswer strings.Builder
	var streamErr string
	doneChan := make(chan struct{})

	ctx := r.Context()
	go func() {
		h.chatUc.AskStream(ctx, req.Prompt, req.UseRAG, req.History,
			func(chunk string) { fullAnswer.WriteString(chunk) },
			func() { close(doneChan) },
			func(err string) {
				streamErr = err
				close(doneChan)
			},
		)
	}()

	select {
	case <-ctx.Done():
		Error(w, http.StatusRequestTimeout, "Request cancelled or timed out")
	case <-doneChan:
		if streamErr != "" {
			Error(w, http.StatusBadGateway, streamErr)
			return
		}
		JSON(w, http.StatusOK, map[string]string{"answer": fullAnswer.String()})
	}
}
