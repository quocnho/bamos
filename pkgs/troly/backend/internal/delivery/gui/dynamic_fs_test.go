package gui

import (
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"troly"
	"io/fs"
)

func TestDynamicFrontendFS(t *testing.T) {
	subFS, err := fs.Sub(troly.FrontendFS, "frontend")
	if err != nil {
		t.Fatalf("failed to sub frontendFS: %v", err)
	}
	dynamicFS := NewDynamicFrontendFS(subFS)
	server := httptest.NewServer(http.FileServer(http.FS(dynamicFS)))
	defer server.Close()

	resp, err := http.Get(server.URL + "/")
	if err != nil {
		t.Fatalf("failed GET /: %v", err)
	}
	defer resp.Body.Close()

	body, _ := io.ReadAll(resp.Body)
	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected 200 OK, got %d, body: %s", resp.StatusCode, string(body))
	}
	if !strings.Contains(string(body), "app-container") {
		t.Fatalf("expected app-container in index.html, got: %s", string(body))
	}
}
