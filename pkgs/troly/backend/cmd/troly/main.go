package main

import (
	"context"
	"fmt"
	"net"
	"net/http"
	"net/url"
	"os"
	"strings"
	"time"

	"troly"
	"troly/backend/internal/delivery/gui"
	"troly/backend/internal/platform/linux"
	"troly/backend/internal/platform/llm"
	"troly/backend/internal/repository/fs"
	"troly/backend/internal/repository/sqlite"
	"troly/backend/internal/usecase/chat"
	"troly/backend/internal/usecase/profile"
	"troly/backend/internal/usecase/settings"
	"troly/backend/internal/usecase/system"
	"troly/backend/internal/usecase/waka"
)

func assistantPort() string {
	if port := os.Getenv("BAMAI_PORT"); port != "" {
		return port
	}
	return "9195"
}

func assistantURL(path string) string {
	return fmt.Sprintf("http://127.0.0.1:%s%s", assistantPort(), path)
}

func isRunning() bool {
	conn, err := net.DialTimeout("tcp", "127.0.0.1:"+assistantPort(), 300*time.Millisecond)
	if err == nil {
		conn.Close()
		return true
	}
	return false
}

func main() {
	fmt.Println("==================================================")
	fmt.Println("🐶 TroLy (Trợ lý) - BamOS Mascot AI (Clean Arch)")
	fmt.Println("==================================================")

	linux.PreferX11Backend()
	linux.PreferStableWebKitRendering()

	startupPanel := ""
	for i := 1; i < len(os.Args); i++ {
		if os.Args[i] == "--settings" && i+1 < len(os.Args) {
			panel := os.Args[i+1]
			if isRunning() {
				endpoint := assistantURL("/api/open-settings?panel=" + url.QueryEscape(panel))
				_, _ = http.Get(endpoint)
				return
			}
			startupPanel = panel
			break
		}
	}

	for _, arg := range os.Args[1:] {
		if arg == "--hide" || arg == "--quit" {
			if !isRunning() {
				fmt.Println("[BamAI] Không có BamAI nào đang chạy.")
				return
			}
			endpoint := "/api/hide"
			if arg == "--quit" {
				endpoint = "/api/quit"
			}
			_, _ = http.Get(assistantURL(endpoint))
			return
		}
	}

	cfgStore := fs.NewConfigStore()
	cfg := cfgStore.LoadConfig()

	ragRepo := sqlite.NewRAGRepo(cfg.RAGDBPath, cfg.LlamaHost)
	memRepo := sqlite.NewMemoryRepo()
	toolRepo := fs.NewToolRepo()
	profileRepo := fs.NewProfileRepo()
	wakaRepo := fs.NewWakaRepo()

	llamaServer := llm.NewLlamaServer(cfg)
	cliEngine := linux.NewCLIEngine(memRepo)

	profileUc := profile.NewProfileUsecase(profileRepo, ragRepo)
	wakaUc := waka.NewWakaUsecase(wakaRepo, ragRepo)
	inspectUc := system.NewInspectUsecase(ragRepo, memRepo)
	modelMgr := settings.NewModelManager(cfgStore, llamaServer)
	chatUc := chat.NewChatUsecase(cfg, ragRepo, memRepo, toolRepo, cliEngine, llamaServer, profileUc, wakaUc)

	var targetDir string
	for i := 1; i < len(os.Args); i++ {
		arg := os.Args[i]
		if arg == "--context-dir" && i+1 < len(os.Args) {
			targetDir = os.Args[i+1]
			break
		} else if !strings.HasPrefix(arg, "-") {
			if info, err := os.Stat(arg); err == nil && info.IsDir() {
				targetDir = arg
				break
			}
		}
	}

	if isRunning() {
		if targetDir != "" {
			escaped := url.QueryEscape(targetDir)
			_, _ = http.Get(assistantURL("/api/context-dir?path=" + escaped))
		} else {
			_, _ = http.Get(assistantURL("/api/show"))
		}
		return
	}

	if targetDir != "" {
		memRepo.SetActiveDirectory(targetDir)
	}

	go func() {
		time.Sleep(1 * time.Second)
		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()
		profileUc.SyncToRAG(ctx)
		wakaUc.SyncToRAG(ctx)
	}()

	if os.Getenv("DISPLAY") == "" && os.Getenv("WAYLAND_DISPLAY") == "" {
		fmt.Println("[BamAI Lỗi] Không tìm thấy DISPLAY hoặc WAYLAND_DISPLAY.")
		os.Exit(1)
	}

	app := gui.NewApp(
		troly.FrontendFS,
		cfgStore,
		ragRepo,
		memRepo,
		toolRepo,
		profileRepo,
		wakaRepo,
		llamaServer,
		chatUc,
		profileUc,
		wakaUc,
		inspectUc,
		modelMgr,
	)
	app.Run(startupPanel)
}
