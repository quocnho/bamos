package llm

import (
	"fmt"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"strings"
	"sync"
	"time"

	"troly/backend/internal/domain"
)

type LlamaServer struct {
	cfg      domain.Config
	startMu  sync.Mutex
	starting bool
}

func NewLlamaServer(cfg domain.Config) *LlamaServer {
	return &LlamaServer{cfg: cfg}
}

func (s *LlamaServer) UpdateConfig(cfg domain.Config) {
	s.startMu.Lock()
	defer s.startMu.Unlock()
	s.cfg = cfg
}

func (s *LlamaServer) urlPort(raw string) string {
	u, err := url.Parse(raw)
	if err != nil {
		return ""
	}
	return u.Port()
}

func (s *LlamaServer) aiServerEnv(modelPath string) []string {
	env := make([]string, 0, len(os.Environ())+2)
	for _, kv := range os.Environ() {
		if strings.HasPrefix(kv, "BAMAI_PORT=") {
			continue
		}
		env = append(env, kv)
	}
	env = append(env, "BAMAI_MODEL_PATH="+modelPath)
	if port := s.urlPort(s.cfg.LlamaHost); port != "" {
		env = append(env, "BAMAI_PORT="+port)
	}
	return env
}

func (s *LlamaServer) IsOffline() bool {
	host := s.cfg.LlamaHost
	if host == "" {
		host = domain.DefaultLlamaHost
	}
	client := &http.Client{Timeout: 600 * time.Millisecond}
	resp, err := client.Get(strings.TrimRight(host, "/") + "/health")
	if err != nil {
		return true
	}
	defer resp.Body.Close()
	return resp.StatusCode != http.StatusOK
}

func (s *LlamaServer) Start() error {
	server := exec.Command("bamos-ai-server")
	server.Env = s.aiServerEnv(s.cfg.ModelPath)
	return server.Start()
}

func (s *LlamaServer) Stop() {
	fmt.Println("[BamAI Power] Đóng dịch vụ AI (llama-server)...")
	_ = exec.Command("pkill", "-9", "-f", "bamos-ai-server").Run()
	_ = exec.Command("pkill", "-9", "-f", "llama-server").Run()
}

func (s *LlamaServer) WaitReady(timeout time.Duration) bool {
	deadline := time.Now().Add(timeout)
	for time.Now().Before(deadline) {
		if !s.IsOffline() {
			return true
		}
		time.Sleep(500 * time.Millisecond)
	}
	return !s.IsOffline()
}

func (s *LlamaServer) EnsureRunning(onProgress func(string), onReady func(started bool)) {
	if !s.IsOffline() {
		if onReady != nil {
			onReady(false)
		}
		return
	}

	s.startMu.Lock()
	if s.starting {
		s.startMu.Unlock()
		return
	}
	s.starting = true
	s.startMu.Unlock()

	if onProgress != nil {
		onProgress("Đang khởi động dịch vụ AI (llama-server)…")
	}

	go func() {
		defer func() {
			s.startMu.Lock()
			s.starting = false
			s.startMu.Unlock()
		}()

		if err := s.Start(); err != nil {
			fmt.Printf("[BamAI Power] Lỗi khởi động llama-server: %v\n", err)
		}
		s.WaitReady(30 * time.Second)
		if onReady != nil {
			onReady(true)
		}
	}()
}
