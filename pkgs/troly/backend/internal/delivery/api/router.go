package api

import (
	"net/http"

	"troly/backend/internal/repository/fs"
	"troly/backend/internal/repository/sqlite"
	"troly/backend/internal/usecase/chat"
	"troly/backend/internal/usecase/profile"
	"troly/backend/internal/usecase/settings"
	"troly/backend/internal/usecase/system"
	"troly/backend/internal/usecase/waka"
)

type Router struct {
	mux *http.ServeMux
}

func NewRouter(
	chatUc *chat.ChatUsecase,
	cfgStore *fs.ConfigStore,
	modelMgr *settings.ModelManager,
	ragRepo *sqlite.RAGRepo,
	profileUc *profile.ProfileUsecase,
	wakaUc *waka.WakaUsecase,
	inspectUc *system.InspectUsecase,
) *Router {
	mux := http.NewServeMux()

	chatH := NewChatHandler(chatUc)
	settingsH := NewSettingsHandler(cfgStore, modelMgr)
	ragH := NewRAGHandler(ragRepo)
	systemH := NewSystemHandler(profileUc, wakaUc, inspectUc)

	// Chat endpoints
	mux.HandleFunc("/api/chat/ask", chatH.HandleAsk)

	// Settings & Model endpoints
	mux.HandleFunc("/api/settings", func(w http.ResponseWriter, r *http.Request) {
		if r.Method == http.MethodGet {
			settingsH.HandleGetSettings(w, r)
		} else {
			settingsH.HandleSaveSettings(w, r)
		}
	})
	mux.HandleFunc("/api/models", settingsH.HandleListModels)

	// RAG endpoints
	mux.HandleFunc("/api/rag/stats", ragH.HandleStats)
	mux.HandleFunc("/api/rag/documents", ragH.HandleListDocs)
	mux.HandleFunc("/api/rag/index", ragH.HandleIndex)
	mux.HandleFunc("/api/rag/delete", ragH.HandleDeleteDoc)
	mux.HandleFunc("/api/rag/clear", ragH.HandleClear)

	// Profile & System & Waka endpoints
	mux.HandleFunc("/api/profile", systemH.HandleProfile)
	mux.HandleFunc("/api/waka/stats", systemH.HandleWaka)
	mux.HandleFunc("/api/system/inspect", systemH.HandleInspect)

	return &Router{mux: mux}
}

func (r *Router) Handler() http.Handler {
	return WithCORS(r.mux)
}

func (r *Router) ServeMux() *http.ServeMux {
	return r.mux
}
