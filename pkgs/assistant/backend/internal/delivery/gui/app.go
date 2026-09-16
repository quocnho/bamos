package gui

import (
	"encoding/json"
	"fmt"
	"io/fs"
	"net"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"

	"bamos-assistant/backend/internal/platform/llm"
	repoFS "bamos-assistant/backend/internal/repository/fs"
	"bamos-assistant/backend/internal/repository/sqlite"
	"bamos-assistant/backend/internal/usecase/chat"
	"bamos-assistant/backend/internal/usecase/profile"
	"bamos-assistant/backend/internal/usecase/settings"
	"bamos-assistant/backend/internal/usecase/system"
	"bamos-assistant/backend/internal/usecase/waka"
)

type App struct {
	frontendFS  fs.FS
	cfgStore    *repoFS.ConfigStore
	ragRepo     *sqlite.RAGRepo
	memRepo     *sqlite.MemoryRepo
	toolRepo    *repoFS.ToolRepo
	profileRepo *repoFS.ProfileRepo
	wakaRepo    *repoFS.WakaRepo
	llamaServer *llm.LlamaServer
	chatUc      *chat.ChatUsecase
	profileUc   *profile.ProfileUsecase
	wakaUc      *waka.WakaUsecase
	inspectUc   *system.InspectUsecase
	modelMgr    *settings.ModelManager
	dispatcher  *Dispatcher
}

func NewApp(
	frontendFS fs.FS,
	cfgStore *repoFS.ConfigStore,
	ragRepo *sqlite.RAGRepo,
	memRepo *sqlite.MemoryRepo,
	toolRepo *repoFS.ToolRepo,
	profileRepo *repoFS.ProfileRepo,
	wakaRepo *repoFS.WakaRepo,
	llamaServer *llm.LlamaServer,
	chatUc *chat.ChatUsecase,
	profileUc *profile.ProfileUsecase,
	wakaUc *waka.WakaUsecase,
	inspectUc *system.InspectUsecase,
	modelMgr *settings.ModelManager,
) *App {
	disp := &Dispatcher{
		cfgStore:    cfgStore,
		ragRepo:     ragRepo,
		memRepo:     memRepo,
		toolRepo:    toolRepo,
		profileRepo: profileRepo,
		wakaRepo:    wakaRepo,
		llamaServer: llamaServer,
		chatUc:      chatUc,
		profileUc:   profileUc,
		wakaUc:      wakaUc,
		inspectUc:   inspectUc,
		modelMgr:    modelMgr,
	}
	SetGlobalDispatcher(disp)

	return &App{
		frontendFS:  frontendFS,
		cfgStore:    cfgStore,
		ragRepo:     ragRepo,
		memRepo:     memRepo,
		toolRepo:    toolRepo,
		profileRepo: profileRepo,
		wakaRepo:    wakaRepo,
		llamaServer: llamaServer,
		chatUc:      chatUc,
		profileUc:   profileUc,
		wakaUc:      wakaUc,
		inspectUc:   inspectUc,
		modelMgr:    modelMgr,
		dispatcher:  disp,
	}
}

type windowState struct {
	Right  int `json:"right"`
	Bottom int `json:"bottom"`
	WorkW  int `json:"work_w"`
	WorkH  int `json:"work_h"`
	Scale  int `json:"scale"`
}

func (a *App) applySavedWindowState() {
	cfg := a.cfgStore.LoadConfig()
	keepAbove := cfg.AlwaysOnTop
	statePath := repoFS.GetWindowStatePath()
	SetWindowStatePath(statePath)

	paths := []string{statePath}
	for _, p := range paths {
		data, err := os.ReadFile(p)
		if err != nil {
			continue
		}
		var st windowState
		if json.Unmarshal(data, &st) != nil || st.Right <= 0 || st.Bottom <= 0 {
			continue
		}
		if st.WorkW <= 0 || st.WorkH <= 0 || st.Scale <= 0 {
			continue
		}
		SetInitialGeometry(st.Right, st.Bottom, st.WorkW, st.WorkH, st.Scale, keepAbove)
		return
	}
	SetDefaultKeepAbove(keepAbove)
}

func (a *App) Run(startupPanel string) {
	subFS, err := fs.Sub(a.frontendFS, "frontend")
	if err != nil {
		fmt.Printf("[BamAI GUI] Lỗi đọc thư mục frontend: %v\n", err)
		return
	}

	a.applySavedWindowState()

	dynamicFS := NewDynamicFrontendFS(subFS)
	mux := http.NewServeMux()
	mux.Handle("/", http.FileServer(http.FS(dynamicFS)))

	mux.HandleFunc("/api/context-dir", func(w http.ResponseWriter, r *http.Request) {
		dir := r.URL.Query().Get("path")
		if dir != "" {
			if a.memRepo != nil {
				a.memRepo.SetActiveDirectory(dir)
			}
			EvalJS(fmt.Sprintf("window.setDirectoryContext && window.setDirectoryContext('%s');", EscapeJSString(dir)))
			TriggerWindowShow()
		}
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(w, `{"status":"ok","dir":"%s"}`, dir)
	})

	mux.HandleFunc("/api/open-settings", func(w http.ResponseWriter, r *http.Request) {
		panel := r.URL.Query().Get("panel")
		TriggerWindowShow()
		EvalJS(fmt.Sprintf("window.openSettingsPanel && window.openSettingsPanel('%s');", EscapeJSString(panel)))
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintf(w, `{"status":"ok","panel":"%s"}`, panel)
	})

	mux.HandleFunc("/api/show", func(w http.ResponseWriter, r *http.Request) {
		TriggerWindowShow()
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintln(w, `{"status":"ok"}`)
	})

	mux.HandleFunc("/api/hide", func(w http.ResponseWriter, r *http.Request) {
		TriggerWindowHide()
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintln(w, `{"status":"ok"}`)
	})

	mux.HandleFunc("/api/quit", func(w http.ResponseWriter, r *http.Request) {
		if a.llamaServer != nil {
			go a.llamaServer.Stop()
		}
		TriggerWindowQuit()
		w.Header().Set("Content-Type", "application/json")
		fmt.Fprintln(w, `{"status":"ok"}`)
	})

	port := os.Getenv("BAMAI_PORT")
	if port == "" {
		port = "9195"
	}
	address := "127.0.0.1:" + port
	listener, err := net.Listen("tcp", address)
	var serverURL string
	if err == nil {
		server := &http.Server{Handler: mux}
		go func() {
			_ = server.Serve(listener)
		}()
		serverURL = "http://" + address
	} else {
		fallbackServer := httptest.NewServer(mux)
		defer fallbackServer.Close()
		serverURL = fallbackServer.URL
	}

	uiURL := serverURL
	if startupPanel != "" {
		uiURL = serverURL + "#panel=" + url.QueryEscape(startupPanel)
	}

	SetupWindowAndWebview(uiURL)
	RunMainLoop()
}
